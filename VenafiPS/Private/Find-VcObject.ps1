function Find-VcObject {
    <#
    .SYNOPSIS
    Find different objects on Certificate Manager, SaaS

    .DESCRIPTION
    Find objects of type ActivityLog, Machine, MachineIdentity, CertificateRequest, CertificateInstance on Certificate Manager, SaaS.
    Supports -First for page size; the max page size is 1000.
    To find certificate objects, use Find-VcCertificate.

    .PARAMETER Type
    Type of object to retrieve, either Certificate, ActivityLog, Machine, MachineIdentity, CertificateRequest, or CertificateInstance.

    .PARAMETER Name
    Case sensitive name to search for.
    The field to be searched is different for each object type.

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

    .OUTPUTS
    PSCustomObject

    .EXAMPLE
    Find-VcObject -Type CertificateInstance

    Get all records

    .EXAMPLE
    Find-VcObject -Type CertificateInstance -First 50

    Get first 50 records

    .EXAMPLE
    Find-VcObject -Type ActivityLog -Filter @('activityType', 'eq', 'Notifications') -First 10

    Retrieve 10 records matching the field name

    .EXAMPLE
    Find-VcObject -Type Certificate -Name searchme

    Get all certificates where the name has 'searchme' in it

    .EXAMPLE
    Find-VcObject -type Certificate -filter @('selfSigned','eq','True')

    Get all self signed certificates

    .EXAMPLE
    Find-VcObject -Type ActivityLog -Filter @('activityType', 'eq', 'Notifications') -First 10 -Order @{'activityDate'='desc'}

    Retrieve the most recent 10 records matching the field name

    .EXAMPLE
    Find-VcObject -Filter @('and', @('activityDate', 'gt', (get-date).AddMonths(-1)), @('or', @('userId', 'eq', 'ab0feb46-8df7-47e7-8da9-f47ab314f26a'), @('userId', 'eq', '933c28de-6352-46f3-bc12-bd96077e8eae')))

    Advanced filtering of results.  This filter will find log entries by 1 of 2 people within the last month.

    .LINK
    https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Private/Find-VcObject.ps1
    #>

    [CmdletBinding(DefaultParameterSetName = 'All')]

    param (

        [Parameter(Mandatory)]
        [ValidateSet('Certificate', 'ActivityLog', 'Machine', 'MachineIdentity', 'CertificateRequest', 'CertificateInstance')]
        [string] $Type,

        [Parameter(ParameterSetName = 'All')]
        [string] $Name,

        [Parameter(Mandatory, ParameterSetName = 'Filter')]
        [System.Collections.Generic.List[object]] $Filter,
        # [System.Collections.ArrayList] $Filter,

        [Parameter(ParameterSetName = 'All')]
        [Parameter(ParameterSetName = 'Filter')]
        [psobject[]] $Order,

        [parameter(Mandatory, ParameterSetName = 'SavedSearch')]
        [string] $SavedSearchName,

        [Parameter()]
        [int] $First,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    Test-VenafiSession $PSCmdlet.MyInvocation

    $objectData = @{
        'Certificate'         = @{
            'uriroot'  = 'outagedetection/v1'
            'urileaf'  = 'certificatesearch'
            'property' = 'certificates'
            'filter'   = @{
                Property        = @{'n' = 'certificateId'; 'e' = { $_.Id } }
                ExcludeProperty = 'id'
            }
            'name'     = 'certificateName'
        }
        'CertificateRequest'  = @{
            'uriroot'  = 'outagedetection/v1'
            'urileaf'  = 'certificaterequestssearch'
            'property' = 'certificaterequests'
            'filter'   = @{
                Property        = @{'n' = 'certificateRequestId'; 'e' = { $_.Id } }
                ExcludeProperty = 'id'
            }
            'name'     = 'subjectDN'
        }
        'CertificateInstance' = @{
            'uriroot'  = 'outagedetection/v1'
            'urileaf'  = 'certificateinstancesearch'
            'property' = 'instances'
            'filter'   = ''
            'name'     = 'hostname'
        }
        'Machine'             = @{
            'uriroot'  = 'v1'
            'urileaf'  = 'machinesearch'
            'property' = 'machines'
            'filter'   = @{
                Property        = @{'n' = 'machineId'; 'e' = { $_.Id } }
                ExcludeProperty = 'id'
            }
            'name'     = 'machineName'
        }
        'MachineIdentity'     = @{
            'uriroot'  = 'v1'
            'urileaf'  = 'machineidentitysearch'
            'property' = 'machineidentities'
            'filter'   = @{
                Property        = @{'n' = 'machineIdentityId'; 'e' = { $_.Id } }
                ExcludeProperty = 'id'
            }
            'name'     = 'certificateName'
        }
        'ActivityLog'         = @{
            'uriroot'  = 'v1'
            'urileaf'  = 'activitylogsearch'
            'property' = 'activityLogEntries'
            'filter'   = @{
                Property        = @{'n' = 'activityLogId'; 'e' = { $_.Id } }
                ExcludeProperty = 'id'
            }
            'name'     = 'activityName'
        }
    }

    $queryParams = @{
        Filter = $Filter
        Order  = $Order
        First  = $First
    }

    if ($Name) {
        $queryParams.Filter = @($objectData.$Type.name, 'FIND', $Name)
    }

    $body = New-VcSearchQuery @queryParams

    if ( $PSBoundParameters.ContainsKey('SavedSearchName') ) {
        # get saved search data and update payload
        $thisSavedSearch = Invoke-VenafiRestMethod -UriRoot 'outagedetection/v1' -UriLeaf 'savedsearches' | Select-Object -ExpandProperty savedSearchInfo | Where-Object name -eq $SavedSearchName
        if ( $thisSavedSearch ) {
            $body.expression = $thisSavedSearch.searchDetails.expression
            $body.ordering = $thisSavedSearch.searchDetails.ordering
        }
        else {
            throw "The saved search name $SavedSearchName could not be found"
        }
    }

    $params = @{
        Method = 'Post'
        Body   = $body
        Header = @{'Accept' = 'application/json' }
    }

    $params.UriRoot = $objectData.$Type.uriroot
    $params.UriLeaf = $objectData.$Type.urileaf

    $params.UriLeaf += '?ownershipTree=true'
    $allObjects = [System.Collections.Generic.List[object]]::new()

    do {

        $response = Invoke-VenafiRestMethod @params

        if ( -not $response ) { continue }

        $thisObjects = $response | Select-Object -ExpandProperty $objectData.$Type.property

        if ( -not $thisObjects ) { break }

        $allObjects.AddRange(@($thisObjects))

        if ( $thisObjects.Count -lt $params.Body.paging.pageSize ) { break }

        if ( $First ) {
            # break out if we have all the objects we asked for
            if ( $allObjects.Count -eq $First ) {
                break
            }
            else {
                $params.Body.paging.pageSize = [System.Math]::Min($First - $allObjects.Count, 1000)
            }
        }

        $params.body.paging.pageNumber += 1

    } while ( $true )

    if ( $objectData.$Type.filter ) {
        $allObjects | Select-Object -Property $objectData.$Type.filter.Property, * -ExcludeProperty $objectData.$Type.filter.ExcludeProperty
    }
    else {
        $allObjects
    }
}
