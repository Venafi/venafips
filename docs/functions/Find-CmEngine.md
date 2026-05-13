# Find-CmEngine

## SYNOPSIS
Find Certificate Manager, Self-Hosted engines using an optional pattern

## SYNTAX

```
Find-CmEngine [-Pattern] <String> [[-TrustClient] <TrustClient>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Find Certificate Manager, Self-Hosted engines using an optional pattern.
This function is an engine wrapper for Find-CmObject.

## EXAMPLES

### EXAMPLE 1
```
Find-CmEngine -Pattern '*partialname*'
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

### -TrustClient
Authentication for the function.
The value defaults to the script session object $TrustClient created by New-TrustClient.

```yaml
Type: TrustClient
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

### CmObject
## NOTES

## RELATED LINKS

[https://venafi.github.io/VenafiPS/functions/Find-CmEngine/](https://venafi.github.io/VenafiPS/functions/Find-CmEngine/)

[https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Find-CmEngine.ps1](https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Find-CmEngine.ps1)

