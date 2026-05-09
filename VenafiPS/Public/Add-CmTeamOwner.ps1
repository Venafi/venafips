function Add-CmTeamOwner {
    <#
    .SYNOPSIS
    Add owners to a team

    .DESCRIPTION
    Add owners to a Certificate Manager, Self-Hosted team

    .PARAMETER ID
    Team ID, this is the ID property from Find-CmIdentity or Get-CmTeam.

    .PARAMETER Owner
    1 or more owners to add to the team
    This is the identity ID property from Find-CmIdentity or Get-CmIdentity.

    .PARAMETER TrustClient
    Authentication for the function.
    The value defaults to the script session object $TrustClient created by New-TrustClient.

    .INPUTS
    ID

    .EXAMPLE
    Add-CmTeamOwner -ID 'local:{803f332e-7576-4696-a5a2-8ac6be6b14e6}' -Owner 'local:{803f332e-7576-4696-a5a2-8ac6be6b14e7}'

    Add owners

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-PUT-Teams-AddTeamOwners.php
    #>

    [Alias('Add-VdcTeamOwner')]
    [CmdletBinding()]
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

        $teamName = Get-CmIdentity -ID $ID | Select-Object -ExpandProperty FullName
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
            UriLeaf = 'Teams/AddTeamOwners'
            Body    = @{
                'Team'   = @{'PrefixedName' = $teamName }
                'Owners' = @($owners)
            }
        }

        $null = Invoke-TrustRestMethod @params
    }
}


