# Set-VdcWorkflowTicketStatus

## SYNOPSIS
Set workflow ticket status

## SYNTAX

```
Set-VdcWorkflowTicketStatus [-TicketGuid] <Guid[]> [-Status] <String> [[-Explanation] <String>]
 [[-ScheduledStart] <DateTime>] [[-ScheduledStop] <DateTime>] [[-VenafiSession] <PSObject>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Set workflow ticket status for a certificate

## EXAMPLES

### EXAMPLE 1
```
Get-VdcWorkflowTicket -Path '\VED\policy\myapp.company.com' | Set-VdcWorkflowTicketStatus -Status Approved
Approve all tickets for a certificate
```

### EXAMPLE 2
```
Get-VdcWorkflowTicket -Path '\VED\policy\myapp.company.com' | Set-VdcWorkflowTicketStatus -Status 'Approved After' -ScheduledStart (Get-Date).AaaDays(3) -Explanation 'weekend upgrade'
Approve all tickets for a certificate after a certain date with an explanation
```

## PARAMETERS

### -TicketGuid
Guid representing a unique ticket

```yaml
Type: Guid[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Status
The new status to assign to the ticket.
Possible values include "Pending", "Approved", "Approved After", "Approved Between", and "Rejected".

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

### -Explanation
Explanation for the status change

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ScheduledStart
Specifies the time after which the ticket should be processed.
ScheduledStart must be specified when the "Approved After" or "Approved Between" statuses are set

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ScheduledStop
Specifies the time before which the ticket should be processed.
ScheduledStop must be specified when the "Approved Between" status is set

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
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
Position: 6
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

### TicketGuid
## OUTPUTS

### None
## NOTES

## RELATED LINKS

[https://venafi.github.io/VenafiPS/functions/Set-VdcWorkflowTicketStatus/](https://venafi.github.io/VenafiPS/functions/Set-VdcWorkflowTicketStatus/)

[https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Set-VdcWorkflowTicketStatus.ps1](https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Set-VdcWorkflowTicketStatus.ps1)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Workflow-ticket-updatestatus.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Workflow-ticket-updatestatus.php)

