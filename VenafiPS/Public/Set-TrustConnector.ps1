function Set-TrustConnector {
    <#
    .SYNOPSIS
    Update an existing connector

    .DESCRIPTION
    Update a new machine, CA, CMSH, or credential connector.
    You can either update the manifest or disable/reenable it.

    .PARAMETER ManifestPath
    Path to an updated manifest for an existing connector.
    Ensure the manifest has the deployment element which is not needed when testing in the simulator.
    See https://github.com/Venafi/vmware-avi-connector?tab=readme-ov-file#manifest for details.

    .PARAMETER Connector
    Connector ID or name to disable.

    .PARAMETER Disable
    Disable or reenable a connector

    .PARAMETER TrustClient
    Authentication for the function.
    The value defaults to the script session object $TrustClient created by New-TrustClient.

    .INPUTS
    Connector

    .EXAMPLE
    Set-TrustConnector -ManifestPath '/tmp/manifest_v2.json'

    Update an existing connector with the same name as in the manifest

    .EXAMPLE
    Set-TrustConnector -Connector 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2' -Disable

    Disable a connector

    .EXAMPLE
    Set-TrustConnector -Connector 'My connector' -Disable

    Disable a connector by name

    .EXAMPLE
    Set-TrustConnector -Connector 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2' -Disable:$false

    Reenable a disabled connector

    #>

    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Manifest')]
    [Alias('Set-VcConnector')]

    param (

        [Parameter(ParameterSetName = 'Manifest', Mandatory)]
        [ValidateScript(
            {
                if ( -not ( Test-Path $_ ) ) {
                    throw "The manifest path $_ cannot be found"
                }
                $true
            }
        )]
        [string] $ManifestPath,

        [Parameter(ParameterSetName = 'Disable', Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('connectorId')]
        [string] $Connector,

        [Parameter(ParameterSetName = 'Disable', Mandatory)]
        [switch] $Disable,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [TrustClient] $TrustClient
    )

    begin {
    }

    process {

        # get the connector id if provided
        $connectorId = if ( $PSBoundParameters.ContainsKey('Connector') ) {
            if ( Test-IsGuid($Connector) ) {
                $Connector
            }
            else {
                $thisConnector = Get-TrustConnector -Connector $Connector
                if ( -not $thisConnector ) {
                    throw ('A connector with the name ''{0}'' was not found' -f $Connector)
                }
                $thisConnector.connectorId
            }
        }

        switch ($PSCmdLet.ParameterSetName) {
            'Manifest' {
                $manifestObject = Get-Content -Path $ManifestPath -Raw | ConvertFrom-Json
                $manifest = if ( $manifestObject.manifest ) {
                    $manifestObject.manifest
                }
                else {
                    $manifestObject
                }

                # get connector details from manifest name
                $thisConnector = Get-TrustConnector -Connector $manifest.name
                if ( -not $thisConnector ) {
                    throw ('An existing connector with the name ''{0}'' was not found' -f $manifest.name)
                }

                # ensure deployment is provided which is not needed during simulator testing
                if ( -not $manifest.deployment ) {
                    throw 'A deployment element was not found in the manifest.  See https://github.com/Venafi/vmware-avi-connector?tab=readme-ov-file#manifest for details.'
                }

                $params = @{
                    Method  = 'Patch'
                    UriLeaf = 'plugins/{0}' -f $thisConnector.connectorId
                    Body    = @{
                        manifest = $manifest
                    }
                }

                if ( $PSCmdlet.ShouldProcess($manifest.name, 'Update connector') ) {
                    $null = Invoke-TrustRestMethod @params
                }
            }

            'Disable' {

                if ( $Disable ) {
                    if ( $PSCmdlet.ShouldProcess($connectorId, "Disable connector") ) {
                        $null = Invoke-TrustRestMethod -Method 'Post' -UriLeaf "plugins/$connectorId/disablements"
                    }
                }
                else {
                    $null = Invoke-TrustRestMethod -Method 'Delete' -UriLeaf "plugins/$connectorId/disablements"
                }
            }
        }
    }
}


