function Add-VcTeamMember {
    <#
    .SYNOPSIS
    Add members to a team

    .DESCRIPTION
    Add members to a Certificate Manager, SaaS team

    .PARAMETER Team
    Team ID or name to add to

    .PARAMETER Member
    1 or more members to add to the team.

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A Certificate Manager, SaaS key can also provided.

    .INPUTS
    Team

    .EXAMPLE
    Add-VcTeamMember -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2' -Member @('ca7ff555-88d2-4bfc-9efa-2630ac44c1f3', 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f4')

    Add members to a Certificate Manager, SaaS team

    #>

    [CmdletBinding()]
    param (

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('PrefixedUniversal', 'Guid')]
        [string] $Team,

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

        $teamId = $Team | Get-VcData -Type Team -FailOnNotFound -FailOnMultiple

        $params.Method = 'Post'
        $params.UriLeaf = "teams/$teamId/members"
        $params.Body = @{
            'members' = @($Member)
        }

        $null = Invoke-VenafiRestMethod @params
    }
}


