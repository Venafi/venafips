function Get-VdcCertificate {
    <#
    .SYNOPSIS
    Get certificate information

    .DESCRIPTION
    Get certificate information, either all available to the api key provided or by id or zone.

    .PARAMETER ID
    Certificate identifier by either path or guid.
    \ved\policy will be automatically applied if a full path isn't provided.

    .PARAMETER IncludePreviousVersions
    Returns details about previous (historical) versions of a certificate.
    This option will add a property named PreviousVersions to the returned object.

    .PARAMETER ExcludeExpired
    Omits expired versions of the previous (historical) versions of a certificate.
    Can only be used with the IncludePreviousVersions parameter.

    .PARAMETER ExcludeRevoked
    Omits revoked versions of the previous (historical) versions of a certificate.
    Can only be used with the IncludePreviousVersions parameter.

    .PARAMETER IncludeStatus
    Include values for Status and StatusText in the response which match the certificate status as seen on the certificate Summary tab.

    .PARAMETER All
    Retrieve all certificates

    .PARAMETER ThrottleLimit
    Limit the number of threads when running in parallel; the default is 100.
    Setting the value to 1 will disable multithreading.
    On PS v5 the ThreadJob module is required.  If not found, multithreading will be disabled.

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.

    .INPUTS
    ID

    .OUTPUTS
    PSCustomObject

    .EXAMPLE
    Get-VdcCertificate -ID '\ved\policy\mycert.com'

    Get certificate info for a specific cert

    .EXAMPLE
    Get-VdcCertificate -All

    Get certificate info for all certs

    .EXAMPLE
    Get-VdcCertificate -ID '\ved\policy\mycert.com' -IncludePreviousVersions

    Get certificate info for a specific cert, including historical versions of the certificate.

    .EXAMPLE
    Get-VdcCertificate -ID '\ved\policy\mycert.com' -IncludeTppPreviousVersions -ExcludeRevoked -ExcludeExpired

    Get certificate info for a specific cert, including historical versions of the certificate that are not revoked or expired.

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-GET-Certificates-guid.php
    #>

    [CmdletBinding(DefaultParameterSetName = 'Id')]

    param (

        [Parameter(ParameterSetName = 'Id', Mandatory, ValueFromPipelineByPropertyName, Position = 0)]
        [Parameter(ParameterSetName = 'IdWithPrevious', Mandatory, ValueFromPipelineByPropertyName, Position = 0)]
        [Alias('Guid', 'Path')]
        [string] $ID,

        [Parameter(Mandatory, ParameterSetName = 'All')]
        [Parameter(Mandatory, ParameterSetName = 'AllWithPrevious')]
        [Switch] $All,

        [Parameter(Mandatory, ParameterSetName = 'IdWithPrevious')]
        [Parameter(Mandatory, ParameterSetName = 'AllWithPrevious')]
        [switch] $IncludePreviousVersions,

        [Parameter(ParameterSetName = 'IdWithPrevious')]
        [Parameter(ParameterSetName = 'AllWithPrevious')]
        [switch] $ExcludeExpired,

        [Parameter(ParameterSetName = 'IdWithPrevious')]
        [Parameter(ParameterSetName = 'AllWithPrevious')]
        [switch] $ExcludeRevoked,

        [Parameter()]
        [switch] $IncludeStatus,

        [Parameter()]
        [int32] $ThrottleLimit = 100,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession = (Get-VenafiSession)
    )

    begin {

        Test-VenafiSession $PSCmdlet.MyInvocation

        $certs = [System.Collections.Generic.List[string]]::new()

    }

    process {

        if ( $All ) {
            return (Find-VdcCertificate -Path '\ved' -Recursive -VenafiSession $VenafiSession | Get-VdcCertificate -IncludePreviousVersions:$IncludePreviousVersions -ExcludeExpired:$ExcludeExpired -ExcludeRevoked:$ExcludeRevoked -VenafiSession $VenafiSession)
        }

        if ( Test-IsGuid($ID) ) {
            $certs.Add($ID)
        }
        else {
            $certs.Add((ConvertTo-VdcFullPath -Path $ID))
        }
    }

    end {

        $parallelParams = @{
            InputObject   = $certs
            ThrottleLimit = $ThrottleLimit
            ProgressTitle = 'Getting certificates'
            VenafiSession = $VenafiSession
            ScriptBlock   = {

                if ( $PSItem -like '\ved*' ) {
                    # a path was provided, get the guid
                    $thisGuid = (ConvertTo-VdcObject -Path $PSItem).Guid
                }
                else {
                    $thisGuid = ([guid] $PSItem).ToString()
                }

                $params = @{
                    UriLeaf       = [System.Web.HttpUtility]::UrlEncode("certificates/{$thisGuid}")
                }

                $response = Invoke-VenafiRestMethod @params

                if ( $using:IncludeStatus ) {
                    $status = $response | Get-VdcCertificateStatus
                    $response | Add-Member @{
                        'Status'     = $status.Status
                        'StatusText' = $status.StatusText
                    }
                }

                if ( $using:IncludePreviousVersions ) {
                    $params.UriLeaf = [System.Web.HttpUtility]::UrlEncode("certificates/{$thisGuid}/PreviousVersions")
                    $params.Body = @{}

                    if ( $ExcludeExpired.IsPresent ) {
                        $params.Body.ExcludeExpired = $ExcludeExpired
                    }
                    if ( $ExcludeRevoked.IsPresent ) {
                        $params.Body.ExcludeRevoked = $ExcludeRevoked
                    }

                    $previous = Invoke-VenafiRestMethod @params

                    if ( $previous.PreviousVersions ) {
                        $previous.PreviousVersions.CertificateDetails | ForEach-Object {
                            $_.StoreAdded = [datetime]$_.StoreAdded
                            $_.ValidFrom = [datetime]$_.ValidFrom
                            $_.ValidTo = [datetime]$_.ValidTo
                        }
                    }

                    $response | Add-Member @{'PreviousVersions' = $previous.PreviousVersions }
                }

                # object transformations
                # put in try/catch in case datetime conversion fails
                try {
                    $response.CertificateDetails.StoreAdded = [datetime]$response.CertificateDetails.StoreAdded
                    $response.CertificateDetails.ValidFrom = [datetime]$response.CertificateDetails.ValidFrom
                    $response.CertificateDetails.ValidTo = [datetime]$response.CertificateDetails.ValidTo
                }
                catch {

                }

                $selectProps = @{
                    Property        =
                    @{
                        n = 'Name'
                        e = { $_.Name }
                    },
                    @{
                        n = 'TypeName'
                        e = { $_.SchemaClass }
                    },
                    @{
                        n = 'Path'
                        e = { $_.DN }
                    }, @{
                        n = 'Guid'
                        e = { [guid]$_.guid }
                    }, @{
                        n = 'ParentPath'
                        e = { $_.ParentDN }
                    }, @{
                        n = 'CreatedOn'
                        e = { [datetime]$_.CreatedOn }
                    },
                    '*'
                    ExcludeProperty = 'DN', 'GUID', 'ParentDn', 'SchemaClass', 'Name', 'CreatedOn'
                }

                $response | Select-Object @selectProps

            }
        }

        Invoke-VenafiParallel @parallelParams

    }
}


