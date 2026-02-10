function Export-VdcCertificate {
    <#
    .SYNOPSIS
    Export certificate data from Certificate Manager, Self-Hosted

    .DESCRIPTION
    Export certificate data including certificate, key, and chain.
    Export certificates by path or vault id, the latter is helpful for historical certificates.

    .PARAMETER Path
    Full path to the certificate

    .PARAMETER VaultId
    Vault ID to the certificate

    .PARAMETER X509
    Provide output in X509 Base64 format.  This is the default if no format is provided.

    .PARAMETER Pkcs7
    Provide output in PKCS #7 format

    .PARAMETER Pkcs8
    Provide output in PKCS #8 format

    .PARAMETER Der
    Provide output in DER format

    .PARAMETER Pkcs12
    Provide output in PKCS #12 format.  Requires a value for PrivateKeyPassword.

    .PARAMETER Jks
    Provide output in JKS format.  Requires a value for FriendlyName.

    .PARAMETER OutPath
    Folder path to save the certificate/key to.  The name of the file will be determined automatically.

    .PARAMETER IncludeChain
    Include the certificate chain with the exported certificate.
    The end entity will be first and the root last.

    .PARAMETER FriendlyName
    Label or alias to use.  Permitted with Base64 and PKCS #12 formats.  Required when exporting JKS.

    .PARAMETER PrivateKeyPassword
    Password required to include the private key.
    You can either provide a String, SecureString, or PSCredential.
    You must adhere to the following rules:
    - Password is at least 12 characters.
    - Comprised of at least three of the following:
        - Uppercase alphabetic letters
        - Lowercase alphabetic letters
        - Numeric characters
        - Special characters

    .PARAMETER KeystorePassword
    Password required to retrieve the certificate in JKS format.
    You can either provide a String, SecureString, or PSCredential.
    You must adhere to the following rules:
    - Password is at least 12 characters.
    - Comprised of at least three of the following:
        - Uppercase alphabetic letters
        - Lowercase alphabetic letters
        - Numeric characters
        - Special characters

    .PARAMETER ThrottleLimit
    Limit the number of threads when running in parallel; the default is 100.
    Setting the value to 1 will disable multithreading.
    On PS v5 the ThreadJob module is required.  If not found, multithreading will be disabled.


    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.

    .INPUTS
    Path, VaultId

    .OUTPUTS
    PSCustomObject

    .EXAMPLE
    Export-VdcCertificate -Path '\ved\policy\mycert.com'

    Get certificate data in X509 format, the default

    .EXAMPLE
    $cert | Export-VdcCertificate -PKCS7 -OutPath 'c:\temp'

    Get certificate data in a specific format and save to a file

    .EXAMPLE
    $cert | Export-VdcCertificate -PKCS7 -IncludeChain

    Get one or more certificates with the certificate chain included

    .EXAMPLE
    $cert | Export-VdcCertificate -PKCS12 -PrivateKeyPassword 'mySecretPassword!'

    Get one or more certificates with private key included

    .EXAMPLE
    Export-VdcCertificate -VaultId 12345 -PKCS12 -PrivateKeyPassword 'mySecretPassword!'

    Export certificate and private key from the vault

    .EXAMPLE
    $cert | Export-VdcCertificate -PKCS8 -PrivateKeyPassword 'mySecretPassword!' -OutPath '~/temp'

    Save certificate info to a file.  PKCS8 with private key will save 3 files, .pem (cert+key), .pem.cer (cert only), and .pem.key (key only)

    .EXAMPLE
    $cert | Export-VdcCertificate -Jks -FriendlyName 'MyFriendlyName' -KeystorePassword $cred.password

    Get certificates in JKS format.

    #>

    [CmdletBinding(DefaultParameterSetName = 'X509ByPath')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'Converting to a secure string, its already plaintext')]

    param (

        [Parameter(Mandatory, ParameterSetName = 'X509ByPath', ValueFromPipelineByPropertyName)]
        [Parameter(Mandatory, ParameterSetName = 'Pkcs7ByPath', ValueFromPipelineByPropertyName)]
        [Parameter(Mandatory, ParameterSetName = 'Pkcs8ByPath', ValueFromPipelineByPropertyName)]
        [Parameter(Mandatory, ParameterSetName = 'DerByPath', ValueFromPipelineByPropertyName)]
        [Parameter(Mandatory, ParameterSetName = 'Pkcs12ByPath', ValueFromPipelineByPropertyName)]
        [Parameter(Mandatory, ParameterSetName = 'JksByPath', ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string] $Path,

        [Parameter(Mandatory, ParameterSetName = 'X509ByVault', ValueFromPipelineByPropertyName)]
        [Parameter(Mandatory, ParameterSetName = 'Pkcs7ByVault', ValueFromPipelineByPropertyName)]
        [Parameter(Mandatory, ParameterSetName = 'Pkcs8ByVault', ValueFromPipelineByPropertyName)]
        [Parameter(Mandatory, ParameterSetName = 'DerByVault', ValueFromPipelineByPropertyName)]
        [Parameter(Mandatory, ParameterSetName = 'Pkcs12ByVault', ValueFromPipelineByPropertyName)]
        [Parameter(Mandatory, ParameterSetName = 'JksByVault', ValueFromPipelineByPropertyName)]
        [Alias('Certificate Vault Id', 'PreviousVersions')]
        [psobject] $VaultId,

        [Parameter(ParameterSetName = 'X509ByPath')]
        [Parameter(ParameterSetName = 'X509ByVault')]
        [Alias('Base64')]
        [switch] $X509,

        [Parameter(Mandatory, ParameterSetName = 'Pkcs7ByPath')]
        [Parameter(Mandatory, ParameterSetName = 'Pkcs7ByVault')]
        [switch] $Pkcs7,

        [Parameter(Mandatory, ParameterSetName = 'Pkcs8ByPath')]
        [Parameter(Mandatory, ParameterSetName = 'Pkcs8ByVault')]
        [switch] $Pkcs8,

        [Parameter(Mandatory, ParameterSetName = 'DerByPath')]
        [Parameter(Mandatory, ParameterSetName = 'DerByVault')]
        [switch] $Der,

        [Parameter(Mandatory, ParameterSetName = 'Pkcs12ByPath')]
        [Parameter(Mandatory, ParameterSetName = 'Pkcs12ByVault')]
        [switch] $Pkcs12,

        [Parameter(Mandatory, ParameterSetName = 'JksByPath')]
        [Parameter(Mandatory, ParameterSetName = 'JksByVault')]
        [switch] $Jks,

        [Parameter(ParameterSetName = 'Pkcs8ByPath')]
        [Parameter(Mandatory, ParameterSetName = 'Pkcs12ByPath')]
        [Parameter(ParameterSetName = 'JksByPath')]
        [Parameter(ParameterSetName = 'Pkcs8ByVault')]
        [Parameter(Mandatory, ParameterSetName = 'Pkcs12ByVault')]
        [Parameter(ParameterSetName = 'JksByVault')]
        [ValidateScript(
            {
                if ( $_ -is [string] -or $_ -is [securestring] -or $_ -is [pscredential] ) {
                    $true
                }
                else {
                    throw 'Unsupported type.  Provide either a String, SecureString, or PSCredential.'
                }
            }
        )]
        [Alias('SecurePassword')]
        [psobject] $PrivateKeyPassword,

        [Parameter(ParameterSetName = 'X509ByPath')]
        [Parameter(ParameterSetName = 'Pkcs7ByPath')]
        [Parameter(ParameterSetName = 'Pkcs8ByPath')]
        [Parameter(ParameterSetName = 'Pkcs12ByPath')]
        [Parameter(ParameterSetName = 'JksByPath')]
        [Parameter(ParameterSetName = 'X509ByVault')]
        [Parameter(ParameterSetName = 'Pkcs7ByVault')]
        [Parameter(ParameterSetName = 'Pkcs8ByVault')]
        [Parameter(ParameterSetName = 'Pkcs12ByVault')]
        [Parameter(ParameterSetName = 'JksByVault')]
        [switch] $IncludeChain,

        [Parameter(ParameterSetName = 'X509ByPath')]
        [Parameter(ParameterSetName = 'Pkcs12ByPath')]
        [Parameter(Mandatory, ParameterSetName = 'JksByPath')]
        [Parameter(ParameterSetName = 'X509ByVault')]
        [Parameter(ParameterSetName = 'Pkcs12ByVault')]
        [Parameter(Mandatory, ParameterSetName = 'JksByVault')]
        [string] $FriendlyName,

        [Parameter(Mandatory, ParameterSetName = 'JksByPath')]
        [Parameter(Mandatory, ParameterSetName = 'JksByVault')]
        [ValidateScript(
            {
                if ( $_ -is [string] -or $_ -is [securestring] -or $_ -is [pscredential] ) {
                    $true
                }
                else {
                    throw 'Unsupported type.  Provide either a String, SecureString, or PSCredential.'
                }
            }
        )]
        [psobject] $KeystorePassword,

        [Parameter()]
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

        [Parameter()]
        [int32] $ThrottleLimit = 100,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession = (Get-VenafiSession)
    )

    begin {
        Test-VenafiSession $PSCmdlet.MyInvocation

        $allCerts = [System.Collections.Generic.List[hashtable]]::new()

        $body = @{ Format = 'Base64' }
        switch ($PSBoundParameters.Keys) {
            'Pkcs7' { $body.Format = 'PKCS #7' }
            'Pkcs8' { $body.Format = 'Base64 (PKCS#8)' }
            'Pkcs12' { $body.Format = 'PKCS #12' }
            'Der' { $body.Format = 'DER' }
            'Jks' { $body.Format = 'JKS' }
            'PrivateKeyPassword' {
                $body.IncludePrivateKey = $true
                $body.Password = $PrivateKeyPassword | ConvertTo-PlaintextString
            }
            'KeystorePassword' {
                $body.Format = 'JKS'
                $body.KeystorePassword = $KeystorePassword | ConvertTo-PlaintextString
            }
            'FriendlyName' {
                $body.FriendlyName = $FriendlyName
            }
            'IncludeChain' {
                $body.IncludeChain = $true
            }
        }

        $body | Write-VerboseWithSecret
    }

    process {
        if ( $Path ) {
            $body.CertificateDN = ($Path | ConvertTo-VdcFullPath)
            $allCerts.Add($body.Clone())
        }
        else {
            foreach ($thisId in $VaultId) {
                $body.VaultId = if ( $thisId.VaultId ) {
                    $thisId.VaultId
                }
                else {
                    $thisId
                }
                $allCerts.Add($body.Clone())
            }
        }

    }

    end {
        $parallelParams = @{
            InputObject   = $allCerts
            ThrottleLimit = $ThrottleLimit
            VenafiSession = $VenafiSession
            ProgressTitle = 'Exporting certificates'
            ScriptBlock   = {
                $thisBody = $PSItem
                $outPath = $using:OutPath
                # foreach ($thisBody in $allCerts) {
                $isByPath = $null -eq $thisBody.VaultId

                try {
                    if ( $isByPath ) {
                        $innerResponse = Invoke-VenafiRestMethod -Method 'Post' -UriLeaf 'certificates/retrieve' -Body $thisBody
                    }
                    else {
                        $innerResponse = Invoke-VenafiRestMethod -Method 'Post' -UriLeaf ('certificates/retrieve/{0}' -f $thisBody.VaultId) -Body $thisBody
                    }
                }
                catch {
                    try {
                        # key not available, get just the cert
                        if ( $_.ToString() -like '*failed to lookup private key*') {

                            # we can't have a p12 without a private key
                            if ( $thisBody.Format -eq 'PKCS #12' ) {
                                throw $_
                            }

                            # it could be we just don't have a private key so get just the cert
                            $thisBody.IncludePrivateKey = $false
                            $thisBody.Password = $null
                            if ( $isByPath ) {
                                $innerResponse = Invoke-VenafiRestMethod -Method 'Post' -UriLeaf 'certificates/retrieve' -Body $thisBody
                            }
                            else {
                                $innerResponse = Invoke-VenafiRestMethod -Method 'Post' -UriLeaf ('certificates/retrieve/{0}' -f $thisBody.VaultId) -Body $thisBody
                            }
                        }
                        else {
                            throw $_
                        }
                    }
                    catch {
                        if ( $isByPath ) {
                            return [pscustomobject]@{
                                'Path'            = $thisBody.CertificateDN
                                'Error'           = $_
                                'CertificateData' = $null
                            }
                        }
                        else {
                            return [pscustomobject]@{
                                'VaultId'         = $thisBody.VaultId
                                'Error'           = $_
                                'CertificateData' = $null
                            }
                        }

                    }
                }

                # data applicable to both bypath and byvault
                $out = $innerResponse | Select-Object @{
                    'n' = 'Format'
                    'e' = {
                        # standardize the format for pkcs8 and pkcs12 across Certificate Manager, Self-Hosted and Certificate Manager, SaaS
                        switch ($thisBody.Format) {
                            'Base64' { 'X509' }
                            'Base64 (PKCS#8)' { 'PKCS8' }
                            'PKCS #12' { 'PKCS12' }
                            Default { $_ }
                        }
                    }
                },
                CertificateData,
                @{
                    n = 'Error'
                    e = { $_.Status }
                }

                # add path/vault specific data
                if ( $isByPath ) {
                    $out | Add-Member @{
                        Path       = $thisBody.CertificateDN
                        PolicyPath = $thisBody.CertificateDN.Substring(0, $thisBody.CertificateDN.LastIndexOf('\'))
                    }
                }
                else {
                    $out | Add-Member @{ 'VaultId' = $thisBody.VaultId }
                }

                if ( $innerResponse.CertificateData ) {

                    if ( $thisBody.Format -in 'Base64', 'Base64 (PKCS#8)' ) {
                        $splitData = Split-CertificateData -InputObject $innerResponse.CertificateData
                    }

                    if ( $outPath ) {

                        $out = $out | Select-Object -Property * -ExcludeProperty CertificateData

                        # write the file with the filename provided
                        $outFile = Join-Path -Path (Resolve-Path -Path $using:OutPath) -ChildPath ($innerResponse.FileName.Trim('"'))
                        $bytes = [Convert]::FromBase64String($innerResponse.CertificateData)
                        [IO.File]::WriteAllBytes($outFile, $bytes)

                        Write-Verbose "Saved $outFile"

                        $out | Add-Member @{'OutFile' = @($outFile) }

                        if ( $thisBody.Format -in 'Base64 (PKCS#8)' -and $thisBody.IncludePrivateKey) {
                            # outFile will be .pem with cert and key
                            # write out the individual files as well
                            try {
                                $crtFile = $outFile.Replace('.pem', '.crt')

                                $sw = [IO.StreamWriter]::new($crtFile, $false, [Text.Encoding]::ASCII)
                                $sw.WriteLine($splitData.CertPem)
                                Write-Verbose "Saved $crtFile"

                                $out.OutFile += $crtFile
                            }
                            finally {
                                if ($null -ne $sw) { $sw.Close() }
                            }

                            if ( $thisBody.IncludePrivateKey ) {
                                try {
                                    $keyFile = $outFile.Replace('.pem', '.key')

                                    $sw = [IO.StreamWriter]::new($keyFile, $false, [Text.Encoding]::ASCII)
                                    $sw.WriteLine($splitData.KeyPem)
                                    Write-Verbose "Saved $keyFile"

                                    $out.OutFile += $keyFile
                                }
                                finally {
                                    if ($null -ne $sw) { $sw.Close() }
                                }
                            }
                        }
                    }
                    else {
                        if ( $thisBody.Format -in 'Base64', 'Base64 (PKCS#8)' ) {

                            $out | Add-Member @{'CertPem' = $splitData.CertPem }

                            if ( $thisBody.IncludePrivateKey ) {
                                $out | Add-Member @{
                                    'KeyPem' = $splitData.KeyPem
                                }
                            }

                            if ( $thisBody.IncludeChain -and $splitData.ChainPem ) {
                                $out | Add-Member @{'ChainPem' = $splitData.ChainPem }
                            }
                        }

                        if ( $thisBody.IncludePrivateKey ) {
                            $out | Add-Member @{
                                'PrivateKeyPassword' = (New-Object System.Management.Automation.PSCredential('unused', ($thisBody.Password | ConvertTo-SecureString -AsPlainText -Force)))
                            }
                        }

                    }
                }

                $out

            }
        }

        Invoke-VenafiParallel @parallelParams

    }
}


