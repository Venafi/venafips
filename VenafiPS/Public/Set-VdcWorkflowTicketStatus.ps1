function Set-VdcWorkflowTicketStatus {
    <#
    .SYNOPSIS
    Set workflow ticket status

    .DESCRIPTION
    Set workflow ticket status for a certificate

    .PARAMETER TicketGuid
    Guid representing a unique ticket

    .PARAMETER Status
    The new status to assign to the ticket.
    Possible values include "Pending", "Approved", "Approved After", "Approved Between", and "Rejected".

    .PARAMETER Explanation
    Explanation for the status change

    .PARAMETER ScheduledStart
    Specifies the time after which the ticket should be processed.
    ScheduledStart must be specified when the "Approved After" or "Approved Between" statuses are set

    .PARAMETER ScheduledStop
    Specifies the time before which the ticket should be processed.
    ScheduledStop must be specified when the "Approved Between" status is set

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.

    .INPUTS
    TicketGuid

    .OUTPUTS
    None

    .EXAMPLE
    Get-VdcWorkflowTicket -Path '\VED\policy\myapp.company.com' | Set-VdcWorkflowTicketStatus -Status Approved
    Approve all tickets for a certificate

    .EXAMPLE
    Get-VdcWorkflowTicket -Path '\VED\policy\myapp.company.com' | Set-VdcWorkflowTicketStatus -Status 'Approved After' -ScheduledStart (Get-Date).AaaDays(3) -Explanation 'weekend upgrade'
    Approve all tickets for a certificate after a certain date with an explanation

    .LINK
    https://venafi.github.io/VenafiPS/functions/Set-VdcWorkflowTicketStatus/

    .LINK
    https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Set-VdcWorkflowTicketStatus.ps1

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Workflow-ticket-updatestatus.php

    #>

    [CmdletBinding(SupportsShouldProcess)]
    [Alias('Set-TppWorkflowTicketStatus')]

    param (

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Guid[]] $TicketGuid,

        [Parameter(Mandatory)]
        [ValidateSet('Pending', 'Approved', 'Approved After', 'Approved Between', 'Rejected')]
        [String] $Status,

        [Parameter()]
        [String] $Explanation,

        [Parameter()]
        [DateTime] $ScheduledStart,

        [Parameter()]
        [DateTime] $ScheduledStop,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {

        switch ($Status) {
            'Approved After' {
                if ( -not $ScheduledStart ) {
                    throw "A status of 'Approved After' requires a value for ScheduledStart"
                }
                if ( $ScheduledStop ) {
                    throw "Do not provide a scheduled stop with a status of 'Approved After'"
                }
            }
            'Approved Between' {
                if ( -not $ScheduledStart -or -not $ScheduledStop ) {
                    throw "A status of 'Approved Between' requires a value for ScheduledStart and ScheduledStop"
                }
            }
            Default {
            }
        }

        Test-VenafiSession $PSCmdlet.MyInvocation
    }

    process {

        foreach ($thisGuid in $TicketGuid) {
            $params = @{

                Method     = 'Post'
                UriLeaf    = 'Workflow/Ticket/UpdateStatus'
                Body       = @{
                    'GUID'   = $thisGuid
                    'Status' = $Status
                }
            }

            if ( $PSBoundParameters.ContainsKey('Explanation') ) {
                $params.Body.Explanation = $Explanation
            }

            if ( $PSBoundParameters.ContainsKey('ScheduledStart') ) {
                $params.Body.ScheduledStart = ($ScheduledStart | ConvertTo-UtcIso8601)
            }

            if ( $PSBoundParameters.ContainsKey('ScheduledStop') ) {
                $params.Body.ScheduledStop = ($ScheduledStop | ConvertTo-UtcIso8601)
            }

            if ( $PSCmdlet.ShouldProcess($params.Body.GUID, 'Set workflow ticket status') ) {

                $response = Invoke-VenafiRestMethod @params

                if ( -not ($response.Result -eq [TppWorkflowResult]::Success) ) {
                    throw ("Error setting workflow ticket status, error is {0}" -f [enum]::GetName([TppWorkflowResult], $response.Result))
                }
            }
        }
    }
}


