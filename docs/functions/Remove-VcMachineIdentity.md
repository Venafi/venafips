# Remove-VcMachineIdentity

## SYNOPSIS
Remove a machine identity

## SYNTAX

```
Remove-VcMachineIdentity [-ID] <String> [[-ThrottleLimit] <Int32>] [[-VenafiSession] <PSObject>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Remove a machine identity from Certificate Manager, SaaS

## EXAMPLES

### EXAMPLE 1
```
Remove-VcMachineIdentity -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2'
Remove a machine identity
```

### EXAMPLE 2
```
Remove-VcMachineIdentity -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2' -Confirm:$false
Remove a machine identity bypassing the confirmation prompt
```

## PARAMETERS

### -ID
Machine Identity ID, this is the guid/uuid

```yaml
Type: String
Parameter Sets: (All)
Aliases: machineIdentityId

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -ThrottleLimit
Limit the number of threads when running in parallel; the default is 100.
Setting the value to 1 will disable multithreading.
On PS v5 the ThreadJob module is required. 
If not found, multithreading will be disabled.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 100
Accept pipeline input: False
Accept wildcard characters: False
```

### -VenafiSession
Authentication for the function.
The value defaults to the script session object $VenafiSession created by New-VenafiSession.
A Certificate Manager, SaaS key can also provided.

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: (Get-VenafiSession)
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

### ID
## OUTPUTS

## NOTES

## RELATED LINKS
