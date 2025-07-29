# New-VenafiSession

## SYNOPSIS
Create a new Venafi TLSPDC or TLSPC session

## SYNTAX

### KeyIntegrated (Default)
```
New-VenafiSession -Server <String> [-TimeoutSec <Int32>] [-PassThru] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### VaultRefreshToken
```
New-VenafiSession [-Server <String>] [-ClientId <String>] [-Scope <Hashtable>] -VaultRefreshTokenName <String>
 [-TimeoutSec <Int32>] [-PassThru] [-SkipCertificateCheck] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### VaultAccessToken
```
New-VenafiSession [-Server <String>] [-Scope <Hashtable>] -VaultAccessTokenName <String> [-TimeoutSec <Int32>]
 [-PassThru] [-SkipCertificateCheck] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### RefreshToken
```
New-VenafiSession -Server <String> -ClientId <String> -RefreshToken <PSObject>
 [-VaultRefreshTokenName <String>] [-AuthServer <String>] [-TimeoutSec <Int32>] [-PassThru]
 [-SkipCertificateCheck] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### AccessToken
```
New-VenafiSession -Server <String> -AccessToken <PSObject> [-VaultAccessTokenName <String>]
 [-TimeoutSec <Int32>] [-PassThru] [-SkipCertificateCheck] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### TokenJwt
```
New-VenafiSession -Server <String> -ClientId <String> -Scope <Hashtable> -Jwt <String> [-TimeoutSec <Int32>]
 [-PassThru] [-SkipCertificateCheck] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### TokenCertificate
```
New-VenafiSession -Server <String> -ClientId <String> -Scope <Hashtable> -Certificate <X509Certificate>
 [-VaultAccessTokenName <String>] [-VaultRefreshTokenName <String>] [-AuthServer <String>]
 [-TimeoutSec <Int32>] [-PassThru] [-SkipCertificateCheck] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### TokenIntegrated
```
New-VenafiSession -Server <String> -ClientId <String> -Scope <Hashtable> [-State <String>]
 [-VaultAccessTokenName <String>] [-VaultRefreshTokenName <String>] [-AuthServer <String>]
 [-TimeoutSec <Int32>] [-PassThru] [-SkipCertificateCheck] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### TokenOAuth
```
New-VenafiSession -Server <String> -Credential <PSCredential> -ClientId <String> -Scope <Hashtable>
 [-State <String>] [-VaultAccessTokenName <String>] [-VaultRefreshTokenName <String>] [-AuthServer <String>]
 [-TimeoutSec <Int32>] [-PassThru] [-SkipCertificateCheck] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### KeyCredential
```
New-VenafiSession -Server <String> -Credential <PSCredential> [-TimeoutSec <Int32>] [-PassThru]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### VcToken
```
New-VenafiSession -Jwt <String> -VcEndpoint <String> [-TimeoutSec <Int32>] [-PassThru]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Vc
```
New-VenafiSession -VcKey <PSObject> [-VcRegion <String>] [-VaultVcKeyName <String>] [-TimeoutSec <Int32>]
 [-PassThru] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### VaultVcKey
```
New-VenafiSession -VaultVcKeyName <String> [-TimeoutSec <Int32>] [-PassThru]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### RefreshSession
```
New-VenafiSession [-RefreshSession] [-TimeoutSec <Int32>] [-PassThru] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Authenticate a user and create a new session with which future calls can be made.
Key based username/password and windows integrated are supported as well as token-based integrated, oauth, and certificate.
By default, a session variable will be created and automatically used with other functions unless -PassThru is used.
Tokens and TLSPC keys can be saved in a vault for future calls.

## EXAMPLES

### EXAMPLE 1
```
New-VenafiSession -Server venafi.mycompany.com -ClientId VenafiPS-MyApp -Scope @{'certificate'='manage'}
```

Create token-based session using Windows Integrated authentication with a certain scope and privilege restriction

### EXAMPLE 2
```
New-VenafiSession -Server venafi.mycompany.com -Credential $cred -ClientId VenafiPS-MyApp -Scope @{'certificate'='manage'}
```

Create token-based session

### EXAMPLE 3
```
New-VenafiSession -Server venafi.mycompany.com -Certificate $myCert -ClientId VenafiPS-MyApp -Scope @{'certificate'='manage'}
```

Create token-based session using a client certificate

### EXAMPLE 4
```
New-VenafiSession -Server venafi.mycompany.com -AuthServer tppauth.mycompany.com -ClientId VenafiPS-MyApp -Credential $cred
```

