function Remove-VdcTeamMember {
    <#
    .SYNOPSIS
    Remove team member

    .DESCRIPTION
    Remove a team member from Certificate Manager, Self-Hosted

    .PARAMETER ID
    Team ID, the ID property from Find-VdcIdentity or Get-VdcTeam.

    .PARAMETER Member
    1 or more members to remove from the team
    This is the identity ID property from Find-VdcIdentity or Get-VdcIdentity.

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A Certificate Manager, Self-Hosted token can also provided.
    If providing a Certificate Manager, Self-Hosted token, an environment variable named VDC_SERVER must also be set.

    .INPUTS
    ID

    .EXAMPLE
    Remove-VdcTeamMember -ID 'local:{803f332e-7576-4696-a5a2-8ac6be6b14e6}' -Member 'local:{803f332e-7576-4696-a5a2-8ac6be6b14e7}'

    Remove members from a team

    .EXAMPLE
    Remove-VdcTeamMember -ID 'local:{803f332e-7576-4696-a5a2-8ac6be6b14e6}' -Member 'local:{803f332e-7576-4696-a5a2-8ac6be6b14e7}' -Confirm:$false

    Remove members from a team bypassing the confirmation prompt

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-PUT-Teams-RemoveTeamMembers.php
    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]

    param (

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('PrefixedUniversal', 'Guid')]
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

        $teamName = Get-VdcIdentity -ID $ID | Select-Object -ExpandProperty FullName
        $members = foreach ($thisMember in $Member) {
            if ( $thisMember.StartsWith('local') ) {
                $teamIdentity = Get-VdcIdentity -ID $thisMember
                @{
                    'PrefixedName'      = $teamIdentity.FullName
                    'PrefixedUniversal' = $teamIdentity.ID
                }
            }
            else {
                @{'PrefixedUniversal' = $thisMember }
            }
        }
        $params = @{
            Method  = 'Put'
            UriLeaf = 'Teams/RemoveTeamMembers'
            Body    = @{
                'Team'    = @{'PrefixedName' = $teamName }
                'Members' = @($members)
            }
        }

        if ( $PSCmdlet.ShouldProcess($ID, "Delete team members") ) {
            $null = Invoke-VenafiRestMethod @params
        }
    }
}


