function Test-VdcToken {
    <#
    .SYNOPSIS
    Test if a Certificate Manager, Self-Hosted token is valid

    .DESCRIPTION
    Use the Certificate Manager, Self-Hosted API call 'Authorize/Verify' to test if the current token is valid.

    .PARAMETER AuthServer
    Auth server or url, venafi.company.com or https://venafi.company.com.
    This will be used to access vedauth for token-based authentication.
    If just the server name is provided, https:// will be appended.

    .PARAMETER AccessToken
    Access token retrieved outside this module.
    You can either provide a String, SecureString, or PSCredential.
    If providing a credential, the username is not used.

    .PARAMETER VaultAccessTokenName
    Name of the SecretManagement vault entry for the access token; the name of the vault must be VenafiPS.

    .PARAMETER VenafiPsToken
    Token object obtained from New-VdcToken

    .PARAMETER VenafiSession
    VenafiSession object to validate.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.

    .PARAMETER GrantDetail
    Provides detailed info about the token object from the Certificate Manager, Self-Hosted server response as an output.  Supported on Certificate Manager, Self-Hosted 20.4 and later.

    .INPUTS
    AccessToken

    .OUTPUTS
    Boolean (default)
    PSCustomObject (GrantDetail)
        ClientId
        AccessIssued
        GrantIssued
        Scope
        Identity
        RefreshExpires

    .EXAMPLE
    Test-VdcToken
    Verify that accesstoken stored in $VenafiSession object is valid.

    .EXAMPLE
    $VenafiPsToken | Test-VdcToken
    Verify that token object from pipeline is valid. Can be used to validate directly object from New-VdcToken.

    .EXAMPLE
    Test-VdcToken -AuthServer venafi.mycompany.com -AccessToken $cred
    Verify that PsCredential object containing accesstoken is valid.

    .EXAMPLE
    Test-VdcToken -VaultAccessTokenName access-token
    Verify access token stored in VenafiPS vault, metadata stored with secret

    .EXAMPLE
    Test-VdcToken -VaultAccessTokenName access-token -AuthServer venafi.mycompany.com
    Verify access token stored in VenafiPS vault providing server to authenticate against

    .EXAMPLE
    Test-VdcToken -GrantDetail
    Verify that accesstoken stored in $VenafiSession object is valid and return PsCustomObject as output with details.

    .LINK
    https://venafi.github.io/VenafiPS/functions/Test-VdcToken/

    .LINK
    https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Test-VdcToken.ps1

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/AuthSDK/r-SDKa-GET-Authorize-Verify.php

    #>

    [CmdletBinding(DefaultParameterSetName = 'Session')]
    [Alias('Test-TppToken')]
    [OutputType([System.Boolean])]

    param (
        [Parameter(Mandatory, ParameterSetName = 'AccessToken')]
        [Parameter(ParameterSetName = 'VaultAccessToken')]
        [ValidateScript(
            {
                $validateMe = if ( $_ -notlike 'https://*') {
                    'https://{0}' -f $_
                }
                else {
                    $_
                }

                try {
                    $null = [System.Uri]::new($validateMe)
                    $true
                }
                catch {
                    throw 'Please enter a valid server, https://venafi.company.com or venafi.company.com'
                }
            }
        )]
        [Alias('Server')]
        [string] $AuthServer,

        [Parameter(Mandatory, ParameterSetName = 'AccessToken', ValueFromPipeline)]
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
        [psobject] $AccessToken,

        [Parameter(Mandatory, ParameterSetName = 'VenafiPsToken')]
        [ValidateScript(
            {
                if ( -not $_.Server -or -not $_.AccessToken ) {
                    throw 'Not a valid VenafiPsToken'
                }
                $true
            }
        )]
        [pscustomobject] $VenafiPsToken,

        [Parameter(Mandatory, ParameterSetName = 'VaultAccessToken')]
        [string] $VaultAccessTokenName,

        [Parameter()]
        [switch] $GrantDetail,

        [Parameter(ParameterSetName = 'Session')]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {
        $params = @{
            Method  = 'Get'
            UriRoot = 'vedauth'
            UriLeaf = 'Authorize/Verify'
        }

        $serverUrl = $AuthServer
        # add prefix if just server url was provided
        if ( $serverUrl -notlike 'https://*') {
            $serverUrl = 'https://{0}' -f $serverUrl
        }
    }

    process {

        Write-Debug ('Parameter set: {0}' -f $PSCmdlet.ParameterSetName)

        switch ($PsCmdlet.ParameterSetName) {
            'Session' {

                $params.VenafiSession = (Get-VenafiSession)
            }

            'AccessToken' {
                $params.Server = $serverUrl

                $accessTokenString = $AccessToken | ConvertTo-PlaintextString

                $params.Header = @{'Authorization' = 'Bearer {0}' -f $accessTokenString }
            }

            'VaultAccessToken' {
                # ensure the appropriate setup has been performed
                if ( -not (Get-Module -Name Microsoft.PowerShell.SecretManagement -ListAvailable)) {
                    throw 'The module Microsoft.PowerShell.SecretManagement is required as well as a vault named ''VenafiPS''.  See the github readme for guidance, https://github.com/Venafi/VenafiPS#tokenkey-secret-storage.'
                }

                $vault = Get-SecretVault -Name 'VenafiPS' -ErrorAction SilentlyContinue
                if ( -not $vault ) {
                    throw 'A SecretManagement vault named ''VenafiPS'' could not be found'
                }

                $tokenSecret = Get-Secret -Name $VaultAccessTokenName -Vault 'VenafiPS' -ErrorAction SilentlyContinue
                if ( -not $tokenSecret ) {
                    throw "'$VaultAccessTokenName' secret not found in vault VenafiPS."
                }

                # check if metadata was stored
                $secretInfo = Get-SecretInfo -Name $VaultAccessTokenName -Vault 'VenafiPS' -ErrorAction SilentlyContinue

                if ( $secretInfo.Metadata.Count -gt 0 ) {
                    $params.Server = $secretInfo.Metadata.AuthServer
                }
                else {
                    if ( -not $AuthServer ) {
                        throw '-AuthServer is a required parameter'
                    }

                    $params.Server = $serverUrl
                }
                $params.Header = @{'Authorization' = 'Bearer {0}' -f $tokenSecret.GetNetworkCredential().password }
            }

            'VenafiPsToken' {
                if ( -not $VenafiPsToken.Server -or -not $VenafiPsToken.AccessToken ) {
                    throw 'Not a valid VenafiPsToken'
                }

                $params.Server = $VenafiPsToken.Server
                $params.Header = @{'Authorization' = 'Bearer {0}' -f $VenafiPsToken.AccessToken.GetNetworkCredential().password }
            }

            Default {
                throw ('Unknown parameter set {0}' -f $PSCmdlet.ParameterSetName)
            }
        }

        Write-Verbose ($params | Out-String)

        $response = Invoke-VenafiRestMethod @params -FullResponse

        if ( $GrantDetail ) {

            switch ( $response.StatusCode ) {

                200 {
                    $responseData = $response.Content | ConvertFrom-Json
                    [PSCustomObject] @{
                        ClientId       = $responseData.application
                        AccessIssued   = ([datetime] '1970-01-01 00:00:00').AddSeconds($responseData.access_issued_on_unix_time)
                        GrantIssued    = ([datetime] '1970-01-01 00:00:00').AddSeconds($responseData.grant_issued_on_unix_time)
                        Scope          = $responseData.scope
                        Identity       = $responseData.identity
                        RefreshExpires = ([datetime] '1970-01-01 00:00:00').AddSeconds($responseData.expires_unix_time)
                    }
                }

                Default {
                    throw ('Grant has been revoked, has expired, or the refresh token is invalid')
                }
            }

        }
        else {

            switch ( $response.StatusCode ) {
                200 {
                    $true
                }

                401 {
                    $false
                }

                Default {
                    throw ('Grant has been revoked, has expired, or the refresh token is invalid')
                }
            }
        }
    }
}

