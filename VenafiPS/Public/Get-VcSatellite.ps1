function Get-VcSatellite {
    <#
    .SYNOPSIS
    Get VSatellite info

    .DESCRIPTION
    Get 1 or more VSatellites.  Encyption key and algorithm will be included.

    .PARAMETER VSatellite
    VSatellite ID or name

    .PARAMETER All
    Get all VSatellites

    .PARAMETER IncludeWorkers
    Include VSatellite workers in the output

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A Certificate Manager, SaaS key can also provided.

    .INPUTS
    ID

    .EXAMPLE
    Get-VcSatellite -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2'

    vsatelliteId                : e2d60b61-9a8c-4a3a-985c-92498bd1fc77
    encryptionKey               : o4aFaJUTtCydprvb1jN15hIa5vJqFpQ1ZiY=
    encryptionKeyAlgorithm      : ED25519
    companyId                   : e2d60b61-9a8c-4a3a-985c-92498bd1fc77
    productEntitlements         : {ANY}
    environmentId               : ea2c3f80-658b-11eb-9bbd-338917ba2e36
    pairingCodeId               : e2d60b61-9a8c-4a3a-985c-92498bd1fc77
    name                        : VSatellite Hub 0001
    edgeType                    : HUB
    edgeStatus                  : ACTIVE
    clientId                    : e2d60b61-9a8c-4a3a-985c-92498bd1fc77
    modificationDate            : 6/15/2023 11:48:40 AM
    address                     : 1.2.3.4
    deploymentDate              : 6/15/2023 11:44:14 AM
    lastSeenOnDate              : 8/13/2023 8:00:06 AM
    reconciliationFailed        : False
    encryptionKeyId             : mwU4oTesrjyGBln0pZ8FkRfhek0UtvighIw=
    encryptionKeyDeploymentDate : 6/15/2023 11:48:40 AM
    kubernetesVersion           : v1.23.6+k3s1
    integrationServicesCount    : 0

    Get a single object by ID

    .EXAMPLE
    Get-VcSatellite -ID 'My Awesome App'

    Get a single object by name.  The name is case sensitive.

    .EXAMPLE
    Get-VcSatellite -All

    Get all VSatellites

    .EXAMPLE
    Get-VcSatellite -All -IncludeWorkers

    Get all VSatellites and include workers
    #>

    [CmdletBinding()]
    [Alias('Get-VaasSatellite')]

    param (

        [Parameter(Mandatory, ParameterSetName = 'ID', ValueFromPipelineByPropertyName)]
        [Alias('vsatelliteId', 'ID')]
        [string] $VSatellite,

        [Parameter(Mandatory, ParameterSetName = 'All')]
        [switch] $All,

        [Parameter()]
        [switch] $IncludeWorkers,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {
        Test-VenafiSession $PSCmdlet.MyInvocation
        $allKeys = Invoke-VenafiRestMethod -UriLeaf 'edgeencryptionkeys' | Select-Object -ExpandProperty encryptionKeys
    }

    process {
        if ( $PSCmdlet.ParameterSetName -eq 'All' ) {
            $response = Invoke-VenafiRestMethod -UriLeaf 'edgeinstances' | Select-Object -ExpandProperty edgeinstances
        }
        else {
            # if the value is a guid, we can look up the vsat directly otherwise get all and search by name
            if ( Test-IsGuid($VSatellite) ) {
                $guid = [guid] $VSatellite
                $response = Invoke-VenafiRestMethod -UriLeaf ('edgeinstances/{0}' -f $guid.ToString())
            }
            else {
                $response = Invoke-VenafiRestMethod -UriLeaf 'edgeinstances' | Select-Object -ExpandProperty edgeinstances | Where-Object { $_.name -eq $VSatellite }
            }
        }

        if ( -not $response ) { return }

        $out = $response | Select-Object @{'n' = 'vsatelliteId'; 'e' = { $_.Id } },
        @{
            'n' = 'encryptionKey'
            'e' = {
                $thisId = $_.encryptionKeyId
                                ($allKeys | Where-Object { $_.id -eq $thisId }).key
            }
        },
        @{
            'n' = 'encryptionKeyAlgorithm'
            'e' = {
                $thisId = $_.encryptionKeyId
                                ($allKeys | Where-Object { $_.id -eq $thisId }).KeyAlgorithm
            }
        }, * -ExcludeProperty Id

        if ( $IncludeWorkers ) {
            $out | Select-Object *, @{
                'n' = 'workers'
                'e' = {
                    Get-VcSatelliteWorker -VSatellite $_.vsatelliteId
                }
            }
        }
        else {
            $out
        }
    }
}

