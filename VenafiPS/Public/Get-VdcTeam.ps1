function Get-VdcTeam {
    <#
    .SYNOPSIS
    Get team info

    .DESCRIPTION
    Get info for a team including members and owners.

    .PARAMETER ID
    Team ID in local prefixed universal format.  You can find the team/group ID with Find-VdcIdentity.

    .PARAMETER All
    Provide this switch to get all teams

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.

    .INPUTS
    ID

    .OUTPUTS
    PSCustomObject

    .EXAMPLE
    Get-VdcTeam -ID 'local:{803f332e-7576-4696-a5a2-8ac6be6b14e6}'

    Get info for a Certificate Manager, Self-Hosted team

    .EXAMPLE
    Find-VdcIdentity -Name MyTeamName | Get-VdcTeam

    Search for a team and then get details

    .EXAMPLE
    Get-VdcTeam -All

    Get info for all teams

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-GET-Teams-prefix-universal.php
    #>

    [CmdletBinding(DefaultParameterSetName = 'ID')]
    [Alias('Get-TppTeam')]

    param (

        [Parameter(Mandatory, ParameterSetName = 'ID', ValueFromPipelineByPropertyName, Position = 0)]
        [Alias('PrefixedUniversal', 'Guid', 'PrefixedName')]
        [string] $ID,

        [Parameter(Mandatory, ParameterSetName = 'All')]
        [switch] $All,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {
        Test-VenafiSession $PSCmdlet.MyInvocation
    }

    process {

        if ( $PSCmdlet.ParameterSetName -eq 'All' ) {

            # no built-in api for this, get group objects and then get details
            Find-VdcObject -Path '\VED\Identity' -Class 'Group' | Where-Object { $_.Name -ne 'Everyone' } | Get-VdcTeam
        }
        else {

            # not only does -match set $matches, but -notmatch does as well
            if ( $ID -notmatch '(?im)^(local:)?\{?([0-9A-F]{8}[-]?(?:[0-9A-F]{4}[-]?){3}[0-9A-F]{12})\}?$' ) {
                Write-Error "'$ID' is not the proper format for a Team.  Format should either be a guid or local:{guid}."
                return
            }

            $params = @{
                UriLeaf = ('Teams/local/{{{0}}}' -f $matches[2])
            }

            try {

                $response = Invoke-VenafiRestMethod @params

                $out = [pscustomobject] ($response.ID | ConvertTo-VdcIdentity)
                $out | Add-Member @{
                    Members = $response.Members | ConvertTo-VdcIdentity
                    Owners  = $response.Owners | ConvertTo-VdcIdentity
                }
                $out
            }
            catch {

                # handle known errors where the local group is not actually a team
                if ( $_.ErrorDetails.Message -like '*Failed to read the team identity;*' ) {
                    Write-Verbose "$ID looks to be a local group and not a Team.  The server responded with $_"
                }
                else {
                    Write-Error "$ID : $_"
                }
            }
        }
    }
}


