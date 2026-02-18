# New-VdcToken

## SYNOPSIS
Get a new access token or refresh an existing one

## SYNTAX

### Integrated (Default)
```
New-VdcToken -AuthServer <String> -ClientId <String> -Scope <Hashtable> [-State <String>]
 [-SkipCertificateCheck] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### RefreshToken
```
New-VdcToken -AuthServer <String> -ClientId <String> -RefreshToken <PSObject> [-SkipCertificateCheck]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Jwt
```
New-VdcToken -AuthServer <String> -ClientId <String> -Scope <Hashtable> -Jwt <String> [-SkipCertificateCheck]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Certificate
```
New-VdcToken -AuthServer <String> -ClientId <String> -Scope <Hashtable> -Certificate <X509Certificate>
 [-SkipCertificateCheck] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### OAuth
```
New-VdcToken -AuthServer <String> -ClientId <String> -Scope <Hashtable> -Credential <PSCredential>
 [-State <String>] [-SkipCertificateCheck] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### RefreshSession
```
New-VdcToken [-SkipCertificateCheck] -VenafiSession <PSObject> [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Get an access token and refresh token (if enabled) to be used with New-VenafiSession or other scripts/utilities that take such a token.
You can also refresh an existing access token if you have the associated refresh token.
Authentication can be provided as integrated, credential, or certificate.

## EXAMPLES

### EXAMPLE 1
```
New-VdcToken -AuthServer 'https://mytppserver.example.com' -Scope @{ Certificate = "manage,discover"; Configuration = "manage" } -ClientId 'MyAppId' -Credential $credential
Get a new token with OAuth
```

### EXAMPLE 2
```
New-VdcToken -AuthServer 'mytppserver.example.com' -Scope @{ Certificate = "manage,discover"; Configuration = "manage" } -ClientId 'MyAppId'
Get a new token with Integrated authentication
```

### EXAMPLE 3
```
New-VdcToken -AuthServer 'mytppserver.example.com' -Scope @{ Certificate = "manage,discover"; Configuration = "manage" } -ClientId 'MyAppId' -Certificate $cert
Get a new token with certificate authentication
```

### EXAMPLE 4
```
New-VdcToken -AuthServer 'mytppserver.example.com' -ClientId 'MyApp' -RefreshToken $refreshCred
Refresh an existing access token by providing the refresh token directly
```

### EXAMPLE 5
```
New-VdcToken -VenafiSession $mySession
Refresh an existing access token by providing a VenafiSession object
```

## PARAMETERS

### -AuthServer
Auth server or url, eg.
venafi.company.com

```yaml
Type: String
Parameter Sets: Integrated, RefreshToken, Jwt, Certificate, OAuth
Aliases: Server

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
Parameter Sets: Integrated, RefreshToken, Jwt, Certificate, OAuth
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Scope
Hashtable with Scopes and privilege restrictions.
The key is the scope and the value is one or more privilege restrictions separated by commas.
A privilege restriction of none or read, use a value of $null.
Scopes include Agent, Certificate, Code Signing, Configuration, Restricted, Security, SSH, and statistics.
See https://docs.venafi.com/Docs/current/TopNav/Content/SDK/AuthSDK/r-SDKa-OAuthScopePrivilegeMapping.php
Using a scope of {'all'='core'} will set all scopes except for admin.
Using a scope of {'all'='admin'} will set all scopes including admin.
Usage of the 'all' scope is not suggested for production.

```yaml
Type: Hashtable
Parameter Sets: Integrated, Jwt, Certificate, OAuth
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential
Username / password credential used to request API Token

```yaml
Type: PSCredential
Parameter Sets: OAuth
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
Parameter Sets: Integrated, OAuth
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Jwt
JSON web token.
Available in Certificate Manager, Self-Hosted v22.4 and later.
Ensure jwt mapping has been configured in VCC, Access Management-\>JWT Mappings.

```yaml
Type: String
Parameter Sets: Jwt
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Certificate
Certificate used to request API token. 
Certificate authentication must be configured for remote web sdk clients, https://docs.venafi.com/Docs/current/TopNav/Content/CA/t-CA-ConfiguringInTPPandIIS-tpp.php.

```yaml
Type: X509Certificate
Parameter Sets: Certificate
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RefreshToken
Provide -RefreshToken along with -ClientId to obtain a new access and refresh token.
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

### -SkipCertificateCheck
Bypass certificate validation when connecting to the server.
This can be helpful for pre-prod environments where ssl isn't setup on the website or you are connecting via IP.

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

### -VenafiSession
VenafiSession object created from New-VenafiSession method.

```yaml
Type: PSObject
Parameter Sets: RefreshSession
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
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

### None
## OUTPUTS

### PSCustomObject with the following properties:
###     Server
###     AccessToken
###     RefreshToken
###     Scope
###     Identity
###     TokenType
###     ClientId
###     Expires
###     RefreshExpires (This property is null when Certificate Manager, Self-Hosted version is less than 21.1)
## NOTES

## RELATED LINKS
