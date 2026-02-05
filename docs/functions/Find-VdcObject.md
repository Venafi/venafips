# Find-VdcObject

## SYNOPSIS
Find objects by path, class, or pattern

## SYNTAX

### FindByPath (Default)
```
Find-VdcObject [-Path <String>] [-Recursive] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### FindByPattern
```
Find-VdcObject [-Path <String>] -Pattern <String> [-Recursive] [-VenafiSession <PSObject>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### FindByClass
```
Find-VdcObject [-Path <String>] [-Pattern <String>] -Class <String[]> [-Recursive] [-VenafiSession <PSObject>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### FindByAttribute
```
Find-VdcObject -Pattern <String> [-Class <String[]>] -Attribute <String[]> [-NoLookup]
 [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Find objects by path, class, or pattern.

## EXAMPLES

### EXAMPLE 1
```
Find-VdcObject
Get all objects recursively starting from \ved\policy
```

### EXAMPLE 2
```
Find-VdcObject -Path '\VED\Policy\certificates'
```

Get all objects in the root of a specific folder

### EXAMPLE 3
```
Find-VdcObject -Path '\VED\Policy\My Folder' -Recursive
```

Get all objects in a folder and subfolders

### EXAMPLE 4
```
Find-VdcObject -Path '\VED\Policy' -Pattern '*test*'
```

Get items in a specific folder filtering the path

### EXAMPLE 5
```
Find-VdcObject -Class 'capi' -Path '\ved\policy\installations' -Recursive
```

Get objects of a specific type

### EXAMPLE 6
```
Find-VdcObject -Class 'capi' -Pattern '*test*' -Path '\ved\policy\installations' -Recursive
```

Get all objects of a specific type where the path is of a specific pattern

### EXAMPLE 7
```
Find-VdcObject -Class 'capi', 'iis6' -Pattern '*test*' -Path '\ved\policy\installations' -Recursive
```

Get objects for multiple types

### EXAMPLE 8
```
Find-VdcObject -Pattern '*f5*'
```

Find objects with the specific name. 
All objects under \ved\policy (the default) will be searched.

### EXAMPLE 9
```
Find-VdcObject -Attribute 'Description' -Pattern 'awesome'
```

Find objects where the specific attribute matches the pattern

### EXAMPLE 10
```
Find-VdcObject -Attribute 'Environment' -Pattern 'Development'
```

Find objects where a custom field value matches the pattern.
By default, the attribute will be checked against the current list of custom fields.

### EXAMPLE 11
```
Find-VdcObject -Attribute 'Description' -Pattern 'venafips' -Class 'X509 Server Certificate'
```

Find objects of a specific type where the specific attribute matches the pattern

### EXAMPLE 12
```
Find-VdcObject -Attribute 'Description' -Pattern 'duplicate' -NoLookup
```

Bypass custom field lookup and force Attribute to be treated as a built-in attribute.
Useful if there are conflicting custom field and built-in attribute names and you want to force the lookup against built-in.

## PARAMETERS

### -Path
The path to start our search. 
The default is \ved\policy.

```yaml
Type: String
Parameter Sets: FindByPath, FindByPattern, FindByClass
Aliases: DN

Required: False
Position: Named
Default value: \ved\policy
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Pattern
By default, object filter to apply to Path.
If the Attribute parameter is provided, this will filter against an object's attribute/custom field values instead of the path.

Follow the below rules:
- To list DNs that include an asterisk or question mark, prepend the character with two backslashes.
- To list DNs with a wildcard character, append a question mark (?).
For example, "test_?.mycompany.net" counts test_1.MyCompany.net and test_2.MyCompany.net but not test12.MyCompany.net.
- To list DNs with similar names, prepend an asterisk.
For example, *est.MyCompany.net, counts Test.MyCompany.net and West.MyCompany.net.
You can also use both literals and wildcards in a pattern.

```yaml
Type: String
Parameter Sets: FindByPattern, FindByAttribute
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: FindByClass
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Class
1 or more classes/types to search for

```yaml
Type: String[]
Parameter Sets: FindByClass
Aliases: TypeName

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String[]
Parameter Sets: FindByAttribute
Aliases: TypeName

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Attribute
A list of attribute names to limit the search against. 
Only valid when searching by pattern.
A custom field name can also be provided.

```yaml
Type: String[]
Parameter Sets: FindByAttribute
Aliases: AttributeName

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Recursive
Searches the subordinates of the object specified in Path.

```yaml
Type: SwitchParameter
Parameter Sets: FindByPath, FindByPattern, FindByClass
Aliases: r

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoLookup
Default functionality when finding by Attribute is to perform a lookup to see if they are custom fields or not.
If they are, pass along the guid instead of name required by the api for custom fields.
To override this behavior and use the attribute name as is, add -NoLookup.
Useful if on the off chance you have a custom field with the same name as a built-in attribute.

```yaml
Type: SwitchParameter
Parameter Sets: FindByAttribute
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
Position: Named
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

### Path
## OUTPUTS

### pscustomobject
## NOTES

## RELATED LINKS

[https://venafi.github.io/VenafiPS/functions/Find-VdcObject/](https://venafi.github.io/VenafiPS/functions/Find-VdcObject/)

[https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Find-VdcObject.ps1](https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Find-VdcObject.ps1)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Config-find.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Config-find.php)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Config-findobjectsofclass.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Config-findobjectsofclass.php)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Config-enumerate.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Config-enumerate.php)

