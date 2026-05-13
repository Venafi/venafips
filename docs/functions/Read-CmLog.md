# Read-CmLog

## SYNOPSIS
Read entries from the Certificate Manager, Self-Hosted log

## SYNTAX

```
Read-CmLog [[-Path] <String>] [[-EventId] <String>] [[-Severity] <CmEventSeverity>] [[-StartTime] <DateTime>]
 [[-EndTime] <DateTime>] [[-Text1] <String>] [[-Text2] <String>] [[-Value1] <Int32>] [[-Value2] <Int32>]
 [[-First] <Int32>] [[-TrustClient] <TrustClient>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Read entries from the Certificate Manager, Self-Hosted log.

## EXAMPLES

### EXAMPLE 1
```
Read-CmLog -First 10
```

Get the most recent 10 log items

### EXAMPLE 2
```
$capiObject | Read-CmLog
```

Find all events for a specific object

### EXAMPLE 3
```
Read-CmLog -EventId '00130003'
```

Find all events with event ID '00130003', Certificate Monitor - Certificate Expiration Notice

## PARAMETERS

### -Path
Path to search for related records

```yaml
Type: String
Parameter Sets: (All)
Aliases: DN

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -EventId
Event ID as found in Logging-\>Event Definitions

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Severity
Filter records by severity

```yaml
Type: CmEventSeverity
Parameter Sets: (All)
Aliases:
Accepted values: Emergency, Alert, Critical, Error, Warning, Notice, Info, Debug

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -StartTime
Start time of events

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -EndTime
End time of events

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Text1
Filter matching results of Text1

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Text2
Filter matching results of Text2

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

### -Value1
Filter matching results of Value1

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Value2
Filter matching results of Value2

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 9
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -First
Return only these number of records

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

### -TrustClient
Authentication for the function.
The value defaults to the script session object $TrustClient created by New-TrustClient.

```yaml
Type: TrustClient
Parameter Sets: (All)
Aliases:

Required: False
Position: 11
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

### Path
## OUTPUTS

### PSCustomObject
###     EventId
###     ClientTimestamp
###     Component
###     ComponentId
###     ComponentSubsystem
###     Data
###     Grouping
###     Id
###     Name
###     ServerTimestamp
###     Severity
###     SourceIP
###     Text1
###     Text2
###     Value1
###     Value2
## NOTES

## RELATED LINKS

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-GET-Log.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-GET-Log.php)

