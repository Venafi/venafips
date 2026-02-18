function Find-VcMachine {
    <#
    .SYNOPSIS
    Find machines

    .DESCRIPTION
    Find machines

    .PARAMETER Filter
    Array or multidimensional array of fields and values to filter on.
    Each array should be of the format @('operator', @(field, comparison operator, value), @(field2, comparison operator2, value2)).
    Nested filters are supported.
    For a complete list of comparison operators, see https://docs.venafi.cloud/api/about-api-search-operators/.

    .PARAMETER Order
    Array of fields to order on.
    For each item in the array, you can provide a field name by itself; this will default to ascending.
    You can also provide a hashtable with the field name as the key and either asc or desc as the value.

    .PARAMETER Name
    Machine name to find via regex match

    .PARAMETER MachineType
    Machine type.  You can use tab-ahead autocompletion for a list.

    .PARAMETER Status
    Machine status, either DRAFT, VERIFIED, OR UNVERIFIED.

    .PARAMETER First
    Only retrieve this many records

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A Certificate Manager, SaaS key can also provided.

    .EXAMPLE
    Find-VcMachine

    Get all machines

    .OUTPUTS

    #>

    [CmdletBinding(DefaultParameterSetName = 'All')]

    param (

        [Parameter(ParameterSetName = 'All')]
        [string] $Name,

        [Parameter(ParameterSetName = 'All')]
        [Alias('Type')]
        [string] $MachineType,

        [Parameter(ParameterSetName = 'All')]
        [ValidateSet('DRAFT', 'VERIFIED', 'UNVERIFIED')]
        [string] $Status,

        [Parameter(Mandatory, ParameterSetName = 'Filter')]
        [System.Collections.Generic.List[object]] $Filter,

        [Parameter()]
        [psobject[]] $Order,

        [Parameter()]
        [int] $First,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    Test-VenafiSession $PSCmdlet.MyInvocation

    $params = @{
        Type  = 'Machine'
        First = $First
    }

    if ( $Order ) { $params.Order = $Order }

    if ( $PSCmdlet.ParameterSetName -eq 'Filter' ) {
        $params.Filter = $Filter
    }
    else {
        $newFilter = [System.Collections.Generic.List[object]]::new()
        $newFilter.Add('AND')

        switch ($PSBoundParameters.Keys) {
            'Name' { $null = $newFilter.Add(@('machineName', 'FIND', $Name)) }
            'MachineType' { $null = $newFilter.Add(@('pluginName', 'EQ', $MachineType)) }
            'Status' { $null = $newFilter.Add(@('status', 'EQ', $Status.ToUpper())) }
        }

        if ( $newFilter.Count -gt 1 ) { $params.Filter = $newFilter }
    }

    Find-VcObject @params

}

