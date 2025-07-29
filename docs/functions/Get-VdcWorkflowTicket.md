# Get-VdcWorkflowTicket

## SYNOPSIS
Get workflow ticket

## SYNTAX

```
Get-VdcWorkflowTicket [-Path] <String[]> [[-VenafiSession] <PSObject>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Get details about workflow tickets associated with a certificate.

## EXAMPLES

### EXAMPLE 1
```
Get-VdcWorkflowTicket -Path '\VED\policy\myapp.company.com'
Get ticket details for 1 certificate
```

### EXAMPLE 2
```
$certs | Get-VdcWorkflowTicket
Get ticket details for multiple certificates
```

## PARAMETERS

### -Path
Path to the certificate

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: DN, CertificateDN

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
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
Position: 2
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

### Path
## OUTPUTS

### PSCustomObject with the following properties:
###     Guid: Workflow ticket Guid
###     ApprovalExplanation: The explanation supplied by the approver.
###     ApprovalFrom: The identity to be contacted for approving.
###     ApprovalReason: The administrator-defined reason text.
###     Approvers: An array of workflow approvers for the certificate.
###     Blocking: The object that the ticket is associated with.
###     Created: The date/time the ticket was created.
###     IssuedDueTo: The workflow object that caused this ticket to be created (if any).
###     Result: Integer result code indicating success 1 or failure. For more information, see Workflow result codes.
###     Status: The status of the ticket.
###     Updated: The date/time that the ticket was last updated.
## NOTES

## RELATED LINKS

[https://venafi.github.io/VenafiPS/functions/Get-VdcWorkflowTicket/](https://venafi.github.io/VenafiPS/functions/Get-VdcWorkflowTicket/)

[https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Get-VdcWorkflowTicket.ps1](https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Get-VdcWorkflowTicket.ps1)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Workflow-ticket-enumerate.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Workflow-ticket-enumerate.php)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Workflow-ticket-details.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Workflow-ticket-details.php)

