function Export-VcCertificate {
    <#
    .SYNOPSIS
    Export certificate data from Certificate Manager, SaaS

    .DESCRIPTION
    Export certificate data in PEM format.  You can retrieve the certificate, chain, and key.
    You can also save the certificate and private key in PEM or PKCS12 format.

    .PARAMETER ID
    Certificate ID, also known as uuid.  Use Find-VcCertificate or Get-VcCertificate to determine the ID.
    You can pipe from those functions as well.

    .PARAMETER PrivateKeyPassword
    Password required to include the private key.
    You can either provide a String, SecureString, or PSCredential.
    Requires PowerShell v7.0+.

    .PARAMETER IncludeChain
    Include the certificate chain with the exported or saved PEM certificate data.

    .PARAMETER OutPath
    Folder path to save the certificate to.  The name of the file will be determined automatically.
    For each certificate a directory will be created in this folder with the format Name-ID.
    In the case of PKCS12, the file will be saved to the root of the folder.

    .PARAMETER PKCS12
    Export the certificate and private key in PKCS12 format.  The default is PEM.
    This is the preferred approach if directly importing into VDC or another VC tenant.
    Requires PowerShell v7.1+.

    .PARAMETER UseLegacy
    Use legacy encryption algorithm when exporting in PKCS12 format.
    Required for older systems that do not support modern algorithms.

    .PARAMETER ThrottleLimit
    Limit the number of threads when running in parallel; the default is 100.
    Setting the value to 1 will disable multithreading.
    On PS v5 the ThreadJob module is required.  If not found, multithreading will be disabled.

    .PARAMETER Force
    Force installation of PSSodium if not already installed

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A Certificate Manager, SaaS key can also provided.

    .INPUTS
    ID

    .OUTPUTS
    PSCustomObject

    .EXAMPLE
    $certId | Export-VcCertificate

    Export certificate data

    .EXAMPLE
    $certId | Export-VcCertificate -PrivateKeyPassword 'myPassw0rd!'

    Export certificate and private key data

    .EXAMPLE
    $certId | Export-VcCertificate -PrivateKeyPassword 'myPassw0rd!' -PKCS12 -OutPath '~/temp'

    Export certificate and private key in PKCS12 format

    .EXAMPLE
    $cert | Export-VcCertificate -OutPath '~/temp'

    Get certificate data and save to a file

    .EXAMPLE
    $cert | Export-VcCertificate -IncludeChain

    Get certificate data with the certificate chain included.

    .NOTES
    This function requires PSSodium.  Install it from the PSGallery or use -Force to automatically install.
    PS v7.1+ is required.
    On Windows, the latest Visual C++ redist must be installed.  See https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist.
    #>

    [CmdletBinding(DefaultParameterSetName = 'PEM')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'Converting to a secure string, its already plaintext')]

    param (

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('certificateId')]
        [string] $ID,

        [Parameter(ParameterSetName = 'PEM')]
        [Parameter(ParameterSetName = 'PKCS12', Mandatory)]
        [ValidateScript(
            {
                if ($PSVersionTable.PSVersion -lt [version]'7.0') {
                    throw 'Exporting private keys is only supported on PowerShell v7.0+'
                }

                if ( $_ -is [string] -or $_ -is [securestring] -or $_ -is [pscredential] ) {
                    $true
                }
                else {
                    throw 'Unsupported type.  Provide either a String, SecureString, or PSCredential.'
                }
            }
        )]
        [psobject] $PrivateKeyPassword,

        [Parameter(ParameterSetName = 'PEM')]
        [switch] $IncludeChain,

        [Parameter(ParameterSetName = 'PEM')]
        [Parameter(ParameterSetName = 'PKCS12')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                if (Test-Path $_ -PathType Container) {
                    $true
                }
                else {
                    Throw "Output path '$_' does not exist"
                }
            })]
        [String] $OutPath,

        [Parameter(ParameterSetName = 'PKCS12', Mandatory)]
        [ValidateScript(
            {
                if ($PSVersionTable.PSVersion -lt [version]'7.1') {
                    throw 'Exporting in PKCS#12 format is only supported on PowerShell v7.1+'
                }
                $true
            }
        )]
        [switch] $PKCS12,

        [Parameter(ParameterSetName = 'PKCS12')]
        [switch] $UseLegacy,

        [Parameter()]
        [int32] $ThrottleLimit = 100,

        [Parameter()]
        [switch] $Force,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession = (Get-VenafiSession)
    )

    begin {
        Test-VenafiSession $PSCmdlet.MyInvocation
        Initialize-PSSodium -Force:$Force

        $allCerts = [System.Collections.Generic.List[string]]::new()
        $pset = $PSCmdlet.ParameterSetName

        # set up the scriptblocks to be executed via invoke-venafiparallel
        if ( $PrivateKeyPassword ) {

            $pkPassString = $PrivateKeyPassword | ConvertTo-PlaintextString

            $sb = {

                $id = $PSItem
                $pkPassString = $using:pkPassString

                $params = @{
                    Method       = 'Post'
                    Header       = @{ 'accept' = 'application/octet-stream' }
                    UriRoot      = 'outagedetection/v1'
                    UriLeaf      = 'certificates/{0}/keystore' -f $id
                    Body         = @{
                        'exportFormat'                = $using:pset
                        'encryptedKeystorePassphrase' = ''
                        'certificateLabel'            = ''
                        'useLegacyFormat'             = $using:UseLegacy.IsPresent
                    }
                    FullResponse = $true
                }

                $out = [pscustomobject] @{
                    certificateId = $id
                    error         = ''
                    format        = $using:pset
                }

                $thisCert = Get-VcCertificate -id $id

                if ( -not $thisCert ) {
                    $out.error = 'Certificate not found'
                    return $out
                }

                if ( -not $thisCert.dekHash ) {
                    $out.error = 'Private key not found'
                    return $out
                }

                # build the encrypted private key password
                Import-Module PSSodium -Force
                $publicKey = Invoke-VenafiRestMethod -UriLeaf "edgeencryptionkeys/$($thisCert.dekHash)" | Select-Object -ExpandProperty key
                $privateKeyPasswordEnc = ConvertTo-SodiumEncryptedString -Text $pkPassString -PublicKey $publicKey
                $params.Body.encryptedPrivateKeyPassphrase = $privateKeyPasswordEnc

                $innerResponse = Invoke-VenafiRestMethod @params

                if ($innerResponse.StatusCode -notin 200, 201, 202) {
                    $out.error = $innerResponse.StatusDescription
                    return $out
                }

                if ( -not $innerResponse.Content ) {
                    $out.error = 'No certificate data received'
                    return $out
                }

                # pkcs12 is a byte array of a pfx file so its easy to handle
                if ( $using:pset -eq 'PKCS12' ) {
                    if ( $using:OutPath ) {
                        $dest = Join-Path -Path (Resolve-Path -Path $using:OutPath) -ChildPath ('{0}.pfx' -f $thisCert.certificateName)
                        [IO.File]::WriteAllBytes($dest, $innerResponse.Content)
                        $out | Add-Member @{'outPath' = $dest }
                    }
                    else {
                        # return contents
                        $out | Add-Member @{ 'certificateData' = [System.Convert]::ToBase64String($innerResponse.Content) }
                        if ( $pkPassString ) {
                            $out | Add-Member @{ 'privateKeyPassword' = (New-Object System.Management.Automation.PSCredential('unused', ($pkPassString | ConvertTo-SecureString -AsPlainText -Force))) }
                        }
                    }
                    return $out
                }

                # pem format returns a byte array of a zip file so lots more processing to do

                $zipFile = '{0}.zip' -f (New-TemporaryFile)
                $unzipPath = Join-Path -Path (Split-Path -Path $zipFile -Parent) -ChildPath $id

                try {
                    # always save the zip file then decide to copy to the final destination or return contents
                    [IO.File]::WriteAllBytes($zipFile, $innerResponse.Content)

                    Write-Verbose ('Expanding {0} to {1}' -f $zipFile, $unzipPath)

                    Expand-Archive -Path $zipFile -DestinationPath $unzipPath
                    $unzipFiles = Get-ChildItem -Path $unzipPath

                    if ( $using:OutPath ) {

                        if ( $using:PKCS12 ) {
                            # create pkcs12 from crt and key
                            $keyFile = Get-ChildItem -Path $unzipPath -Filter '*.key'

                            if ( $keyFile.Count -ne 1 ) {
                                $out.error = 'Private key not found'
                                return $out
                            }

                            $keyPath = $keyFile.FullName
                            $crtPath = $keyPath.Replace('.key', '.crt')
                            $cert = [System.Security.Cryptography.X509Certificates.x509Certificate2]::CreateFromEncryptedPemFile($crtPath, $pkPassString, $keyPath)
                            # export content type of 3 is for pfx
                            $cert.Export(3, $pkPassString) | Set-Content -Path (Join-Path -Path $using:OutPath -ChildPath ('{0}.pfx' -f $keyFile.BaseName)) -AsByteStream
                        }
                        else {
                            # copy files from zip to final desination since they are already in pem format
                            $dest = Join-Path -Path (Resolve-Path -Path $using:OutPath) -ChildPath $thisCert.certificateName
                            $null = New-Item -Path $dest -ItemType Directory -Force
                            $unzipFiles | Copy-Item -Destination $dest -Force
                            $out | Add-Member @{'outPath' = $dest }
                        }
                    }
                    else {
                        # pull in the contents so we can provide them
                        switch ($unzipFiles) {
                            { $_.Name.EndsWith('.key') } {
                                $out | Add-Member @{'KeyPem' = Get-Content -Path $_.FullName -Raw }
                            }
                            { $_.Name.EndsWith('root-last.pem') } {

                                $pem = Split-CertificateData -InputObject (Get-Content -Path $_.FullName -Raw)

                                $out | Add-Member @{'CertPem' = $pem.CertPem }
                                if ( $using:IncludeChain ) {
                                    $out | Add-Member @{'ChainPem' = $pem.ChainPem }
                                }
                            }
                        }
                    }
                    $out
                }
                finally {
                    Remove-Item -Path $unzipPath -Recurse -Force -ErrorAction SilentlyContinue
                    Remove-Item -Path $zipFile -Force -ErrorAction SilentlyContinue
                }
            }
        }
        else {
            # no need to get the entire keystore if just getting cert/chain

            # cert/chain only, no private key.  different api call, better performance.
            $sb = {
                $params = @{
                    UriRoot      = 'outagedetection/v1'
                    UriLeaf      = 'certificates/{0}/contents' -f $PSItem
                    Body         = @{
                        format = 'PEM'
                    }
                    FullResponse = $true
                }

                if ( $using:IncludeChain ) {
                    $params.Body.chainOrder = 'EE_FIRST'
                }
                else {
                    $params.Body.chainOrder = 'EE_ONLY'
                }

                $out = [pscustomobject] @{
                    certificateId = $PSItem
                    error         = if ($innerResponse.StatusCode -notin 200, 201, 202) { $innerResponse.StatusDescription }
                }

                $thisCert = Get-VcCertificate -id $PSItem

                if ( -not $thisCert ) {
                    $out.error = 'Certificate not found'
                    return $out
                }

                $innerResponse = Invoke-VenafiRestMethod @params
                $certificateData = $innerResponse.Content

                if ( $certificateData ) {
                    if ( $using:OutPath ) {
                        $dest = Join-Path -Path (Resolve-Path -Path $using:OutPath) -ChildPath $thisCert.certificateName
                        $null = New-Item -Path $dest -ItemType Directory -Force
                        $outFile = Join-Path -Path $dest -ChildPath ('{0}.{1}' -f $PSItem, $params.Body.format)
                        try {
                            $sw = [IO.StreamWriter]::new($outFile, $false, [Text.Encoding]::ASCII)
                            $sw.WriteLine($certificateData)
                            Write-Verbose "Saved $outFile"
                        }
                        finally {
                            if ($null -ne $sw) { $sw.Close() }
                        }

                        $out | Add-Member @{'outPath' = $dest }
                    }
                    else {
                        $out | Add-Member @{'certificateData' = $certificateData }
                    }
                }
                $out
            }
        }
    }

    process {
        $allCerts.Add($ID)
    }

    end {
        if ( $allCerts.Count -eq 0 ) {
            return
        }

        $invokeParams = @{
            InputObject   = $allCerts
            ScriptBlock   = $sb
            ThrottleLimit = $ThrottleLimit
            ProgressTitle = 'Exporting certificates'
            VenafiSession = $VenafiSession
        }
        Invoke-VenafiParallel @invokeParams
    }
}


