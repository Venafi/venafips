function New-VcConnector {
    <#
    .SYNOPSIS
    Create a new connector

    .DESCRIPTION
    Create a new machine, CA, TPP, or credential connector

    .PARAMETER ManifestPath
    Path to an existing manifest.
    Manifest can either be directly from the simulator or a full manifest with deployment element.
    If the manifest is from the simulator, the DeploymentImage parameter is required.

    .PARAMETER DeploymentImage
    Path to the already uploaded docker image.
    This parameter is only to be used for a manifest directly from the simulator.

    .PARAMETER Maintainer
    Optional value to specify the organization, individual, email, location, or website responsible for maintaining the connector
    This parameter is only to be used for a manifest directly from the simulator.

    .PARAMETER PassThru
    Return newly created connector object

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A Certificate Manager, SaaS key can also provided.

    .OUTPUTS
    PSCustomObject, if PassThru provided

    .EXAMPLE
    New-VcConnector -ManifestPath '/tmp/manifest.json'

    Create a new connector from a manifest which already contains deployment information

    .EXAMPLE
    New-VcConnector -ManifestPath '/tmp/manifest.json' -PassThru

    Create a new connector and return the newly created connector object

    .EXAMPLE
    New-VcConnector -ManifestPath '/tmp/manifest.json' -DeploymentImage 'docker.io/venafi/connector:latest@sha256:1234567890abcdef'

    Create a new connector from a manifest from the simulator

    .LINK
    https://developer.venafi.com/tlsprotectcloud/reference/post-v1-plugins

    #>

    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'FullManifest')]

    param (
        [Parameter(Mandatory, ParameterSetName = 'FromSimulator')]
        [Parameter(Mandatory, ParameterSetName = 'FullManifest')]
        [ValidateScript(
            {
                if ( -not ( Test-Path $_ ) ) {
                    throw "The manifest path $_ cannot be found"
                }
                $true
            }
        )]
        [string] $ManifestPath,

        [Parameter(Mandatory, ParameterSetName = 'FromSimulator')]
        [string] $DeploymentImage,

        [Parameter(ParameterSetName = 'FromSimulator')]
        [string] $Maintainer,

        [Parameter()]
        [switch] $PassThru,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {
        Test-VenafiSession $PSCmdlet.MyInvocation
    }

    process {

        $json = Get-Content -Path $ManifestPath -Raw

        $manifestObject = if ($PSVersionTable.PSVersion.Major -lt 6) {
            $hashtable = @{}
            (ConvertFrom-Json $json).psobject.properties | ForEach-Object { $hashtable[$_.Name] = $_.Value }
            $hashtable
        }
        else {
            $json | ConvertFrom-Json -AsHashtable
        }

        if ( $PSCmdlet.ParameterSetName -eq 'FromSimulator' ) {

            if ( $manifestObject.manifest -or !$manifestObject.name ) {
                throw 'This manifest is not from the simulator'
            }

            $manifestBody = @{
                pluginType = $manifestObject.pluginType
                manifest   = $manifestObject
            }
            $manifestBody.manifest | Add-Member @{'deployment' = @{
                    image             = $DeploymentImage
                    'executionTarget' = 'vsat'
                }
            }

            if ( $Maintainer ) {
                $manifestBody.maintainer = $Maintainer
            }
        }
        else {
            # full manifest with deployment details, validate we have the structure and data needed
            if ( !$manifestObject.manifest -or !$manifestObject.manifest.deployment ) {
                throw 'This is not the correct manifest structure.  See https://developer.venafi.com/tlsprotectcloud/reference/post-v1-plugins.'
            }
            $manifestBody = $manifestObject
        }

        $params = @{
            Method  = 'Post'
            UriLeaf = 'plugins'
            Body    = $manifestBody
        }

        if ( $PSCmdlet.ShouldProcess($manifestBody.manifest.name, 'Create connector') ) {

            try {
                $response = Invoke-VenafiRestMethod @params
                if ( $PassThru ) {
                    $response.plugins | Select-Object @{ 'n' = 'connectorId'; 'e' = { $_.Id } }, @{ 'n' = 'connectorType'; 'e' = { $_.pluginType } }, * -ExcludeProperty Id, pluginType
                }
            }
            catch {
                $PSCmdlet.ThrowTerminatingError($PSItem)
            }
        }
    }
}

