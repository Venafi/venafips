# Export-VcReport

## SYNOPSIS
Get custom report data

## SYNTAX

```
Export-VcReport [-Report] <String> [[-OutPath] <String>] [[-VenafiSession] <PSObject>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Get custom report data and either save to a file or get as a powershell object

## EXAMPLES

### EXAMPLE 1
```
$reportData = Export-VcReport -Report 'Custom expiration report'
```

Get report data for further processing

### EXAMPLE 2
```
Export-VcReport -Report 'Custom expiration report' -OutPath '~/reports'
```

Save report data to a csv file. 
The directory must already exist.
In this example, the file would be saved to '~/reports/Custom expiration report.csv'.

## PARAMETERS

### -Report
Report name as specified on Insights -\> Custom Reports

```yaml
Type: String
Parameter Sets: (All)
Aliases: reportId

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -OutPath
Optional path to write the output to.
This is just the directory; the file name will be the Report name, eg.
MyReport.csv.

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

### -VenafiSession
Authentication for the function.
The value defaults to the script session object $VenafiSession created by New-VenafiSession.
A TLSPC key can also provided.

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
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

### Report
## OUTPUTS

## NOTES

## RELATED LINKS
