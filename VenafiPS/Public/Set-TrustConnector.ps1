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

    .PARAMETER ID
    Connector ID to update.
    If not provided, the ID will be looked up by the name in the manifest provided by ManifestPath.
    Note that if both ManifestPath and ID are provided and the name in the manifest is different than the one associated with ID, the name will be changed.

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
    Set-TrustConnector -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2' -ManifestPath '/tmp/manifest_v2.json'

    Update an existing connector utilizing a specific connector ID

    .EXAMPLE
    Set-TrustConnector -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2' -Disable

    Disable a connector

    .EXAMPLE
    Get-TrustConnector -ID 'My connector' | Set-TrustConnector -Disable

    Disable a connector by name

    .EXAMPLE
    Set-TrustConnector -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2' -Disable:$false

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

        [Parameter(ParameterSetName = 'Manifest', ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Disable', Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('connectorId')]
        [ValidateScript(
            {
                if ( -not (Test-IsGuid -InputObject $_ ) ) {
                    throw "$_ is not a valid connector id format"
                }
                $true
            }
        )]
        [string] $ID,

        [Parameter(ParameterSetName = 'Disable', Mandatory)]
        [switch] $Disable,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [TrustClient] $TrustClient
    )

    begin {
    }

    process {

        switch ($PSCmdLet.ParameterSetName) {
            'Manifest' {
                $manifestObject = Get-Content -Path $ManifestPath -Raw | ConvertFrom-Json
                $manifest = if ( $manifestObject.manifest ) {
                    $manifestObject.manifest
                } else {
                    $manifestObject
                }

                # if connector is provided, update that specific one
                # if not, use the name from the manifest to find the existing connector id

                if ( $ID ) {
                    $connectorId = $ID
                }
                else {
                    $thisConnector = Get-TrustConnector -ID $manifest.name
                    if ( -not $thisConnector ) {
                        throw ('An existing connector with the name {0} was not found' -f $manifest.name)
                    }
                    $connectorId = $thisConnector.connectorId
                }

                # ensure deployment is provided which is not needed during simulator testing
                if ( -not $manifest.deployment ) {
                    throw 'A deployment element was not found in the manifest.  See https://github.com/Venafi/vmware-avi-connector?tab=readme-ov-file#manifest for details.'
                }

                $params = @{
                    Method  = 'Patch'
                    UriLeaf = "plugins/$connectorId"
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
                    if ( $PSCmdlet.ShouldProcess($ID, "Disable connector") ) {
                        $null = Invoke-TrustRestMethod -Method 'Post' -UriLeaf "plugins/$ID/disablements"
                    }
                }
                else {
                    $null = Invoke-TrustRestMethod -Method 'Delete' -UriLeaf "plugins/$ID/disablements"
                }
            }
        }
    }
}


