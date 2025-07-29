# Test-VdcToken

## SYNOPSIS
Test if a TLSPDC token is valid

## SYNTAX

### Session (Default)
```
Test-VdcToken [-GrantDetail] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### VaultAccessToken
```
Test-VdcToken [-AuthServer <String>] -VaultAccessTokenName <String> [-GrantDetail]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### AccessToken
```
Test-VdcToken -AuthServer <String> -AccessToken <PSObject> [-GrantDetail] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### VenafiPsToken
```
Test-VdcToken -VenafiPsToken <PSObject> [-GrantDetail] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Use the TLSPDC API call 'Authorize/Verify' to test if the current token is valid.

## EXAMPLES

### EXAMPLE 1
```
Test-VdcToken
Verify that accesstoken stored in $VenafiSession object is valid.
```

### EXAMPLE 2
```
$VenafiPsToken | Test-VdcToken
Verify that token object from pipeline is valid. Can be used to validate directly object from New-VdcToken.
```

### EXAMPLE 3
```
Test-VdcToken -AuthServer venafi.mycompany.com -AccessToken $cred
Verify that PsCredential object containing accesstoken is valid.
```

### EXAMPLE 4
```
Test-VdcToken -VaultAccessTokenName access-token
Verify access token stored in VenafiPS vault, metadata stored with secret
```

### EXAMPLE 5
```
Test-VdcToken -VaultAccessTokenName access-token -AuthServer venafi.mycompany.com
Verify access token stored in VenafiPS vault providing server to authenticate against
```

### EXAMPLE 6
```
Test-VdcToken -GrantDetail
Verify that accesstoken stored in $VenafiSession object is valid and return PsCustomObject as output with details.
```

## PARAMETERS

### -AuthServer
Auth server or url, venafi.company.com or https://venafi.company.com.
This will be used to access vedauth for token-based authentication.
If just the server name is provided, https:// will be appended.

```yaml
Type: String
Parameter Sets: VaultAccessToken
Aliases: Server

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: AccessToken
Aliases: Server

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AccessToken
Access token retrieved outside this module.
You can either provide a String, SecureString, or PSCredential.
If providing a credential, the username is not used.

```yaml
Type: PSObject
Parameter Sets: AccessToken
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -VenafiPsToken
Token object obtained from New-VdcToken

```yaml
Type: PSObject
Parameter Sets: VenafiPsToken
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -VaultAccessTokenName
Name of the SecretManagement vault entry for the access token; the name of the vault must be VenafiPS.

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

### -GrantDetail
Provides detailed info about the token object from the TLSPDC server response as an output. 
Supported on TLSPDC 20.4 and later.

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
VenafiSession object to validate.
The value defaults to the script session object $VenafiSession created by New-VenafiSession.

```yaml
Type: PSObject
Parameter Sets: Session
Aliases:

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

### AccessToken
## OUTPUTS

### Boolean (default)
### PSCustomObject (GrantDetail)
###     ClientId
###     AccessIssued
###     GrantIssued
###     Scope
###     Identity
###     RefreshExpires
## NOTES

## RELATED LINKS

[https://venafi.github.io/VenafiPS/functions/Test-VdcToken/](https://venafi.github.io/VenafiPS/functions/Test-VdcToken/)

[https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Test-VdcToken.ps1](https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Test-VdcToken.ps1)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/AuthSDK/r-SDKa-GET-Authorize-Verify.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/AuthSDK/r-SDKa-GET-Authorize-Verify.php)

