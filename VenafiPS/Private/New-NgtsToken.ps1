function New-NgtsToken {
    <#
    .SYNOPSIS
    Get a new access token or refresh an existing one

    .DESCRIPTION
    Get an access token and refresh token (if enabled) to be used with New-TrustClient or other scripts/utilities that take such a token.
    You can also refresh an existing access token if you have the associated refresh token.
    Authentication can be provided as integrated, credential, or certificate.

    .PARAMETER Credential
    Client ID and Secret to authenticate with.  The username must be in the format user@1234567890.iam.panserviceaccount.com where 1234567890 is the TSG ID.  The password is the client secret.

    .PARAMETER Tsg
    Tenant Service Group ID for NGTS.  Only required if the TSG ID in the credential username is not the target.

    .EXAMPLE
    New-NgtsToken -Credential $credential

    Get a new token with client credential authentication, using the client ID and secret from $credential.  The TSG ID will be parsed from the username in the credential.

    .EXAMPLE
    New-NgtsToken -Credential $credential -Tsg 1234567890

    Get a new token with client credential authentication, using the client ID and secret from $credential.  The TSG ID will be set to 1234567890, overriding the value parsed from the credential username.

    .INPUTS
    None

    .OUTPUTS
    TrustToken
    #>

    [CmdletBinding()]
    [OutputType([TrustToken])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'Generating cred from api call response data')]

    param (

        [Parameter(Mandatory)]
        [ValidateScript(
            {
                $tsgMatch = [regex]::Match($_.UserName, '^[^@]+@(?<tsg>\d{10})\.iam\.panserviceaccount\.com$')
                if ( -not $tsgMatch.Success ) {
                    throw 'Credential.UserName must be in the format user@1234567890.iam.panserviceaccount.com'
                }

                $true
            }
        )]
        [System.Management.Automation.PSCredential] $Credential,

        [Parameter()]
        [ValidateRange(1000000000, 9999999999)]
        [long] $Tsg
    )

    $credentialTsg = ([regex]::Match($Credential.UserName, '^[^@]+@(?<tsg>\d{10})\.iam\.panserviceaccount\.com$')).Groups['tsg'].Value
    $resolvedTsg = if ($PSBoundParameters.ContainsKey('Tsg')) { [string]$Tsg } else { $credentialTsg }

    $params = @{
        Headers     = @{
            "Accept" = "application/json"
        }
        Uri         = 'https://auth.apps.paloaltonetworks.com/oauth2/access_token'
        Method      = "Post"
        Body        = @{
            "grant_type"    = "client_credentials"
            "client_id"     = $Credential.UserName
            "client_secret" = $Credential.GetNetworkCredential().Password
            "scope"         = 'tsg_id:{0}' -f $resolvedTsg
        }
        ContentType = "application/x-www-form-urlencoded"
    }

    $response = Invoke-RestMethod @params
    if ( -not $response ) {
        return
    }

    $response | Write-VerboseWithSecret

    $newToken = [TrustToken]::new()
    $newToken.AccessToken = New-Object System.Management.Automation.PSCredential('AccessToken', ($response.access_token | ConvertTo-SecureString -AsPlainText -Force))
    $newToken.Expires = [DateTime]::UtcNow.AddSeconds($response.expires_in)
    $newToken.Scope = $response.scope

    $newToken
}
