function Find-VcMachineIdentity {
    <#
    .SYNOPSIS
    Find machine identities

    .DESCRIPTION
    Find machine identities

    .PARAMETER Status
    Search by one or more statuses.  Valid values are DISCOVERED, VALIDATED, and INSTALLED

    .PARAMETER Machine
    Search by machine name or ID

    .PARAMETER Certificate
    Search by certificate name or ID

    .PARAMETER Filter
    Array or multidimensional array of fields and values to filter on.
    Each array should be of the format @('operator', @(field, comparison operator, value), @(field2, comparison operator2, value2)).
    Nested filters are supported.
    For a complete list of comparison operators, see https://docs.venafi.cloud/api/about-api-search-operators/.

    .PARAMETER Order
    Array of fields to order on.
    For each item in the array, you can provide a field name by itself; this will default to ascending.
    You can also provide a hashtable with the field name as the key and either asc or desc as the value.

    .PARAMETER First
    Only retrieve this many records

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A Certificate Manager, SaaS key can also provided.

    .EXAMPLE
    Find-VcMachineIdentity

    Get all machine identities

    .OUTPUTS
    pscustomobject
    #>

    [CmdletBinding(DefaultParameterSetName = 'All')]

    param (

        [Parameter(ParameterSetName = 'All')]
        [ValidateSet('DISCOVERED', 'VALIDATED', 'INSTALLED')]
        [string[]] $Status,

        [Parameter(ParameterSetName = 'All')]
        [string] $Machine,

        [Parameter(ParameterSetName = 'All')]
        [string] $Certificate,

        [Parameter(Mandatory, ParameterSetName = 'Filter')]
        [System.Collections.Generic.List[object]] $Filter,

        [parameter()]
        [psobject[]] $Order,

        [Parameter()]
        [int] $First,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )


    $params = @{
        Type  = 'MachineIdentity'
        First = $First
    }

    if ( $Order ) { $params.Order = $Order }

    if ( $PSCmdlet.ParameterSetName -eq 'Filter' ) {
        $params.Filter = $Filter
    }
    else {
        $newFilter = [System.Collections.Generic.List[object]]::new()

        switch ($PSBoundParameters.Keys) {
            'Status' {
                $newFilter.Add(@('status', 'MATCH', $Status.ToUpper()))
            }

            'Machine' {
                $machineId = Get-VcData -Type Machine -InputObject $Machine -FailOnNotFound
                $newFilter.Add(@('machineId', 'eq', $machineId))
            }

            'Certificate' {
                $certId = Get-VcData -Type Certificate -InputObject $Certificate -FailOnNotFound
                $newFilter.Add(@('certificateId', 'in', $certId))
            }
        }

        if ( $newFilter.Count -gt 0 ) {
            $params.Filter = $newFilter
        }
    }

    Find-VcObject @params
}

