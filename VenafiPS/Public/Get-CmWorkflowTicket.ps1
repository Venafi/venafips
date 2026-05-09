function Get-CmWorkflowTicket {
    <#
    .SYNOPSIS
    Get workflow ticket

    .DESCRIPTION
    Get details about workflow tickets associated with a certificate.

    .PARAMETER Path
    Path to the certificate

    .PARAMETER TrustClient
    Authentication for the function.
    The value defaults to the script session object $TrustClient created by New-TrustClient.

    .INPUTS
    Path

    .OUTPUTS
    PSCustomObject with the following properties:
        Guid: Workflow ticket Guid
        ApprovalExplanation: The explanation supplied by the approver.
        ApprovalFrom: The identity to be contacted for approving.
        ApprovalReason: The administrator-defined reason text.
        Approvers: An array of workflow approvers for the certificate.
        Blocking: The object that the ticket is associated with.
        Created: The date/time the ticket was created.
        IssuedDueTo: The workflow object that caused this ticket to be created (if any).
        Result: Integer result code indicating success 1 or failure. For more information, see Workflow result codes.
        Status: The status of the ticket.
        Updated: The date/time that the ticket was last updated.

    .EXAMPLE
    Get-CmWorkflowTicket -Path '\VED\policy\myapp.company.com'
    Get ticket details for 1 certificate

    .EXAMPLE
    $certs | Get-CmWorkflowTicket
    Get ticket details for multiple certificates

    .LINK
    https://venafi.github.io/VenafiPS/functions/Get-CmWorkflowTicket/

    .LINK
    https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Get-CmWorkflowTicket.ps1

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Workflow-ticket-enumerate.php

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Workflow-ticket-details.php

    #>

    [Alias('Get-VdcWorkflowTicket')]
    [CmdletBinding()]

    param (

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                if ( $_ | Test-CmDnPath ) {
                    $true
                }
                else {
                    throw "'$_' is not a valid DN path"
                }
            })]
        [Alias('DN', 'CertificateDN')]
        [String[]] $Path,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [TrustClient] $TrustClient
    )

    begin {
        Write-Verbose ("Parameter set {0}" -f $PsCmdlet.ParameterSetName)
    }

    process {

        $ticketGuid = foreach ($thisDn in $Path) {

            $params = @{

                Method     = 'Post'
                UriLeaf    = 'Workflow/Ticket/Enumerate'
                Body       = @{
                    'ObjectDN' = $thisDn
                }
            }

            $response = Invoke-TrustRestMethod @params

            if ( $response ) {
                Write-Verbose ("Found {0} workflow tickets for certificate {1}" -f $response.GUIDs.count, $thisDn)
                $response.GUIDs
            }
        }

        foreach ($thisGuid in $ticketGuid) {
            $params = @{

                Method     = 'Post'
                UriLeaf    = 'Workflow/Ticket/Details'
                Body       = @{
                    'GUID' = $thisGuid
                }
            }

            $response = Invoke-TrustRestMethod @params

            if ( $response.Result -eq [CmWorkflowResult]::Success ) {
                $response | Add-Member @{
                    TicketGuid = [guid] $thisGuid
                }
                $response
            }
            else {
                throw ("Error getting ticket details, error is {0}" -f [enum]::GetName([CmWorkflowResult], $response.Result))
            }
        }
    }
}

