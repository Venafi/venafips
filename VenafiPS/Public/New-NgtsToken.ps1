function New-NgtsToken {
    <#
    .SYNOPSIS
    Get a new access token or refresh an existing one

    .DESCRIPTION
    Get an access token and refresh token (if enabled) to be used with New-VenafiSession or other scripts/utilities that take such a token.
    You can also refresh an existing access token if you have the associated refresh token.
    Authentication can be provided as integrated, credential, or certificate.

    .PARAMETER AuthServer
    Auth server or url, eg. venafi.company.com

    .PARAMETER ClientId
    Application/integration ID configured in Venafi for token-based authentication.
    Case sensitive.

    .PARAMETER Scope
    Hashtable with Scopes and privilege restrictions.
    The key is the scope and the value is one or more privilege restrictions separated by commas.
    A privilege restriction of none or read, use a value of $null.
    Scopes include Agent, Certificate, Code Signing, Configuration, Restricted, Security, SSH, and statistics.
    See https://docs.venafi.com/Docs/current/TopNav/Content/SDK/AuthSDK/r-SDKa-OAuthScopePrivilegeMapping.php
    Using a scope of {'all'='core'} will set all scopes except for admin.
    Using a scope of {'all'='admin'} will set all scopes including admin.
    Usage of the 'all' scope is not suggested for production.

    .PARAMETER Credential
    Username / password credential used to request API Token

    .PARAMETER State
    A session state, redirect URL, or random string to prevent Cross-Site Request Forgery (CSRF) attacks

    .PARAMETER Jwt
    JSON web token.
    Available in Certificate Manager, Self-Hosted v22.4 and later.
    Ensure jwt mapping has been configured in VCC, Access Management->JWT Mappings.

    .PARAMETER Certificate
    Certificate used to request API token.  Certificate authentication must be configured for remote web sdk clients, https://docs.venafi.com/Docs/current/TopNav/Content/CA/t-CA-ConfiguringInTPPandIIS-tpp.php.

    .PARAMETER RefreshToken
    Provide -RefreshToken along with -ClientId to obtain a new access and refresh token.
    You can either provide a String, SecureString, or PSCredential.
    If providing a credential, the username is not used.

    .PARAMETER SkipCertificateCheck
    Bypass certificate validation when connecting to the server.
    This can be helpful for pre-prod environments where ssl isn't setup on the website or you are connecting via IP.

    .PARAMETER VenafiSession
    VenafiSession object created from New-VenafiSession method.

    .EXAMPLE
    New-VdcToken -AuthServer 'https://mytppserver.example.com' -Scope @{ Certificate = "manage,discover"; Configuration = "manage" } -ClientId 'MyAppId' -Credential $credential
    Get a new token with OAuth

    .EXAMPLE
    New-VdcToken -AuthServer 'mytppserver.example.com' -Scope @{ Certificate = "manage,discover"; Configuration = "manage" } -ClientId 'MyAppId'
    Get a new token with Integrated authentication

    .EXAMPLE
    New-VdcToken -AuthServer 'mytppserver.example.com' -Scope @{ Certificate = "manage,discover"; Configuration = "manage" } -ClientId 'MyAppId' -Certificate $cert
    Get a new token with certificate authentication

    .EXAMPLE
    New-VdcToken -AuthServer 'mytppserver.example.com' -ClientId 'MyApp' -RefreshToken $refreshCred
    Refresh an existing access token by providing the refresh token directly

    .EXAMPLE
    New-VdcToken -VenafiSession $mySession
    Refresh an existing access token by providing a VenafiSession object

    .INPUTS
    None

    .OUTPUTS
    PSCustomObject with the following properties:
        Server
        AccessToken
        RefreshToken
        Scope
        Identity
        TokenType
        ClientId
        Expires
        RefreshExpires (This property is null when Certificate Manager, Self-Hosted version is less than 21.1)
    #>

    [CmdletBinding()]
    [OutputType([PSCustomObject])]
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

    $newToken = [PSCustomObject] @{
        AccessToken = New-Object System.Management.Automation.PSCredential('AccessToken', ($response.access_token | ConvertTo-SecureString -AsPlainText -Force))
        Expires     = [DateTime]::UtcNow.AddSeconds($response.expires_in)
        Scope       = $response.scope
    }

    $newToken
}
