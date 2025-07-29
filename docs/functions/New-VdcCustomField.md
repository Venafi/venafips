# New-VdcCustomField

## SYNOPSIS
Create new custom field in Venafi of the specified class and type.

## SYNTAX

```
New-VdcCustomField [-Name] <String> [-Label] <String> [-Class] <String[]> [-Type] <String>
 [[-AllowedValue] <String[]>] [-Single] [[-Help] <String>] [[-ErrorMessage] <String>] [-Mandatory]
 [-Policyable] [[-RegEx] <String>] [-RenderHidden] [-RenderReadOnly] [-DateOnly] [-TimeOnly] [-PassThru]
 [[-VenafiSession] <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Creates a new custom field in Venafi.
Required parameters are name, label, class and type.
See Venafi docs for information about other metadata items.

## EXAMPLES

### EXAMPLE 1
```
New-VdcCustomField -Name "Last Date" -Label "Last Date" -Class "X509 Certificate" -Type "String" -RenderReadOnly -Help "Last Date of certificate import"
Create new custom field for certificates
```

## PARAMETERS

### -Name
Name of new custom field

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

### -Label
Label of new custom field

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

### -Class
Class of new custom field, either 'Device' or 'X509 Certificate'

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Type
Type of new custom field, one of 'String', 'List', 'DateTime', 'Identity'

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AllowedValue
An array of allowable values for the Custom Field.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Single
Controls the number of input selections.
If not used the user can select
multiple values for the Custom Field.
Otherwise the user can select only
one value

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Help
The tool tip to show to the user how to populate the Custom Field.

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

### -ErrorMessage
The error message that you define for this Custom Field.

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

### -Mandatory
Determines if a value is required in the custom field.
If not used a value is
optional, otherwise the user must enter a value.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Policyable
Determines if the custom field can be used in a policy setting to apply to
all objects in the policy.
If not used the custom field cannot apply to a policy.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -RegEx
The regular expression to control user input.

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

### -RenderHidden
Controls the visibility of the custom field in the UI.
By default custom fields
are visible in the class they are created for.
This switch hides them.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -RenderReadOnly
Controls if the custom field is read only.
By default a user can change the custom
field value.
This switch makes it the custom field value cannot be changed.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -DateOnly
Controls if the custom field requires a calendar date.
By default a date is not required.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -TimeOnly
Controls if the custom field requires a time of day.
By default a time is not required.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
Return a PSCustomObject with the following properties:
    AllowedValues
    Class
    DateOnly
    DN
    ErrorMessage
    Guid
    Help
    Label
    Mandatory
    Name
    Policyable
    RegularExpression
    RenderHidden
    RenderReadOnly
    Single
    TimeOnly
    Type

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
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
Position: 9
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

### None
## OUTPUTS

### PSCustomObject, if PassThru provided
## NOTES

## RELATED LINKS

[https://venafi.github.io/VenafiPS/functions/New-VdcCustomField/](https://venafi.github.io/VenafiPS/functions/New-VdcCustomField/)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Metadata-DefineItem.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Metadata-DefineItem.php)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Metadata-Item.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Metadata-Item.php)

