# Remove-VdcPermission

## SYNOPSIS
Remove permissions from TLSPDC objects

## SYNTAX

### ByGuid (Default)
```
Remove-VdcPermission -Guid <Guid[]> [-IdentityId <String[]>] [-VenafiSession <PSObject>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### ByPath
```
Remove-VdcPermission -Path <String[]> [-IdentityId <String[]>] [-VenafiSession <PSObject>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Remove permissions from TLSPDC objects
You can opt to remove permissions for a specific user or all assigned

## EXAMPLES

### EXAMPLE 1
```
Find-VdcObject -Path '\VED\Policy\My folder' | Remove-VdcPermission
Remove all permissions from a specific object
```

### EXAMPLE 2
```
Find-VdcObject -Path '\VED' -Recursive | Remove-VdcPermission -IdentityId 'AD+blah:879s8d7f9a8ds7f9s8d7f9'
Remove all permissions for a specific user
```

## PARAMETERS

### -Path
Full path to an object. 
You can also pipe in a TppObject

```yaml
Type: String[]
Parameter Sets: ByPath
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Guid
Guid that represents an object

```yaml
Type: Guid[]
Parameter Sets: ByGuid
Aliases: ObjectGuid

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -IdentityId
Prefixed Universal Id of the user or group to have their permissions removed

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: PrefixedUniversalId

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -VenafiSession
Authentication for the function.
The value defaults to the script session object $VenafiSession created by New-VenafiSession.

```yaml
Type: PSObject
Parameter Sets: (All)
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

### Path, Guid, IdentityId
## OUTPUTS

### None
## NOTES

## RELATED LINKS

[https://venafi.github.io/VenafiPS/functions/Remove-VdcPermission/](https://venafi.github.io/VenafiPS/functions/Remove-VdcPermission/)

[https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Remove-VdcPermission.ps1](https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Remove-VdcPermission.ps1)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-DELETE-Permissions-object-guid-principal.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-DELETE-Permissions-object-guid-principal.php)