Create token-based session using oauth authentication where the vedauth and vedsdk are hosted on different servers

### EXAMPLE 5
```
$sess = New-VenafiSession -Server venafi.mycompany.com -Credential $cred -PassThru
```

Create session and return the session object instead of setting to script scope variable

### EXAMPLE 6
```
New-VenafiSession -Server venafi.mycompany.com -AccessToken $accessCred
```

Create session using an access token obtained outside this module

### EXAMPLE 7
```
New-VenafiSession -Server venafi.mycompany.com -RefreshToken $refreshCred -ClientId VenafiPS-MyApp
```

Create session using a refresh token

### EXAMPLE 8
```
New-VenafiSession -Server venafi.mycompany.com -RefreshToken $refreshCred -ClientId VenafiPS-MyApp -VaultRefreshTokenName TppRefresh
```

Create session using a refresh token and store the newly created refresh token in the vault

### EXAMPLE 9
```
New-VenafiSession -VcKey $cred
```

Create session against TLSPC

### EXAMPLE 10
```
New-VenafiSession -VcKey $cred -VcRegion 'eu'
```

Create session against TLSPC in EU region

### EXAMPLE 11
```
New-VenafiSession -VaultVcKeyName vaas-key
```

Create session against TLSPC with a key stored in a vault

## PARAMETERS

### -Server
Server or url to access vedsdk, venafi.company.com or https://venafi.company.com.
If AuthServer is not provided, this will be used to access vedauth as well for token-based authentication.
If just the server name is provided, https:// will be appended.

```yaml
Type: String
Parameter Sets: KeyIntegrated, RefreshToken, AccessToken, TokenJwt, TokenCertificate, TokenIntegrated, TokenOAuth, KeyCredential
Aliases: ServerUrl, Url

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: VaultRefreshToken, VaultAccessToken
Aliases: ServerUrl, Url

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential
Username and password used for token-based authentication. 
Not required for integrated authentication.

```yaml
Type: PSCredential
Parameter Sets: TokenOAuth, KeyCredential
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ClientId
Application/integration ID configured in Venafi for token-based authentication.
Case sensitive.

```yaml
Type: String
Parameter Sets: VaultRefreshToken
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: RefreshToken, TokenJwt, TokenCertificate, TokenIntegrated, TokenOAuth
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Scope
Hashtable with Scopes and privilege restrictions.
The key is the scope and the value is one or more privilege restrictions separated by commas, @{'certificate'='delete,manage'}.
Scopes include Agent, Certificate, Code Signing, Configuration, Restricted, Security, SSH, and statistics.
For no privilege restriction or read access, use a value of $null.
For a scope to privilege mapping, see https://docs.venafi.com/Docs/current/TopNav/Content/SDK/AuthSDK/r-SDKa-OAuthScopePrivilegeMapping.php
Using a scope of {'all'='core'} will set all scopes except for admin.
Using a scope of {'all'='admin'} will set all scopes including admin.
Usage of the 'all' scope is not suggested for production.

```yaml
Type: Hashtable
Parameter Sets: VaultRefreshToken, VaultAccessToken
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: Hashtable
Parameter Sets: TokenJwt, TokenCertificate, TokenIntegrated, TokenOAuth
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -State
A session state, redirect URL, or random string to prevent Cross-Site Request Forgery (CSRF) attacks

```yaml
Type: String
Parameter Sets: TokenIntegrated, TokenOAuth
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AccessToken
Provide an existing access token to create a session.
You can either provide a String, SecureString, or PSCredential.
If providing a credential, the username is not used.

```yaml
Type: PSObject
Parameter Sets: AccessToken
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RefreshToken
Provide an existing refresh token to create a session.
You can either provide a String, SecureString, or PSCredential.
If providing a credential, the username is not used.

```yaml
Type: PSObject
Parameter Sets: RefreshToken
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Jwt
JSON web token.
Available in TLSPDC v22.4 and later.
Ensure JWT mapping has been configured in VCC, Access Management-\>JWT Mappings.

```yaml
Type: String
Parameter Sets: TokenJwt, VcToken
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Certificate
Certificate for TLSPDC token-based authentication

