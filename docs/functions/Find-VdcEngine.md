# Find-VdcEngine

## SYNOPSIS
Find TLSPDC engines using an optional pattern

## SYNTAX

```
Find-VdcEngine [-Pattern] <String> [[-VenafiSession] <PSObject>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Find TLSPDC engines using an optional pattern.
This function is an engine wrapper for Find-VdcObject.

## EXAMPLES

### EXAMPLE 1
```
Find-VdcEngine -Pattern '*partialname*'
```

Get engines whose name matches the supplied pattern

## PARAMETERS

### -Pattern
Filter against engine names using asterisk (*) and/or question mark (?) wildcard characters.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -VenafiSession
Authentication for the function.
The value defaults to the script session object $VenafiSession created by New-VenafiSession.
A TLSPDC token can also be provided, but this requires an environment variable VDC_SERVER to be set.

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

### Pattern
## OUTPUTS

### TppObject
## NOTES

## RELATED LINKS

[https://venafi.github.io/VenafiPS/functions/Find-VdcEngine/](https://venafi.github.io/VenafiPS/functions/Find-VdcEngine/)

[https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Find-VdcEngine.ps1](https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Find-VdcEngine.ps1)

