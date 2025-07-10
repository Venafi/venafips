function Revoke-VdcToken {
    <#
    .SYNOPSIS
    Revoke a token

    .DESCRIPTION
    Revoke a token and invalidate the refresh token if provided/available.
    This could be an access token retrieved from this module or from other means.

    .PARAMETER AuthServer
    Server name or URL for the vedauth service

    .PARAMETER AccessToken
    Provide an existing access token to revoke.
    You can either provide a String, SecureString, or PSCredential.
    If providing a credential, the username is not used.

    .PARAMETER VenafiPsToken
    Token object obtained from New-VdcToken

    .PARAMETER Force
    Bypass the confirmation prompt

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.

    .INPUTS
    VenafiPsToken

    .OUTPUTS
    none

    .EXAMPLE
    Revoke-VdcToken
    Revoke token stored in session variable $VenafiSession from New-VenafiSession

    .EXAMPLE
    Revoke-VdcToken -Force
    Revoke token bypassing confirmation prompt

    .EXAMPLE
    Revoke-VdcToken -AuthServer venafi.company.com -AccessToken $cred
    Revoke a token obtained from TLSPDC, not necessarily via VenafiPS

    .LINK
    https://venafi.github.io/VenafiPS/functions/Revoke-VdcToken/

    .LINK
    https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Revoke-VdcToken.ps1

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/AuthSDK/r-SDKa-GET-Revoke-Token.php

    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High', DefaultParameterSetName = 'Session')]
    [Alias('Revoke-TppToken')]

    param (
        [Parameter(Mandatory, ParameterSetName = 'AccessToken')]
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

        [Parameter(Mandatory, ParameterSetName = 'AccessToken')]
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

        [Parameter(Mandatory, ParameterSetName = 'VenafiPsToken', ValueFromPipeline)]
        [pscustomobject] $VenafiPsToken,

        [Parameter()]
        [switch] $Force,

        [Parameter(ParameterSetName = 'Session')]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {
        $params = @{
            Method  = 'Get'
            UriRoot = 'vedauth'
            UriLeaf = 'Revoke/Token'
        }
    }

    process {

        Write-Verbose ('Parameter set: {0}' -f $PSCmdlet.ParameterSetName)

        switch ($PsCmdlet.ParameterSetName) {
            'Session' {
                $params.VenafiSession = (Get-VenafiSession)
                $target = $params.VenafiSession.Server
            }

            'AccessToken' {
                $AuthUrl = $AuthServer
                # add prefix if just server was provided
                if ( $AuthServer -notlike 'https://*') {
                    $AuthUrl = 'https://{0}' -f $AuthUrl
                }

                $params.Server = $target = $AuthUrl

                $accessTokenString = $AccessToken | ConvertTo-PlaintextString

                $params.Header = @{'Authorization' = 'Bearer {0}' -f $accessTokenString }
            }

            'VenafiPsToken' {
                if ( -not $VenafiPsToken.Server -or -not $VenafiPsToken.AccessToken ) {
                    throw 'Not a valid VenafiPsToken'
                }

                $params.Server = $target = $VenafiPsToken.Server
                $params.Header = @{'Authorization' = 'Bearer {0}' -f $VenafiPsToken.AccessToken.GetNetworkCredential().password }
            }

            Default {
                throw ('Unknown parameter set {0}' -f $PSCmdlet.ParameterSetName)
            }
        }

        Write-Verbose ($params | Out-String)

        if ( $Force ) {
            $ConfirmPreference = 'None'
        }

        if ( $PSCmdlet.ShouldProcess($target) ) {
            Invoke-VenafiRestMethod @params
        }
    }
}


