function Get-VcSatelliteWorker {
    <#
    .SYNOPSIS
    Get VSatellite worker info

    .DESCRIPTION
    Get 1 or more VSatellite workers, the bridge between a vsatellite and ADCS

    .PARAMETER ID
    VSatellite worker ID

    .PARAMETER All
    Get all VSatellite workers

    .PARAMETER VSatellite
    Get workers associated with a specific VSatellite, specify either VSatellite ID or name

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A Certificate Manager, SaaS key can also provided.

    .INPUTS
    ID, VSatelliteID

    .EXAMPLE
    Get-VcSatelliteWorker -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2'

    vsatelliteWorkerId : 5df78790-a155-11ef-a5a8-8f3513444123
    companyId          : 09b24f81-b22b-11ea-91f3-123456789098
    host               : 1.2.3.4
    port               : 555
    pairingCode        : a138fe58-ecb6-45a4-a9af-01dd4d5c74d1
    pairingPublicKey   : FDww6Nml8IUFQZ56j9LRweEWoCQ1732wi/ZfZaQj+s0=
    status             : DRAFT

    Get a single worker by ID

    .EXAMPLE
    Get-VcSatelliteWorker -All

    Get all VSatellite workers

    .EXAMPLE
    Get-VcSatelliteWorker -VSatellite 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f3'

    Get all workers associated with a specific VSatellite

    #>

    [CmdletBinding()]

    param (

        [Parameter(Mandatory, ParameterSetName = 'ID', ValueFromPipelineByPropertyName)]
        [Alias('vsatelliteWorkerId')]
        [guid] $ID,

        [Parameter(Mandatory, ParameterSetName = 'All')]
        [switch] $All,

        [Parameter(Mandatory, ParameterSetName = 'VSatellite', ValueFromPipelineByPropertyName)]
        [Alias('vsatelliteId')]
        [string] $VSatellite,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {
        Test-VenafiSession $PSCmdlet.MyInvocation
    }

    process {

        switch ($PSCmdlet.ParameterSetName) {
            'All' {
                $response = Invoke-VenafiRestMethod -UriLeaf 'edgeworkers' | Select-Object -ExpandProperty edgeWorkers
            }

            'ID' {
                $guid = [guid] $ID
                $response = Invoke-VenafiRestMethod -UriLeaf ('edgeworkers/{0}' -f $guid.ToString())
            }

            'VSatellite' {
                # limit workers retrieved by the vsat they are associated with

                # if the value is a guid, we can look up the vsat directly otherwise get all and search by name
                $vsatelliteId = if ( Test-IsGuid($VSatellite) ) {
                    $guid = [guid] $VSatellite
                    $guid.ToString()
                }
                else {
                    Invoke-VenafiRestMethod -UriLeaf 'edgeinstances' | Select-Object -ExpandProperty edgeInstances | Where-Object { $_.name -eq $VSatellite } | Select-Object -ExpandProperty id
                }

                $response = Invoke-VenafiRestMethod -UriLeaf 'edgeworkers' -Body @{'edgeInstanceId' = $vsatelliteID } | Select-Object -ExpandProperty edgeWorkers
            }
        }

        if ( -not $response ) { return }

        $response | Select-Object `
        @{'n' = 'vsatelliteWorkerId'; 'e' = { $_.Id } },
        @{'n' = 'vsatelliteId'; 'e' = { $_.edgeInstanceId } }, * -ExcludeProperty Id, edgeInstanceId
    }
}

