function New-VcToken {
    <#
    .SYNOPSIS
    Get a new access token

    .DESCRIPTION
    Get a new access token from an endpoint and JWT.
    You can also provide a VenafiSession, or no session to use the script scoped one, which will use the stored endpoint and jwt to refresh the access token.
    This only works if the jwt has not expired.

    .PARAMETER Endpoint
    Token Endpoint URL as shown on the service account details page in Certificate Manager, SaaS

    .PARAMETER Jwt
    JSON web token with access to the configured service account

    .PARAMETER VenafiSession
    VenafiSession object created from New-VenafiSession method.
    This can be used to refresh the access token if the JWT has not expired.

    .EXAMPLE
    New-VcToken

    Refresh the existing access token stored in the script scoped variable VenafiSession
    Only possible if the JWT has not expired.

    .EXAMPLE
    New-VcToken -Endpoint 'https://api.venafi.cloud/v1/oauth2/v2.0/2222c771-61f3-11ec-8a47-490a1e43c222/token' -Jwt $Jwt

    Get a new token with OAuth

    .EXAMPLE
    New-VcToken -VenafiSession $sess

    Refresh the existing access token stored in session.
    Only possible if the JWT has not expired.

    .INPUTS
    None

    .OUTPUTS
    PSCustomObject with the following properties:
        Endpoint
        AccessToken
        JWT
        Expires
    #>

    [CmdletBinding(DefaultParameterSetName = 'ScriptSession')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'Converting to a secure string, its already plaintext')]
    [OutputType([PSCustomObject])]

    param (
        [Parameter(ParameterSetName = 'Endpoint', Mandatory)]
        [ValidateScript(
            {
                try {
                    $null = [System.Uri]::new($_)
                    $true
                }
                catch {
                    throw 'Please enter a valid endpoint, eg. https://api.venafi.cloud/v1/oauth2/v2.0/2222c771-61f3-11ec-8a47-490a1e43c222/token'
                }
            }
        )]
        [string] $Endpoint,

        [Parameter(ParameterSetName = 'Endpoint', Mandatory)]
        [Parameter(ParameterSetName = 'Session')]
        [string] $Jwt,

        [Parameter(ParameterSetName = 'Session', Mandatory)]
        [ValidateScript(
            {
                if ( -not $_.Token.Endpoint -or -not $_.Token.JWT ) {
                    throw 'VenafiSession requires Endpoint and JWT.  To get a new access token, create a new session with New-VenafiSession.'
                }
                $true
            }
        )]
        [pscustomobject] $VenafiSession

    )

    $params = @{
        Uri         = $Endpoint
        Method      = "POST"
        ContentType = "application/x-www-form-urlencoded"
        Body        = @{
            grant_type            = "client_credentials"
            client_assertion_type = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
            client_assertion      = $Jwt
        }
    }

    if ( $PSCmdlet.ParameterSetName -in 'ScriptSession', 'Session' ) {

        $sess = if ( $PSCmdlet.ParameterSetName -eq 'ScriptSession' ) {
            $script:VenafiSession
        }
        else {
            $VenafiSession
        }

        $params.Uri = $sess.Token.Endpoint
        if ( $sess.Token.JWT ) {
            $params.Body.client_assertion = $sess.Token.JWT.GetNetworkCredential().password
        }
        if ( -not $params.Body.client_assertion ) {
            throw [System.ArgumentException]::new('-Jwt must be provided directly or via a VenafiSession.')
        }
    }

    $response = Invoke-RestMethod @params
    if ( -not $response ) {
        return
    }

    $response | Write-VerboseWithSecret

    $newToken = [PSCustomObject] @{
        Endpoint    = $params.Uri
        AccessToken = New-Object System.Management.Automation.PSCredential('AccessToken', ($response.access_token | ConvertTo-SecureString -AsPlainText -Force))
        JWT         = New-Object System.Management.Automation.PSCredential('JWT', ($params.Body.client_assertion | ConvertTo-SecureString -AsPlainText -Force))
        Expires     = [DateTime]::UtcNow.AddSeconds($response.expires_in)
    }

    if ( $PSCmdlet.ParameterSetName -eq 'ScriptSession' ) {
        $script:VenafiSession.Token = $newToken
        Write-Verbose 'Refreshed access token in script scoped variable VenafiSession'
    }
    else {
        $newToken
    }

}


