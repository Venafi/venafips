# Invoke-VcWorkflow

## SYNOPSIS
Start a machine or machine identity workflow

## SYNTAX

```
Invoke-VcWorkflow [-ID] <String> [[-Workflow] <String>] [[-ThrottleLimit] <Int32>]
 [[-VenafiSession] <PSObject>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Start a workflow to either test machine credentials or provision or discover machine identities

## EXAMPLES

### EXAMPLE 1
```
Invoke-VcWorkflow -ID '1345baf1-fc56-49b7-aa03-78e35bfe0a1a' -Workflow 'Provision'
```

ID                                   Success WorkflowName WorkflowID
--                                   ------- ------------ ----------
1345baf1-fc56-49b7-aa03-78e35bfe0a1a    True Provision    345b9d33-8c8a-4d4b-9fea-124f3a72f957

Trigger provisioning

### EXAMPLE 2
```
Invoke-VcWorkflow -ID '1345baf1-fc56-49b7-aa03-78e35bfe0a1a' -Workflow 'Test'
```

ID               : 1345baf1-fc56-49b7-aa03-78e35bfe0a1a
Success          : False
WorkflowName     : Test
WorkflowID       : 345b9d33-8c8a-4d4b-9fea-124f3a72f957
Error            : failed to connect to Citrix ADC: \[ERROR\] nitro-go: Failed to create resource of type login, name=login, err=failed: 401 Unauthorized ({ "errorcode": 354,
                   "message": "Invalid username or password", "severity": "ERROR" })

Trigger test connection, but it failed

### EXAMPLE 3
```
Find-VcMachineIdentity -Filter @('and', @('certificateValidityEnd', 'lt', (get-date).AddDays(30)), @('certificateValidityEnd', 'gt', (get-date))) | ForEach-Object {
    $renewResult = $_ | Invoke-VenafiCertificateAction -Renew
    # optionally add renew validation
    $_ | Invoke-VcWorkflow -Workflow 'Provision'
}
```

ID                                   Success WorkflowName WorkflowID
--                                   ------- ------------ ----------
1345baf1-fc56-49b7-aa03-78e35bfe0a1a    True Provision    345b9d33-8c8a-4d4b-9fea-124f3a72f957
89fa4370-2026-11ee-8a18-ff9579bb988e    True Provision    7598917c-7027-4927-be73-e592bcc4c567

Renew and provision all machine identities with certificates expiring within 30 days

## PARAMETERS

### -ID
Machine or machine identity id for the workflow to trigger.
Workflows 'Test' and 'GetConfig' require the machine ID.
Workflows 'Provision' and 'Discover' require the machine identity ID.

```yaml
Type: String
Parameter Sets: (All)
Aliases: machineID, machineIdentityID

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Workflow
The name of the workflow to trigger.
Valid values are 'Test', 'GetConfig', 'Provision', or 'Discover'.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: Test
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
Position: 3
Default value: 100
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
Position: 4
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

### ID
## OUTPUTS

### pscustomobject
## NOTES
Currently no eu or au region support when providing an api key directly
Use a session from New-VenafiSession

## RELATED LINKS
