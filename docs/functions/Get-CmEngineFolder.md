# Get-CmEngineFolder

## SYNOPSIS
Get Certificate Manager, Self-Hosted folder/engine assignments

## SYNTAX

### ID (Default)
```
Get-CmEngineFolder [-ID] <String> [-TrustClient <TrustClient>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### All
```
Get-CmEngineFolder [-All] [-TrustClient <TrustClient>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
When the input is a policy folder, retrieves an array of assigned Certificate Manager, Self-Hosted processing engines.
When the input is a Certificate Manager, Self-Hosted engine, retrieves an array of assigned policy folders.
If there are no matching assignments, nothing will be returned.

## EXAMPLES

### EXAMPLE 1
```
Get-CmEngineFolder -Path '\VED\Engines\MYVENSERVER'
```

Get an array of policy folders assigned to the Certificate Manager, Self-Hosted processing engine 'MYVENSERVER'.

### EXAMPLE 2
```
Get-CmEngineFolder -Path '\VED\Policy\Certificates\Web Team'
```

Get an array of Certificate Manager, Self-Hosted processing engines assigned to the policy folder '\VED\Policy\Certificates\Web Team'.

### EXAMPLE 3
```
[guid]'866e1d59-d5d2-482a-b9e6-7bb657e0f416' | Get-CmEngineFolder
```

When the GUID is assigned to a Certificate Manager, Self-Hosted processing engine, returns an array of assigned policy folders.
When the GUID is assigned to a policy folder, returns an array of assigned Certificate Manager, Self-Hosted processing engines.
Otherwise nothing will be returned.

## PARAMETERS

### -ID
The full DN path or Guid to a Certificate Manager, Self-Hosted processing engine or policy folder.

```yaml
Type: String
Parameter Sets: ID
Aliases: EngineGuid, Guid, EnginePath, Path

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -All
Get all engine/folder assignments

```yaml
Type: SwitchParameter
Parameter Sets: All
Aliases:

Required: True
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

### ID
## OUTPUTS

### PSCustomObject
## NOTES

## RELATED LINKS

[https://venafi.github.io/VenafiPS/functions/Get-CmEngineFolder/](https://venafi.github.io/VenafiPS/functions/Get-CmEngineFolder/)

[https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Get-CmEngineFolder.ps1](https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Get-CmEngineFolder.ps1)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-GET-ProcessingEngines-Engine-eguid.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-GET-ProcessingEngines-Engine-eguid.php)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-GET-ProcessingEngines-Folder-fguid.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-GET-ProcessingEngines-Folder-fguid.php)

