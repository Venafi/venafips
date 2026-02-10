function Get-VcConnector {
    <#
    .SYNOPSIS
    Get connector info

    .DESCRIPTION
    Get details on 1 or all connectors associated with your tenant

    .PARAMETER Connector
    Connector ID or name

    .PARAMETER All
    Get all connectors

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A Certificate Manager, SaaS key can also provided.

    .INPUTS
    Connector

    .EXAMPLE
    Get-VcConnector -Connector 'My Connector'

    Get a single object by name.  The name is case sensitive.

    .EXAMPLE
    Get-VcConnector -All

    Get all connectors

    #>

    [CmdletBinding(DefaultParameterSetName = 'ID')]
    [Alias('Get-VaasConnector')]

    param (

        [Parameter(Mandatory, ParameterSetName = 'ID', ValueFromPipelineByPropertyName, Position = 0)]
        [Alias('connectorId', 'ID')]
        [string] $Connector,

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

        $params = @{
            UriLeaf = 'plugins'
        }

        if ( $PSBoundParameters.ContainsKey('Connector') ) {
            if ( Test-IsGuid($Connector) ) {
                $params.UriLeaf += "/{0}" -f $Connector
            }
            else {
                # search by name
                return Get-VcConnector -All | Where-Object { $_.name -eq $Connector }
            }
        }
        else {
            # getting all by default excludes disabled connectors so let's include them
            $params.Body = @{'includeDisabled' = $true }
        }

        $response = Invoke-VenafiRestMethod @params

        if ( $response.PSObject.Properties.Name -contains 'plugins' ) {
            $connectors = $response | Select-Object -ExpandProperty 'plugins'
        }
        else {
            $connectors = $response
        }

        if ( $connectors ) {
            $connectors | Select-Object @{ 'n' = 'connectorId'; 'e' = { $_.Id } }, @{ 'n' = 'connectorType'; 'e' = { $_.pluginType } }, * -ExcludeProperty Id, pluginType
        }
    }
}

