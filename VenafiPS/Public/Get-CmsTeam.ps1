function Get-CmsTeam {
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

    .PARAMETER TrustClient
    Authentication for the function.
    The value defaults to the script session object $TrustClient created by New-TrustClient.

    .INPUTS
    ID

    .OUTPUTS
    PSCustomObject

    .EXAMPLE
    Get-CmsTeam -Team 'MyTeam'

    Get info for a team by name

    .EXAMPLE
    Get-CmsTeam -Team 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2'

    Get info for a team by id

    .EXAMPLE
    Get-CmsTeam -All

    Get info for all teams

    .LINK
    https://api.venafi.cloud/webjars/swagger-ui/index.html?urls.primaryName=account-service#/Teams/get_2

    .LINK
    https://api.venafi.cloud/webjars/swagger-ui/index.html?urls.primaryName=account-service#/Teams/get_1
    #>

        [Alias('Get-VcTeam')]
    [CmdletBinding()]
    param (

        [Parameter(Mandatory, ParameterSetName = 'ID', ValueFromPipelineByPropertyName, Position = 0)]
        [Alias('teamID')]
        [string] $Team,

        [Parameter(Mandatory, ParameterSetName = 'All')]
        [switch] $All,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [TrustClient] $TrustClient
    )

    process {

        if ( $PSCmdlet.ParameterSetName -eq 'All' ) {
            $response = Invoke-TrustRestMethod -UriLeaf 'teams'
        }
        else {

            if ( Test-IsGuid -InputObject $Team ) {
                $guid = [guid] $Team
                $response = Invoke-TrustRestMethod -UriLeaf ('teams/{0}' -f $guid.ToString())
            }
            else {
                # assume team name
                $response = Invoke-TrustRestMethod -UriLeaf 'teams' | Select-Object -ExpandProperty teams | Where-Object name -eq $Team
            }
        }

        $teams = if ( $response.PSObject.Properties.Name -contains 'teams' ) {
            $response | Select-Object -ExpandProperty teams
        }
        else {
            $response
        }

        if ( $teams ) {
            $teams | Select-Object -Property @{n = 'teamId'; e = { $_.id } }, * -ExcludeProperty id
        }
    }
}