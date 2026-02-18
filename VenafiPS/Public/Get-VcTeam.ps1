function Get-VcTeam {
    <#
    .SYNOPSIS
    Get team info

    .DESCRIPTION
    Get info on teams including members and owners.
    Retrieve info on 1 or all.

    .PARAMETER Team
    Team name or guid.

    .PARAMETER All
    Get all teams

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A Certificate Manager, SaaS key can also provided.

    .INPUTS
    ID

    .OUTPUTS
    PSCustomObject

    .EXAMPLE
    Get-VcTeam -Team 'MyTeam'

    Get info for a team by name

    .EXAMPLE
    Get-VcTeam -Team 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2'

    Get info for a team by id

    .EXAMPLE
    Get-VcTeam -All

    Get info for all teams

    .LINK
    https://api.venafi.cloud/webjars/swagger-ui/index.html?urls.primaryName=account-service#/Teams/get_2

    .LINK
    https://api.venafi.cloud/webjars/swagger-ui/index.html?urls.primaryName=account-service#/Teams/get_1
    #>

    [CmdletBinding()]

    param (

        [Parameter(Mandatory, ParameterSetName = 'ID', ValueFromPipelineByPropertyName, Position = 0)]
        [Alias('teamID', 'owningTeam', 'owningTeams', 'owningTeamId', 'ownedTeams', 'ID')]
        [string] $Team,

        [Parameter(Mandatory, ParameterSetName = 'All')]
        [switch] $All,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Alias('Key', 'AccessToken')]
        [psobject] $VenafiSession
    )

    begin {
        Test-VenafiSession $PSCmdlet.MyInvocation
    }

    process {

        if ( $PSCmdlet.ParameterSetName -eq 'All' ) {
            $response = Invoke-VenafiRestMethod -UriLeaf 'teams'
        }
        else {

            if ( Test-IsGuid -InputObject $Team ) {
                $guid = [guid] $Team
                $response = Invoke-VenafiRestMethod -UriLeaf ('teams/{0}' -f $guid.ToString())
            }
            else {
                # assume team name
                $response = Invoke-VenafiRestMethod -UriLeaf 'teams' | Select-Object -ExpandProperty teams | Where-Object name -eq $Team
            }
        }

        if ( $response.PSObject.Properties.Name -contains 'teams' ) {
            $response | Select-Object -ExpandProperty teams | ConvertTo-VcTeam
        }
        else {
            $response | ConvertTo-VcTeam
        }
    }
}

