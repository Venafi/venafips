function Find-VcCertificateInstance {
    <#
    .SYNOPSIS
    Find certificate requests

    .DESCRIPTION
    Find certificate requests

    .PARAMETER Filter
    Array or multidimensional array of fields and values to filter on.
    Each array should be of the format @('operator', @(field, comparison operator, value), @(field2, comparison operator2, value2)).
    Nested filters are supported.
    For a complete list of comparison operators, see https://docs.venafi.cloud/api/about-api-search-operators/.
    To see which fields you can search on, execute Find-VcCertificateInstance -First 1.

    .PARAMETER Order
    Array of fields to order on.
    For each item in the array, you can provide a field name by itself; this will default to ascending.
    You can also provide a hashtable with the field name as the key and either asc or desc as the value.

    .PARAMETER HostName
    Hostname to find via regex match

    .PARAMETER IpAddress
    Machine IP Address

    .PARAMETER Port
    Machine port

    .PARAMETER Status
    Instance status, either IN_USE or SUPERSEDED

    .PARAMETER First
    Only retrieve this many records

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A Certificate Manager, SaaS key can also provided.

    .EXAMPLE
    Find-VcCertificateInstance

    Get all instancese

    .OUTPUTS

    #>

    [CmdletBinding(DefaultParameterSetName = 'SimpleFilter')]

    param (

        [Parameter(ParameterSetName = 'SimpleFilter')]
        [string] $HostName,

        [Parameter(ParameterSetName = 'SimpleFilter')]
        [ipaddress] $IpAddress,

        [Parameter(ParameterSetName = 'SimpleFilter')]
        [int] $Port,

        [Parameter(ParameterSetName = 'SimpleFilter')]
        [ValidateSet('IN_USE', 'SUPERSEDED')]
        [string] $Status,

        [Parameter(Mandatory, ParameterSetName = 'AdvancedFilter')]
        [System.Collections.Generic.List[object]] $Filter,

        [parameter()]
        [psobject[]] $Order,

        [Parameter()]
        [int] $First,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    Test-VenafiSession $PSCmdlet.MyInvocation

    $params = @{
        Type  = 'CertificateInstance'
        First = $First
    }

    if ( $Order ) { $params.Order = $Order }

    if ( $PSCmdlet.ParameterSetName -eq 'AdvancedFilter' ) {
        $params.Filter = $Filter
    }
    else {
        $newFilter = [System.Collections.Generic.List[object]]::new()
        $newFilter.Add('AND')

        switch ($PSBoundParameters.Keys) {
            'HostName' { $null = $newFilter.Add(@('hostname', 'FIND', $HostName)) }
            'IpAddress' { $null = $newFilter.Add(@('ipAddress', 'EQ', $IpAddress.IPAddressToString)) }
            'Port' { $null = $newFilter.Add(@('port', 'EQ', $Port.ToString())) }
            'Status' { $null = $newFilter.Add(@('deploymentStatus', 'EQ', $Status.ToUpper())) }
        }

        if ( $newFilter.Count -gt 1 ) { $params.Filter = $newFilter }
    }

    Find-VcObject @params
}

