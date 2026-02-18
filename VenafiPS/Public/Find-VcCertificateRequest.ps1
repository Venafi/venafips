function Find-VcCertificateRequest {
    <#
    .SYNOPSIS
    Find certificate requests

    .DESCRIPTION
    Find certificate requests via fields directly or provide a string filter

    .PARAMETER Status
    Request status, one of 'NEW', 'PENDING', 'PENDING_APPROVAL', 'PENDING_FINAL_APPROVAL', 'REJECTED_APPROVAL', 'REQUESTED', 'ISSUED', 'REJECTED', 'CANCELLED', 'REVOKED', 'FAILED', 'DELETED'

    .PARAMETER Application
    One or more application id or names

    .PARAMETER User
    One or more owner user id or usernames

    .PARAMETER IssuingTemplate
    One or more issuing template id or names

    .PARAMETER CreateDateFrom
    Filter certificate requests from this date/time and forward

    .PARAMETER KeyLength
    Certificate key length

    .PARAMETER IncludeAny
    When using multiple filter parameters, combine them with OR logic instead of AND logic

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
    Find-VcCertificateRequest

    Get all certificate requests

    .EXAMPLE
    Find-VcCertificateRequest -Application 'MyApp' -CreateDateFrom (Get-Date).AddDays(-7)

    Find requests for a specific application created in the last 7 days

    .OUTPUTS

    #>

    [CmdletBinding(DefaultParameterSetName = 'SimpleFilter')]

    param (

        [Parameter(ParameterSetName = 'SimpleFilter')]
        [ValidateSet('NEW', 'PENDING', 'PENDING_APPROVAL', 'PENDING_FINAL_APPROVAL', 'REJECTED_APPROVAL', 'REQUESTED', 'ISSUED', 'REJECTED', 'CANCELLED', 'REVOKED', 'FAILED', 'DELETED')]
        [string[]] $Status,

        [Parameter(ParameterSetName = 'SimpleFilter')]
        [string[]] $Application,

        [Parameter(ParameterSetName = 'SimpleFilter')]
        [string[]] $User,

        [Parameter(ParameterSetName = 'SimpleFilter')]
        [string[]] $IssuingTemplate,

        [Parameter(ParameterSetName = 'SimpleFilter')]
        [int] $KeyLength,

        [Parameter(ParameterSetName = 'SimpleFilter')]
        [datetime] $CreateDateFrom,

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
        Type  = 'CertificateRequest'
        First = $First
    }

    if ( $Order ) { $params.Order = $Order }

    if ( $PSCmdlet.ParameterSetName -eq 'AdvancedFilter' ) {
        $params.Filter = $Filter
    }
    else {
        $newFilter = [System.Collections.Generic.List[object]]::new()
        # Use OR or AND based on IncludeAny parameter
        if ($IncludeAny) {
            $newFilter.Add('OR')
        }
        else {
            $newFilter.Add('AND')
        }


        switch ($PSBoundParameters.Keys) {
            'Status' { $null = $newFilter.Add(@('status', 'IN', $Status.ToUpper())) }
            'KeyLength' { $null = $newFilter.Add(@('keyLength', 'EQ', $KeyLength.ToString())) }
            'Application' { $null = $newFilter.Add(@('applicationId', 'IN', @(($Application | Get-VcData -Type Application)))) }
            'User' { $null = $newFilter.Add(@('certificateOwnerUserId', 'MATCH', @(($User | Get-VcData -Type User)))) }
            'IssuingTemplate' { $null = $newFilter.Add(@('certificateIssuingTemplateId', 'MATCH', @(($IssuingTemplate | Get-VcData -Type IssuingTemplate)))) }
            'CreateDateFrom' { $null = $newFilter.Add(@('creationDate', 'GTE', $CreateDateFrom)) }
        }

        if ( $newFilter.Count -gt 1 ) { $params.Filter = $newFilter }
    }

    Find-VcObject @params

}

