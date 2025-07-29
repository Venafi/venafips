# New-VdcObject

## SYNOPSIS
Create a new object

## SYNTAX

### NonDup (Default)
```
New-VdcObject -Path <String> -Class <String> [-Attribute <Hashtable>] [-PushCertificate] [-Force] [-PassThru]
 [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Dup
```
New-VdcObject -Path <String> [-SourcePath <String>] [-PushCertificate] [-Force] [-PassThru]
 [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Generic use function to create a new object if a specific function hasn't been created yet for the class.
This can also be used to duplicate an existing object.

## EXAMPLES

### EXAMPLE 1
```
New-VdcObject -Path '\VED\Policy\Test Device' -Class 'Device' -Attribute @{'Description'='new device testing'}
```

Create a new object

### EXAMPLE 2
```
New-VdcObject -Path 'missing\folder\again' -Class 'Policy' -Force
```

Create a new object as well as any missing policy folders in the path

### EXAMPLE 3
```
New-VdcObject -Path '\VED\Policy\Test Device' -Class 'Device' -Attribute @{'Description'='new device testing'} -PassThru
```

Create a new object and return the resultant object

### EXAMPLE 4
```
New-VdcObject -Path '\VED\Policy\Test Device\App' -Class 'Basic' -Attribute @{'Driver Name'='appbasic';'Certificate'='\Ved\Policy\mycert.com'}
```

Create a new Basic application and associate it to a device and certificate

### EXAMPLE 5
```
New-VdcObject -Path 'certificates\duplicate.company.com' -SourcePath 'certificates\original.company.com'
```

Create a duplicate object with all attributes from the original being copied over

## PARAMETERS

### -Path
Full path, including name, for the object to be created.
If the root path is excluded, \ved\policy will be prepended.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Class
Class name of the new object.
See https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/SchemaReference/r-SDK-CNattributesWhere.php for more info.

```yaml
Type: String
Parameter Sets: NonDup
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Attribute
Hashtable with initial values for the new object.
These will be specific to the object class being created.

```yaml
Type: Hashtable
Parameter Sets: NonDup
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SourcePath
Provide this path when you want to duplicate an existing object.
This will be the path of the source object and Path will be the destination.
All attributes which have been set on this object will be copied to the new one.
Retrieving all existing attributes will take some time.

Not recommended for duplicating certificates.

```yaml
Type: String
Parameter Sets: Dup
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PushCertificate
If creating an application object, you can optionally push the certificate once the creation is complete.
Only available if a 'Certificate' key containing the certificate path is provided for Attribute.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: ProvisionCertificate

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Force the creation of missing parent policy folders when the class is either Policy or Device.

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
Return a TppObject representing the newly created object.

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

### none
## OUTPUTS

### TppObject, if PassThru provided
## NOTES

## RELATED LINKS

[https://venafi.github.io/VenafiPS/functions/New-VdcObject/](https://venafi.github.io/VenafiPS/functions/New-VdcObject/)

[https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/New-VdcObject.ps1](https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/New-VdcObject.ps1)

[https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Add-VdcCertificateAssociation.ps1](https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Add-VdcCertificateAssociation.ps1)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Config-create.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Config-create.php)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/SchemaReference/r-SDK-CNattributesWhere.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/SchemaReference/r-SDK-CNattributesWhere.php)

