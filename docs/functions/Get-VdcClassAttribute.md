# Get-VdcClassAttribute

## SYNOPSIS
List all attributes for a specified class

## SYNTAX

```
Get-VdcClassAttribute [-ClassName] <String> [[-VenafiSession] <PSObject>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
List all attributes for a specified class, helpful for validation or to pass to Get-VdcAttribute

## EXAMPLES

### EXAMPLE 1
```
Get-VdcClassAttribute -ClassName 'X509 Server Certificate'
```

Get all attributes for the specified class

## PARAMETERS

### -ClassName
Class name to retrieve attributes for

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

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: (Get-VenafiSession)
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

### ClassName
## OUTPUTS

### PSCustomObject
## NOTES

## RELATED LINKS
