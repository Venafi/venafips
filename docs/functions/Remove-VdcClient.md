# Remove-VdcClient

## SYNOPSIS
Remove registered client agents

## SYNTAX

```
Remove-VdcClient [-ClientID] <String[]> [-RemoveAssociatedDevice] [[-VenafiSession] <PSObject>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Remove registered client agents.
Provide an array of client IDs to remove a large list at once.

## EXAMPLES

### EXAMPLE 1
```
Remove-VdcClient -ClientId 1234, 5678
Remove clients
```

### EXAMPLE 2
```
Remove-VdcClient -ClientId 1234, 5678 -RemoveAssociatedDevice
Remove clients and associated devices
```

## PARAMETERS

### -ClientID
Unique id for one or more clients

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -RemoveAssociatedDevice
For a registered Agent, delete the associated Device objects, and only certificates that belong to the associated device.
Delete any related Discovery information.
Preserve unrelated device, certificate, and Discovery information in other locations of the Policy tree and Secret Store.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: RemoveAssociatedDevices

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -VenafiSession
Authentication for the function.
The value defaults to the script session object $VenafiSession created by New-VenafiSession.
A TLSPDC token can also be provided.
If providing a TLSPDC token, an environment variable named VDC_SERVER must also be set.

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
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

### ClientId
## OUTPUTS

### None
## NOTES

## RELATED LINKS

[https://venafi.github.io/VenafiPS/functions/Remove-VdcClient/](https://venafi.github.io/VenafiPS/functions/Remove-VdcClient/)

[https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Remove-VdcClient.ps1](https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Remove-VdcClient.ps1)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-ClientDelete.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-ClientDelete.php)