```yaml
Type: X509Certificate
Parameter Sets: TokenCertificate
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -VaultAccessTokenName
Name of the SecretManagement vault entry for the access token; the name of the vault must be VenafiPS.
This value can be provided standalone or with credentials. 
First time use requires it to be provided with credentials to retrieve the access token to populate the vault.
With subsequent uses, it can be provided standalone and the access token will be retrieved without the need for credentials.

```yaml
Type: String
Parameter Sets: VaultAccessToken
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: AccessToken, TokenCertificate, TokenIntegrated, TokenOAuth
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -VaultRefreshTokenName
Name of the SecretManagement vault entry for the refresh token; the name of the vault must be VenafiPS.
This value can be provided standalone or with credentials. 
Each time this is used, a new access and refresh token will be obtained.
First time use requires it to be provided with credentials to retrieve the refresh token and populate the vault.
With subsequent uses, it can be provided standalone and the refresh token will be retrieved without the need for credentials.

```yaml
Type: String
Parameter Sets: VaultRefreshToken
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: RefreshToken, TokenCertificate, TokenIntegrated, TokenOAuth
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AuthServer
If you host your authentication service, vedauth, is on a separate server than vedsdk, use this parameter to specify the url eg., venafi.company.com or https://venafi.company.com.
If AuthServer is not provided, the value provided for Server will be used.
If just the server name is provided, https:// will be appended.

```yaml
Type: String
Parameter Sets: RefreshToken, TokenCertificate, TokenIntegrated, TokenOAuth
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -VcKey
Api key from your TLSPC instance. 
The api key can be found under your user profile-\>preferences.
You can either provide a String, SecureString, or PSCredential.
If providing a credential, the username is not used.

```yaml
Type: PSObject
Parameter Sets: Vc
Aliases: VaasKey

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -VcRegion
TLSPC region to connect to, tab-ahead values provided. 
Defaults to 'us'.

```yaml
Type: String
Parameter Sets: Vc
Aliases:

Required: False
Position: Named
Default value: Us
Accept pipeline input: False
Accept wildcard characters: False
```

### -VcEndpoint
Token Endpoint URL as shown on the service account details page.

```yaml
Type: String
Parameter Sets: VcToken
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -VaultVcKeyName
Name of the SecretManagement vault entry for the TLSPC key.
First time use requires it to be provided with -VcKey to populate the vault.
With subsequent uses, it can be provided standalone and the key will be retrieved without the need for -VcKey.
The server associated with the region will be saved and restored when this parameter is used on subsequent use.

```yaml
Type: String
Parameter Sets: Vc
Aliases: VaultVaasKeyName

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: VaultVcKey
Aliases: VaultVaasKeyName

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RefreshSession
Obtain a new access token from the refresh token.
Requires an existing module scoped $VenafiSession.

```yaml
Type: SwitchParameter
Parameter Sets: RefreshSession
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -TimeoutSec
Specifies how long the request can be pending before it times out.
Enter a value in seconds.
The default value, 0, specifies an indefinite time-out.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
Optionally, send the session object to the pipeline instead of script scope.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -SkipCertificateCheck
Bypass certificate validation when connecting to the server.
This can be helpful for pre-prod environments where ssl isn't setup on the website or you are connecting via IP.
You can also create an environment variable named VENAFIPS_SKIP_CERT_CHECK and set it to 1 for the same effect.

```yaml
Type: SwitchParameter
Parameter Sets: VaultRefreshToken, VaultAccessToken, RefreshToken, AccessToken, TokenJwt, TokenCertificate, TokenIntegrated, TokenOAuth
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### VenafiSession, if -PassThru is provided
## NOTES

## RELATED LINKS

[https://venafi.github.io/VenafiPS/functions/New-VenafiSession/](https://venafi.github.io/VenafiPS/functions/New-VenafiSession/)

[https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/New-VenafiSession.ps1](https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/New-VenafiSession.ps1)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/API_Reference/r-SDK-POST-Authorize.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/API_Reference/r-SDK-POST-Authorize.php)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/API_Reference/r-SDK-GET-Authorize-Integrated.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/API_Reference/r-SDK-GET-Authorize-Integrated.php)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/AuthSDK/r-SDKa-POST-Authorize-Integrated.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/AuthSDK/r-SDKa-POST-Authorize-Integrated.php)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/AuthSDK/r-SDKa-POST-AuthorizeOAuth.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/AuthSDK/r-SDKa-POST-AuthorizeOAuth.php)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/AuthSDK/r-SDKa-POST-AuthorizeCertificate.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/AuthSDK/r-SDKa-POST-AuthorizeCertificate.php)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/AuthSDK/r-SDKa-POST-AuthorizeJwt.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/AuthSDK/r-SDKa-POST-AuthorizeJwt.php)

[https://github.com/PowerShell/SecretManagement](https://github.com/PowerShell/SecretManagement)

[https://github.com/PowerShell/SecretStore](https://github.com/PowerShell/SecretStore)

