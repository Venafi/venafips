function Add-VcTeamOwner {
    <#
    .SYNOPSIS
    Add owners to a team

    .DESCRIPTION
    Add owners to a Certificate Manager, SaaS team

    .PARAMETER Team
    Team ID or name

    .PARAMETER Owner
    1 or more owners to add to the team
    This is the unique guid obtained from Get-VcIdentity.

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A Certificate Manager, SaaS key can also provided.

    .INPUTS
    Team

    .EXAMPLE
    Add-VcTeamOwner -Team 'DevOps' -Owner @('ca7ff555-88d2-4bfc-9efa-2630ac44c1f3', 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f4')

    Add owners

    .LINK
    https://api.venafi.cloud/webjars/swagger-ui/index.html#/Teams/addOwner
    #>

    [CmdletBinding()]
    param (

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('ID')]
        [string] $Team,

        [Parameter(Mandatory)]
        [string[]] $Owner,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {
        Test-VenafiSession $PSCmdlet.MyInvocation

        $params = @{
            Method = 'Post'
            Body   = @{
                'owners' = @($Owner)
            }
        }
    }

    process {

        $params.UriLeaf = 'teams/{0}/owners' -f (Get-VcData -InputObject $Team -Type 'Team' -FailOnNotFound -FailOnMultiple)

        $null = Invoke-VenafiRestMethod @params
    }
}


