# Set-TrustConnector

## SYNOPSIS
Update an existing connector

## SYNTAX

### Manifest (Default)
```
Set-TrustConnector -ManifestPath <String> [-ID <String>] [-TrustClient <TrustClient>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Disable
```
Set-TrustConnector -ID <String> [-Disable] [-TrustClient <TrustClient>] [-ProgressAction <ActionPreference>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Update a new machine, CA, CMSH, or credential connector.
You can either update the manifest or disable/reenable it.

## EXAMPLES

### EXAMPLE 1
```
Set-TrustConnector -ManifestPath '/tmp/manifest_v2.json'
```

Update an existing connector with the same name as in the manifest

### EXAMPLE 2
```
Set-TrustConnector -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2' -ManifestPath '/tmp/manifest_v2.json'
```

Update an existing connector utilizing a specific connector ID

### EXAMPLE 3
```
Set-TrustConnector -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2' -Disable
```

Disable a connector

### EXAMPLE 4
```
Get-TrustConnector -ID 'My connector' | Set-TrustConnector -Disable
```

Disable a connector by name

### EXAMPLE 5
```
Set-TrustConnector -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2' -Disable:$false
```

Reenable a disabled connector

## PARAMETERS

### -ManifestPath
Path to an updated manifest for an existing connector.
Ensure the manifest has the deployment element which is not needed when testing in the simulator.
See https://github.com/Venafi/vmware-avi-connector?tab=readme-ov-file#manifest for details.

```yaml
Type: String
Parameter Sets: Manifest
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ID
Connector ID to update.
If not provided, the ID will be looked up by the name in the manifest provided by ManifestPath.
Note that if both ManifestPath and ID are provided and the name in the manifest is different than the one associated with ID, the name will be changed.

```yaml
Type: String
Parameter Sets: Manifest
Aliases: connectorId

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: Disable
Aliases: connectorId

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Disable
Disable or reenable a connector

```yaml
Type: SwitchParameter
Parameter Sets: Disable
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

### Connector
## OUTPUTS

## NOTES

## RELATED LINKS
