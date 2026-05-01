function New-VcToken {
    <#
    .SYNOPSIS
    Get a new access token

    .DESCRIPTION
    Get a new access token from an endpoint and JWT.
    You can also provide a TrustClient, or no session to use the script scoped one, which will use the stored endpoint and jwt to refresh the access token.
    This only works if the jwt has not expired.

    .PARAMETER Endpoint
    Token Endpoint URL as shown on the service account details page in Certificate Manager, SaaS

    .PARAMETER Jwt
    JSON web token with access to the configured service account

    .EXAMPLE
    New-VcToken -Endpoint 'https://api.venafi.cloud/v1/oauth2/v2.0/2222c771-61f3-11ec-8a47-490a1e43c222/token' -Jwt $Jwt

    Get a new token with OAuth

    .INPUTS
    None

    .OUTPUTS
    TrustToken
    #>

    [CmdletBinding(DefaultParameterSetName = 'ScriptSession')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'Converting to a secure string, its already plaintext')]
    [OutputType([TrustToken])]

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
                if ( -not $_.AuthServer -or -not $_.Credential ) {
                    throw 'TrustClient requires Endpoint and JWT.  To get a new access token, create a new session with New-TrustClient.'
                }
                $true
            }
        )]
        [object] $TrustClient

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
            $script:TrustClient
        }
        else {
            $TrustClient
        }

        $params.Uri = $sess.AuthServer
        if ( $sess.Credential ) {
            $params.Body.client_assertion = $sess.Credential.GetNetworkCredential().password
        }
        if ( -not $params.Body.client_assertion ) {
            throw [System.ArgumentException]::new('-Jwt must be provided directly or via a TrustClient.')
        }
    }

    $response = Invoke-RestMethod @params
    if ( -not $response ) {
        return
    }

    $response | Write-VerboseWithSecret

    $newToken = [TrustToken]::new()
    $newToken.Server = $params.Uri
    $newToken.AccessToken = New-Object System.Management.Automation.PSCredential('AccessToken', ($response.access_token | ConvertTo-SecureString -AsPlainText -Force))
    $newToken.Credential = New-Object System.Management.Automation.PSCredential('JWT', ($params.Body.client_assertion | ConvertTo-SecureString -AsPlainText -Force))
    $newToken.Scope = $response.scope
    $newToken.Expires = [DateTime]::UtcNow.AddSeconds($response.expires_in)

    if ( $PSCmdlet.ParameterSetName -eq 'ScriptSession' ) {
        $script:TrustClient.AccessToken = $newToken.AccessToken
        $script:TrustClient.Expires = $newToken.Expires
        $script:TrustClient.AuthServer = $newToken.Server
        $script:TrustClient.Credential = $newToken.Credential
        Write-Verbose 'Refreshed access token in script scoped variable TrustClient'
    }
    else {
        $newToken
    }

}


