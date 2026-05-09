function Get-CmTeam {
    <#
    .SYNOPSIS
    Get team info

    .DESCRIPTION
    Get info for a team including members and owners.

    .PARAMETER ID
    Team ID in local prefixed universal format.  You can find the team/group ID with Find-CmIdentity.

    .PARAMETER All
    Provide this switch to get all teams

    .PARAMETER TrustClient
    Authentication for the function.
    The value defaults to the script session object $TrustClient created by New-TrustClient.

    .INPUTS
    ID

    .OUTPUTS
    PSCustomObject

    .EXAMPLE
    Get-CmTeam -ID 'local:{803f332e-7576-4696-a5a2-8ac6be6b14e6}'

    Get info for a Certificate Manager, Self-Hosted team

    .EXAMPLE
    Find-CmIdentity -Name MyTeamName | Get-CmTeam

    Search for a team and then get details

    .EXAMPLE
    Get-CmTeam -All

    Get info for all teams

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-GET-Teams-prefix-universal.php
    #>

    [Alias('Get-VdcTeam')]
    [CmdletBinding(DefaultParameterSetName = 'ID')]

    param (

        [Parameter(Mandatory, ParameterSetName = 'ID', ValueFromPipelineByPropertyName, Position = 0)]
        [Alias('PrefixedUniversal', 'Guid', 'PrefixedName')]
        [string] $ID,

        [Parameter(Mandatory, ParameterSetName = 'All')]
        [switch] $All,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [TrustClient] $TrustClient
    )

    begin {
    }

    process {

        if ( $PSCmdlet.ParameterSetName -eq 'All' ) {

            # no built-in api for this, get group objects and then get details
            Find-CmObject -Path '\VED\Identity' -Class 'Group' | Where-Object { $_.Name -ne 'Everyone' } | Get-CmTeam
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

                $response = Invoke-TrustRestMethod @params

                $out = [pscustomobject] ($response.ID | ConvertTo-CmIdentity)
                $out | Add-Member @{
                    Members = $response.Members | ConvertTo-CmIdentity
                    Owners  = $response.Owners | ConvertTo-CmIdentity
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


