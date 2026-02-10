function Import-VcCertificate {
    <#
    .SYNOPSIS
    Import one or more certificates

    .DESCRIPTION
    Import one or more certificates and their private keys.
    PKCS8 (.pem), PKCS12 (.pfx or .p12), and X509 (.pem, .cer, or .crt) certificates are supported.

    .PARAMETER Path
    Path to a certificate file or folder with multiple certificates.
    Wildcards are also supported, eg. /my/path/*.pfx.
    Provide either this or -Data.

    .PARAMETER Data
    Contents of a certificate/key to import.
    Provide either this or -Path.

    .PARAMETER PKCS8
    Provided -Data is in PKCS #8 format.
    This parameter will be deprecated in a future release.  Use -Format PKCS8.

    .PARAMETER PKCS12
    Provided -Data is in PKCS #12 format
    This parameter will be deprecated in a future release.  Use -Format PKCS12.

    .PARAMETER Format
    Specify the format provided in -Data.
    PKCS12, PKCS8, and X509 are supported.
    This will replace -PKCS8 and -PKCS12 in a future release.

    .PARAMETER PrivateKeyPassword
    Password the private key was encrypted with

    .PARAMETER ThrottleLimit
    Limit the number of threads when running in parallel; the default is 10.  Applicable to PS v7+ only.
    100 keystores will be imported at a time so it's less important to have a very high throttle limit.

    .PARAMETER Force
    Force installation of PSSodium if not already installed.  This is required for the import of keys.

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A Certificate Manager, SaaS key can also provided.

    .EXAMPLE
    Import-VcCertificate -CertificatePath c:\www.VenafiPS.com.pfx

    Import a certificate/key

    .EXAMPLE
    Export-VdcCertificate -Path '\ved\policy\my.cert.com' -Pkcs12 -PrivateKeyPassword 'myPassw0rd!' | Import-VcCertificate -VenafiSession $vaas_key

    Export from Certificate Manager, Self-Hosted and import into Certificate Manager, SaaS.
    As $VenafiSession can only point to one platform at a time, in this case Certificate Manager, Self-Hosted, the session needs to be overridden for the import.

    .EXAMPLE
    Find-VdcCertificate -Path '\ved\policy\certs' -Recursive | Export-VdcCertificate -Pkcs12 -PrivateKeyPassword 'myPassw0rd!' | Import-VcCertificate -VenafiSession $vaas_key

    Bulk export from Certificate Manager, Self-Hosted and import into Certificate Manager, SaaS.
    As $VenafiSession can only point to one platform at a time, in this case Certificate Manager, Self-Hosted, the session needs to be overridden for the import.

    .EXAMPLE
    Find-VcCertificate | Export-VcCertificate -PrivateKeyPassword 'secretPassword#' -PKCS12 | Import-VcCertificate -VenafiSession $tenant2_key

    Export from 1 Certificate Manager, SaaS tenant and import to another.
    This assumes New-VenafiSession has been run for the source tenant.

    .INPUTS
    Data

    .LINK
    https://developer.venafi.com/tlsprotectcloud/reference/certificates_import

    .NOTES
    This function requires the use of sodium encryption via the PSSodium PowerShell module.
    Dotnet standard 2.0 or greater is required via PS Core (recommended) or supporting .net runtime.
    On Windows, the latest Visual C++ redist must be installed.  See https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist.

    Non keystore imports, just certs no keys, will override the blocklist by default.
    To honor the blocklist, set the environment variable VC_ENABLE_BLOCKLIST to 'true'.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByFile')]
    [Alias('Import-VaasCertificate')]

    param (

        [Parameter(Mandatory, ParameterSetName = 'ByFile')]
        [ValidateNotNullOrEmpty()]
        [Alias('FullName', 'CertificatePath', 'FilePath')]
        [String] $Path,

        [Parameter(Mandatory, ParameterSetName = 'PKCS12', ValueFromPipelineByPropertyName)]
        [Parameter(Mandatory, ParameterSetName = 'PKCS8', ValueFromPipelineByPropertyName)]
        [Parameter(Mandatory, ParameterSetName = 'Format', ValueFromPipelineByPropertyName)]
        [Alias('certificateData')]
        [String] $Data,

        [Parameter(Mandatory, ParameterSetName = 'PKCS8')]
        [switch] $PKCS8,

        [Parameter(Mandatory, ParameterSetName = 'PKCS12')]
        [switch] $PKCS12,

        [Parameter(Mandatory, ParameterSetName = 'Format', ValueFromPipelineByPropertyName)]
        [String] $Format,

        [Parameter(Mandatory, ParameterSetName = 'PKCS8')]
        [Parameter(Mandatory, ParameterSetName = 'PKCS12')]
        [Parameter(ParameterSetName = 'ByFile')]
        [Parameter(ParameterSetName = 'Format', ValueFromPipelineByPropertyName)]
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
        [psobject] $PrivateKeyPassword,

        [Parameter()]
        [int32] $ThrottleLimit = 10,

        [Parameter()]
        [switch] $Force,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {

        if ( $PSBoundParameters.ContainsKey('PKCS12') -or $PSBoundParameters.ContainsKey('PKCS8') ) {
            Write-Warning '-PKCS8 and -PKCS12 will soon be deprecated.  Utilize -Format instead.'
        }

        Test-VenafiSession $PSCmdlet.MyInvocation

        Initialize-PSSodium -Force:$Force

        $vSat = Get-VcData -Type 'VSatellite' -First
        if ( -not $vSat ) { throw 'No active VSatellites were found' }

        if ( $PrivateKeyPassword ) {
            $pkPassString = ConvertTo-PlaintextString -InputObject $PrivateKeyPassword
        }

        # different api calls for certs with and without keys so maintain them separately for ease of us
        $allCerts = [System.Collections.Generic.List[hashtable]]::new()
        $allNoKeyCerts = [System.Collections.Generic.List[hashtable]]::new()

    }

    process {

        if ( $PSCmdlet.ParameterSetName -eq 'ByFile' ) {
            $resolvedPath = Resolve-Path -Path $Path -ErrorAction Stop
            $files = if (Test-Path -Path $resolvedPath -PathType Container) {
                Get-ChildItem -Path $resolvedPath -File | Select-Object -ExpandProperty FullName
            }
            else {
                @($resolvedPath)
            }

            foreach ($file in $files) {

                Write-Verbose "Processing $file"

                switch ([System.IO.Path]::GetExtension($file)) {
                    { $_ -in '.pfx', '.p12' } {
                        if ($PSVersionTable.PSVersion.Major -lt 6) {
                            $cert = Get-Content $file -Encoding Byte
                        }
                        else {
                            $cert = Get-Content $file -AsByteStream
                        }

                        $allCerts.Add(@{
                                'CertData' = [System.Convert]::ToBase64String($cert)
                                'Format'   = 'PKCS12'
                            }
                        )
                    }

                    { $_ -in '.pem', '.cer', '.crt' } {
                        $split = Split-CertificateData -InputObject (Get-Content $file -Raw)

                        if ( $split.KeyPem ) {
                            $allCerts.Add(@{
                                    'CertPem' = $split.CertPem
                                    'KeyPem'  = $split.KeyPem
                                    'Format'  = 'PKCS8'
                                }
                            )
                        }
                        else {
                            $allNoKeyCerts.Add(@{
                                    'CertPem' = $split.CertPem -replace "`r|`n|-----BEGIN CERTIFICATE-----|-----END CERTIFICATE-----"
                                }
                            )
                        }
                    }

                    default {
                        Write-Verbose "$file is not a certificate"
                    }
                }
            }
        }
        else {
            # check if Data exists since we allow null/empty in case piping from another function and data is not there
            if ( $Data ) {

                $addMe = @{
                    'Format' = ''
                }

                if ( $Format ) {
                    $addMe.Format = $Format
                    # privatekeypassword might have been provided via pipeline so this must be in process block
                    if ( $PrivateKeyPassword ) {
                        $pkPassString = ConvertTo-PlaintextString -InputObject $PrivateKeyPassword
                    }
                }
                else {
                    $addMe.Format = $PSCmdlet.ParameterSetName
                }

                switch ($addMe.Format) {
                    'PKCS12' {
                        $addMe.'CertData' = $Data -replace "`r|`n|-----BEGIN CERTIFICATE-----|-----END CERTIFICATE-----"
                        $allCerts.Add($addMe)
                    }

                    # X509 and PKCS8 both use Base64, but 'Base64' is how Certificate Manager, Self-Hosted refers to x509
                    # this allows us to pipe from Certificate Manager, Self-Hosted to Certificate Manager, SaaS
                    { $_ -in 'PKCS8', 'X509', 'Base64' } {
                        $splitData = Split-CertificateData -InputObject $Data

                        if ( $splitData.KeyPem ) {
                            $addMe.CertPem = $splitData.CertPem
                            $addMe.KeyPem = $splitData.KeyPem
                            $allCerts.Add($addMe)
                        }
                        else {
                            $allNoKeyCerts.Add(@{
                                    'CertPem' = $splitData.CertPem -replace "`r|`n|-----BEGIN CERTIFICATE-----|-----END CERTIFICATE-----"
                                }
                            )
                        }
                    }

                    default {
                        Write-Error "Unknown format '$_'"
                    }
                }
            }
        }
    }

    end {
        if ( $allCerts.Count -eq 0 -and $allNoKeyCerts.Count -eq 0 ) { return }

        Write-Verbose ('Importing {0} certificates' -f ($allCerts.Count + $allNoKeyCerts.Count))

        if ( $allCerts.Count -gt 0 ) {
            # process all certs with keys

            Write-Debug ($allCerts | ConvertTo-Json)
            $importList = [System.Collections.Generic.List[hashtable]]::new()

            if ( -not $pkPassString ) {
                throw [System.ArgumentNullException]::new('PrivateKeyPassword', 'When importing certificates with private keys, a private key password is required.')
            }

            $dekEncryptedPassword = ConvertTo-SodiumEncryptedString -Text $pkPassString -PublicKey $vSat.encryptionKey

            # rebuild invoke params as the payload can contain multiple keys at once
            # max 100 certs and keys at a time
            for ($i = 0; $i -lt $allCerts.Count; $i += 100) {

                $params = @{
                    Method  = 'POST'
                    UriRoot = 'outagedetection/v1'
                    UriLeaf = 'certificates/imports'
                    Body    = @{
                        'edgeInstanceId'  = $vSat.vsatelliteId
                        'encryptionKeyId' = $vSat.encryptionKeyId
                    }
                }

                $keystores = foreach ($thisCert in $allCerts[$i..($i + 99)]) {
                    switch ($thisCert.Format) {
                        'PKCS12' {
                            @{
                                'pkcs12Keystore'       = $thisCert.CertData
                                'dekEncryptedPassword' = $dekEncryptedPassword
                            }
                        }

                        'PKCS8' {
                            @{
                                'certificate'                 = $thisCert.CertPem
                                'passwordEncryptedPrivateKey' = $thisCert.KeyPem
                                'dekEncryptedPassword'        = $dekEncryptedPassword
                            }
                        }
                    }
                }

                $params.Body.importInformation = @($keystores)
                $importList.Add($params)
            }

            $sb = {
                $params = $PSItem

                $requestResponse = Invoke-VenafiRestMethod @params

                do {
                    try {
                        $jobResponse = Invoke-VenafiRestMethod -UriRoot 'outagedetection/v1' -UriLeaf "certificates/imports/$($requestResponse.id)"
                        Write-Verbose ('import id: {0}, status: {1}' -f $requestResponse.id, $jobResponse.status)
                    }
                    catch {
                        if ( $_.Exception.StatusCode -eq 500 -and $_.ErrorDetails.Message -match 'Unexpected error encountered' ) {
                            # issue in api where it returns a 500 even though it hasn't actually failed
                            # perhaps it takes longer for the import process to get started and provide a 'processing' state
                            Write-Verbose ('import id: {0}, status: no status yet' -f $requestResponse.id)
                        }
                        else {
                            throw $_
                        }
                    }

                    Start-Sleep 2
                } until (
                    $jobResponse.status -in 'COMPLETED', 'FAILED'
                )

                if ( $jobResponse.status -eq 'COMPLETED' ) {
                    $jobResponse.results
                }
                else {
                    # importing only 1 keycert that fails does not give us any results to return to the user :(
                    throw 'Import failed'
                }
            }

            $invokeParams = @{
                InputObject   = $importList
                ScriptBlock   = $sb
                ThrottleLimit = $ThrottleLimit
                ProgressTitle = 'Importing certificates with private keys'
            }
            $invokeResponse = Invoke-VenafiParallel @invokeParams

            $keyOut = $invokeResponse | Select-Object -Property fingerprint, status, reason
        }

        if ( $allNoKeyCerts.Count -gt 0 ) {
            # process all certs without keys

            Write-Debug ($allNoKeyCerts | ConvertTo-Json)
            $importList = [System.Collections.Generic.List[hashtable]]::new()
            $bl = -not ($env:VC_ENABLE_BLOCKLIST -eq 'true')

            # rebuild invoke params as the payload can contain multiple keys at once
            # max 100 certs and keys at a time
            for ($i = 0; $i -lt $allNoKeyCerts.Count; $i += 100) {

                $params = @{
                    Method  = 'POST'
                    UriRoot = 'outagedetection/v1'
                    UriLeaf = 'certificates'
                    Body    = @{
                        # default to true unless the environment variable is set
                        overrideBlocklist = $bl
                    }
                }

                $importCertPayload = foreach ($thisCert in $allNoKeyCerts[$i..($i + 99)]) {
                    @{
                        'certificate' = $thisCert.CertPem
                    }
                }

                $params.Body.certificates = @($importCertPayload)
                $importList.Add($params)
            }

            $sb = {
                $params = $PSItem
                Invoke-VenafiRestMethod @params
            }

            $invokeParams = @{
                InputObject   = $importList
                ScriptBlock   = $sb
                ThrottleLimit = $ThrottleLimit
                ProgressTitle = 'Importing certificates without private keys'
            }
            $invokeNoKeyResponse = Invoke-VenafiParallel @invokeParams

            $noKeyOut = $invokeNoKeyResponse | Select-Object @{'n' = 'certificate'; 'e' = { $_.certificateInformations | Select-Object id, fingerprint } }, statistics
        }

        # powershell only lets us output 1 object
        if ( $keyOut -and -not $noKeyOut ) {
            $keyOut
        }
        elseif ($noKeyOut -and -not $keyOut) {
            $noKeyOut
        }
        else {
            @{
                'WithoutKey' = $noKeyOut
                'WithKey'    = $keyOut
            }
        }
    }
}


