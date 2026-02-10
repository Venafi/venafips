function Remove-VcTeamOwner {
    <#
    .SYNOPSIS
    Remove team owner

    .DESCRIPTION
    Remove a team owner from Certificate Manager, SaaS

    .PARAMETER ID
    Team ID, the unique guid obtained from Get-VcTeam.

    .PARAMETER Owner
    1 or more owners to remove from the team
    This is the unique guid obtained from Get-VcIdentity.

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A Certificate Manager, SaaS key can also provided.

    .INPUTS
    ID

    .EXAMPLE
    Remove-VcTeamOwner -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2' -Owner @('ca7ff555-88d2-4bfc-9efa-2630ac44c1f3', 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f4')

    Remove owners from a team

    .EXAMPLE
    Remove-VcTeamOwner -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2' -Owner 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f3' -Confirm:$false

    Remove an owner from a team with no confirmation prompting

    .LINK
    https://api.venafi.cloud/webjars/swagger-ui/index.html#/Teams/removeOwner
    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]

    param (

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('teamId')]
        [string] $ID,

        [Parameter(Mandatory)]
        [string[]] $Owner,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {
        Test-VenafiSession $PSCmdlet.MyInvocation
    }

    process {

        # get team details and ensure at least 1 owner will remain
        $thisTeam = Get-VcTeam -ID $ID
        $ownerCompare = Compare-Object -ReferenceObject $thisTeam.owners -DifferenceObject $Owner
        if ( -not ($ownerCompare | Where-Object { $_.SideIndicator -eq '<=' }) ) {
            throw 'A team must have at least one owner and you are attempting to remove them all'
        }

        $params = @{
            Method  = 'Delete'
            UriLeaf = "teams/$ID/owners"
            Body    = @{
                'owners' = @($Owner)
            }
        }

        if ( $PSCmdlet.ShouldProcess($ID, "Delete team owners") ) {
            $null = Invoke-VenafiRestMethod @params
        }
    }
}


