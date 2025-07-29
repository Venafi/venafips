# Add-VdcEngineFolder

## SYNOPSIS
Add policy folder assignments to a TLSPDC processing engine

## SYNTAX

```
Add-VdcEngineFolder [-EnginePath] <String> [-FolderPath] <String[]> [[-VenafiSession] <PSObject>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Add one or more policy folder assignments to a TLSPDC processing engine.

## EXAMPLES

### EXAMPLE 1
```
Add-VdcEngineFolder -EnginePath '\VED\Engines\MYVENAFI01' -FolderPath '\VED\Policy\Certificates\Web Team'
Add processing engine MYVENAFI01 to the policy folders '\VED\Policy\Certificates\Web Team'.
```

### EXAMPLE 2
```
Add-VdcEngineFolder -EnginePath '\VED\Engines\MYVENAFI01' -FolderPath @('\VED\Policy\Certificates\Web Team','\VED\Policy\Certificates\Database Team')
Add processing engine MYVENAFI01 to the policy folders '\VED\Policy\Certificates\Web Team' and '\VED\Policy\Certificates\Database Team'.
```

### EXAMPLE 3
```
$EngineObjects | Add-VdcEngineFolder -FolderPath @('\VED\Policy\Certificates\Web Team','\VED\Policy\Certificates\Database Team') -Confirm:$false
Add one or more processing engines via the pipeline to multiple policy folders. Suppress the confirmation prompt.
```

## PARAMETERS

### -EnginePath
The full DN path to a TLSPDC processing engine.

```yaml
Type: String
Parameter Sets: (All)
Aliases: EngineDN, Engine, Path

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -FolderPath
The full DN path to one or more policy folders (string array).

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: FolderDN, Folder

Required: True
Position: 2
Default value: None
Accept pipeline input: False
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

### EnginePath or EngineObject, FolderPath[]
## OUTPUTS

### None
## NOTES

## RELATED LINKS

[https://venafi.github.io/VenafiPS/functions/Add-VdcEngineFolder/](https://venafi.github.io/VenafiPS/functions/Add-VdcEngineFolder/)

[https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Add-VdcEngineFolder.ps1](https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Add-VdcEngineFolder.ps1)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-ProcessingEngines-Engine-eguid.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-ProcessingEngines-Engine-eguid.php)

