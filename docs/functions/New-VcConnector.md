# New-VcConnector

## SYNOPSIS
Create a new connector

## SYNTAX

### FullManifest (Default)
```
New-VcConnector -ManifestPath <String> [-PassThru] [-VenafiSession <PSObject>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### FromSimulator
```
New-VcConnector -ManifestPath <String> -DeploymentImage <String> [-Maintainer <String>] [-PassThru]
 [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Create a new machine, CA, TPP, or credential connector

## EXAMPLES

### EXAMPLE 1
```
New-VcConnector -ManifestPath '/tmp/manifest.json'
```

Create a new connector from a manifest which already contains deployment information

### EXAMPLE 2
```
New-VcConnector -ManifestPath '/tmp/manifest.json' -PassThru
```

Create a new connector and return the newly created connector object

### EXAMPLE 3
```
New-VcConnector -ManifestPath '/tmp/manifest.json' -DeploymentImage 'docker.io/venafi/connector:latest@sha256:1234567890abcdef'
```

Create a new connector from a manifest from the simulator

## PARAMETERS

### -ManifestPath
Path to an existing manifest.
Manifest can either be directly from the simulator or a full manifest with deployment element.
If the manifest is from the simulator, the DeploymentImage parameter is required.

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

### -DeploymentImage
Path to the already uploaded docker image.
This parameter is only to be used for a manifest directly from the simulator.

```yaml
Type: String
Parameter Sets: FromSimulator
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Maintainer
Optional value to specify the organization, individual, email, location, or website responsible for maintaining the connector
This parameter is only to be used for a manifest directly from the simulator.

```yaml
Type: String
Parameter Sets: FromSimulator
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
Return newly created connector object

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
A Certificate Manager, SaaS key can also provided.

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

## OUTPUTS

### PSCustomObject, if PassThru provided
## NOTES

## RELATED LINKS

[https://developer.venafi.com/tlsprotectcloud/reference/post-v1-plugins](https://developer.venafi.com/tlsprotectcloud/reference/post-v1-plugins)

