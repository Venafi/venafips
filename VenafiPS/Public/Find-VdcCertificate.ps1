function Find-VdcCertificate {
    <#
    .SYNOPSIS
    Find certificates in Certificate Manager, Self-Hosted based on various attributes

    .DESCRIPTION
    Find certificates based on various attributes.
    Supports standard PS paging parameters First and Skip.
    If -First not provided, the default return is 1000 records.

    .PARAMETER Path
    Starting path to search from.  If not provided, the default is \ved\policy.

    .PARAMETER Guid
    Guid which represents a starting path.

    .PARAMETER Recursive
    Search recursively starting from the search path.

    .PARAMETER Country
    Find certificates by Country attribute of Subject DN.

    .PARAMETER CommonName
    Find certificates by Common name attribute of Subject DN.

    .PARAMETER Issuer
    Find certificates by issuer. Use the CN, O, L, S, and C values from the certificate request.

    .PARAMETER KeyAlgorithm
    Find certificates by algorithm for the public key.

    .PARAMETER KeySize
    Find certificates by public key size.

    .PARAMETER KeySizeGreaterThan
    Find certificates with a key size greater than the specified value.

    .PARAMETER KeySizeLessThan
    Find certificates with a key size less than the specified value.

    .PARAMETER Locale
    Find certificates by Locality/City attribute of Subject Distinguished Name (DN).

    .PARAMETER Organization
    Find certificates by Organization attribute of Subject DN.

    .PARAMETER OrganizationUnit
    Find certificates by Organization Unit (OU).

    .PARAMETER State
    Find certificates by State/Province attribute of Subject DN.

    .PARAMETER SanDns
    Find certificates by Subject Alternate Name (SAN) Distinguished Name Server (DNS).

    .PARAMETER SanEmail
    Find certificates by SAN Email RFC822.

    .PARAMETER SanIP
    Find certificates by SAN IP Address.

    .PARAMETER SanUpn
    Find certificates by SAN User Principal Name (UPN) or OtherName.

    .PARAMETER SanUri
    Find certificates by SAN Uniform Resource Identifier (URI).

    .PARAMETER SerialNumber
    Find certificates by Serial number.

    .PARAMETER SignatureAlgorithm
    Find certificates by the algorithm used to sign the certificate (e.g. SHA1RSA).

    .PARAMETER Thumbprint
    Find certificates by one or more SHA-1 thumbprints.

    .PARAMETER IssueDate
    Find certificates by the date of issue.

    .PARAMETER IssueDateAfter
    Find certificates issued after a certain date

    .PARAMETER IssueDateBefore
    Find certificates issued before a certain date

    .PARAMETER ExpireDate
    Find certificates by expiration date.

    .PARAMETER ExpireAfter
    Find certificates that expire after a certain date.

    .PARAMETER ExpireBefore
    Find certificates that expire before a certain date.

    .PARAMETER Enabled
    Include only certificates that are enabled or disabled.

    .PARAMETER InError
    Only include certificates in an error state.

    .PARAMETER IsSelfSigned
    Only include self-signed certificates

    .PARAMETER IsWildcard
    Only include wilcard certificates

    .PARAMETER IsExpired
    Only include expired certificates

    .PARAMETER NetworkValidationEnabled
    Only include certificates with network validation enabled or disabled.

    .PARAMETER CreatedDate
    Find certificates that were created at an exact date and time.

    .PARAMETER CreatedAfter
    Find certificate created after this date and time.

    .PARAMETER CreatedBefore
    Find certificate created before this date and time.

    .PARAMETER CertificateType
    Find certificate by category of usage. Use CodeSigning, Device, Server, and/or User.

    .PARAMETER ManagementType
    Find certificates with a Management type of Unassigned, Monitoring, Enrollment, or Provisioning.

    .PARAMETER PendingWorkflow
    Only include certificates that have a pending workflow resolution (have an outstanding workflow ticket).

    .PARAMETER Stage
    Find certificates by one or more stages in the certificate lifecycle.

    .PARAMETER StageGreaterThan
    Find certificates with a stage greater than the specified stage (does not include specified stage).

    .PARAMETER StageLessThan
    Find certificates with a stage less than the specified stage (does not include specified stage).

    .PARAMETER ValidationEnabled
    Only include certificates with validation enabled or disabled.

    .PARAMETER ValidationState
    Find certificates with a validation state of Blank, Success, or Failure.

    .PARAMETER Algorithm
    Name or OID for the PKIX algorithm, first introduced in v25.1.

    .PARAMETER CountOnly
    Return the count of certificates found from the query as opposed to the certificates themselves

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.

    .INPUTS
    Path

    .OUTPUTS
    pscustomobject, Int when CountOnly provided

    .EXAMPLE
    Find-VdcCertificate

    Find first 1000 certificates

    .EXAMPLE
    Find-VdcCertificate -IsExpired

    Find expired certificates

    .EXAMPLE
    Find-VdcCertificate -ExpireBefore '2018-01-01'

    Find certificates expiring before a certain date

    .EXAMPLE
    Find-VdcCertificate -ExpireBefore "2018-01-01" -First 5

    Find 5 certificates expiring before a certain date

    .EXAMPLE
    Find-VdcCertificate -ExpireBefore "2018-01-01" -First 5 -Skip 2

    Find 5 certificates expiring before a certain date, starting at the 3rd certificate found.

    .EXAMPLE
    Find-VdcCertificate -Path '\VED\Policy\My Policy'

    Find certificates in a specific path

    .EXAMPLE
    Find-VdcCertificate -Issuer 'CN=Example Root CA, O=Venafi,Inc., L=Salt Lake City, S=Utah, C=US'

    Find certificates by issuer

    .EXAMPLE
    Find-VdcCertificate -Path '\VED\Policy\My Policy' -Recursive

    Find certificates in a specific path and all subfolders

    .EXAMPLE
    Find-VdcCertificate | Get-VdcCertificate

    Get detailed certificate info

    .EXAMPLE
    Find-VdcCertificate -ExpireBefore "2019-09-01" | Invoke-VdcCertificateAction -Renew

    Renew all certificates expiring before a certain date

    .EXAMPLE
    Find-VdcCertificate -First 500

    Find the first 500 certificates

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-GET-Certificates.php

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-GET-Certificates-guid.php

    .LINK
    https://msdn.microsoft.com/en-us/library/system.web.httputility(v=vs.110).aspx
    #>

    [CmdletBinding(SupportsPaging)]

    param (

        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('DN')]
        [String] $Path = '\ved\policy',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [guid] $Guid,

        [Parameter()]
        [Switch] $Recursive,

        # [Parameter()]
        # [int] $Limit = 1000,

        # [Parameter()]
        # [int] $Offset,

        [Parameter()]
        [Alias('C')]
        [String] $Country,

        [Parameter()]
        [Alias('CN')]
        [String] $CommonName,

        [Parameter()]
        [String] $Issuer,

        [Parameter()]
        [String[]] $KeyAlgorithm,

        [Parameter()]
        [Int[]] $KeySize,

        [Parameter()]
        [Int] $KeySizeGreaterThan,

        [Parameter()]
        [Int] $KeySizeLessThan,

        [Parameter()]
        [Alias('L')]
        [String[]] $Locale,

        [Parameter()]
        [Alias('O')]
        [String[]] $Organization,

        [Parameter()]
        [Alias('OU')]
        [String[]] $OrganizationUnit,

        [Parameter()]
        [Alias('S')]
        [String[]] $State,

        [Parameter()]
        [String] $SanDns,

        [Parameter()]
        [String] $SanEmail,

        [Parameter()]
        [String] $SanIP,

        [Parameter()]
        [String] $SanUpn,

        [Parameter()]
        [String] $SanUri,

        [Parameter()]
        [String] $SerialNumber,

        [Parameter()]
        [String] $SignatureAlgorithm,

        [Parameter()]
        [String] $Thumbprint,

        [Parameter()]
        [Alias('ValidFrom')]
        [DateTime] $IssueDate,

        [Parameter()]
        [Alias('ValidFromGreater')]
        [DateTime] $IssueDateAfter,

        [Parameter()]
        [Alias('ValidFromLess')]
        [DateTime] $IssueDateBefore,

        [Parameter()]
        [Alias('ValidTo')]
        [DateTime] $ExpireDate,

        [Parameter()]
        [Alias('ValidToGreater')]
        [DateTime] $ExpireAfter,

        [Parameter()]
        [Alias('ValidToLess')]
        [DateTime] $ExpireBefore,

        [Parameter()]
        [Switch] $Enabled,

        [Parameter()]
        [switch] $InError,

        [Parameter()]
        [switch] $IsSelfSigned,

        [Parameter()]
        [switch] $IsWildcard,

        [Parameter()]
        [switch] $IsExpired,

        [Parameter()]
        [bool] $NetworkValidationEnabled,

        [Parameter()]
        [Alias('CreatedOn')]
        [datetime] $CreatedDate,

        [Parameter()]
        [Alias('CreatedOnGreater')]
        [datetime] $CreatedAfter,

        [Parameter()]
        [Alias('CreatedOnLess')]
        [datetime] $CreatedBefore,

        [Parameter()]
        [ValidateSet('CodeSigning', 'Device', 'Server', 'User')]
        [String[]] $CertificateType,

        [Parameter()]
        [TppManagementType[]] $ManagementType,

        [Parameter()]
        [Switch] $PendingWorkflow,

        [Parameter()]
        [TppCertificateStage[]] $Stage,

        [Parameter()]
        [Alias('StageGreater')]
        [TppCertificateStage] $StageGreaterThan,

        [Parameter()]
        [Alias('StageLess')]
        [TppCertificateStage] $StageLessThan,

        [Parameter()]
        [Switch] $ValidationEnabled,

        [Parameter()]
        [ValidateSet('Blank', 'Success', 'Failure')]
        [String[]] $ValidationState,

        [Parameter()]
        [string] $Algorithm,

        [Parameter()]
        [Switch] $CountOnly,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {
        Test-VenafiSession $PSCmdlet.MyInvocation

        $params = @{

            Method       = 'Get'
            UriLeaf      = 'certificates/'
            Body         = @{
                Limit  = 1000
                Offset = 0
            }
            FullResponse = $true
        }

        if ($PSCmdlet.PagingParameters.First -ne [uint64]::MaxValue -and $PSCmdlet.PagingParameters.First -le 1000) {
            $params.Body.Limit = $PSCmdlet.PagingParameters.First
        }

        if ($PSCmdlet.PagingParameters.Skip) {
            $params.Body.Offset = $PSCmdlet.PagingParameters.Skip
        }

        if ( $CountOnly.IsPresent ) {
            $params.Method = 'Head'
        }

        switch ($PSBoundParameters.Keys) {
            'CreatedDate' {
                $params.Body.Add( 'CreatedOn', ($CreatedDate | ConvertTo-UtcIso8601) )
            }
            'CreatedBefore' {
                $params.Body.Add( 'CreatedOnLess', ($CreatedBefore | ConvertTo-UtcIso8601) )
            }
            'CreatedAfter' {
                $params.Body.Add( 'CreatedOnGreater', ($CreatedAfter | ConvertTo-UtcIso8601) )
            }
            'CertificateType' {
                $params.Body.Add( 'CertificateType', $CertificateType -join ',' )
            }
            'Country' {
                $params.Body.Add( 'C', $Country )
            }
            'CommonName' {
                $params.Body.Add( 'CN', $CommonName )
            }
            'Issuer' {
                $params.Body.Add( 'Issuer', '"{0}"' -f $Issuer )
            }
            'KeyAlgorithm' {
                $params.Body.Add( 'KeyAlgorithm', $KeyAlgorithm -join ',' )
            }
            'KeySize' {
                $params.Body.Add( 'KeySize', $KeySize -join ',' )
            }
            'KeySizeGreaterThan' {
                $params.Body.Add( 'KeySizeGreater', $KeySizeGreaterThan )
            }
            'KeySizeLessThan' {
                $params.Body.Add( 'KeySizeLess', $KeySizeLessThan )
            }
            'Locale' {
                $params.Body.Add( 'L', $Locale -join ',' )
            }
            'Organization' {
                $params.Body.Add( 'O', $Organization -join ',' )
            }
            'OrganizationUnit' {
                $params.Body.Add( 'OU', $OrganizationUnit -join ',' )
            }
            'State' {
                $params.Body.Add( 'S', $State -join ',' )
            }
            'SanDns' {
                $params.Body.Add( 'SAN-DNS', $SanDns )
            }
            'SanEmail' {
                $params.Body.Add( 'SAN-Email', $SanEmail )
            }
            'SanIP' {
                $params.Body.Add( 'SAN-IP', $SanIP )
            }
            'SanUpn' {
                $params.Body.Add( 'SAN-UPN', $SanUpn )
            }
            'SanUri' {
                $params.Body.Add( 'SAN-URI', $SanUri )
            }
            'SerialNumber' {
                $params.Body.Add( 'Serial', $SerialNumber )
            }
            'SignatureAlgorithm' {
                $params.Body.Add( 'SignatureAlgorithm', $SignatureAlgorithm -join ',' )
            }
            'Thumbprint' {
                $params.Body.Add( 'Thumbprint', $Thumbprint )
            }
            'IssueDateAfter' {
                $params.Body.Add( 'ValidFromGreater', ($IssueDateAfter | ConvertTo-UtcIso8601) )
            }
            'IssueDateBefore' {
                $params.Body.Add( 'ValidFromLess', ($IssueDateBefore | ConvertTo-UtcIso8601) )
            }
            'IssueDate' {
                $params.Body.Add( 'ValidFrom', ($IssueDate | ConvertTo-UtcIso8601) )
            }
            'ExpireDate' {
                $params.Body.Add( 'ValidTo', ($ExpireDate | ConvertTo-UtcIso8601) )
            }
            'ExpireAfter' {
                $params.Body.Add( 'ValidToGreater', ($ExpireAfter | ConvertTo-UtcIso8601) )
            }
            'ExpireBefore' {
                $params.Body.Add( 'ValidToLess', ($ExpireBefore | ConvertTo-UtcIso8601) )
            }
            'Enabled' {
                $params.Body.Add( 'Disabled', [int] (-not $Enabled) )
            }
            'InError' {
                $params.Body.Add( 'InError', [int]$InError.IsPresent )
            }
            'IsSelfSigned' {
                $params.Body.Add( 'IsSelfSigned', [int] $IsSelfSigned.IsPresent )
            }
            'IsWildcard' {
                $params.Body.Add( 'IsWildcard', [int] $IsWildcard.IsPresent )
            }
            'IsExpired' {
                if ( $IsExpired.IsPresent ) {
                    $params.Body.Add( 'ValidToLess', ((Get-Date) | ConvertTo-UtcIso8601) )
                } else {
                    $params.Body.Add( 'ValidToGreater', ((Get-Date) | ConvertTo-UtcIso8601) )
                }
            }
            'NetworkValidationEnabled' {
                $params.Body.Add( 'NetworkValidationDisabled', [int] (-not $NetworkValidationEnabled) )
            }
            'ManagementType' {
                $params.Body.Add( 'ManagementType', $ManagementType -join ',' )
            }
            'PendingWorkflow' {
                $params.Body.Add( 'PendingWorkflow', '')
            }
            'Stage' {
                $params.Body.Add( 'Stage', ($Stage | ForEach-Object { [TppCertificateStage]::$_.value__ }) -join ',' )
            }
            'StageGreaterThan' {
                $params.Body.Add( 'StageGreater', [TppCertificateStage]::$StageGreaterThan.value__ )
            }
            'StageLessThan' {
                $params.Body.Add( 'StageLess', [TppCertificateStage]::$StageLessThan.value__ )
            }
            'ValidationEnabled' {
                $params.Body.Add( 'ValidationDisabled', [int] (-not $ValidationEnabled) )
            }
            'ValidationState' {
                $params.Body.Add( 'ValidationState', $ValidationState -join ',' )
            }

            'Algorithm' {
                $params.Body.Add('PkixParameterSet', $Algorithm)
            }
        }
    }

    process {

        if ( $PSBoundParameters.ContainsKey('Path') ) {
            $thisPath = $Path | ConvertTo-VdcFullPath
        }
        elseif ( $PSBoundParameters.ContainsKey('Guid') ) {
            # guid provided, get path
            $pathObject = ConvertTo-VdcObject -Guid $Guid
            if ( $pathObject.TypeName -ne 'Policy' ) {
                throw [System.Management.Automation.PSArgumentOutOfRangeException]::new('Guid', $pathObject.TypeName, 'Must be a Policy')
                return
            }
            $thisPath = $pathObject.Path
        }

        if ( $thisPath ) {
            if ( $Recursive.IsPresent ) {
                $params.Body.ParentDnRecursive = $thisPath
            }
            else {
                $params.Body.ParentDn = $thisPath
            }
        }

        $response = Invoke-VenafiRestMethod @params

        $totalRecordCount = 0
        if ($PSVersionTable.PSVersion.Major -lt 6) {
            $totalRecordCount = [int]$response.Headers.'X-Record-Count'
        }
        else {
            $totalRecordCount = [int]($response.Headers.'X-Record-Count'[0])
        }

        if ( $CountOnly ) {
            return $totalRecordCount
        }

        Write-Verbose "Total number of records for this query: $totalRecordCount"

        $content = $response.content | ConvertFrom-Json
        $content.Certificates.ForEach{
            ConvertTo-VdcObject -Path $_.DN -Guid $_.Guid -TypeName $_.SchemaClass
        }

        if ($PSBoundParameters.ContainsKey('First')) {
            $totalRecordCount = $PSCmdlet.PagingParameters.First
        }

        $setPoint = $params.Body.Offset + $params.Body.Limit

        while ($totalRecordCount -gt $setPoint) {

            # up the offset so we get the next set of records
            $params.Body.Offset += $params.Body.Limit
            $setPoint = $params.Body.Offset + $params.Body.Limit

            $end = if ( $totalRecordCount -lt $setPoint ) {
                $totalRecordCount
            }
            else {
                $setPoint
            }

            Write-Verbose ('getting {0}-{1} of {2}' -f ($params.Body.Offset + 1), $end, $totalRecordCount)
            try {
                $response = Invoke-VenafiRestMethod @params -Verbose:$false
            }
            catch {
                $ProgressPreference = $oldProgressPreference
                throw $_
            }

            $content = $response.content | ConvertFrom-Json
            $content.Certificates.ForEach{
                ConvertTo-VdcObject -Path $_.DN -Guid $_.Guid -TypeName $_.SchemaClass
            }
        }
    }
}

