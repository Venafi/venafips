function Add-CmsTeamOwner {
    <#
    .SYNOPSIS
    Add owners to a team

    .DESCRIPTION
    Add owners to a Certificate Manager, SaaS team

    .PARAMETER Team
    Team ID or name

    .PARAMETER Owner
    1 or more owners to add to the team
    This is the unique guid obtained from Get-CmsUser.

    .PARAMETER TrustClient
    Authentication for the function.
    The value defaults to the script session object $TrustClient created by New-TrustClient.

    .INPUTS
    Team

    .EXAMPLE
    Add-CmsTeamOwner -Team 'DevOps' -Owner @('ca7ff555-88d2-4bfc-9efa-2630ac44c1f3', 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f4')

    Add owners

    .LINK
    https://api.venafi.cloud/webjars/swagger-ui/index.html#/Teams/addOwner
    #>

        [Alias('Add-VcTeamOwner')]
    [CmdletBinding()]
    param (

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('ID')]
        [string] $Team,

        [Parameter(Mandatory)]
        [string[]] $Owner,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [TrustClient] $TrustClient
    )

    begin {

        $params = @{
            Method = 'Post'
            Body   = @{
                'owners' = @($Owner)
            }
        }
    }

    process {

        $params.UriLeaf = 'teams/{0}/owners' -f (Get-TrustData -InputObject $Team -Type 'Team' -FailOnNotFound -FailOnMultiple)

        $null = Invoke-TrustRestMethod @params
    }
}


