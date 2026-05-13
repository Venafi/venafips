# Get-TrustTag

## SYNOPSIS
Get tag names and values

## SYNTAX

### ID
```
Get-TrustTag [-Tag] <String> [-TrustClient <TrustClient>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### All
```
Get-TrustTag [-All] [-TrustClient <TrustClient>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Get 1 or all tags.
Tag values will be provided.

## EXAMPLES

### EXAMPLE 1
```
Get-TrustTag -Tag 'MyTag'
```

Get a single tag

### EXAMPLE 2
```
Get-TrustTag -Tag 'MyTag:MyValue'
```

Get a single tag only if it has the specified value

### EXAMPLE 3
```
Get-TrustTag -All
```

Get all tags

## PARAMETERS

### -Tag
Tag name or name:value pair to get.
If a value is provided, the tag must have that value to be returned.

```yaml
Type: String
Parameter Sets: ID
Aliases: Name

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -All
Get all tags

```yaml
Type: SwitchParameter
Parameter Sets: All
Aliases:

Required: True
Position: Named
Default value: False
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

### Name
## OUTPUTS

## NOTES

## RELATED LINKS
