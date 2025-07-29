# Rename-VdcObject

## SYNOPSIS
Rename and/or move an object

## SYNTAX

```
Rename-VdcObject [-Path] <String> [-NewPath] <String> [[-VenafiSession] <PSObject>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Rename and/or move an object

## EXAMPLES

### EXAMPLE 1
```
Rename-VdcObject -Path '\VED\Policy\My Devices\OldDeviceName' -NewPath '\ved\policy\my devices\NewDeviceName'
Rename an object
```

### EXAMPLE 2
```
Rename-VdcObject -Path '\VED\Policy\My Devices\DeviceName' -NewPath '\ved\policy\new devices folder\DeviceName'
Move an object
```

## PARAMETERS

### -Path
Full path to an existing object

```yaml
Type: String
Parameter Sets: (All)
Aliases: SourceDN

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NewPath
New path, including name

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

## NOTES

## RELATED LINKS

[https://venafi.github.io/VenafiPS/functions/Rename-VdcObject/](https://venafi.github.io/VenafiPS/functions/Rename-VdcObject/)

[https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Rename-VdcObject.ps1](https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Rename-VdcObject.ps1)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Config-renameobject.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Config-renameobject.php)

