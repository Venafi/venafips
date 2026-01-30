# Get-VcMachine

## SYNOPSIS
Get machine details

## SYNTAX

### ID (Default)
```
Get-VcMachine [-Machine] <String> [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### All
```
Get-VcMachine [-All] [-IncludeConnectionDetail] [-VenafiSession <PSObject>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Get machine details for 1 or all.

## EXAMPLES

### EXAMPLE 1
```
Get-VcMachine -Machine 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2'
```

machineId              : cf7cfdc0-2b2a-11ee-9546-5136c4b21504
companyId              : cf7cfdc0-2b2a-11ee-9546-5136c4b21504
machineTypeId          : fc569b60-cf24-11ed-bdc6-77a4bac4cb50
pluginId               : ff645e14-bd1a-11ed-a009-ce063932f86d
integrationId          : cf7c8014-2b2a-11ee-9a03-fa8930555887
machineName            : MyCitrix
status                 : VERIFIED
machineType            : Citrix ADC
creationDate           : 7/25/2023 4:35:36 PM
modificationDate       : 7/25/2023 4:35:36 PM
machineIdentitiesCount : 0
owningTeam             : 59920180-a3e2-11ec-8dcd-3fcbf84c7db1
ownership              : @{owningTeams=System.Object\[\]}
connectionDetails      : @{hostnameOrAddress=1.2.3.4; password=uYroVBk/KtuuujEbfFC/06wtkIrOga7N96JdFSEQFhhn7KPUEWA=;
                         username=ZLQlnciWsVp+qIUJQ8nYcAuHh55FxKdFsWhHVp7LLU+0y8aDp1pw==}

Get a single machine by ID

### EXAMPLE 2
```
Get-VcMachine -Machine 'MyCitrix'
```

Get a single machine by name. 
The name is case sensitive.

### EXAMPLE 3
```
Get-VcMachine -All
```

machineId              : cf7cfdc0-2b2a-11ee-9546-5136c4b21504
companyId              : cf7cfdc0-2b2a-11ee-9546-5136c4b21504
machineTypeId          : fc569b60-cf24-11ed-bdc6-77a4bac4cb50
pluginId               : ff645e14-bd1a-11ed-a009-ce063932f86d
integrationId          : cf7c8014-2b2a-11ee-9a03-fa8930555887
machineName            : MyCitrix
status                 : VERIFIED
machineType            : Citrix ADC
creationDate           : 7/25/2023 4:35:36 PM
modificationDate       : 7/25/2023 4:35:36 PM
machineIdentitiesCount : 0
owningTeam             : 59920180-a3e2-11ec-8dcd-3fcbf84c7db1
ownership              : @{owningTeams=System.Object\[\]}

Get all machines. 
Note the connection details are not included by default with -All.
See -IncludeConnectionDetails if this is needed.

### EXAMPLE 4
```
Get-VcMachine -All -IncludeConnectionDetails
```

machineId              : cf7cfdc0-2b2a-11ee-9546-5136c4b21504
companyId              : cf7cfdc0-2b2a-11ee-9546-5136c4b21504
machineTypeId          : fc569b60-cf24-11ed-bdc6-77a4bac4cb50
pluginId               : ff645e14-bd1a-11ed-a009-ce063932f86d
integrationId          : cf7c8014-2b2a-11ee-9a03-fa8930555887
machineName            : MyCitrix
status                 : VERIFIED
machineType            : Citrix ADC
creationDate           : 7/25/2023 4:35:36 PM
modificationDate       : 7/25/2023 4:35:36 PM
machineIdentitiesCount : 0
owningTeam             : 59920180-a3e2-11ec-8dcd-3fcbf84c7db1
ownership              : @{owningTeams=System.Object\[\]}
connectionDetails      : @{hostnameOrAddress=1.2.3.4; password=uYroVBk/KtuuujEbfFC/06wtkIrOga7N96JdFSEQFhhn7KPUEWA=;
                         username=ZLQlnciWsVp+qIUJQ8nYcAuHh55FxKdFsWhHVp7LLU+0y8aDp1pw==}

Get all machines and include the connection details.
Getting connection details will require an additional API call for each machine and can take some time.
Use PowerShell v7+ to perform this in parallel and speed things up.

## PARAMETERS

### -Machine
Machine ID or name

```yaml
Type: String
Parameter Sets: ID
Aliases: machineId, ID

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -All
Get all machines

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

### -IncludeConnectionDetail
Getting all machines does not include connection details.
Use -IncludeConnectionDetail to add this to the output, but note it will require an additional API call for each machine and can take some time.
Execute with PowerShell v7+ to run in parallel and speed things up.

```yaml
Type: SwitchParameter
Parameter Sets: All
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
A TLSPC key can also provided.

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

### Machine
## OUTPUTS

## NOTES

## RELATED LINKS
