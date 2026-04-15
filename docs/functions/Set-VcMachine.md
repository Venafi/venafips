# Set-VcMachine

## SYNOPSIS
Update an existing machine settings

## SYNTAX

```
Set-VcMachine [-Machine] <String> [[-Name] <String>] [[-ConnectionDetail] <Hashtable>] [[-Satellite] <String>]
 [-PassThru] [[-VenafiSession] <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Update an existing machine settings, including name, connection details, and satellite.

## EXAMPLES

### EXAMPLE 1
```
Set-VcMachine -Machine GregIIS -Name GregIIS2
```

Update the name of a machine

### EXAMPLE 2
```
Set-VcMachine -Machine GregIIS -Satellite 'My New Satellite'
```

Update the satellite of a machine

### EXAMPLE 3
```
Get-VcMachine -Machine GregIIS | Select-Object -ExpandProperty connectionDetails
```

The current connection details of a machine will be shown. 
For example, let's say it shows the following:
    authenticationType : kerberos
    credentialType     : local
    hostnameOrAddress  : greg.paloaltonetworks.com
    https              : False
    kerberos           : @{domain=mydomain.paloaltonetworks.com; keyDistributionCenter=ad.mydomain.paloaltonetworks.com; servicePrincipalName=WSMAN/greg.paloaltonetworks.com}

If you want to update the key distribution center, you can run the following command:

Set-VcMachine -Machine GregIIS -ConnectionDetail @{ 'kerberos' = @{ 'keyDistributionCenter' = 'new value' } }

This will update just the key distribution center value while leaving the rest of the connection details the same.

### EXAMPLE 4
```
Set-VcMachine -Machine GregIIS -ConnectionDetail @{ 'kerberos' = @{ 'keyDistributionCenter' = 'new value' } } -PassThru
```

Update a machine and return the updated machine object with the new connection details

### EXAMPLE 5
```
Set-VcMachine -Machine GregIIS -ConnectionDetail @{ 'kerberos' = @{ 'keyDistributionCenter' = 'new value' } } | Invoke-VcWorkflow -Workflow 'Test'
```

Update a machine connection detail and then test the connection with the Test workflow. 
Note that the workflow will use the updated connection details.

## PARAMETERS

### -Machine
Machine ID or name

```yaml
Type: String
Parameter Sets: (All)
Aliases: machineId

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Name
New machine name to update to

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ConnectionDetail
Connection details to update. 
This should be a hashtable with the same structure as the connectionDetails object returned by Get-VcMachine. 
You can provide a partial hashtable with just
the values you want to update. 
See the example below for details.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Satellite
New Satellite name or ID

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
Return the updated machine object

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
Position: 5
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

### Machine
## OUTPUTS

## NOTES

## RELATED LINKS
