# Revoke-VdcGrant

## SYNOPSIS
Revoke all grants for a specific user

## SYNTAX

```
Revoke-VdcGrant [[-ID] <String[]>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Revoke all grants for a specific user.
You must either be an administrator or oauth administrator to perform this action.
Also, your token must have the admin:delete scope.
Available in TLSPDC v22.3 and later.

## EXAMPLES

### EXAMPLE 1
```
Revoke-VdcGrant -ID local:{9e9db8d6-234a-409c-8299-e3b81ce2f916}
```

Revoke all grants for a user

### EXAMPLE 2
```
Get-VdcIdentity -ID me@x.com | Revoke-VdcGrant
```

Revoke all grants getting universal id from other identity functions

## PARAMETERS

### -ID
Prefixed universal id for the user. 
To search, use Find-VdcIdentity.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: PrefixedUniversalID, IdentityID

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
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

### ID
## OUTPUTS

### None
## NOTES

## RELATED LINKS

[https://venafi.github.io/VenafiPS/functions/Revoke-VdcGrant/](https://venafi.github.io/VenafiPS/functions/Revoke-VdcGrant/)

[https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Revoke-VdcGrant.ps1](https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Revoke-VdcGrant.ps1)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-oauth-revokegrants.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-oauth-revokegrants.php)

