# Revoke-VdcToken

## SYNOPSIS
Revoke a token

## SYNTAX

### Session (Default)
```
Revoke-VdcToken [-Force] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### AccessToken
```
Revoke-VdcToken -AuthServer <String> -AccessToken <PSObject> [-Force] [-ProgressAction <ActionPreference>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

### VenafiPsToken
```
Revoke-VdcToken -VenafiPsToken <PSObject> [-Force] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Revoke a token and invalidate the refresh token if provided/available.
This could be an access token retrieved from this module or from other means.

## EXAMPLES

### EXAMPLE 1
```
Revoke-VdcToken
Revoke token stored in session variable $VenafiSession from New-VenafiSession
```

### EXAMPLE 2
```
Revoke-VdcToken -Force
Revoke token bypassing confirmation prompt
```

### EXAMPLE 3
```
Revoke-VdcToken -AuthServer venafi.company.com -AccessToken $cred
Revoke a token obtained from TLSPDC, not necessarily via VenafiPS
```

## PARAMETERS

### -AuthServer
Server name or URL for the vedauth service

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
Provide an existing access token to revoke.
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

### -VenafiPsToken
Token object obtained from New-VdcToken

```yaml
Type: PSObject
Parameter Sets: VenafiPsToken
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Force
Bypass the confirmation prompt

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
Authentication for the function.
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

### VenafiPsToken
## OUTPUTS

### none
## NOTES

## RELATED LINKS

[https://venafi.github.io/VenafiPS/functions/Revoke-VdcToken/](https://venafi.github.io/VenafiPS/functions/Revoke-VdcToken/)

[https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Revoke-VdcToken.ps1](https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Revoke-VdcToken.ps1)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/AuthSDK/r-SDKa-GET-Revoke-Token.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/AuthSDK/r-SDKa-GET-Revoke-Token.php)

