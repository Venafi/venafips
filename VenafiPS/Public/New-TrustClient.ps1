function New-TrustClient {
    <#
    .SYNOPSIS
    Create a new Venafi Certificate Manager, Self-Hosted, Certificate Manager, SaaS or NGTS session

    .DESCRIPTION
    Authenticate a user and create a new session with which future calls can be made.
    Key based username/password and windows integrated are supported as well as token-based integrated, oauth, and certificate.
    By default, a session variable will be created and automatically used with other functions unless -PassThru is used.
    Tokens and Certificate Manager, SaaS keys can be saved in a vault for future calls.

    .PARAMETER Server
    Server or url to access vedsdk, venafi.company.com or https://venafi.company.com.
    If AuthServer is not provided, this will be used to access vedauth as well for token-based authentication.
    If just the server name is provided, https:// will be appended.

    .PARAMETER Credential
    Username and password used for token-based authentication.  Not required for integrated authentication.

    .PARAMETER ClientId
    Application/integration ID configured in Venafi for token-based authentication.
    Case sensitive.

    .PARAMETER Scope
    Hashtable with Scopes and privilege restrictions.
    The key is the scope and the value is one or more privilege restrictions separated by commas, @{'certificate'='delete,manage'}.
    Scopes include Agent, Certificate, Code Signing, Configuration, Restricted, Security, SSH, and statistics.
    For no privilege restriction or read access, use a value of $null.
    For a scope to privilege mapping, see https://docs.venafi.com/Docs/current/TopNav/Content/SDK/AuthSDK/r-SDKa-OAuthScopePrivilegeMapping.php
    Using a scope of {'all'='core'} will set all scopes except for admin.
    Using a scope of {'all'='admin'} will set all scopes including admin.
    Usage of the 'all' scope is not suggested for production.

    .PARAMETER State
    A session state, redirect URL, or random string to prevent Cross-Site Request Forgery (CSRF) attacks

    .PARAMETER AccessToken
    Provide an existing access token to create a session.
    You can either provide a String, SecureString, or PSCredential.
    If providing a credential, the username is not used.

    .PARAMETER Jwt
    JSON web token.
    Available in Certificate Manager, Self-Hosted v22.4 and later.
    Ensure JWT mapping has been configured in VCC, Access Management->JWT Mappings.

    .PARAMETER Certificate
    Certificate for Certificate Manager, Self-Hosted token-based authentication

    .PARAMETER RefreshToken
    Provide an existing refresh token to create a session.
    You can either provide a String, SecureString, or PSCredential.
    If providing a credential, the username is not used.

    .PARAMETER VaultAccessTokenName
    Name of the SecretManagement vault entry for the access token; the name of the vault must be VenafiPS.
    This value can be provided standalone or with credentials.  First time use requires it to be provided with credentials to retrieve the access token to populate the vault.
    With subsequent uses, it can be provided standalone and the access token will be retrieved without the need for credentials.

    .PARAMETER VaultRefreshTokenName
    Name of the SecretManagement vault entry for the refresh token; the name of the vault must be VenafiPS.
    This value can be provided standalone or with credentials.  Each time this is used, a new access and refresh token will be obtained.
    First time use requires it to be provided with credentials to retrieve the refresh token and populate the vault.
    With subsequent uses, it can be provided standalone and the refresh token will be retrieved without the need for credentials.

    .PARAMETER AuthServer
    If you host your authentication service, vedauth, is on a separate server than vedsdk, use this parameter to specify the url eg., venafi.company.com or https://venafi.company.com.
    If AuthServer is not provided, the value provided for Server will be used.
    If just the server name is provided, https:// will be appended.

    .PARAMETER RefreshSession
    Obtain a new access token from the refresh token.
    Requires an existing module scoped $TrustClient.

    .PARAMETER VcKey
    Api key from your Certificate Manager, SaaS instance.  The api key can be found under your user profile->preferences.
    You can either provide a String, SecureString, or PSCredential.
    If providing a credential, the username is not used.

    .PARAMETER VcAccessToken
    Provide an existing access token to create a Certificate Manager, SaaS session.
    You can either provide a String, SecureString, or PSCredential.
    If providing a credential, the username is not used.

    .PARAMETER VcRegion
    Certificate Manager, SaaS region to connect to.  Values include 'us', 'eu', 'au', 'uk', 'sg', 'ca'.  Defaults to 'us'.
    If your region is not included, you can provide the full server base URL and it will be used instead of the built-in regions.

    .PARAMETER VcEndpoint
    Token Endpoint URL as shown on the service account details page.

    .PARAMETER VaultVcKeyName
    Name of the SecretManagement vault entry for the Certificate Manager, SaaS key.
    First time use requires it to be provided with -VcKey to populate the vault.
    With subsequent uses, it can be provided standalone and the key will be retrieved without the need for -VcKey.
    The server associated with the region will be saved and restored when this parameter is used on subsequent use.

    .PARAMETER NgtsCredential
    PSCredential object for NGTS authentication.
    The username must be in the format user@1234567890.iam.panserviceaccount.com where 1234567890 is the TSG ID.
    The password is the client secret.

    .PARAMETER Tsg
    Tenant Service Group ID for NGTS.  Only required if the TSG ID in the credential username is not the target.

    .PARAMETER SkipCertificateCheck
    Bypass certificate validation when connecting to the server.
    This can be helpful for pre-prod environments where ssl isn't setup on the website or you are connecting via IP.
    You can also create an environment variable named VENAFIPS_SKIP_CERT_CHECK and set it to 1 for the same effect.

    .PARAMETER TimeoutSec
    Specifies how long the request can be pending before it times out. Enter a value in seconds. The default value, 0, specifies an indefinite time-out.

    .PARAMETER PassThru
    Optionally, send the session object to the pipeline instead of script scope.

    .OUTPUTS
    TrustClient, if -PassThru is provided

    .EXAMPLE
    New-TrustClient -Server venafi.mycompany.com -ClientId VenafiPS-MyApp -Scope @{'certificate'='manage'}

    Create token-based session using Windows Integrated authentication with a certain scope and privilege restriction

    .EXAMPLE
    New-TrustClient -Server venafi.mycompany.com -Credential $cred -ClientId VenafiPS-MyApp -Scope @{'certificate'='manage'}

    Create token-based session

    .EXAMPLE
    New-TrustClient -Server venafi.mycompany.com -Certificate $myCert -ClientId VenafiPS-MyApp -Scope @{'certificate'='manage'}

    Create token-based session using a client certificate

    .EXAMPLE
    New-TrustClient -Server venafi.mycompany.com -AuthServer tppauth.mycompany.com -ClientId VenafiPS-MyApp -Credential $cred

    Create token-based session using oauth authentication where the vedauth and vedsdk are hosted on different servers

    .EXAMPLE
    $sess = New-TrustClient -Server venafi.mycompany.com -Credential $cred -PassThru

    Create session and return the session object instead of setting to script scope variable

    .EXAMPLE
    New-TrustClient -Server venafi.mycompany.com -AccessToken $accessCred

    Create session using an access token obtained outside this module

    .EXAMPLE
    New-TrustClient -Server venafi.mycompany.com -RefreshToken $refreshCred -ClientId VenafiPS-MyApp

    Create session using a refresh token

    .EXAMPLE
    New-TrustClient -Server venafi.mycompany.com -RefreshToken $refreshCred -ClientId VenafiPS-MyApp -VaultRefreshTokenName TppRefresh

    Create session using a refresh token and store the newly created refresh token in the vault

    .EXAMPLE
    New-TrustClient -VcKey $cred

    Create session against Certificate Manager, SaaS

    .EXAMPLE
    New-TrustClient -VcKey $cred -VcRegion 'eu'

    Create session against Certificate Manager, SaaS in EU region

    .EXAMPLE
    New-TrustClient -VaultVcKeyName vaas-key

    Create session against Certificate Manager, SaaS with a key stored in a vault

    .EXAMPLE
    New-TrustClient -NgtsCredential $cred

    Create session against NGTS with the provided credential

    .EXAMPLE
    New-TrustClient -NgtsCredential $cred -Tsg 1234567890

    Create session against NGTS with the provided credential and override the TSG specified in the credential username

    .LINK
    https://venafi.github.io/VenafiPS/functions/New-TrustClient/

    .LINK
    https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/New-TrustClient.ps1

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/API_Reference/r-SDK-POST-Authorize.php

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/API_Reference/r-SDK-GET-Authorize-Integrated.php

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/AuthSDK/r-SDKa-POST-Authorize-Integrated.php

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/AuthSDK/r-SDKa-POST-AuthorizeOAuth.php

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/AuthSDK/r-SDKa-POST-AuthorizeCertificate.php

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/AuthSDK/r-SDKa-POST-AuthorizeJwt.php

    .LINK
    https://github.com/PowerShell/SecretManagement

    .LINK
    https://github.com/PowerShell/SecretStore

    .LINK
    https://pan.dev/scm/docs/access-tokens/
    #>

    [CmdletBinding(DefaultParameterSetName = 'TokenIntegrated')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Not needed')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'Converting secret to credential')]

    param(
        [Parameter(Mandatory, ParameterSetName = 'TokenOAuth')]
        [Parameter(Mandatory, ParameterSetName = 'TokenIntegrated')]
        [Parameter(Mandatory, ParameterSetName = 'TokenCertificate')]
        [Parameter(Mandatory, ParameterSetName = 'TokenJwt')]
        [Parameter(Mandatory, ParameterSetName = 'AccessToken')]
        [Parameter(Mandatory, ParameterSetName = 'RefreshToken')]
        [Parameter(ParameterSetName = 'VaultAccessToken')]
        [Parameter(ParameterSetName = 'VaultRefreshToken')]
        [Alias('ServerUrl', 'Url')]
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
        [string] $Server,

        [Parameter(Mandatory, ParameterSetName = 'TokenOAuth')]
        [System.Management.Automation.PSCredential] $Credential,

        [Parameter(Mandatory, ParameterSetName = 'TokenIntegrated')]
        [Parameter(Mandatory, ParameterSetName = 'TokenOAuth')]
        [Parameter(Mandatory, ParameterSetName = 'TokenCertificate')]
        [Parameter(Mandatory, ParameterSetName = 'TokenJwt')]
        [Parameter(ParameterSetName = 'RefreshToken', Mandatory)]
        [Parameter(ParameterSetName = 'VaultRefreshToken')]
        [string] $ClientId,

        [Parameter(Mandatory, ParameterSetName = 'TokenIntegrated')]
        [Parameter(Mandatory, ParameterSetName = 'TokenOAuth')]
        [Parameter(Mandatory, ParameterSetName = 'TokenCertificate')]
        [Parameter(Mandatory, ParameterSetName = 'TokenJwt')]
        [Parameter(ParameterSetName = 'VaultAccessToken')]
        [Parameter(ParameterSetName = 'VaultRefreshToken')]
        [hashtable] $Scope,

        [Parameter(ParameterSetName = 'TokenIntegrated')]
        [Parameter(ParameterSetName = 'TokenOAuth')]
        [string] $State,

        [Parameter(Mandatory, ParameterSetName = 'AccessToken')]
        [psobject] $AccessToken,

        [Parameter(Mandatory, ParameterSetName = 'RefreshToken')]
        [psobject] $RefreshToken,

        [Parameter(Mandatory, ParameterSetName = 'TokenJwt')]
        [Parameter(Mandatory, ParameterSetName = 'VcToken')]
        [string] $Jwt,

        [Parameter(Mandatory, ParameterSetName = 'TokenCertificate')]
        [X509Certificate] $Certificate,

        [Parameter(Mandatory, ParameterSetName = 'VaultAccessToken')]
        [Parameter(ParameterSetName = 'AccessToken')]
        [Parameter(ParameterSetName = 'TokenIntegrated')]
        [Parameter(ParameterSetName = 'TokenOAuth')]
        [Parameter(ParameterSetName = 'TokenCertificate')]
        [string] $VaultAccessTokenName,

        [Parameter(Mandatory, ParameterSetName = 'VaultRefreshToken')]
        [Parameter(ParameterSetName = 'RefreshToken')]
        [Parameter(ParameterSetName = 'TokenIntegrated')]
        [Parameter(ParameterSetName = 'TokenOAuth')]
        [Parameter(ParameterSetName = 'TokenCertificate')]
        [string] $VaultRefreshTokenName,

        [Parameter(ParameterSetName = 'TokenOAuth')]
        [Parameter(ParameterSetName = 'TokenIntegrated')]
        [Parameter(ParameterSetName = 'TokenCertificate')]
        [Parameter(ParameterSetName = 'RefreshToken')]
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
        [string] $AuthServer,

        [Parameter(Mandatory, ParameterSetName = 'Vc')]
        [psobject] $VcKey,

        [Parameter(ParameterSetName = 'Vc')]
        [Parameter(ParameterSetName = 'VcAccessToken')]
        [ValidateScript(
            {
                if ( $_ -notin ($script:VcRegions).Keys ) {
                    Write-Warning ('{0} is not a built-in known region which includes {1}.  Continuing with user-provided region.' -f $_, (($script:VcRegions).Keys -join ','))
                }
                $true
            }
        )]
        [string] $VcRegion = 'us',

        [Parameter(Mandatory, ParameterSetName = 'VcAccessToken')]
        [ValidateNotNullOrEmpty()]
        [psobject] $VcAccessToken,

        [Parameter(Mandatory, ParameterSetName = 'VcToken')]
        [string] $VcEndpoint,

        [Parameter(ParameterSetName = 'Vc')]
        [Parameter(Mandatory, ParameterSetName = 'VaultVcKey')]
        [string] $VaultVcKeyName,

        [Parameter(ParameterSetName = 'Ngts', Mandatory)]
        [ValidateScript(
            {
                $tsgMatch = [regex]::Match($_.UserName, '^[^@]+@(?<tsg>\d{10})\.iam\.panserviceaccount\.com$')
                if ( -not $tsgMatch.Success ) {
                    throw 'Credential.UserName must be in the format user@1234567890.iam.panserviceaccount.com'
                }

                $true
            }
        )]
        [System.Management.Automation.PSCredential] $NgtsCredential,

        [Parameter(ParameterSetName = 'Ngts')]
        [ValidateRange(1000000000, 9999999999)]
        [long] $Tsg,

        [Parameter(ParameterSetName = 'RefreshSession')]
        [switch] $RefreshSession,

        [Parameter()]
        [Int32] $TimeoutSec = 0,

        [Parameter()]
        [switch] $PassThru,

        [Parameter(ParameterSetName = 'TokenOAuth')]
        [Parameter(ParameterSetName = 'TokenIntegrated')]
        [Parameter(ParameterSetName = 'TokenCertificate')]
        [Parameter(ParameterSetName = 'TokenJwt')]
        [Parameter(ParameterSetName = 'AccessToken')]
        [Parameter(ParameterSetName = 'RefreshToken')]
        [Parameter(ParameterSetName = 'VaultAccessToken')]
        [Parameter(ParameterSetName = 'VaultRefreshToken')]
        [switch] $SkipCertificateCheck
    )

    $isVerbose = if ($PSBoundParameters.Verbose -eq $true) { $true } else { $false }

    $serverUrl = $Server
    # add prefix if just server url was provided
    if ( $Server -notlike 'https://*') {
        $serverUrl = 'https://{0}' -f $serverUrl
    }

    $authServerUrl = $serverUrl
    if ( $AuthServer ) {
        $authServerUrl = $AuthServer
        if ( $authServerUrl -notlike 'https://*') {
            $authServerUrl = 'https://{0}' -f $authServerUrl
        }
    }

    $newClient = [TrustClient]::new()
    $newClient.Platform = 'VDC'
    $newClient.Server = $serverUrl
    $newClient.TimeoutSec = $TimeoutSec
    $newClient.SkipCertificateCheck = $SkipCertificateCheck.IsPresent

    Write-Verbose ('Parameter set: {0}' -f $PSCmdlet.ParameterSetName)

    if ( $PSBoundParameters.Keys -like 'Vault*') {
        # ensure the appropriate setup has been performed
        if ( -not (Get-Module -Name Microsoft.PowerShell.SecretManagement -ListAvailable)) {
            throw 'Vault functionality requires the module Microsoft.PowerShell.SecretManagement as well as a vault named ''VenafiPS''.  See the github readme for guidance, https://github.com/Venafi/VenafiPS#tokenkey-secret-storage.'
        }

        $vault = Get-SecretVault -Name 'VenafiPS' -ErrorAction SilentlyContinue
        if ( -not $vault ) {
            throw 'A SecretManagement vault named ''VenafiPS'' could not be found'
        }
    }

    # if ( $PSCmdlet.ShouldProcess($Server, 'New session') ) {
    Switch ($PsCmdlet.ParameterSetName)	{

        'RefreshSession' {
            if ( -not $script:TrustClient ) {
                throw 'No existing session to refresh'
            }

            $client = $script:TrustClient

            if ( -not $client.AuthServer -or -not $client.RefreshToken -or -not $client.ClientId ) {
                throw 'In order to refresh an existing session, it must have a Server, RefreshToken, and ClientId.'
            }

            $refreshParams = @{
                Server               = $client.AuthServer
                RefreshToken         = $client.RefreshToken
                ClientId             = $client.ClientId
                SkipCertificateCheck = $client.SkipCertificateCheck
            }

            New-TrustClient @refreshParams
            return
        }

        { $_ -in 'TokenOAuth', 'TokenIntegrated', 'TokenCertificate', 'TokenJwt' } {
            $params = @{
                AuthServer           = $authServerUrl
                ClientId             = $ClientId
                Scope                = $Scope
                SkipCertificateCheck = $SkipCertificateCheck
            }

            if ($Credential) {
                $params.Credential = $Credential
            }

            if ($Certificate) {
                $params.Certificate = $Certificate
            }

            if ( $PSBoundParameters.ContainsKey('Jwt') ) {
                $params.Jwt = $Jwt
            }

            if ($State) {
                $params.State = $State
            }

            $token = New-VdcToken @params -Verbose:$isVerbose
            $newClient.AuthType = 'OAuth'
            $newClient.AccessToken = $token.AccessToken
            $newClient.RefreshToken = $token.RefreshToken
            $newClient.AuthServer = $token.Server
            $newClient.ClientId = $token.ClientId
            $newClient.Scope = $token.Scope
            $newClient.Expires = $token.Expires
            if ($token.RefreshExpires -gt [datetime]::MinValue) { $newClient.RefreshExpires = $token.RefreshExpires }
            if ($Credential) { $newClient.Credential = $Credential }
        }

        'VcToken' {
            # access token via service account for Certificate Manager, SaaS
            $newClient.Platform = 'VC'
            $systemUri = [System.Uri]::new($VcEndpoint)
            $newClient.Server = 'https://{0}' -f $systemUri.Host
            $token = New-VcToken -Endpoint $VcEndpoint -Jwt $Jwt -Verbose:$isVerbose
            $newClient.AuthType = 'BearerToken'
            $newClient.AccessToken = $token.AccessToken
            $newClient.Expires = $token.Expires
            $newClient.Scope = $token.Scope
            $newClient.AuthServer = $token.Server
            $newClient.Credential = $token.Credential
        }

        'AccessToken' {
            $newClient.AuthType = 'BearerToken'
            $newClient.AuthServer = $authServerUrl
            # we don't have the expiry so create one and rely on api failures if invalid
            $newClient.Expires = (Get-Date).AddMonths(12)

            $newClient.AccessToken = if ( $AccessToken -is [string] ) { New-Object System.Management.Automation.PSCredential('AccessToken', ($AccessToken | ConvertTo-SecureString -AsPlainText -Force)) }
            elseif ($AccessToken -is [pscredential]) { $AccessToken }
            elseif ($AccessToken -is [securestring]) { New-Object System.Management.Automation.PSCredential('AccessToken', $AccessToken) }
            else { throw 'Unsupported type for -AccessToken.  Provide either a String, SecureString, or PSCredential.' }

            # validate token
            $null = Invoke-TrustRestMethod -UriRoot 'vedauth' -UriLeaf 'Authorize/Verify' -TrustClient $newClient
        }

        'VaultAccessToken' {
            $tokenSecret = Get-Secret -Name $VaultAccessTokenName -Vault 'VenafiPS' -ErrorAction SilentlyContinue
            if ( -not $tokenSecret ) {
                throw "'$VaultAccessTokenName' secret not found in vault VenafiPS."
            }

            # check if metadata was stored or we should get from params
            $secretInfo = Get-SecretInfo -Name $VaultAccessTokenName -Vault 'VenafiPS' -ErrorAction SilentlyContinue

            if ( $secretInfo.Metadata.Count -gt 0 ) {
                $newClient.Server = $secretInfo.Metadata.Server
                $newClient.AuthType = 'BearerToken'
                $newClient.AuthServer = $secretInfo.Metadata.AuthServer
                $newClient.AccessToken = $tokenSecret
                $newClient.ClientId = $secretInfo.Metadata.ClientId
                $newClient.Scope = $secretInfo.Metadata.Scope
                $newClient.SkipCertificateCheck = [bool] $secretInfo.Metadata.SkipCertificateCheck
                $newClient.TimeoutSec = $secretInfo.Metadata.TimeoutSec
            }
            else {
                throw 'Server and ClientId metadata not found.  Execute New-TrustClient -Server $server -Credential $cred -ClientId $clientId -Scope $scope -VaultAccessToken $secretName and attempt the operation again.'
            }

        }

        'RefreshToken' {
            $params = @{
                AuthServer           = $authServerUrl
                ClientId             = $ClientId
                SkipCertificateCheck = $SkipCertificateCheck
            }
            $params.RefreshToken = if ( $RefreshToken -is [string] ) { New-Object System.Management.Automation.PSCredential('RefreshToken', ($RefreshToken | ConvertTo-SecureString -AsPlainText -Force)) }
            elseif ($RefreshToken -is [pscredential]) { $RefreshToken }
            elseif ($RefreshToken -is [securestring]) { New-Object System.Management.Automation.PSCredential('RefreshToken', $RefreshToken) }
            else { throw 'Unsupported type for -RefreshToken.  Provide either a String, SecureString, or PSCredential.' }

            $newToken = New-VdcToken @params
            $newClient.AuthType = 'OAuth'
            $newClient.AccessToken = $newToken.AccessToken
            $newClient.RefreshToken = $newToken.RefreshToken
            $newClient.AuthServer = $newToken.Server
            $newClient.ClientId = $newToken.ClientId
            $newClient.Scope = $newToken.Scope
            $newClient.Expires = $newToken.Expires
            if ($newToken.RefreshExpires) { $newClient.RefreshExpires = $newToken.RefreshExpires }
        }

        'VaultRefreshToken' {
            $tokenSecret = Get-Secret -Name $VaultRefreshTokenName -Vault 'VenafiPS' -ErrorAction SilentlyContinue
            if ( -not $tokenSecret ) {
                throw "'$VaultRefreshTokenName' secret not found in vault VenafiPS."
            }

            # check if metadata was stored or we should get from params
            $secretInfo = Get-SecretInfo -Name $VaultRefreshTokenName -Vault 'VenafiPS' -ErrorAction SilentlyContinue

            if ( $secretInfo.Metadata.Count -gt 0 ) {
                $params = @{
                    AuthServer           = $secretInfo.Metadata.AuthServer
                    ClientId             = $secretInfo.Metadata.ClientId
                    SkipCertificateCheck = [bool] $secretInfo.Metadata.SkipCertificateCheck
                }
            }
            else {
                throw 'Server and ClientId metadata not found.  Execute New-TrustClient -Server $server -Credential $cred -ClientId $clientId -Scope $scope -VaultRefreshToken $secretName and attempt the operation again.'
            }

            $params.RefreshToken = $tokenSecret

            $newToken = New-VdcToken @params
            $newClient.AuthType = 'OAuth'
            $newClient.AccessToken = $newToken.AccessToken
            $newClient.RefreshToken = $newToken.RefreshToken
            $newClient.AuthServer = $newToken.Server
            $newClient.ClientId = $newToken.ClientId
            $newClient.Scope = $newToken.Scope
            $newClient.Expires = $newToken.Expires
            if ($newToken.RefreshExpires) { $newClient.RefreshExpires = $newToken.RefreshExpires }
            $newClient.Server = $newToken.Server
            $newClient.Scope = $secretInfo.Metadata.Scope | ConvertFrom-Json
            $newClient.SkipCertificateCheck = [bool] $secretInfo.Metadata.SkipCertificateCheck
            $newClient.TimeoutSec = $secretInfo.Metadata.TimeoutSec
        }

        'Vc' {
            $newClient.Platform = 'VC'
            $newClient.Server = if ( $VcRegion -in ($script:VcRegions).Keys ) {
                ($script:VcRegions).$VcRegion
            }
            else {
                $VcRegion
            }
            $key = if ( $VcKey -is [string] ) { New-Object System.Management.Automation.PSCredential('VcKey', ($VcKey | ConvertTo-SecureString -AsPlainText -Force)) }
            elseif ($VcKey -is [pscredential]) { $VcKey }
            elseif ($VcKey -is [securestring]) { New-Object System.Management.Automation.PSCredential('VcKey', $VcKey) }
            else { throw 'Unsupported type for -VcKey.  Provide either a String, SecureString, or PSCredential.' }
            $newClient.AuthType = 'ApiKey'
            $newClient.ApiKey = $key

            if ( $VaultVcKeyName ) {
                $metadata = @{
                    Server     = $newClient.Server
                    TimeoutSec = [int]$newClient.TimeoutSec
                }
                Set-Secret -Name $VaultVcKeyName -Secret $newClient.ApiKey -Vault 'VenafiPS' -Metadata $metadata
            }
        }

        'VcAccessToken' {
            $newClient.Platform = 'VC'
            $newClient.Server = if ( $VcRegion -in ($script:VcRegions).Keys ) {
                ($script:VcRegions).$VcRegion
            }
            else {
                $VcRegion
            }
            $newClient.AuthType = 'BearerToken'

            $newClient.AccessToken = if ( $VcAccessToken -is [string] ) { New-Object System.Management.Automation.PSCredential('AccessToken', ($VcAccessToken | ConvertTo-SecureString -AsPlainText -Force)) }
            elseif ($VcAccessToken -is [pscredential]) { $VcAccessToken }
            elseif ($VcAccessToken -is [securestring]) { New-Object System.Management.Automation.PSCredential('AccessToken', $VcAccessToken) }
            else { throw 'Unsupported type for -VcAccessToken.  Provide either a String, SecureString, or PSCredential.' }
            $newClient.Expires = (Get-Date).AddMonths(12)
        }

        'VaultVcKey' {
            $keySecret = Get-Secret -Name $VaultVcKeyName -Vault 'VenafiPS' -ErrorAction SilentlyContinue
            if ( -not $keySecret ) {
                throw "'$VaultVcKeyName' secret not found in vault VenafiPS."
            }

            $secretInfo = Get-SecretInfo -Name $VaultVcKeyName -Vault 'VenafiPS' -ErrorAction SilentlyContinue

            if ( $secretInfo.Metadata.Count -gt 0 ) {
                $newClient.Server = $secretInfo.Metadata.Server
            }
            else {
                throw 'Server metadata not found.  Execute New-TrustClient -VcKey $key -VaultVcKeyName $secretName and attempt the operation again.'
            }

            $newClient.Platform = 'VC'
            $newClient.AuthType = 'ApiKey'
            $newClient.ApiKey = $keySecret
        }

        'Ngts' {
            $params = @{
                Credential = $NgtsCredential
            }

            if ($Tsg) {
                $params.Tsg = $Tsg
            }

            $token = New-NgtsToken @params -Verbose:$isVerbose

            $newClient.Platform = 'NGTS'
            $newClient.Server = 'https://api.strata.paloaltonetworks.com'
            $newClient.AuthType = 'ClientCredential'
            $newClient.Credential = $NgtsCredential
            $newClient.AccessToken = $token.AccessToken
            $newClient.Scope = $token.Scope
            $newClient.Expires = $token.Expires
            if ($Tsg) {
                $newClient.Tsg = $Tsg
            }
            elseif ( $token.Scope -match '(?:^|\s)tsg_id:([^\s]+)' ) {
                $newClient.Tsg = $Matches[1]
            }
        }

        Default {
            throw ('Unknown parameter set {0}' -f $PSCmdlet.ParameterSetName)
        }
    }

    # will fail if user is on an older version.  this isn't required so bypass on failure
    # only applicable to tpp
    if ( $newClient.Platform -eq 'VDC' ) {
        $newClient.Version = [Version]((Invoke-TrustRestMethod -UriLeaf 'SystemStatus/Version' -TrustClient $newClient -ErrorAction SilentlyContinue).Version)
        $certFields = 'X509 Certificate', 'Device', 'Application Base' | Get-VdcCustomField -TrustClient $newClient -ErrorAction SilentlyContinue
        # make sure we remove duplicates
        $newClient.CustomField = $certFields.Items | Sort-Object -Property Guid -Unique
    }
    elseif ( $newClient.Platform -eq 'NGTS' ) {
        # NGTS does not expose the VC useraccounts endpoint. Capture TSG context from token scope.
        # if ( -not $newClient.Tsg -and $newClient.Scope -match '(?:^|\s)tsg_id:([^\s]+)' ) {
        #     $newClient.Tsg = $Matches[1]
        # }

        # if ( $newClient.Tsg ) {
        #     $newClient.User = [pscustomobject] @{
        #         tsgId = $newClient.Tsg
        #         scope = $newClient.Scope
        #     }
        # }
    }
    else {

        # user might not have access to this api, eg. service account
        $me = Invoke-TrustRestMethod -UriLeaf 'useraccounts' -TrustClient $newClient -ErrorAction SilentlyContinue
        if ( $me.user ) {
            $newClient.User = $me.user | Select-Object @{
                'n' = 'userId'
                'e' = {
                    $_.Id
                }
            }, * -ExcludeProperty id
        }
    }

    if ( $VaultAccessTokenName -or $VaultRefreshTokenName ) {
        # save secret and all associated metadata to be retrieved later
        $metadata = @{
            Server               = $newClient.Server
            AuthServer           = $newClient.AuthServer
            ClientId             = $newClient.ClientId
            Scope                = $newClient.Scope | ConvertTo-Json -Compress
            SkipCertificateCheck = [int]$newClient.SkipCertificateCheck
            TimeoutSec           = [int]$newClient.TimeoutSec
        }

        $metadata | ConvertTo-Json | Write-Verbose

        if ( $VaultAccessTokenName ) {
            Set-Secret -Name $VaultAccessTokenName -Secret $newClient.AccessToken -Vault 'VenafiPS' -Metadata $metadata
        }
        else {
            if ( $newClient.RefreshToken ) {
                Set-Secret -Name $VaultRefreshTokenName -Secret $newClient.RefreshToken -Vault 'VenafiPS' -Metadata $metadata
            }
            else {
                Write-Warning 'Refresh token not provided by server and will not be saved in the vault'
            }
        }
    }

    if ( $PassThru ) {
        $newClient
    }
    else {
        $Script:TrustClient = $newClient
    }
}


