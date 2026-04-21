function Add-TrustTeamMember {
    <#
    .SYNOPSIS
    Add members to a team

    .DESCRIPTION
    Add members to a Certificate Manager, SaaS team

    .PARAMETER Team
    Team ID or name to add to

    .PARAMETER Member
    1 or more members to add to the team.

    .PARAMETER TrustClient
    Authentication for the function.
    The value defaults to the script session object $TrustClient created by New-TrustClient.

    .INPUTS
    Team

    .EXAMPLE
    Add-TrustTeamMember -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2' -Member @('ca7ff555-88d2-4bfc-9efa-2630ac44c1f3', 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f4')

    Add members to a Certificate Manager, SaaS team

    #>

    [CmdletBinding()]
    [Alias('Add-VcTeamMember')]
    param (

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('PrefixedUniversal')]
        [string] $Team,

        [Parameter(Mandatory)]
        [string[]] $Member,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [TrustClient] $TrustClient
    )

    begin {
    }

    process {

        $teamId = $Team | Get-TrustData -Type Team -FailOnNotFound -FailOnMultiple

        $params.Method = 'Post'
        $params.UriLeaf = "teams/$teamId/members"
        $params.Body = @{
            'members' = @($Member)
        }

        $null = Invoke-TrustRestMethod @params
    }
}


