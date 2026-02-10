function Find-VcCertificate {
    <#
    .SYNOPSIS
    Find certificates in Certificate Manager, SaaS

    .DESCRIPTION
    Find certificates based on various attributes.

    .PARAMETER Name
    Search for certificates with the name matching part or all of the value

    .PARAMETER KeyLength
    Search by certificate key length

    .PARAMETER Serial
    Search by serial number

    .PARAMETER Fingerprint
    Search by fingerprint

    .PARAMETER IsSelfSigned
    Search for only self signed certificates

    .PARAMETER IsExpired
    Search for only expired certificates.
    This will search for only certificates that are expired including active, retired, current, old, etc.
    Use -IsExpired:$false for certificates that are NOT expired.

    .PARAMETER Status
    Search by one or more certificate statuses.  Valid values include ACTIVE, RETIRED, and DELETED.

    .PARAMETER ExpireBefore
    Search for certificates expiring before a certain date.
    Use with -ExpireAfter for a defined start and end.

    .PARAMETER ExpireAfter
    Search for certificates expiring after a certain date.
    Use with -ExpireBefore for a defined start and end.

    .PARAMETER VersionType
    Search by version type.  Valid values include CURRENT and OLD.

    .PARAMETER SanDns
    Search for certificates with SAN DNS matching part or all of the value

    .PARAMETER Application
    Application ID or name that this certificate is associated with.
    Use Tab Completion to see available applications.

    .PARAMETER Tag
    One or more tags associated with the certificate.
    You can specify either just a tag name or name:value.

    .PARAMETER CN
    Search for certificates where the subject CN matches all of part of the value

    .PARAMETER Issuer
    Search by issuer name

    .PARAMETER IncludeAny
    When using multiple filter parameters, combine them with OR logic instead of AND logic

    .PARAMETER Filter
    Array or multidimensional array of fields and values to filter on.
    Each array should be of the format @(field, comparison operator, value).
    To combine filters, use the format @('operator', @(field, comparison operator, value), @(field2, comparison operator2, value2)).
    Nested filters are supported.
    Field names and values are case sensitive, but VenafiPS will try and convert to the proper case if able.

    Available operators are:

    Operator    |	Name                    |	Description and Usage
    -----------------------------------------------------------------------------------
    EQ              Equal operator              The search result is equal to the specified value. Valid for numeric or Boolean fields.
    FIND            Find operator               The search result is based on the value of all or part of one or more strings. You can also use Regular Expressions (regex).
    GT              Greater than                The search result has a higher numeric value than the specified value.
    GTE             Greater than or equal to    The search result is equal or has a higher numeric value than the specified value.
    IN              In clause                   The search result matches one of the values in an array.
    LT              Less Than                   The search result has a lower value than the specified value.
    LTE             Less than or equal to       The search result is equal or less than the specified value.
    MATCH           Match operator              The search result includes a string value from the supplied list. You can also use regex for your search.

    For more info comparison operators, see https://docs.venafi.cloud/api/about-api-search-operators/.

    .PARAMETER Order
    1 or more fields to order on.
    For each item in the array, you can provide a field name by itself; this will default to ascending.
    You can also provide a hashtable with the field name as the key and either asc or desc as the value.

    .PARAMETER SavedSearchName
    Find certificates based on a saved search, see https://docs.venafi.cloud/vaas/certificates/saving-certificate-filters

    .PARAMETER First
    Only retrieve this many records

    .PARAMETER ApplicationDetail
    Retrieve detailed application info.
    This will cause additional api calls to be made and take longer.

    .PARAMETER OwnerDetail
    Retrieve detailed user/team owner info.
    This will cause additional api calls to be made and take longer.

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A Certificate Manager, SaaS key can also provided.

    .INPUTS
    None

    .OUTPUTS
    PSCustomObject

    .EXAMPLE
    Find-VcCertificate

    Find all certificates

    .EXAMPLE
    Find-VcCertificate -First 500

    Find the first 500 certificates

    .EXAMPLE
    Find-VcCertificate -Name 'mycert.company.com'

    Find certificates matching all of part of the name

    .EXAMPLE
    Find-VcCertificate -Fingerprint '075C43428E70BCF941039F54B8ED78DE4FACA87F'

    Find certificates matching a single value

    .EXAMPLE
    Find-VcCertificate -ExpireAfter (get-date) -ExpireBefore (get-date).AddDays(30)

    Find certificates matching multiple values.  In this case, find all certificates expiring in the next 30 days.

    .EXAMPLE
    Find-VcCertificate -ExpireAfter (get-date) -ExpireBefore (get-date).AddDays(30)| Invoke-VcCertificateAction -Renew

    Find all certificates expiring in the next 30 days and renew them

    .EXAMPLE
    Find-VcCertificate -Filter @('subjectDN', 'FIND', 'www.barron.com')

    Find via a filter instead of using built-in function properties

    .EXAMPLE
    Find-VcCertificate -ApplicatonDetail

    Include application details, not just the ID.
    This will make additional api calls and will increase the response time.

    .EXAMPLE
    Find-VcCertificate -OwnerDetail

    Include user/team owner details, not just the ID.
    This will make additional api calls and will increase the response time.
    #>

    [CmdletBinding(DefaultParameterSetName = 'SimpleFilter')]

    param (

        [Parameter(ParameterSetName = 'SimpleFilter')]
        [string] $Name,

        [Parameter(ParameterSetName = 'SimpleFilter')]
        [int32] $KeyLength,

        [Parameter(ParameterSetName = 'SimpleFilter')]
        [string] $Serial,

        [Parameter(ParameterSetName = 'SimpleFilter')]
        [string] $Fingerprint,

        [Parameter(ParameterSetName = 'SimpleFilter')]
        [switch] $IsSelfSigned,

        [Parameter(ParameterSetName = 'SimpleFilter')]
        [switch] $IsExpired,

        [Parameter(ParameterSetName = 'SimpleFilter')]
        [ValidateSet('ACTIVE', 'RETIRED', 'DELETED')]
        [string[]] $Status,

        [Parameter(ParameterSetName = 'SimpleFilter')]
        [datetime] $ExpireBefore,

        [Parameter(ParameterSetName = 'SimpleFilter')]
        [datetime] $ExpireAfter,

        [Parameter(ParameterSetName = 'SimpleFilter')]
        [ValidateSet('CURRENT', 'OLD')]
        [Alias('Version')]
        [string] $VersionType,

        [Parameter(ParameterSetName = 'SimpleFilter')]
        [string] $SanDns,

        [Parameter(ParameterSetName = 'SimpleFilter')]
        [ValidateNotNullOrEmpty()]
        [string[]] $Application,

        [Parameter(ParameterSetName = 'SimpleFilter')]
        [string[]] $Tag,

        [Parameter(ParameterSetName = 'SimpleFilter')]
        [string] $CN,

        [Parameter(ParameterSetName = 'SimpleFilter')]
        [string] $Issuer,

        [Parameter(ParameterSetName = 'SimpleFilter')]
        [switch] $IncludeAny,

        [Parameter(Mandatory, ParameterSetName = 'AdvancedFilter')]
        [System.Collections.Generic.List[object]] $Filter,

        [Parameter()]
        [psobject[]] $Order,

        [parameter(Mandatory, ParameterSetName = 'SavedSearch')]
        [string] $SavedSearchName,

        [Parameter()]
        [switch] $ApplicationDetail,

        [Parameter()]
        [Alias('IncludeVaasOwner')]
        [switch] $OwnerDetail,

        [Parameter()]
        [int] $First,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    Test-VenafiSession $PSCmdlet.MyInvocation

    $apps = [System.Collections.Generic.List[object]]::new()
    $appOwners = [System.Collections.Generic.List[object]]::new()

    $params = @{
        Type  = 'Certificate'
        First = $First
    }

    if ( $Order ) { $params.Order = $Order }

    switch ($PSCmdlet.ParameterSetName) {
        'AdvancedFilter' {
            $params.Filter = $Filter
            break
        }

        'SimpleFilter' {
            $newFilter = [System.Collections.Generic.List[object]]::new()
            # Use OR or AND based on IncludeAny parameter
            if ($IncludeAny) {
                $newFilter.Add('OR')
            }
            else {
                $newFilter.Add('AND')
            }

            switch ($PSBoundParameters.Keys) {
                'Name' { $null = $newFilter.Add(@('certificateName', 'FIND', $Name)) }
                'KeyLength' { $null = $newFilter.Add(@('keyStrength', 'EQ', $KeyLength.ToString())) }
                'Serial' { $null = $newFilter.Add(@('serialNumber', 'EQ', $Serial)) }
                'Fingerprint' { $null = $newFilter.Add(@('fingerprint', 'EQ', $Fingerprint)) }
                'IsSelfSigned' { $null = $newFilter.Add(@('selfSigned', 'EQ', $IsSelfSigned.IsPresent.ToString())) }
                'IsExpired' {
                    if ( $IsExpired.IsPresent ) {
                        $null = $newFilter.Add(@('validityEnd', 'LT', (Get-Date)))
                        $params.Order = @{'validityEnd' = 'desc' }
                    }
                    else {
                        $null = $newFilter.Add(@('validityEnd', 'GTE', (Get-Date)))
                        $params.Order = @{'validityEnd' = 'asc' }
                    }
                }
                'VersionType' { $null = $newFilter.Add(@('versionType', 'MATCH', $VersionType)) }
                'Status' {
                    $null = $newFilter.Add(@('certificateStatus', 'MATCH', $Status.ToUpper()))
                }
                'ExpireBefore' { $null = $newFilter.Add(@('validityEnd', 'LTE', $ExpireBefore)) }
                'ExpireAfter' { $null = $newFilter.Add(@('validityEnd', 'GTE', $ExpireAfter)) }
                'SanDns' { $null = $newFilter.Add(@('subjectAlternativeNameDns', 'FIND', $SanDns)) }
                'CN' { $null = $newFilter.Add(@('subjectCN', 'FIND', $CN)) }
                'Issuer' { $null = $newFilter.Add(@('issuerCN', 'FIND', $Issuer)) }
                'Application' { $null = $newFilter.Add(@('applicationIds', 'IN', @(($Application | Get-VcData -Type Application)))) }
                'Tag' {
                    $null = $newFilter.Add(@('tags', 'MATCH', $Tag))
                }
            }

            if ( $newFilter.Count -gt 1 ) { $params.Filter = $newFilter }
        }

        'SavedSearch' {
            $params.SavedSearchName = $SavedSearchName
            break
        }
    }
    $response = Find-VcObject @params

    $response | Select-Object *,
    @{
        'n' = 'application'
        'e' = {
            if ( $ApplicationDetail ) {
                foreach ($thisAppId in $_.applicationIds) {
                    $thisApp = $apps | Where-Object applicationId -eq $thisAppId
                    if ( -not $thisApp ) {
                        $thisApp = Get-VcApplication -ID $thisAppId | Select-Object -Property * -ExcludeProperty ownerIdsAndTypes, ownership
                        $apps.Add($thisApp)
                    }
                    $thisApp
                }
            }
            else {
                $_.applicationIds
            }
        }
    },
    @{
        'n' = 'owner'
        'e' = {
            if ( $OwnerDetail ) {

                # this scriptblock requires ?ownershipTree=true be part of the url
                foreach ( $thisOwner in $_.ownership.owningContainers.owningUsers ) {
                    $thisOwnerDetail = $appOwners | Where-Object id -eq $thisOwner
                    if ( -not $thisOwnerDetail ) {
                        $thisOwnerDetail = Get-VcIdentity -ID $thisOwner | Select-Object firstName, lastName, emailAddress,
                        @{
                            'n' = 'status'
                            'e' = { $_.userStatus }
                        },
                        @{
                            'n' = 'role'
                            'e' = { $_.systemRoles }
                        },
                        @{
                            'n' = 'type'
                            'e' = { 'USER' }
                        },
                        @{
                            'n' = 'userId'
                            'e' = { $_.id }
                        }

                        $appOwners.Add($thisOwnerDetail)

                    }
                    $thisOwnerDetail
                }

                foreach ($thisOwner in $_.ownership.owningContainers.owningTeams) {
                    $thisOwnerDetail = $appOwners | Where-Object id -eq $thisOwner
                    if ( -not $thisOwnerDetail ) {
                        $thisOwnerDetail = Get-VcTeam -ID $thisOwner | Select-Object name, role, members,
                        @{
                            'n' = 'type'
                            'e' = { 'TEAM' }
                        },
                        @{
                            'n' = 'teamId'
                            'e' = { $_.id }
                        }

                        $appOwners.Add($thisOwnerDetail)
                    }
                    $thisOwnerDetail
                }
            }
            else {
                $_.ownership.owningContainers | Select-Object owningUsers, owningTeams
            }
        }
    },
    @{
        'n' = 'instance'
        'e' = { $_.instances }
    },
    @{
        'n' = 'issuerCN'
        'e' = { $_.issuerCN[0] }
    },
    @{
        'n' = 'issuerOU'
        'e' = { $_.issuerOU[0] }
    } -ExcludeProperty applicationIds, instances, totalInstanceCount, ownership, issuerCN, issuerOU
}

