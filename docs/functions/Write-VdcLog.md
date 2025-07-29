# Write-VdcLog

## SYNOPSIS
Write entries to the TLSPDC log

## SYNTAX

```
Write-VdcLog [-CustomEventGroup] <String> [-EventId] <String> [-Component] <String>
 [[-Severity] <TppEventSeverity>] [[-SourceIp] <IPAddress>] [[-ComponentID] <Int32>]
 [[-ComponentSubsystem] <String>] [[-Text1] <String>] [[-Text2] <String>] [[-Value1] <Int32>]
 [[-Value2] <Int32>] [[-VenafiSession] <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Write entries to the log for custom event groups.
It is not permitted to write to the default log.
Ensure the group and event id are correct as the api will not fail if incorrect.

## EXAMPLES

### EXAMPLE 1
```
Write-VdcLog -CustomEventGroup '0200' -EventId '0001' -Component '\ved\policy\mycert.com'
Log an event to a custom group
```

## PARAMETERS

### -CustomEventGroup
ID containing hex values between 0100-0299 referring to the created custom group.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -EventId
Event ID from within the EventGroup provided, a 4 character hex value.
Only provide the 4 character event id, do not precede with group ID.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Component
Path to the item this event is associated with

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Severity
Severity of the event

```yaml
Type: TppEventSeverity
Parameter Sets: (All)
Aliases:
Accepted values: Emergency, Alert, Critical, Error, Warning, Notice, Info, Debug

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SourceIp
The IP that originated the event

```yaml
Type: IPAddress
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ComponentID
Component ID that originated the event

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -ComponentSubsystem
Component subsystem that originated the event

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Text1
String data to write to log. 
See link for event ID messages for more info.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Text2
String data to write to log. 
See link for event ID messages for more info.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 9
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Value1
Integer data to write to log. 
See link for event ID messages for more info.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 10
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Value2
Integer data to write to log. 
See link for event ID messages for more info.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 11
Default value: 0
Accept pipeline input: False
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
Position: 12
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

### none
## OUTPUTS

### none
## NOTES

## RELATED LINKS

[https://venafi.github.io/VenafiPS/functions/Write-VdcLog/](https://venafi.github.io/VenafiPS/functions/Write-VdcLog/)

[https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Write-VdcLog.ps1](https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Write-VdcLog.ps1)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Log.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Log.php)

