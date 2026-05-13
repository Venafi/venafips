# Convert-CmObject

## SYNOPSIS
Change the class/object type of an existing object

## SYNTAX

```
Convert-CmObject [-Path] <String> [-Class] <String> [-PassThru] [[-TrustClient] <TrustClient>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Change the class/object type of an existing object.
Please note, changing the class does NOT change any attributes and must be done separately.
Using -PassThru will allow you to pass the input to other functions including Set-CmAttribute; see the examples.

## EXAMPLES

### EXAMPLE 1
```
Convert-CmObject -Path '\ved\policy\' -Class 'X509 Device Certificate'
```

Convert an object to a different type

### EXAMPLE 2
```
Convert-CmObject -Path '\ved\policy\device\app' -Class 'CAPI' -PassThru | Set-CmAttribute -Attribute @{'Driver Name'='appcapi'}
```

Convert an object to a different type, return the updated object and update attributes

### EXAMPLE 3
```
Find-CmObject -Class Basic | Convert-CmObject -Class 'capi' -PassThru | Set-CmAttribute -Attribute @{'Driver Name'='appcapi'}
```

Convert multiple objects to a different type, return the updated objects and update attributes

## PARAMETERS

### -Path
Path to the object

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Class
New class/type

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

### -PassThru
Return a CmObject representing the newly converted object

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

### -TrustClient
Authentication for the function.
The value defaults to the script session object $TrustClient created by New-TrustClient.

```yaml
Type: TrustClient
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
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

### Path
## OUTPUTS

### pscustomobject, if -PassThru provided
## NOTES

## RELATED LINKS

[https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Convert-CmObject.ps1](https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Convert-CmObject.ps1)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Config-mutateobject.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Config-mutateobject.php)

