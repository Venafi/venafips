function Remove-CmTeamOwner {
    <#
    .SYNOPSIS
    Remove team owner

    .DESCRIPTION
    Remove a team owner from Certificate Manager, Self-Hosted

    .PARAMETER ID
    Team ID, the ID property from Find-CmIdentity or Get-CmTeam.

    .PARAMETER Owner
    1 or more owners to remove from the team
    This is the identity ID property from Find-CmIdentity or Get-CmIdentity.

    .PARAMETER TrustClient
    Authentication for the function.
    The value defaults to the script session object $TrustClient created by New-TrustClient.

    .INPUTS
    ID

    .EXAMPLE
    Remove-CmTeamOwner -ID 'local:{803f332e-7576-4696-a5a2-8ac6be6b14e6}' -Owner 'local:{803f332e-7576-4696-a5a2-8ac6be6b14e7}'

    Remove owners from a team

    .LINK
    https://docs.venafi.com/Docs/21.4SDK/TopNav/Content/SDK/WebSDK/r-SDK-PUT-Teams-DemoteTeamOwners.php
    #>

    [Alias('Remove-VdcTeamOwner')]
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]

    param (

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('PrefixedUniversal', 'Guid')]
        [string] $ID,

        [Parameter(Mandatory)]
        [string[]] $Owner,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [TrustClient] $TrustClient
    )

    begin {
    }

    process {

        # get team details and ensure at least 1 owner will remain
        $thisTeam = Get-CmTeam -ID $ID
        $ownerCompare = Compare-Object -ReferenceObject $thisTeam.owners.ID -DifferenceObject $Owner
        if ( -not ($ownerCompare | Where-Object { $_.SideIndicator -eq '<=' }) ) {
            throw 'A team must have at least one owner and you are attempting to remove them all'
        }

        # $teamName = Get-CmIdentity -ID $ID | Select-Object -ExpandProperty FullName
        $owners = foreach ($thisOwner in $Owner) {
            if ( $thisOwner.StartsWith('local') ) {
                $ownerIdentity = Get-CmIdentity -ID $thisOwner
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
            $null = Invoke-TrustRestMethod @params

            # we've only demoted the owners to members.  now remove them
            Remove-CmTeamMember -ID $ID -Member $Owner
        }
    }
}


