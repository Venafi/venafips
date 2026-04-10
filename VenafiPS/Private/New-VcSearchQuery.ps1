function New-VcSearchQuery {
    <#
    .SYNOPSIS
        Build body for various vaas api calls

    .DESCRIPTION
        Build body for various api calls, typically for searching, eg. certificates, logs.

    .PARAMETER Filter
        Array or multidimensional array of fields and values to filter on.
        Each array should be of the format @('operator', @(field, comparison operator, value), @(field2, comparison operator2, value2)).
        Nested filters are supported.
        For a complete list of comparison operators, see https://docs.venafi.cloud/api/about-api-search-operators/.

    .PARAMETER Order
        Array or multidimensional array of fields to Order on.
        Each array should be of the format @(field, asc/desc).
        If just the field name is provided, ascending will be used.

    .EXAMPLE
    New-VcSearchQuery -Filter @('authenticationType', 'eq', 'NONE')
    Filter log results

    .OUTPUTS
    Hashtable
    #>

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'No state is actually changing')]

    [CmdletBinding()]
    [OutputType([Hashtable])]

    param(

        [parameter()]
        [System.Collections.Generic.List[object]] $Filter,

        [parameter()]
        [psobject[]] $Order,

        [Parameter()]
        [int] $First
    )

    begin {

        $operators = 'EQ', 'FIND', 'GT', 'GTE', 'IN', 'LT', 'LTE', 'MATCH'

        $query = @{
            'expression' = @{}
            'ordering'   = @{}
            'paging'     = @{}
        }

        $vaasPageSizeLimit = 1000

        if ( $First -le 0 ) {
            $First = $vaasPageSizeLimit
        }

        $query.paging.Add('pageSize', [Math]::Min($First, $vaasPageSizeLimit))

        $query.paging.Add('pageNumber', 0)

        function New-VaasExpression {
            [CmdletBinding()]
            param (
                [parameter()]
                [System.Collections.Generic.List[object]] $Filter
            )

            $loopFilter = $Filter
            $operator = $null

            # first item may be the operator or a filter
            # if so, pull it off the list and process the rest
            if ($Filter[0] -is 'String' -and $Filter[0] -in 'AND', 'OR') {
                $operator = $Filter[0].ToUpper()
                $loopFilter.RemoveAt(0)
            }

            $operands = foreach ($thisItem in $loopFilter) {
                if ( $thisItem.count -eq 3 ) {

                    # handle nested expressions
                    if ( $thisItem[2] -is 'Object[]' -and $thisItem[2][1] -in $operators ) {
                        New-VaasExpression -Filter $thisItem
                    }

                    # vaas fields are case sensitive, get the proper case if we're aware of the field
                    $thisField = $thisItem[0]
                    $thisFieldCased = $vaasFields | Where-Object { $_.ToLower() -eq $thisField.ToLower() }

                    $newOperand = @{
                        'field'    = if ($thisFieldCased) { $thisFieldCased } else { $thisField }
                        'operator' = $thisItem[1].ToUpper()
                    }

                    # handle different value types
                    # note the use of property 'values' for an array, eg. when the operator is find, in, match
                    switch ($thisItem[2].GetType().Name) {
                        'DateTime' {
                            $newOperand.Add('value', ($thisItem[2] | ConvertTo-UtcIso8601))
                            break
                        }

                        'String' {
                            $newValue = $thisItem[2]
                            # these values should be upper case, fix in case not provided that way
                            if ( $newOperand.field.ToLower() -in $vaasValuesToUpper.ToLower() ) {
                                $newValue = $thisItem[2].ToUpper()
                            }
                            $newOperand.Add('value', $newValue)
                            break
                        }

                        Default {
                            # we have a list
                            $newOperand.Add('values', $thisItem[2])
                        }
                    }

                    $newOperand
                }
                else {
                    New-VaasExpression -Filter $thisItem
                }

            }

            if ( $Filter.Count -gt 1 -and $Filter[0] -notin 'AND', 'OR' ) {
                $operator = 'AND'
            }

            if ( $operator ) {
                @{
                    'operator' = $operator
                    'operands' = @($operands)
                }
            }
            else {
                $operands
            }
        }
    }

    process {

        if ( $Filter ) {
            $thisFilter = $Filter
            # if we have a basic filter of field, operator, value, force it to be a 1 item array intead of 3 items
            if ( $Filter.Count -eq 3 -and -not ($Filter | Where-Object { $_ -isnot [string] })) {
                $thisFilter = @(, $Filter)
            }
            $query.expression = New-VaasExpression -Filter $thisFilter
        }


        if ( $Order ) {
            $query.ordering.Add('orders', @())

            # @($Order) | ForEach-Object {
            foreach ($thisOrder in $Order) {
                # $thisOrder = $_
                switch ($thisOrder.GetType().Name) {
                    'String' {
                        $thisOrderCased = $vaasFields | Where-Object { $_.ToLower() -eq $thisOrder.ToLower() }

                        $query.ordering.orders += @{
                            'field'     = if ($thisOrderCased) { $thisOrderCased } else { $thisOrder }
                            'direction' = 'ASC'
                        }
                        break
                    }

                    'HashTable' {
                        if ( $thisOrder.Values[0] -notin 'asc', 'desc' ) {
                            throw ('Invalid order direction, {0}.  Provide either ''asc'' or ''desc''' -f $thisOrder.Values[0])
                        }

                        $thisOrderCased = $vaasFields | Where-Object { $_.ToLower() -eq $thisOrder.Keys[0].ToLower() }

                        $query.ordering.orders += @{
                            'field'     = if ($thisOrderCased) { $thisOrderCased } else { $thisOrder.Keys[0] }
                            'direction' = $thisOrder.Values[0].ToUpper()
                        }
                        break
                    }

                    Default {
                        throw 'Invalid format for Order'
                    }
                }
            }
        }
        $query
    }
}
