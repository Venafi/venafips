# Remove-VdcObject

## SYNOPSIS
Remove TLSPDC objects

## SYNTAX

```
Remove-VdcObject [-Path] <String> [-Recursive] [[-ThrottleLimit] <Int32>] [[-VenafiSession] <PSObject>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Remove a TLSPDC object and optionally perform a recursive removal.
This process can be very destructive as it will remove anything you send it!!!
Run this in parallel with PowerShell v7+ when you have a large number to process.

## EXAMPLES

### EXAMPLE 1
```
Remove-VdcObject -Path '\VED\Policy\My empty folder'
Remove an object
```

### EXAMPLE 2
```
Remove-VdcObject -Path '\VED\Policy\folder' -Recursive
Remove an object and all objects contained
```

### EXAMPLE 3
```
Find-VdcObject -Class 'capi' | Remove-VdcObject
Find 1 or more objects and remove them
```

### EXAMPLE 4
```
Remove-VdcObject -Path '\VED\Policy\folder' -Confirm:$false
Remove an object without prompting for confirmation.  Be careful!
```

## PARAMETERS

### -Path
Full path to an existing object

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Recursive
Remove recursively, eg.
everything within a policy folder

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

### -ThrottleLimit
Limit the number of threads when running in parallel; the default is 100.
Setting the value to 1 will disable multithreading.
On PS v5 the ThreadJob module is required. 
If not found, multithreading will be disabled.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 100
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

### None
## NOTES

## RELATED LINKS

[https://venafi.github.io/VenafiPS/functions/Remove-VdcObject/](https://venafi.github.io/VenafiPS/functions/Remove-VdcObject/)

[https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Remove-VdcObject.ps1](https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Remove-VdcObject.ps1)

[https://docs.venafi.com/Docs/currentSDK/TopNav/Content/SDK/WebSDK/r-SDK-POST-Config-delete.php](https://docs.venafi.com/Docs/currentSDK/TopNav/Content/SDK/WebSDK/r-SDK-POST-Config-delete.php)

