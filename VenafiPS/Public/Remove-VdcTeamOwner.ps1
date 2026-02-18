function Remove-VdcTeamOwner {
    <#
    .SYNOPSIS
    Remove team owner

    .DESCRIPTION
    Remove a team owner from Certificate Manager, Self-Hosted

    .PARAMETER ID
    Team ID, the ID property from Find-VdcIdentity or Get-VdcTeam.

    .PARAMETER Owner
    1 or more owners to remove from the team
    This is the identity ID property from Find-VdcIdentity or Get-VdcIdentity.

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A Certificate Manager, Self-Hosted token can also provided.
    If providing a Certificate Manager, Self-Hosted token, an environment variable named VDC_SERVER must also be set.

    .INPUTS
    ID

    .EXAMPLE
    Remove-VdcTeamOwner -ID 'local:{803f332e-7576-4696-a5a2-8ac6be6b14e6}' -Owner 'local:{803f332e-7576-4696-a5a2-8ac6be6b14e7}'

    Remove owners from a team

    .LINK
    https://docs.venafi.com/Docs/21.4SDK/TopNav/Content/SDK/WebSDK/r-SDK-PUT-Teams-DemoteTeamOwners.php
    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]

    param (

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('PrefixedUniversal', 'Guid')]
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
        $thisTeam = Get-VdcTeam -ID $ID
        $ownerCompare = Compare-Object -ReferenceObject $thisTeam.owners.ID -DifferenceObject $Owner
        if ( -not ($ownerCompare | Where-Object { $_.SideIndicator -eq '<=' }) ) {
            throw 'A team must have at least one owner and you are attempting to remove them all'
        }

        # $teamName = Get-VdcIdentity -ID $ID | Select-Object -ExpandProperty FullName
        $owners = foreach ($thisOwner in $Owner) {
            if ( $thisOwner.StartsWith('local') ) {
                $ownerIdentity = Get-VdcIdentity -ID $thisOwner
                @{
                    'PrefixedName'      = $ownerIdentity.FullName
                    'PrefixedUniversal' = $ownerIdentity.ID
                }
            }
            else {
                @{'PrefixedUniversal' = $thisOwner }
            }
        }

        $params = @{
            Method  = 'Put'
            UriLeaf = 'Teams/DemoteTeamOwners'
            Body    = @{
                'Team'   = @{'PrefixedName' = $thisTeam.FullName }
                'Owners' = @($owners)
            }
        }

        if ( $PSCmdlet.ShouldProcess($ID, "Delete team owners") ) {
            $null = Invoke-VenafiRestMethod @params

            # we've only demoted the owners to members.  now remove them
            Remove-VdcTeamMember -ID $ID -Member $Owner
        }
    }
}


