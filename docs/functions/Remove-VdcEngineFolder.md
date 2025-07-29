# Remove-VdcEngineFolder

## SYNOPSIS
Remove TLSPDC processing engine assignment(s) from policy folder(s)

## SYNTAX

### Matrix
```
Remove-VdcEngineFolder -FolderPath <String[]> -EnginePath <String[]> [-VenafiSession <PSObject>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### AllEngines
```
Remove-VdcEngineFolder -FolderPath <String[]> [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

### AllFolders
```
Remove-VdcEngineFolder -EnginePath <String[]> [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Remove TLSPDC processing engine assignment(s) from policy folder(s).

If you do not supply a list of TLSPDC processing engines, then all processing engines will be removed from the supplied list of policy folders.

If you do not supply a list of policy folders, then all policy folder assignments will be removed from the supplied list of processing engines.

Supplying both a list of policy folders and processing engines will result in the removal of the specified engines from the list of policy folders.

Errors due to a policy engine not being assigned to the listed policy folder are ignored.

## EXAMPLES

### EXAMPLE 1
```
Remove-VdcEngineFolder -FolderPath '\VED\Policy\Certificates\Web Team' -EnginePath @('\VED\Engines\MYVENAFI01','\VED\Engines\MYVENAFI02')
Remove policy folder '\VED\Policy\Certificates\Web Team' from the processing engines MYVENAFI01 and MYVENAFI02.
```

### EXAMPLE 2
```
Remove-VdcEngineFolder -FolderPath @('\VED\Policy\Certificates\Web Team','\VED\Policy\Certificates\Database Team')
Remove all processing engine assignments for the policy folders '\VED\Policy\Certificates\Web Team' and '\VED\Policy\Certificates\Database Team'.
```

### EXAMPLE 3
```
Remove-VdcEngineFolder -EnginePath @('\VED\Engines\MYVENAFI01','\VED\Engines\MYVENAFI02') -Confirm:$false
Removed all policy folder assignments from the processing engines MYVENAFI01 and MYVENAFI02. Suppress the confirmation prompt.
```

## PARAMETERS

### -FolderPath
The full DN path to one or more policy folders (string array).

```yaml
Type: String[]
Parameter Sets: Matrix, AllEngines
Aliases: FolderDN, Folder

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -EnginePath
The full DN path to one or more TLSPDC processing engines (string array).

```yaml
Type: String[]
Parameter Sets: Matrix, AllFolders
Aliases: EngineDN, Engine

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
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

### FolderPath[], EnginePath[]
## OUTPUTS

### None
## NOTES

## RELATED LINKS

[https://venafi.github.io/VenafiPS/functions/Remove-VdcEngineFolder/](https://venafi.github.io/VenafiPS/functions/Remove-VdcEngineFolder/)

[https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Remove-VdcEngineFolder.ps1](https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Remove-VdcEngineFolder.ps1)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-DELETE-ProcessingEngines-Folder-fguid.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-DELETE-ProcessingEngines-Folder-fguid.php)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-DELETE-ProcessingEngines-Folder-fguid-eguid.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-DELETE-ProcessingEngines-Folder-fguid-eguid.php)

