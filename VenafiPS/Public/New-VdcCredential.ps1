function New-VdcCredential {
    <#
    .SYNOPSIS
    Create a new credential

    .DESCRIPTION
    Create a new credential of type Password, Username Password, or Certificate.

    .PARAMETER Path
    Full path, including name, for the object to be created.
    If the root path is excluded, \ved\policy will be prepended.

    .PARAMETER Secret
    The secret value for the credential.  The type of credential created will depend on the type of this parameter.
    If a String or SecureString is provided, a Password Credential will be created.
    If a PSCredential is provided, a Username Password Credential will be created with the username and password from the PSCredential.

    .PARAMETER CertificatePath
    If provided, a Certificate Credential will be created.
    The certificate must be in a PFX/PKCS12 format and Secret must contain the private key password for the certificate to be imported correctly.

    .PARAMETER PassThru
    Return the newly created object properties.

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.

    .EXAMPLE
    New-VdcCredential -Path '\VED\Policy\cred' -Secret $myCred

    Create a new Username Credential with the username and password from $myCred

    .EXAMPLE
    New-VdcCredential -Path '\VED\Policy\cred' -Secret $myPassword

    Create a new Password Credential with the value of $myPassword.
    $myPassword can be a string or a securestring.

    .EXAMPLE
    New-VdcCredential -Path '\VED\Policy\certcred' -Secret $certPassword -CertificatePath 'C:\mycert.pfx'

    Create a new Certificate Credential with the certificate at 'C:\mycert.pfx' and the password $certPassword.

    .EXAMPLE
    New-VdcCredential -Path '\VED\Policy\certcred' -Secret $certPassword -CertificatePath 'C:\mycert.pfx' -PassThru

    Create a new Certificate Credential and return the object.

    .INPUTS
    none

    .OUTPUTS
    pscustomobject, if PassThru provided

    #>

    [CmdletBinding(DefaultParameterSetName = 'UsernamePassword', SupportsShouldProcess)]

    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Path,

        [Parameter(Mandatory, ParameterSetName = 'UsernamePassword')]
        [Parameter(Mandatory, ParameterSetName = 'Certificate')]
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
        [psobject] $Secret,

        [Parameter(Mandatory, ParameterSetName = 'Certificate')]
        [ValidateScript(
            {
                if ( Test-Path $_ ) { $true }
                else { throw "Certificate path '$_' does not exist." }
            }
        )]
        [string] $CertificatePath,

        [Parameter()]
        [switch] $PassThru,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession = (Get-VenafiSession)
    )

    begin {
    }

    process {

        $newPath = $Path | ConvertTo-VdcFullPath

        $params = @{
            Method  = 'Post'
            UriLeaf = 'Credentials/Create'
            Body    = @{
                CredentialPath = $newPath
                Values         = @()
            }
        }

        # if string or securestring, Password Credential.  if PSCredential, Username Password Credential
        if ( $Secret -is [string] ) {
            $params.Body.FriendlyName = 'Password'
            $params.Body.Values += @{
                Name  = 'Password'
                Type  = 'string'
                Value = $Secret
            }
        }
        elseif ($Secret -is [securestring]) {
            $params.Body.FriendlyName = 'Password'
            $params.Body.Values += @{
                Name  = 'Password'
                Type  = 'string'
                Value = (New-Object System.Management.Automation.PSCredential('unused', $Secret)).GetNetworkCredential().password
            }
        }
        elseif ($Secret -is [pscredential]) {
            $params.Body.FriendlyName = 'UsernamePassword'
            $params.Body.Values += @{
                Name  = 'Username'
                Type  = 'string'
                Value = $Secret.UserName
            },
            @{
                Name  = 'Password'
                Type  = 'string'
                Value = $Secret.GetNetworkCredential().password
            }
        }

        if ( $CertificatePath ) {
            # get certificate from local store or file path
            # validate we have the correct password now as VDC will only do this when trying to retrieve and not on creation
            try {
                $certObject = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2(
                    $CertificatePath,
                    ($params.Body.Values | Where-Object { $_.Name -eq 'Password' }).Value,
                    [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable
                )
            }
            catch {
                throw "Failed to load certificate from path '$CertificatePath'.  $_"
            }

            $params.Body.FriendlyName = 'Certificate'
            $params.Body.Values += @{
                Name  = 'Certificate'
                Type  = 'byte[]'
                Value = [System.Convert]::ToBase64String(
                    $certObject.Export(
                        [System.Security.Cryptography.X509Certificates.X509ContentType]::Pfx,
                        ($params.Body.Values | Where-Object { $_.Name -eq 'Password' }).Value
                    )
                )
            }

            # we only need the password so remove the username if it's there
            $params.Body.Values = $params.Body.Values | Where-Object { $_.Name -ne 'Username' }
        }

        if ( $PSCmdlet.ShouldProcess($newPath, 'Create credential') ) {

            $response = Invoke-VenafiRestMethod @params

            if ( $response.Result -eq 1 ) {
                Write-Verbose "Credential created at path $newPath"
            }
            else {
                throw "Failed to create credential at path $newPath.  Response: $($response | ConvertTo-Json -Depth 5)"
            }

            if ( $PassThru ) {
                Get-VdcObject -Path $newPath -VenafiSession $VenafiSession
            }
        }
    }
}


