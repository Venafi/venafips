function Find-VcLog {
    <#
    .SYNOPSIS
    Find log entries on TLSPC

    .DESCRIPTION
    Find log entries

    .PARAMETER Type
    One or more activity type, tab completion supported

    .PARAMETER Name
    One or more activity name, tab completion supported

    .PARAMETER Message
    Look anywhere in the message for the string provided

    .PARAMETER DateFrom
    Filter logs from this date/time.
    Combine with DateTo for a date range.

    .PARAMETER DateTo
    Filter logs to this date/time
    Combine with DateFrom for a date range.

    .PARAMETER Critical
    Filter logs by critical or not.

    .PARAMETER IncludeAny
    When using multiple filter parameters (Type, Name, Message, Criticality), combine them with OR logic instead of AND logic

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
    A TLSPC key can also provided.

    .OUTPUTS
    PSCustomObject
        activityLogId
        activityDate
        activityType
        activityName
        criticality
        message
        payload
        companyId

    .EXAMPLE
    Find-VcLog -First 10

    Get the most recent 10 log items

    .EXAMPLE
    Find-VcLog -Type 'Authentication'

    Filter log results by specific value

    .EXAMPLE
    Find-VcLog -DateFrom (Get-Date).AddDays(-7) -Message "certificate"

    Find all logs from the past week containing "certificate" in the message

    .EXAMPLE
    Find-VcLog -Type 'Authentication' -Message 'failed' -IncludeAny

    Find logs that are either Authentication type OR contain 'failed' in the message

    .EXAMPLE
    Find-VcLog -Filter @('and', @('activityDate', 'gt', (get-date).AddMonths(-1)), @('or', @('message', 'find', 'greg@venafi.com'), @('message', 'find', 'bob@venafi.com')), @('activityType','eq','Authentication'))

    Advanced filtering of results.
    This filter will find authentication log entries by 1 of 2 people within the last month.

    .EXAMPLE
    Find-VcLog -Type 'Authentication' -Order 'activityDate'

    Filter log results and order them.
    By default, order will be ascending.

    .EXAMPLE
    Find-VcLog -Type 'Authentication' -Order @{'activityDate'='desc'}

    Filter log results and order them descending

    .EXAMPLE
    Find-VcLog -Type 'Authentication' -Order @{'activityDate'='desc'}, 'criticality'

    Filter log results and order them by multiple fields

    .LINK
    https://api.venafi.cloud/webjars/swagger-ui/index.html?configUrl=/v3/api-docs/swagger-config#/Activity%20Logs/activitylogs_getByExpression

    #>

    [CmdletBinding(DefaultParameterSetName = 'SimpleFilter')]

    param (

        [Parameter(ParameterSetName = 'SimpleFilter')]
        [Alias('Type')]
        [string[]] $EventType,

        [Parameter(ParameterSetName = 'SimpleFilter')]
        [Alias('Name')]
        [string[]] $EventName,

        [Parameter(ParameterSetName = 'SimpleFilter')]
        [string] $Message,

        [Parameter(ParameterSetName = 'SimpleFilter')]
        [switch] $Critical,

        [Parameter(ParameterSetName = 'SimpleFilter')]
        [datetime] $DateFrom,

        [Parameter(ParameterSetName = 'SimpleFilter')]
        [datetime] $DateTo,

        [Parameter(ParameterSetName = 'SimpleFilter')]
        [switch] $IncludeAny,

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
        Type  = 'ActivityLog'
        First = $First
    }

    if ( $Order ) { $params.Order = $Order }

    if ( $PSCmdlet.ParameterSetName -eq 'AdvancedFilter' ) {
        $params.Filter = $Filter
    }
    else {
        # Build filter based on provided parameters
        $newFilter = [System.Collections.Generic.List[object]]::new()

        # Use OR or AND based on IncludeAny parameter
        if ($IncludeAny) {
            $newFilter.Add('OR')
        } else {
            $newFilter.Add('AND')
        }

        # Add simple filters based on parameters
        switch ($PSBoundParameters.Keys) {
            'Type' { $null = $newFilter.Add(@('activityType', 'IN', $Type)) }
            'Name' { $null = $newFilter.Add(@('activityName', 'IN', $Name)) }
            'Message' { $null = $newFilter.Add(@('message', 'FIND', $Message)) }
            'Critical' { $null = $newFilter.Add(@('criticality', 'IN', @([int]$Critical.IsPresent))) }
            'DateFrom' { $null = $newFilter.Add(@('activityDate', 'GTE', $DateFrom)) }
            'DateTo' { $null = $newFilter.Add(@('activityDate', 'LTE', $DateTo)) }
        }

        if ( $newFilter.Count -gt 1 ) { $params.Filter = $newFilter }
    }

    Find-VcObject @params
}

