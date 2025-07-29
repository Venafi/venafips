# New-VdcPolicy

## SYNOPSIS
Add a new policy folder

## SYNTAX

### NameWithPolicyAttribute
```
New-VdcPolicy -Path <String> -Name <String[]> -Attribute <Hashtable> -Class <String> [-Lock] [-Force]
 [-PassThru] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### PathWithPolicyAttribute
```
New-VdcPolicy -Path <String> -Attribute <Hashtable> -Class <String> [-Lock] [-Force] [-PassThru]
 [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Name
```
New-VdcPolicy -Path <String> -Name <String[]> [-Description <String>] [-Attribute <Hashtable>] [-Force]
 [-PassThru] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### Path
```
New-VdcPolicy -Path <String> [-Description <String>] [-Attribute <Hashtable>] [-Force] [-PassThru]
 [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Add a new policy folder(s). 
Add object attributes or policy attributes at the same time.

## EXAMPLES

### EXAMPLE 1
```
$newPolicy = New-VdcPolicy -Path 'new'
```

Create a new policy folder

### EXAMPLE 2
```
$newPolicy = New-VdcPolicy -Path 'existing' -Name 'new1', 'new2', 'new3'
```

Create multiple policy folders

### EXAMPLE 3
```
$newPolicy = New-VdcPolicy -Path 'new1\new2\new3' -Force
```

Create a new policy folder named new3 and create new1 and new2 if they do not exist

### EXAMPLE 4
```
$newPolicy = New-VdcPolicy -Path 'new' -Attribute {'Description'='my new policy folder'}
```

Create a new policy folder setting attributes on the object at creation time

### EXAMPLE 5
```
$newPolicy = New-VdcPolicy -Path 'new' -Class 'X509 Certificate' -Attribute {'State'='UT'}
```

Create a new policy folder setting policy attributes (not object attributes)

### EXAMPLE 6
```
$newPolicy = New-VdcPolicy -Path 'new' -Class 'X509 Certificate' -Attribute {'State'='UT'} -Lock
```

Create a new policy folder setting policy attributes (not object attributes) and locking them

### EXAMPLE 7
```
$newPolicy = New-VdcPolicy -Path 'new' -PassThru
```

Create a new policy folder returning the policy object created

## PARAMETERS

### -Path
Full path to the new policy folder.
If the root path is excluded, \ved\policy will be prepended.
If used with -Name, this will be the root path and subfolders will be created.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Name
One of more policy folders to create under -Path.

```yaml
Type: String[]
Parameter Sets: NameWithPolicyAttribute, Name
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Description
Deprecated. 
Use -Attribute @{''Description''=''my description''} instead.

```yaml
Type: String
Parameter Sets: Name, Path
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Attribute
Hashtable with names and values to be set on the policy itself.
If used with -Class, this will set policy attributes.
If setting a custom field, you can use either the name or guid as the key.
To clear a value overwriting policy, set the value to $null.

```yaml
Type: Hashtable
Parameter Sets: NameWithPolicyAttribute, PathWithPolicyAttribute
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: Hashtable
Parameter Sets: Name, Path
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Class
Use with -Attribute to set policy attributes at policy creation time.
If unsure of the class name, add the value through the TLSPDC UI and go to Support-\>Policy Attributes to find it.

```yaml
Type: String
Parameter Sets: NameWithPolicyAttribute, PathWithPolicyAttribute
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Lock
Use with -PolicyAttribute and -Class to lock the policy attribute

```yaml
Type: SwitchParameter
Parameter Sets: NameWithPolicyAttribute, PathWithPolicyAttribute
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Force the creation of missing parent policy folders

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
Return a TppObject representing the newly created policy.

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
Position: Named
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

### TppObject, if PassThru provided
## NOTES

## RELATED LINKS

[https://venafi.github.io/VenafiPS/functions/New-VdcPolicy/](https://venafi.github.io/VenafiPS/functions/New-VdcPolicy/)

[https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/New-VdcPolicy.ps1](https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/New-VdcPolicy.ps1)

[https://venafi.github.io/VenafiPS/functions/New-VdcObject/](https://venafi.github.io/VenafiPS/functions/New-VdcObject/)

[https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/New-VdcObject.ps1](https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/New-VdcObject.ps1)

