function Remove-VcTeamMember {
    <#
    .SYNOPSIS
    Remove team member

    .DESCRIPTION
    Remove a team member from Certificate Manager, SaaS

    .PARAMETER ID
    Team ID, this is the unique guid obtained from Get-VcTeam.

    .PARAMETER Member
    1 or more members to remove from the team
    This is the unique guid obtained from Get-VcIdentity.

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A Certificate Manager, SaaS key can also provided.

    .INPUTS
    ID

    .EXAMPLE
    Remove-VcTeamMember -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2' -Member @('ca7ff555-88d2-4bfc-9efa-2630ac44c1f3', 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f4')

    Remove members from a team

    .EXAMPLE
    Remove-VcTeamMember -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2' -Member 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f3' -Confirm:$false

    Remove members from a team with no confirmation prompting

    .LINK
    https://api.venafi.cloud/webjars/swagger-ui/index.html#/Teams/removeMember
    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]

    param (

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('teamId')]
        [string] $ID,

        [Parameter(Mandatory)]
        [string[]] $Member,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {
        Test-VenafiSession $PSCmdlet.MyInvocation
    }

    process {

        $params = @{
            Method  = 'Delete'
            UriLeaf = "teams/$ID/members"
            Body    = @{
                'members' = @($Member)
            }
        }

        if ( $PSCmdlet.ShouldProcess($ID, "Delete team members") ) {
            $null = Invoke-VenafiRestMethod @params
        }
    }
}


