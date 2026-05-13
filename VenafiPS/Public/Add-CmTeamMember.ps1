function Add-CmTeamMember {
    <#
    .SYNOPSIS
    Add members to a team

    .DESCRIPTION
    Add members to a Certificate Manager, Self-Hosted team

    .PARAMETER ID
    Team ID from Find-CmIdentity or Get-CmTeam.

    .PARAMETER Member
    1 or more members to add to the team.
    The identity ID property from Find-CmIdentity or Get-CmIdentity.

    .PARAMETER TrustClient
    Authentication for the function.
    The value defaults to the script session object $TrustClient created by New-TrustClient.
    A Certificate Manager, Self-Hosted token can be provided.

    .INPUTS
    ID

    .EXAMPLE
    Add-CmTeamMember -ID 'local:{803f332e-7576-4696-a5a2-8ac6be6b14e6}' -Member 'local:{803f332e-7576-4696-a5a2-8ac6be6b14e7}'

    Add members to a Certificate Manager, Self-Hosted team

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-PUT-Teams-AddTeamMembers.php
    #>

    [Alias('Add-VdcTeamMember')]
    [CmdletBinding()]

    param (

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('PrefixedUniversal', 'Guid')]
        [string] $ID,

        [Parameter(Mandatory)]
        [string[]] $Member,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [TrustClient] $TrustClient
    )

    begin {
    }

    process {

        $teamName = Get-CmIdentity -ID $ID | Select-Object -ExpandProperty FullName
        $members = foreach ($thisMember in $Member) {
            if ( $thisMember.StartsWith('local') ) {
                $memberIdentity = Get-CmIdentity -ID $thisMember
                @{
                    'PrefixedName'      = $memberIdentity.FullName
                    'PrefixedUniversal' = $memberIdentity.ID
                }
            }
            else {
                @{'PrefixedUniversal' = $thisMember }
            }
        }

        $params = @{
            Method  = 'Put'
            UriLeaf = 'Teams/AddTeamMembers'
            Body    = @{
                'Team'    = @{'PrefixedName' = $teamName }
                'Members' = @($members)
            }
        }

        $null = Invoke-TrustRestMethod @params
    }
}


