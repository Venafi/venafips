function Get-TrustMcpTool {
    <#
    .SYNOPSIS
    Get the MCP tool definitions for a platform

    .DESCRIPTION
    Returns the tools exposed by Start-TrustMcpServer.
    Each tool has a name, description, json input schema, the platforms it supports, and a handler scriptblock.
    Tools with the same name can exist for different platforms so the model sees one consistent tool name,
    eg. find_certificates, with platform appropriate arguments.
    Handlers receive the tool arguments as a PSCustomObject and the TrustClient and should return objects;
    output is sanitized by the caller.

    .PARAMETER Platform
    Only return tools which support this platform
    #>

    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Arguments', Justification = 'All handlers share the same signature')]
    param (
        [Parameter()]
        [TrustPlatform] $Platform
    )

    $firstSchema = @{
        type        = 'integer'
        description = 'Maximum number of results to return.  Default 25, maximum 200.'
        minimum     = 1
        maximum     = 200
    }

    $tools = @(

        #region whoami
        @{
            name        = 'whoami'
            platforms   = 'CM', 'CMS', 'NGTS'
            description = 'Get details about the current VenafiPS connection: platform (CM = Certificate Manager Self-Hosted, CMS = Certificate Manager SaaS, NGTS = Next-Generation Trust Security), server, who is signed in and their roles, authentication type, client id, scope, and token expiration.  Call this first to understand which platform you are working with and what the account can do.'
            inputSchema = @{ type = 'object'; properties = @{} }
            handler     = {
                param($Arguments, $TrustClient)

                $out = [ordered]@{
                    platform             = $TrustClient.Platform.ToString()
                    server               = $TrustClient.Server
                    serverVersion        = $TrustClient.PlatformData.Version
                    tsg                  = $TrustClient.PlatformData.Tsg
                    identity             = $null
                    authType             = $TrustClient.AuthType.ToString()
                    clientId             = if ( $TrustClient.ClientId ) { $TrustClient.ClientId } else { $null }
                    scope                = $TrustClient.Scope
                    authServer           = if ( $TrustClient.AuthServer -and $TrustClient.AuthServer -ne $TrustClient.Server ) { $TrustClient.AuthServer } else { $null }
                    # MaxValue, eg. an api key, doesn't expire
                    expires              = if ( $TrustClient.Expires -gt [datetime]::MinValue -and $TrustClient.Expires.Year -lt 9999 ) { $TrustClient.Expires } else { $null }
                    refreshExpires       = if ( $TrustClient.RefreshExpires -gt [datetime]::MinValue ) { $TrustClient.RefreshExpires } else { $null }
                    canRefresh           = $TrustClient.CanRefresh()
                    # the name of the vault entry, not its value.  vaultRefreshTokenName would be redacted by name.
                    vaultEntry           = if ( $TrustClient.VaultRefreshTokenName ) { $TrustClient.VaultRefreshTokenName } else { $null }
                    skipCertificateCheck = $TrustClient.SkipCertificateCheck
                    venafiPSVersion      = $script:ModuleVersion
                }

                # who is signed in.  don't fail whoami if this isn't available, eg. missing permission or platform support
                try {
                    $out.identity = if ( $TrustClient.Platform -eq 'CM' ) {
                        $me = Get-CmIdentity -Me -TrustClient $TrustClient
                        [ordered]@{ name = $me.Name; id = $me.ID; fullName = $me.FullName; path = $me.Path }
                    }
                    else {
                        $me = Get-CmsUser -Me -TrustClient $TrustClient
                        [ordered]@{
                            username      = $me.username
                            name          = ('{0} {1}' -f $me.firstname, $me.lastname).Trim()
                            email         = $me.emailAddress
                            id            = $me.userId
                            userType      = $me.userType
                            accountType   = $me.userAccountType
                            status        = $me.userStatus
                            systemRoles   = @($me.systemRoles)
                            productRoles  = $me.productRoles
                            ownedTeams    = @($me.ownedTeams)
                            memberedTeams = @($me.memberedTeams)
                        }
                    }
                }
                catch {
                    $out.identityError = $_.Exception.Message
                }

                # leave out what doesn't apply to this connection
                $empty = @($out.Keys | Where-Object { $null -eq $out[$_] -and $_ -ne 'identity' })
                foreach ( $key in $empty ) { $out.Remove($key) }
                $out
            }
        }
        #endregion

        #region find_certificates
        @{
            name        = 'find_certificates'
            platforms   = 'CM'
            description = 'Search the Certificate Manager Self-Hosted inventory for certificates.  Returns name, path, and guid for each certificate along with the total number of matches.  Use get_certificate with the path or guid for full details.'
            inputSchema = @{
                type       = 'object'
                properties = [ordered]@{
                    path                 = @{ type = 'string'; description = 'Policy folder to search in, eg. \VED\Policy\Certificates.  Searches the entire inventory if not provided.' }
                    recursive            = @{ type = 'boolean'; description = 'Search subfolders of path.  Default true.' }
                    common_name          = @{ type = 'string'; description = 'Subject common name, case-insensitive, starts with.  eg. www matches www.company.com but company.com does not.' }
                    san_dns              = @{ type = 'string'; description = 'DNS subject alternative name, case-insensitive, starts with.  eg. www matches www.company.com but company.com does not.' }
                    issuer               = @{ type = 'string'; description = 'Issuer, case-insensitive.  A full DN, eg. CN=Example Issuing CA, DC=example, DC=com, is an exact and fast match; spacing must match exactly.  Any other value, eg. Example Issuing, matches issuers containing the text but scans up to 5000 certificates, so narrow with path or other filters for large inventories.  Partial matches return the full matchedIssuers DNs to use for exact searches.' }
                    expiring_within_days = @{ type = 'integer'; minimum = 1; description = 'Only certificates which are not yet expired and expire within this many days' }
                    expired              = @{ type = 'boolean'; description = 'Only certificates which are already expired.  Cannot be combined with expiring_within_days.' }
                    in_error             = @{ type = 'boolean'; description = 'Only certificates currently in an error state' }
                    pending_workflow     = @{ type = 'boolean'; description = 'Only certificates waiting on a workflow approval' }
                    management_type      = @{ type = 'array'; items = @{ type = 'string'; enum = @('Unassigned', 'Monitoring', 'Enrollment', 'Provisioning') }; description = 'Only certificates with these management types.  Monitoring and Unassigned are not renewed automatically.' }
                    key_algorithm        = @{ type = 'string'; enum = @('RSA', 'ECC'); description = 'Only certificates with this key algorithm' }
                    key_size_less_than   = @{ type = 'integer'; minimum = 1; description = 'Only certificates with a key smaller than this many bits, eg. 2048 with key_algorithm RSA for weak RSA keys' }
                    signature_algorithm  = @{ type = 'string'; description = 'Only certificates signed with this algorithm.  25.1 uses the long name, eg. sha1WithRSAEncryption, sha256WithRSAEncryption, ecdsa-with-SHA256; earlier versions the short name, eg. sha1RSA, sha256RSA.  If there are no matches, try the other form.' }
                    wildcard             = @{ type = 'boolean'; description = 'true for only wildcard certificates, false to exclude them' }
                    self_signed          = @{ type = 'boolean'; description = 'true for only self-signed certificates, false to exclude them' }
                    include_details      = @{ type = 'boolean'; description = 'Include issuer, subject, CN, SANs, serial, thumbprint, validity, and key details for each certificate.  Default false.' }
                    first                = $firstSchema
                }
            }
            handler     = {
                param($Arguments, $TrustClient)

                $params = @{ TrustClient = $TrustClient }
                if ( $Arguments.path ) {
                    $params.Path = $Arguments.path
                    $params.Recursive = ($Arguments.recursive -ne $false)
                }
                if ( $Arguments.common_name ) { $params.CommonName = $Arguments.common_name }
                if ( $Arguments.san_dns ) { $params.SanDns = $Arguments.san_dns }
                # the api only supports an exact match on the full issuer dn, anything else is matched locally
                $issuerContains = $null
                if ( $Arguments.issuer ) {
                    if ( $Arguments.issuer -match '^\s*[A-Za-z][\w.]*\s*=' ) {
                        $params.Issuer = $Arguments.issuer
                    }
                    else {
                        $issuerContains = $Arguments.issuer.Trim()
                    }
                }
                if ( $Arguments.expired -and $Arguments.expiring_within_days ) {
                    throw 'expired and expiring_within_days cannot be used together'
                }
                if ( $Arguments.expired ) { $params.IsExpired = $true }
                if ( $Arguments.expiring_within_days ) {
                    $params.ExpireAfter = Get-Date
                    $params.ExpireBefore = (Get-Date).AddDays([int]$Arguments.expiring_within_days)
                }
                if ( $Arguments.in_error ) { $params.InError = $true }
                if ( $Arguments.pending_workflow ) { $params.PendingWorkflow = $true }
                if ( $Arguments.management_type ) { $params.ManagementType = [string[]]@($Arguments.management_type) }
                if ( $Arguments.key_algorithm ) { $params.KeyAlgorithm = $Arguments.key_algorithm }
                if ( $Arguments.key_size_less_than ) { $params.KeySizeLessThan = [int]$Arguments.key_size_less_than }
                if ( $Arguments.signature_algorithm ) { $params.SignatureAlgorithm = $Arguments.signature_algorithm }
                # these are filters both ways, false excludes them
                if ( $null -ne $Arguments.wildcard ) { $params.IsWildcard = [bool]$Arguments.wildcard }
                if ( $null -ne $Arguments.self_signed ) { $params.IsSelfSigned = [bool]$Arguments.self_signed }

                $first = Resolve-TrustMcpFirst $Arguments.first
                $props = 'Name', 'Path', 'Guid'
                # only needed when retrieving certificates, not counting
                $fields = @{}
                if ( $Arguments.include_details ) {
                    $fields.OptionalField = 'Issuer', 'Subject', 'KeyAlgorithm', 'KeySize'
                    $props += 'X509'
                }

                if ( -not $issuerContains ) {
                    $total = Find-CmCertificate @params -CountOnly
                    $certs = @(Find-CmCertificate @params @fields -First $first)

                    return [ordered]@{
                        totalMatches = $total
                        returned     = $certs.Count
                        certificates = @($certs | Select-Object $props)
                    }
                }

                $maxScan = 5000
                $candidates = Find-CmCertificate @params -CountOnly
                if ( -not $fields.OptionalField ) { $fields.OptionalField = 'Issuer' }
                $matched = @(
                    Find-CmCertificate @params @fields -First $maxScan | Where-Object {
                        $_.X509.Issuer -and $_.X509.Issuer.IndexOf($issuerContains, [System.StringComparison]::OrdinalIgnoreCase) -ge 0
                    }
                )

                [ordered]@{
                    totalMatches    = $matched.Count
                    returned        = [System.Math]::Min($first, $matched.Count)
                    scanned         = [System.Math]::Min($maxScan, $candidates)
                    truncated       = ($candidates -gt $maxScan)
                    matchedIssuers  = @($matched | ForEach-Object { $_.X509.Issuer } | Sort-Object -Unique)
                    note            = 'Issuer was matched by containing text.  Use a matchedIssuers value as issuer for a faster exact search.  If truncated, totalMatches only covers the certificates scanned.'
                    certificates    = @($matched | Select-Object -First $first | Select-Object $props)
                }
            }
        }

        @{
            name        = 'find_certificates'
            platforms   = 'CMS', 'NGTS'
            description = 'Search the certificate inventory.  Returns a summary of each certificate including id, name, subject CN, SANs, issuer, validity, status, and key details.  Use get_certificate with the id for full details.'
            inputSchema = @{
                type       = 'object'
                properties = [ordered]@{
                    name                 = @{ type = 'string'; description = 'Certificate name, partial match' }
                    common_name          = @{ type = 'string'; description = 'Subject common name' }
                    san_dns              = @{ type = 'string'; description = 'DNS subject alternative name' }
                    issuer               = @{ type = 'string'; description = 'Issuer common name' }
                    application          = @{ type = 'string'; description = 'Application name or id the certificate is assigned to' }
                    status               = @{ type = 'string'; enum = @('ACTIVE', 'RETIRED', 'DELETED'); description = 'Certificate status.  Default ACTIVE.' }
                    expiring_within_days = @{ type = 'integer'; minimum = 1; description = 'Only certificates which are not yet expired and expire within this many days, soonest first' }
                    expired              = @{ type = 'boolean'; description = 'Only certificates which are already expired.  Cannot be combined with expiring_within_days.' }
                    first                = $firstSchema
                }
            }
            handler     = {
                param($Arguments, $TrustClient)

                $first = Resolve-TrustMcpFirst $Arguments.first
                $params = @{
                    TrustClient = $TrustClient
                    First       = $first
                    Status      = if ( $Arguments.status ) { $Arguments.status } else { 'ACTIVE' }
                }
                if ( $Arguments.name ) { $params.Name = $Arguments.name }
                if ( $Arguments.common_name ) { $params.CN = $Arguments.common_name }
                if ( $Arguments.san_dns ) { $params.SanDns = $Arguments.san_dns }
                if ( $Arguments.issuer ) { $params.Issuer = $Arguments.issuer }
                if ( $Arguments.application ) { $params.Application = $Arguments.application }
                if ( $Arguments.expired -and $Arguments.expiring_within_days ) {
                    throw 'expired and expiring_within_days cannot be used together'
                }
                if ( $Arguments.expired ) { $params.IsExpired = $true }
                if ( $Arguments.expiring_within_days ) {
                    $params.IsExpired = $false
                    $params.ExpireBefore = (Get-Date).AddDays([int]$Arguments.expiring_within_days)
                }

                $certs = @(Find-TrustCertificate @params)

                [ordered]@{
                    returned       = $certs.Count
                    moreMayExist   = ($certs.Count -ge $first)
                    certificates   = @($certs | Select-Object certificateId, certificateName, subjectCN,
                        @{ n = 'sanDns'; e = { @($_.subjectAlternativeNamesByType.dNSName) } },
                        issuerCN, validityStart, validityEnd, certificateStatus, keyType, keyStrength, serialNumber, fingerprint, applicationIds)
                }
            }
        }
        #endregion

        #region get_certificate
        @{
            name        = 'get_certificate'
            platforms   = 'CM'
            description = 'Get full details for a single certificate including subject, SANs, issuer, validity, key details, processing status, and any error.  With include_history, also the previous versions it replaced, most recent first.'
            inputSchema = @{
                type       = 'object'
                properties = [ordered]@{
                    id              = @{ type = 'string'; description = 'Certificate path, eg. \VED\Policy\Certificates\www.company.com, or guid' }
                    include_history = @{ type = 'boolean'; description = 'Include previous versions of the certificate with their serial, thumbprint, validity, and revocation status.  Default false.' }
                }
                required   = @('id')
            }
            handler     = {
                param($Arguments, $TrustClient)

                $cert = Get-CmCertificate -ID $Arguments.id -IncludeStatus -IncludePreviousVersions:($Arguments.include_history -eq $true) -TrustClient $TrustClient

                if ( $Arguments.include_history -eq $true ) {
                    # summarize each version, the full details of every renewal are too large to be useful
                    $history = @(
                        $cert.PreviousVersions | Where-Object { $_ } | ForEach-Object { $_.CertificateDetails } | Sort-Object { [datetime]$_.ValidFrom } -Descending | ForEach-Object {
                            [ordered]@{
                                serial           = $_.Serial
                                thumbprint       = $_.Thumbprint
                                validFrom        = $_.ValidFrom
                                validTo          = $_.ValidTo
                                issuer           = $_.Issuer
                                key              = '{0} {1}' -f $_.KeyAlgorithm, $_.KeySize
                                sans             = @($_.SubjectAltNameDNS)
                                revocationStatus = $_.RevocationStatus
                                revocationDate   = $_.RevocationDate
                            }
                        }
                    )
                    $cert = $cert | Select-Object -Property * -ExcludeProperty PreviousVersions
                    $cert | Add-Member -NotePropertyName previousVersionCount -NotePropertyValue $history.Count
                    $cert | Add-Member -NotePropertyName previousVersions -NotePropertyValue @($history | Select-Object -First 25)
                }

                $cert
            }
        }

        @{
            name        = 'get_certificate'
            platforms   = 'CMS', 'NGTS'
            description = 'Get full details for a single certificate including subject, SANs, issuer, validity, key details, and application assignment.'
            inputSchema = @{
                type       = 'object'
                properties = @{
                    id = @{ type = 'string'; description = 'Certificate id or name' }
                }
                required   = @('id')
            }
            handler     = {
                param($Arguments, $TrustClient)
                Get-TrustCertificate -Certificate $Arguments.id -TrustClient $TrustClient
            }
        }
        #endregion

        #region certificate_expiry_summary
        @{
            name        = 'certificate_expiry_summary'
            platforms   = 'CM'
            description = 'Count certificates which are expired or expiring in the next 7, 30, and 90 days.  Use this for a quick risk overview before drilling in with find_certificates.'
            inputSchema = @{
                type       = 'object'
                properties = @{
                    path = @{ type = 'string'; description = 'Policy folder to summarize, including subfolders.  The entire inventory is used if not provided.' }
                }
            }
            handler     = {
                param($Arguments, $TrustClient)

                $base = @{ TrustClient = $TrustClient; CountOnly = $true }
                if ( $Arguments.path ) {
                    $base.Path = $Arguments.path
                    $base.Recursive = $true
                }
                $now = Get-Date

                [ordered]@{
                    expired      = Find-CmCertificate @base -IsExpired
                    within7Days  = Find-CmCertificate @base -ExpireAfter $now -ExpireBefore $now.AddDays(7)
                    within30Days = Find-CmCertificate @base -ExpireAfter $now -ExpireBefore $now.AddDays(30)
                    within90Days = Find-CmCertificate @base -ExpireAfter $now -ExpireBefore $now.AddDays(90)
                    note         = 'Counts are cumulative, eg. within30Days includes within7Days'
                }
            }
        }

        @{
            name        = 'certificate_expiry_summary'
            platforms   = 'CMS', 'NGTS'
            description = 'Count active certificates which are expired or expiring in the next 7, 30, and 90 days.  Use this for a quick risk overview before drilling in with find_certificates.'
            inputSchema = @{
                type       = 'object'
                properties = @{
                    application = @{ type = 'string'; description = 'Limit to certificates assigned to this application name or id' }
                }
            }
            handler     = {
                param($Arguments, $TrustClient)

                # no count api so retrieve once and bucket locally
                $max = 5000
                $now = Get-Date
                $params = @{
                    TrustClient  = $TrustClient
                    Status       = 'ACTIVE'
                    ExpireBefore = $now.AddDays(90)
                    First        = $max
                }
                if ( $Arguments.application ) { $params.Application = $Arguments.application }

                $ends = @(Find-TrustCertificate @params | ForEach-Object { [datetime]$_.validityEnd })

                [ordered]@{
                    expired      = @($ends | Where-Object { $_ -lt $now }).Count
                    within7Days  = @($ends | Where-Object { $_ -ge $now -and $_ -le $now.AddDays(7) }).Count
                    within30Days = @($ends | Where-Object { $_ -ge $now -and $_ -le $now.AddDays(30) }).Count
                    within90Days = @($ends | Where-Object { $_ -ge $now }).Count
                    truncated    = ($ends.Count -ge $max)
                    note         = 'Counts are cumulative, eg. within30Days includes within7Days'
                }
            }
        }
        #endregion

        #region certificate_inventory_summary
        @{
            name        = 'certificate_inventory_summary'
            platforms   = 'CM'
            description = 'Summarize certificates in one call: counts in error, expired, never issued, and pending approval; the top values by policy folder, issuer, key, expiry, class, management type, and lifetime; readiness for shorter maximum validity (CA/B Forum SC-081: 200 days from 15 Mar 2026, 100 days from 15 Mar 2027, 47 days from 15 Mar 2029, for publicly trusted TLS); and crypto posture, eg. weak keys, SHA-1, wildcards, self-signed, and no SANs.  Use this instead of calling get_certificate for many certificates, eg. to report on a folder or compare CAs.  Use find_certificates or browse_policy_tree to list the certificates behind a count.'
            inputSchema = @{
                type       = 'object'
                properties = [ordered]@{
                    path = @{ type = 'string'; description = 'Policy folder to summarize, including subfolders.  The entire inventory is used if not provided.' }
                    top  = @{ type = 'integer'; minimum = 1; maximum = 50; description = 'Number of values to return for each grouping, the rest are combined into other.  Default 10.' }
                }
            }
            handler     = {
                param($Arguments, $TrustClient)

                # each certificate is read once with the details needed to group it.
                # cap it so a very large inventory doesn't run for minutes, ~1000 certificates take 10 seconds
                $limit = 10000
                $top = if ( $Arguments.top ) { [Math]::Min(50, [int]$Arguments.top) } else { 10 }

                $base = @{ TrustClient = $TrustClient }
                if ( $Arguments.path ) {
                    $base.Path = $Arguments.path
                    $base.Recursive = $true
                }

                $total = Find-CmCertificate @base -CountOnly
                $certs = @(Find-CmCertificate @base -OptionalField Issuer, KeyAlgorithm, KeySize -First $limit)
                $now = Get-Date

                $managementType = [ordered]@{}
                foreach ( $type in 'Provisioning', 'Enrollment', 'Monitoring', 'Unassigned' ) {
                    $managementType[$type] = Find-CmCertificate @base -ManagementType $type -CountOnly
                }

                # certificates which are valid now, and how many days each was issued for
                $current = @($certs | Where-Object { $_.X509.ValidFrom -and $_.X509.ValidTo -and [datetime]$_.X509.ValidTo -gt $now })
                $lifetimeDays = { param($Cert) ([datetime]$Cert.X509.ValidTo - [datetime]$Cert.X509.ValidFrom).TotalDays }
                $lifetimeBucket = {
                    param($Cert)
                    $days = & $lifetimeDays $Cert
                    if ( $days -le 47 ) { '47 days or less' } elseif ( $days -le 100 ) { '48-100 days' } elseif ( $days -le 200 ) { '101-200 days' } elseif ( $days -le 398 ) { '201-398 days' } else { 'over 398 days' }
                }

                $group = {
                    param($Items, [scriptblock] $Key)
                    $groups = @($Items | Group-Object -Property $Key -NoElement | Sort-Object -Property @{ e = 'Count'; Descending = $true }, Name)
                    $out = @(
                        $groups | Select-Object -First $top | ForEach-Object { [ordered]@{ value = $_.Name; count = $_.Count } }
                    )
                    if ( $groups.Count -gt $top ) {
                        $out += [ordered]@{ value = ('other ({0} values)' -f ($groups.Count - $top)); count = [int]($groups | Select-Object -Skip $top | Measure-Object -Property Count -Sum).Sum }
                    }
                    , $out
                }

                $expiry = {
                    if ( -not $_.X509.ValidTo ) { return 'never issued' }
                    $days = ([datetime]$_.X509.ValidTo - $now).TotalDays
                    switch ( $days ) {
                        { $_ -lt 0 } { 'expired'; break }
                        { $_ -le 30 } { '0-30 days'; break }
                        { $_ -le 90 } { '31-90 days'; break }
                        { $_ -le 365 } { '91-365 days'; break }
                        default { 'over 1 year' }
                    }
                }

                [ordered]@{
                    path            = if ( $Arguments.path ) { $Arguments.path } else { '\VED\Policy' }
                    total           = $total
                    summarized      = $certs.Count
                    truncated       = $certs.Count -lt $total
                    inError         = Find-CmCertificate @base -InError -CountOnly
                    pendingApproval = Find-CmCertificate @base -PendingWorkflow -CountOnly
                    expired         = @($certs | Where-Object { $_.X509.ValidTo -and [datetime]$_.X509.ValidTo -lt $now }).Count
                    neverIssued     = @($certs | Where-Object { -not $_.X509.ValidTo }).Count
                    # buckets in date order, there are never more than 6
                    byExpiry        = @(
                        $buckets = $certs | Group-Object -Property $expiry -NoElement
                        foreach ( $b in 'expired', '0-30 days', '31-90 days', '91-365 days', 'over 1 year', 'never issued' ) {
                            $n = ($buckets | Where-Object Name -eq $b).Count
                            if ( $n ) { [ordered]@{ value = $b; count = $n } }
                        }
                    )
                    byFolder        = & $group $certs { $_.ParentPath }
                    byIssuer        = & $group ($certs | Where-Object { $_.X509.Issuer }) { $_.X509.Issuer }
                    byKey           = & $group ($certs | Where-Object { $_.X509.KeyAlgorithm }) { '{0} {1}' -f $_.X509.KeyAlgorithm, $_.X509.KeySize }
                    byClass         = & $group $certs { $_.TypeName }
                    byManagementType = $managementType
                    # how long certificates which are valid now were issued for, buckets at the SC-081 limits
                    byLifetime       = @(
                        foreach ( $b in '47 days or less', '48-100 days', '101-200 days', '201-398 days', 'over 398 days' ) {
                            $n = @($current | Where-Object { (& $lifetimeBucket $_) -eq $b }).Count
                            if ( $n ) { [ordered]@{ value = $b; count = $n } }
                        }
                    )
                    validityReduction = [ordered]@{
                        currentlyValid       = $current.Count
                        lifetimeOver200Days  = @($current | Where-Object { (& $lifetimeDays $_) -gt 200 }).Count
                        lifetimeOver100Days  = @($current | Where-Object { (& $lifetimeDays $_) -gt 100 }).Count
                        lifetimeOver47Days   = @($current | Where-Object { (& $lifetimeDays $_) -gt 47 }).Count
                        # monitoring and unassigned certificates are renewed by hand, if at all
                        notAutomated         = $managementType.Monitoring + $managementType.Unassigned
                        note                 = 'SC-081 applies to publicly trusted TLS certificates; certificates from private CAs, see byIssuer, are not affected.  Lifetime counts cover certificates valid now; each will need a shorter lifetime when renewed.  Automated is Provisioning or Enrollment management type.'
                    }
                    posture          = [ordered]@{
                        rsaUnder2048Bits = @($certs | Where-Object { $_.X509.KeyAlgorithm -eq 'RSA' -and $_.X509.KeySize -and [int]$_.X509.KeySize -lt 2048 }).Count
                        # 25.1 matches the long name, eg. sha1WithRSAEncryption, earlier versions the short name, eg. sha1RSA.  each version matches only one.
                        sha1Signed       = [int]@('sha1WithRSAEncryption', 'ecdsa-with-SHA1', 'sha1RSA', 'sha1ECDSA' | ForEach-Object { Find-CmCertificate @base -SignatureAlgorithm $_ -CountOnly } | Measure-Object -Sum).Sum
                        md5Signed        = [int]@('md5WithRSAEncryption', 'md5RSA' | ForEach-Object { Find-CmCertificate @base -SignatureAlgorithm $_ -CountOnly } | Measure-Object -Sum).Sum
                        wildcard         = Find-CmCertificate @base -IsWildcard -CountOnly
                        selfSigned       = Find-CmCertificate @base -IsSelfSigned -CountOnly
                        noSans           = @($certs | Where-Object { $_.X509.ValidTo -and -not ($_.X509.SANS.PSObject.Properties.Value | Where-Object { $_ }) }).Count
                        note             = 'RSA and ECC keys, see byKey, are both vulnerable to a large quantum computer; plan migration to post-quantum algorithms with your CAs.'
                    }
                }
            }
        }
        #endregion

        #region find_certificates_by_ca
        @{
            name        = 'find_certificates_by_ca'
            platforms   = 'CM'
            description = 'Find certificates issued by, or chaining to, a certificate authority, eg. to respond to a CA being distrusted or compromised.  Returns the matching issuers with their counts, how each matched, and the certificates.  With include_chain, each other issuer''s chain is followed using its AIA urls to find certificates whose intermediate or root CA matches, so the MCP server needs to reach those urls.  Use get_certificate_consumers for where a certificate is installed.'
            inputSchema = @{
                type       = 'object'
                properties = [ordered]@{
                    ca            = @{ type = 'string'; description = 'Text in the CA subject DN, case-insensitive, eg. eMudhra, EM DV TLS CA - G3B, or a full DN' }
                    include_chain = @{ type = 'boolean'; description = 'Also match certificates whose issuer chains to a matching intermediate or root CA.  Default true.' }
                    path          = @{ type = 'string'; description = 'Policy folder to search, including subfolders.  The entire inventory is used if not provided.' }
                    first         = $firstSchema
                }
                required   = @('ca')
            }
            handler     = {
                param($Arguments, $TrustClient)

                $ca = "$($Arguments.ca)".Trim()
                if ( -not $ca ) { throw 'ca is required' }
                $first = Resolve-TrustMcpFirst $Arguments.first
                $includeChain = $Arguments.include_chain -ne $false
                $limit = 10000
                # following a chain downloads up to a few certificates, so limit the number of issuers checked
                $maxIssuers = 50

                $base = @{ TrustClient = $TrustClient }
                if ( $Arguments.path ) {
                    $base.Path = $Arguments.path
                    $base.Recursive = $true
                }
                $total = Find-CmCertificate @base -CountOnly
                $certs = @(Find-CmCertificate @base -OptionalField Issuer, Subject -First $limit | Where-Object { $_.X509.Issuer })

                $contains = { param([string] $Text) $Text -and $Text.IndexOf($ca, [System.StringComparison]::OrdinalIgnoreCase) -ge 0 }
                $groups = @($certs | Group-Object { $_.X509.Issuer } | Sort-Object Count -Descending)

                $hits = [System.Collections.Generic.List[object]]::new()
                $warnings = [System.Collections.Generic.List[string]]::new()
                $checked = 0
                $notChecked = 0
                $selfSignedSkipped = 0
                $cache = @{}

                foreach ( $g in $groups ) {
                    if ( & $contains $g.Name ) {
                        $hits.Add([ordered]@{ issuer = $g.Name; count = $g.Count; matchedBy = 'issuer'; chain = @(); certs = $g.Group })
                        continue
                    }
                    if ( -not $includeChain ) { continue }
                    # a self-signed certificate is its own issuer and has no chain to follow
                    $signedBy = @($g.Group | Where-Object { $_.X509.Subject -ne $_.X509.Issuer })
                    if ( -not $signedBy ) { $selfSignedSkipped++; continue }
                    if ( $checked -ge $maxIssuers ) { $notChecked++; continue }
                    $checked++

                    # any certificate from the issuer has its AIA url and authority key id
                    $details = (Get-CmCertificate -ID $signedBy[0].Guid -TrustClient $TrustClient).CertificateDetails
                    if ( $details.Subject -eq $details.Issuer ) { continue }
                    $result = Get-TrustMcpIssuerChain -Issuer $details.Issuer -AuthorityKeyId $details.AIAKeyIdentifier -AiaUrl @($details.AIACAIssuerURL) -Cache $cache
                    $result.warnings | ForEach-Object { $warnings.Add($_) }
                    # the issuing CA already didn't match, look above it
                    $above = @($result.chain | Select-Object -Skip 1 | ForEach-Object { $_.subject })
                    if ( $above | Where-Object { & $contains $_ } ) {
                        $hits.Add([ordered]@{ issuer = $g.Name; count = $g.Count; matchedBy = 'chain'; chain = $above; certs = $g.Group })
                    }
                }

                $matchedCerts = @($hits | ForEach-Object { $_.certs })
                [ordered]@{
                    ca                = $ca
                    totalCertificates = $matchedCerts.Count
                    scanned           = $certs.Count
                    truncated         = $total -gt $limit
                    issuersChecked    = $checked
                    # issuers with the fewest certificates aren't chain checked past the limit
                    issuersNotChecked = $notChecked
                    selfSignedIssuers = $selfSignedSkipped
                    issuers           = @($hits | ForEach-Object { [ordered]@{ issuer = $_.issuer; count = $_.count; matchedBy = $_.matchedBy; chainAboveIssuer = $_.chain } })
                    certificates      = @($matchedCerts | Select-Object -First $first | ForEach-Object { [ordered]@{ name = $_.Name; path = $_.Path; issuer = $_.X509.Issuer; validTo = $_.X509.ValidTo } })
                    warnings          = @($warnings | Sort-Object -Unique | Select-Object -First 20)
                }
            }
        }
        #endregion

        #region search_logs
        @{
            name        = 'search_logs'
            platforms   = 'CM'
            description = 'Search the Certificate Manager Self-Hosted event log, most recent first.  Useful to troubleshoot why a certificate failed to renew or provision, or to audit who changed what.  Event data, eg. the new value of a changed attribute, is decoded into data.  Use group_by to summarize many events, eg. errors per application, instead of listing each one.'
            inputSchema = @{
                type       = 'object'
                properties = [ordered]@{
                    path        = @{ type = 'string'; description = 'Only events related to this object path, eg. a certificate' }
                    severity    = @{ type = 'string'; enum = @([enum]::GetNames([CmEventSeverity])); description = 'Only events with this severity' }
                    event_id    = @{ type = 'array'; items = @{ type = 'string'; pattern = '^[0-9a-fA-F]{8}$' }; description = 'Only events with these ids, 8 hex digits, eg. 46680017.  Matched by the server so the whole time range is searched, unlike event and text.  The first 4 digits are the component, eg. 4668 is Adaptable App, so an event_id from one event finds its relatives.' }
                    event       = @{ type = 'string'; description = 'Only events whose name contains this text, case-insensitive, eg. Attribute Changed, Renewal, Script' }
                    text        = @{ type = 'string'; description = 'Only events containing this text, case-insensitive, in the name, text fields, or decoded data, eg. a user, attribute, or value.  event and text search the most recent 2000 events in the time range; if moreMayExist is true narrow with path or since_hours.' }
                    since_hours = @{ type = 'integer'; minimum = 1; description = 'Only events from the last N hours.  Default 24.' }
                    group_by    = @{ type = 'string'; enum = @('component', 'event', 'event_and_component'); description = 'Return one row per object (component), event name, or both, with the count, first and last time, and most common message, instead of each event.  first limits the number of groups.' }
                    first       = $firstSchema
                }
            }
            handler     = {
                param($Arguments, $TrustClient)

                $first = Resolve-TrustMcpFirst $Arguments.first 50
                $filter = $Arguments.event -or $Arguments.text
                # event and text are matched here, and groups are counted here, so read more events
                $scanLimit = if ( $filter -or $Arguments.group_by ) { 2000 } else { $first }

                $params = @{
                    TrustClient = $TrustClient
                    StartTime   = (Get-Date).AddHours( - $(if ( $Arguments.since_hours ) { [int]$Arguments.since_hours } else { 24 }))
                    First       = $scanLimit
                }
                if ( $Arguments.path ) { $params.Path = $Arguments.path }
                if ( $Arguments.severity ) { $params.Severity = $Arguments.severity }

                $strict = [System.Text.UTF8Encoding]::new($false, $true)
                # data is lines, some base64 encoded, eg. "(null)\r\n1\r\nSVJTLU5vb3A=".  decode those which are readable text.
                $decode = {
                    param([string] $Data)
                    if ( -not $Data ) { return @() }
                    @(
                        # leave out .net stack frames, eg. '   at Venafi.Drivers...', they're large and not useful here
                        foreach ( $line in ($Data -split '\r?\n' | Where-Object { $_ -ne '' -and $_ -notmatch '^\s+at \S' }) ) {
                            if ( $line -eq '(null)' ) { $null; continue }
                            $value = $line
                            if ( $line.Length -ge 8 -and $line.Length % 4 -eq 0 -and $line -match '^[A-Za-z0-9+/]+={0,2}$' ) {
                                try {
                                    $text = $strict.GetString([Convert]::FromBase64String($line))
                                    if ( $text -notmatch '[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]' ) { $value = $text }
                                }
                                catch {
                                    # not base64 or not utf8 text, keep as is
                                    $null = $_
                                }
                            }
                            $value
                        }
                    )
                }

                # true if any read returned its limit, so there may be more in the log than we have
                $hitLimit = $false
                $raw = if ( $Arguments.event_id ) {
                    # the api takes one event id at a time, merge them newest first like a normal read
                    @(@(
                            foreach ( $id in @($Arguments.event_id) ) {
                                if ( $id -notmatch '^[0-9a-fA-F]{8}$' ) { throw "event_id '$id' must be 8 hex digits, eg. 46680017" }
                                $read = @(Read-CmLog @params -EventId $id)
                                if ( $read.Count -ge $scanLimit ) { $hitLimit = $true }
                                $read
                            }
                        ) | Sort-Object -Property ServerTimestamp -Descending)
                }
                else {
                    $read = @(Read-CmLog @params)
                    $hitLimit = $read.Count -ge $scanLimit
                    $read
                }
                $events = @(
                    foreach ( $e in $raw ) {
                        $data = & $decode $e.Data
                        $out = [ordered]@{
                            timestamp = $e.ServerTimestamp
                            severity  = $e.Severity
                            name      = $e.Name
                            component = $e.Component
                            text1     = $e.Text1
                            text2     = $e.Text2
                            data      = $data
                            value1    = $e.Value1
                            value2    = $e.Value2
                            sourceIP  = $e.SourceIP
                            eventId   = $e.EventId
                        }
                        if ( $Arguments.event -and $e.Name -notlike "*$($Arguments.event)*" ) { continue }
                        if ( $Arguments.text ) {
                            $haystack = @($e.Name, $e.Text1, $e.Text2, $e.Component) + $data
                            if ( -not ($haystack | Where-Object { "$_" -like "*$($Arguments.text)*" }) ) { continue }
                        }
                        $out
                    }
                )

                if ( $Arguments.group_by ) {
                    $keyOf = switch ( $Arguments.group_by ) {
                        'component' { { $_.component } }
                        'event' { { $_.name } }
                        default { { '{0}|{1}' -f $_.name, $_.component } }
                    }
                    $groups = @(
                        $events | Group-Object -Property $keyOf | ForEach-Object {
                            $g = $_.Group
                            $times = @($g.timestamp | Sort-Object)
                            # text2 usually holds the error, otherwise the first decoded data
                            $message = @($g | ForEach-Object { if ( $_.text2 ) { $_.text2 } else { @($_.data | Where-Object { $_ })[0] } } | Where-Object { $_ }) |
                                Group-Object -NoElement | Sort-Object Count -Descending | Select-Object -First 1 -ExpandProperty Name
                            $out = [ordered]@{}
                            if ( $Arguments.group_by -ne 'event' ) { $out.component = $g[0].component }
                            if ( $Arguments.group_by -ne 'component' ) { $out.event = $g[0].name } else { $out.events = @($g.name | Sort-Object -Unique) }
                            $out.count = $g.Count
                            $out.first = $times[0]
                            $out.last = $times[-1]
                            $out.severity = @($g.severity | ForEach-Object { "$_" } | Sort-Object -Unique)
                            $out.eventIds = @($g.eventId | Sort-Object -Unique)
                            $out.message = $message
                            $out
                        } | Sort-Object { $_.count } -Descending
                    )
                    return [ordered]@{
                        totalEvents  = $events.Count
                        totalGroups  = $groups.Count
                        # counts are only complete if the read didn't hit its limit
                        moreMayExist = $hitLimit
                        groups       = @($groups | Select-Object -First $first)
                    }
                }

                [ordered]@{
                    returned     = [Math]::Min($events.Count, $first)
                    # the log may have more if the read hit its limit
                    moreMayExist = ($events.Count -gt $first) -or $hitLimit
                    events       = @($events | Select-Object -First $first)
                }
            }
        }

        @{
            name        = 'search_logs'
            platforms   = 'CMS', 'NGTS'
            description = 'Search the activity log, most recent first.  Useful to troubleshoot failures or audit who changed what.'
            inputSchema = @{
                type       = 'object'
                properties = [ordered]@{
                    event_type  = @{ type = 'string'; description = 'Event type, eg. Certificates, Authentication, Applications' }
                    event_name  = @{ type = 'string'; description = 'Event name, eg. Certificate Validation Started' }
                    message     = @{ type = 'string'; description = 'Text to find in the event message' }
                    critical    = @{ type = 'boolean'; description = 'Only critical events' }
                    since_hours = @{ type = 'integer'; minimum = 1; description = 'Only events from the last N hours.  Default 24.' }
                    first       = $firstSchema
                }
            }
            handler     = {
                param($Arguments, $TrustClient)

                $params = @{
                    TrustClient = $TrustClient
                    DateFrom    = (Get-Date).AddHours( - $(if ( $Arguments.since_hours ) { [int]$Arguments.since_hours } else { 24 }))
                    First       = Resolve-TrustMcpFirst $Arguments.first 50
                    Order       = @{ 'activityDate' = 'desc' }
                }
                if ( $Arguments.event_type ) { $params.EventType = $Arguments.event_type }
                if ( $Arguments.event_name ) { $params.EventName = $Arguments.event_name }
                if ( $Arguments.message ) { $params.Message = $Arguments.message }
                if ( $Arguments.critical ) { $params.Critical = $true }

                Find-TrustLog @params
            }
        }
        #endregion

        #region browse_policy_tree
        @{
            name        = 'browse_policy_tree'
            platforms   = 'CM'
            description = 'List objects in the Certificate Manager Self-Hosted policy tree, eg. folders (Policy), certificates, devices, and applications.  Start at \VED\Policy and drill down.'
            inputSchema = @{
                type       = 'object'
                properties = [ordered]@{
                    path      = @{ type = 'string'; description = 'Folder path to list.  Default \VED\Policy.' }
                    class     = @{ type = 'array'; items = @{ type = 'string' }; description = 'Only objects of these classes, eg. Policy, Device, Basic.  Certificates have several classes; to find all certificates provide X509 Certificate, X509 Server Certificate, X509 Device Certificate, X509 User Certificate, and X509 Code Signing Certificate.' }
                    name      = @{ type = 'string'; description = 'Object name, case-insensitive contains, eg. test matches www.test.com and Test Folder.  Use * and ? for your own wildcard pattern.' }
                    recursive = @{ type = 'boolean'; description = 'Include objects in subfolders.  Default false.' }
                    first     = $firstSchema
                }
            }
            handler     = {
                param($Arguments, $TrustClient)

                $params = @{
                    TrustClient = $TrustClient
                    Path        = if ( $Arguments.path ) { $Arguments.path } else { '\VED\Policy' }
                    Recursive   = ($Arguments.recursive -eq $true)
                }
                # a single string is accepted too
                if ( $Arguments.class ) { $params.Class = [string[]]@($Arguments.class) }
                if ( $Arguments.name ) {
                    $params.Pattern = if ( $Arguments.name -match '[*?]' ) { $Arguments.name } else { '*{0}*' -f $Arguments.name }
                }

                $objects = @(Find-CmObject @params)
                $first = Resolve-TrustMcpFirst $Arguments.first 100

                [ordered]@{
                    total   = $objects.Count
                    objects = @($objects | Select-Object -First $first Name, TypeName, Path, Guid)
                }
            }
        }
        #endregion

        #region get_attributes
        @{
            name        = 'get_attributes'
            platforms   = 'CM'
            description = 'Get attribute values for a Certificate Manager Self-Hosted object, eg. a certificate or device, or the policy attributes configured on a policy folder.  For policy attributes provide class, eg. X509 Certificate, and the folder path; policyPath shows where the value is inherited from and locked whether it is enforced.  Common X509 Certificate policy attributes include Certificate Authority, Management Type, Key Algorithm, Key Bit Strength, Contact, and Approver.  Use recursive with class and attributes to search all policy folders, eg. find which folders use a specific CA.'
            inputSchema = @{
                type       = 'object'
                properties = [ordered]@{
                    path       = @{ type = 'string'; description = 'Object or policy folder path, eg. \VED\Policy\Certificates, or guid' }
                    class      = @{ type = 'string'; description = 'Read policy attributes for this class instead of object attributes, eg. X509 Certificate.  path must be a policy folder.' }
                    attributes = @{ type = 'array'; items = @{ type = 'string' }; description = 'Attribute names, or custom field labels, to retrieve.  All attributes are retrieved if not provided, which is slower.' }
                    recursive  = @{ type = 'boolean'; description = 'Also read policy attributes for every policy folder under path.  Requires class and attributes.  Only folders with a value are returned.  Default false.' }
                    first      = @{ type = 'integer'; minimum = 1; maximum = 200; description = 'With recursive, maximum number of policy folders to read.  Default 100, maximum 200.' }
                }
                required   = @('path')
            }
            handler     = {
                param($Arguments, $TrustClient)

                $attribs = @($Arguments.attributes | Where-Object { $_ })

                if ( $Arguments.recursive -and -not ($Arguments.class -and $attribs) ) {
                    throw 'recursive requires class and attributes'
                }

                $params = @{ TrustClient = $TrustClient }
                if ( $Arguments.class ) { $params.Class = $Arguments.class }
                if ( $attribs ) { $params.Attribute = $attribs } else { $params.All = $true }

                $path = $Arguments.path
                if ( $path -match '^\{?[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}\}?$' ) {
                    $path = (Get-CmObject -Guid $path -TrustClient $TrustClient).Path
                }

                # key attributes by name so secret looking names are redacted by the sanitizer
                $convert = {
                    param($Result)
                    $out = [ordered]@{}
                    foreach ( $a in $Result.Attribute ) {
                        $thisAttrib = [ordered]@{ value = $a.Value; policyPath = $a.PolicyPath; locked = $a.Locked }
                        if ( $null -ne $a.Overridden ) { $thisAttrib.overridden = $a.Overridden }
                        if ( $a.CustomFieldGuid ) { $thisAttrib.customFieldGuid = $a.CustomFieldGuid }
                        $out[$a.Name] = $thisAttrib
                    }
                    [ordered]@{ path = $Result.Path; className = $Result.ClassName; attributes = $out }
                }

                if ( -not $Arguments.recursive ) {
                    return (Get-CmAttribute -Path $path @params | ForEach-Object { & $convert $_ })
                }

                $folders = @($path) + @(Find-CmObject -Path $path -Class Policy -Recursive -TrustClient $TrustClient | Select-Object -ExpandProperty Path)
                $first = Resolve-TrustMcpFirst $Arguments.first 100
                $results = @($folders | Select-Object -First $first | Get-CmAttribute @params | ForEach-Object { & $convert $_ })

                [ordered]@{
                    foldersSearched = [System.Math]::Min($first, $folders.Count)
                    totalFolders    = $folders.Count
                    truncated       = ($folders.Count -gt $first)
                    policies        = @($results | Where-Object { $_.attributes.Values | Where-Object { $null -ne $_.value } } | Sort-Object { $_.path })
                }
            }
        }
        #endregion

        #region list_ca_templates
        @{
            name        = 'list_ca_templates'
            platforms   = 'CM'
            description = 'List CA templates, the objects which connect Certificate Manager Self-Hosted to a certificate authority, eg. Microsoft CA, DigiCert CA, Adaptable CA.  For Adaptable CAs the driver script is included.  To see which policy folders use a template, call get_attributes with class X509 Certificate, attributes Certificate Authority, and recursive.'
            inputSchema = @{
                type       = 'object'
                properties = [ordered]@{
                    path = @{ type = 'string'; description = 'Folder containing CA templates, including subfolders.  Default \VED\Policy\Administration\CAs.' }
                }
            }
            handler     = {
                param($Arguments, $TrustClient)

                $path = if ( $Arguments.path ) { $Arguments.path } else { '\VED\Policy\Administration\CAs' }
                $templates = @(Find-CmObject -Path $path -Recursive -TrustClient $TrustClient | Where-Object TypeName -ne 'Policy')

                $adaptable = @($templates | Where-Object TypeName -eq 'Adaptable CA')
                $scripts = @{}
                if ( $adaptable ) {
                    $adaptable | Get-CmAttribute -Attribute 'Interoperability Script' -TrustClient $TrustClient -ErrorAction SilentlyContinue | ForEach-Object {
                        $scripts[$_.Path] = $_.'Interoperability Script'
                    }
                }

                [ordered]@{
                    total       = $templates.Count
                    caTemplates = @(
                        foreach ( $t in $templates ) {
                            $out = [ordered]@{ name = $t.Name; typeName = $t.TypeName; path = $t.Path; guid = $t.Guid }
                            if ( $scripts[$t.Path] ) { $out.driverScript = $scripts[$t.Path] }
                            $out
                        }
                    )
                }
            }
        }
        #endregion

        #region find_workflow_tickets
        @{
            name        = 'find_workflow_tickets'
            platforms   = 'CM'
            description = 'Get workflow approval tickets, including status, approvers, the reason the ticket was created, and who last updated it.  Provide a certificate path for its tickets, or a folder path, or nothing, to find tickets for all certificates pending approval.'
            inputSchema = @{
                type       = 'object'
                properties = [ordered]@{
                    path  = @{ type = 'string'; description = 'Certificate path, or a policy folder to search including subfolders.  The entire inventory is searched if not provided.' }
                    first = @{ type = 'integer'; minimum = 1; maximum = 200; description = 'Maximum number of certificates to get tickets for.  Default 25, maximum 200.' }
                }
            }
            handler     = {
                param($Arguments, $TrustClient)

                $certPaths = if ( $Arguments.path -and (Get-CmObject -Path $Arguments.path -TrustClient $TrustClient).TypeName -ne 'Policy' ) {
                    $Arguments.path
                }
                else {
                    $params = @{ TrustClient = $TrustClient; PendingWorkflow = $true; First = (Resolve-TrustMcpFirst $Arguments.first) }
                    if ( $Arguments.path ) {
                        $params.Path = $Arguments.path
                        $params.Recursive = $true
                    }
                    Find-CmCertificate @params | Select-Object -ExpandProperty Path
                }

                @(
                    foreach ( $thisPath in $certPaths ) {
                        Get-CmWorkflowTicket -Path $thisPath -TrustClient $TrustClient |
                            Select-Object @{ n = 'CertificatePath'; e = { $thisPath } }, * -ExcludeProperty Result
                    }
                )
            }
        }
        #endregion

        #region get_certificate_consumers
        @{
            name        = 'get_certificate_consumers'
            platforms   = 'CM'
            description = 'List where a certificate is installed: the applications, eg. F5 LTM, IIS, PEM, which consume it and the device each belongs to.  Use this to assess the impact of a certificate expiring or being revoked.'
            inputSchema = @{
                type       = 'object'
                properties = @{
                    id = @{ type = 'string'; description = 'Certificate path or guid' }
                }
                required   = @('id')
            }
            handler     = {
                param($Arguments, $TrustClient)

                $path = if ( Test-IsGuid $Arguments.id ) { (Get-CmObject -Guid $Arguments.id -TrustClient $TrustClient).Path } else { $Arguments.id }
                $consumers = @(Get-CmAttribute -Path $path -Attribute 'Consumers' -TrustClient $TrustClient -AsValue | Where-Object { $_ })

                [ordered]@{
                    certificatePath = $path
                    total           = $consumers.Count
                    consumers       = @(
                        if ( $consumers ) {
                            Get-CmObject -Path $consumers -TrustClient $TrustClient | ForEach-Object {
                                [ordered]@{ path = $_.Path; typeName = $_.TypeName; device = $_.ParentPath }
                            }
                        }
                    )
                }
            }
        }
        #endregion

        #region get_certificate_chain
        @{
            name        = 'get_certificate_chain'
            platforms   = 'CM'
            description = 'Get a certificate and its issuing chain, end entity first and root last, with subject, issuer, serial, thumbprints, validity, and key details for each.  Use this to check which intermediate and root CAs a certificate chains to.  The certificate comes from Certificate Manager and each issuer is downloaded from the Authority Information Access url in the certificate below it, so the MCP server needs to reach those urls; complete is false and warnings explain why if the chain could not be followed to a root.  Private keys are never retrieved.'
            inputSchema = @{
                type       = 'object'
                properties = @{
                    id = @{ type = 'string'; description = 'Certificate path or guid' }
                }
                required   = @('id')
            }
            handler     = {
                param($Arguments, $TrustClient)

                # retrieving the certificate from Certificate Manager needs certificate:manage, so use its details and download the issuers instead
                $cert = Get-CmCertificate -ID $Arguments.id -TrustClient $TrustClient
                $details = $cert.CertificateDetails
                if ( -not $details.Thumbprint ) { throw ('{0} has not been issued, so it has no chain' -f $cert.Path) }

                $leaf = [ordered]@{
                    subject            = $details.Subject
                    issuer             = $details.Issuer
                    serialNumber       = $details.Serial
                    thumbprintSha1     = $details.Thumbprint
                    validFrom          = $details.ValidFrom
                    validTo            = $details.ValidTo
                    keyAlgorithm       = $details.KeyAlgorithm
                    keySize            = $details.KeySize
                    signatureAlgorithm = $details.SignatureAlgorithm
                    selfSigned         = $details.Subject -eq $details.Issuer
                    source             = 'Certificate Manager'
                }

                $issuers = if ( $leaf.selfSigned ) {
                    @{ chain = @(); complete = $true; warnings = @() }
                }
                else {
                    Get-TrustMcpIssuerChain -Issuer $details.Issuer -AuthorityKeyId $details.AIAKeyIdentifier -AiaUrl @($details.AIACAIssuerURL)
                }

                [ordered]@{
                    certificatePath = $cert.Path
                    total           = 1 + $issuers.chain.Count
                    complete        = $issuers.complete
                    chain           = @(, $leaf) + @($issuers.chain)
                    warnings        = @($issuers.warnings)
                }
            }
        }
        #endregion

        #region find_objects_by_attribute
        @{
            name        = 'find_objects_by_attribute'
            platforms   = 'CM'
            description = 'Find objects by the value of an attribute set directly on them, eg. applications whose PowerShell Script is MyDriver, devices whose Host is 10.0.0.1, or certificates with a custom field value.  Values inherited from policy folders are not searched; to find folders which set a value use get_attributes with class, attributes, and recursive.  Use list_class_attributes for valid attribute names.'
            inputSchema = @{
                type       = 'object'
                properties = [ordered]@{
                    attribute = @{ type = 'string'; description = 'Attribute name or custom field label, eg. PowerShell Script, Host, Description' }
                    value     = @{ type = 'string'; description = 'Value to find, case-insensitive contains.  Use * and ? for your own wildcard pattern.  Custom fields require the exact value.' }
                    class     = @{ type = 'array'; items = @{ type = 'string' }; description = 'Only objects of these classes, eg. Adaptable App, Device, X509 Server Certificate' }
                    first     = $firstSchema
                }
                required   = @('attribute', 'value')
            }
            handler     = {
                param($Arguments, $TrustClient)

                # custom fields are matched on the exact value so don't add wildcards
                $isCustomField = $TrustClient.PlatformData.CustomField | Where-Object { $_.Label -eq $Arguments.attribute -or $_.Guid -eq $Arguments.attribute }
                $pattern = if ( $isCustomField -or $Arguments.value -match '[*?]' ) { $Arguments.value } else { '*{0}*' -f $Arguments.value }

                $params = @{
                    TrustClient = $TrustClient
                    Attribute   = $Arguments.attribute
                    Pattern     = $pattern
                }
                if ( $Arguments.class ) { $params.Class = [string[]]@($Arguments.class) }

                $objects = @(Find-CmObject @params)
                $first = Resolve-TrustMcpFirst $Arguments.first 100

                [ordered]@{
                    total   = $objects.Count
                    objects = @($objects | Select-Object -First $first Name, TypeName, Path, Guid)
                }
            }
        }
        #endregion

        #region list_class_attributes
        @{
            name        = 'list_class_attributes'
            platforms   = 'CM'
            description = 'List the attribute names, and custom fields, for a class, eg. X509 Server Certificate, Adaptable App, Device, to use with get_attributes and find_objects_by_attribute.  definedBy is the class the attribute is inherited from.'
            inputSchema = @{
                type       = 'object'
                properties = @{
                    class = @{ type = 'string'; description = 'Class name, eg. X509 Server Certificate, Adaptable App, Device, Policy' }
                }
                required   = @('class')
            }
            handler     = {
                param($Arguments, $TrustClient)

                $customFields = @((Get-CmCustomField -Class $Arguments.class -TrustClient $TrustClient).Items | Where-Object { $_ })
                # custom fields are also class attributes named by guid, they're listed with their labels in customFields instead
                $attributes = @(Get-CmClassAttribute -ClassName $Arguments.class -TrustClient $TrustClient | Where-Object Name -NotIn $customFields.Guid)

                [ordered]@{
                    class        = $Arguments.class
                    attributes   = @($attributes | Sort-Object Name | ForEach-Object { [ordered]@{ name = $_.Name; definedBy = $_.Class } })
                    customFields = @(
                        foreach ( $cf in $customFields ) {
                            [ordered]@{
                                label         = $cf.Label
                                guid          = $cf.Guid
                                type          = $cf.Type
                                mandatory     = [bool]$cf.Mandatory
                                policyable    = [bool]$cf.Policyable
                                allowedValues = @($cf.AllowedValues)
                                defaultValues = @($cf.DefaultValues)
                            }
                        }
                    )
                }
            }
        }
        #endregion

        #region get_system_status
        @{
            name        = 'get_system_status'
            platforms   = 'CM'
            description = 'Get Certificate Manager Self-Hosted health: the status and modules of each server''s services, eg. the platform, log server, and IIS, and the processing engines with the policy folders directly assigned to each.  Use this when certificates are not processing, eg. renewals or provisioning are not starting.'
            # the engine endpoints are called directly, Get-CmEngineFolder needs configuration=manage to look up engines by folder
            cmScope     = 'configuration=$null'
            inputSchema = @{ type = 'object'; properties = @{} }
            handler     = {
                param($Arguments, $TrustClient)

                $status = try {
                    @(Get-CmSystemStatus -TrustClient $TrustClient)
                }
                catch {
                    # the api is known to fail on some versions, still return the engines
                    "Unable to get the service status: $($_.Exception.Message)"
                }

                $engines = @((Invoke-TrustRestMethod -UriLeaf 'ProcessingEngines/' -TrustClient $TrustClient).Engines | Where-Object { $_ })

                [ordered]@{
                    services = $status
                    engines  = @(
                        foreach ( $e in $engines ) {
                            $guid = '{{{0}}}' -f "$($e.EngineGuid)".Trim('{}')
                            $folders = (Invoke-TrustRestMethod -UriLeaf "ProcessingEngines/Engine/$guid" -TrustClient $TrustClient).Folders
                            [ordered]@{
                                name    = $e.EngineName
                                path    = $e.EngineDN
                                # the engine itself is returned as a folder
                                folders = @($folders | Where-Object { $_ -and $_.FolderGuid -ne $guid } | ForEach-Object { $_.FolderDN })
                            }
                        }
                    )
                }
            }
        }
        #endregion

        #region get_permissions
        @{
            name        = 'get_permissions'
            platforms   = 'CM'
            description = 'Get the permissions users and groups have on an object, eg. a policy folder or certificate.  Each identity lists the permissions it is allowed: view, read, write, create, delete, rename, revoke, associate, policyWrite, managePermissions, privateKeyRead, and privateKeyWrite.  Effective permissions, including inherited, are returned by default.  Requires the Security token scope.'
            inputSchema = @{
                type       = 'object'
                properties = [ordered]@{
                    path     = @{ type = 'string'; description = 'Object path or guid, eg. \VED\Policy\Certificates' }
                    identity = @{ type = 'string'; description = 'Only this user or group, prefixed id eg. local:{guid} or AD+domain:guid.  Use get_identity to find it.' }
                    explicit = @{ type = 'boolean'; description = 'Return permissions set directly on the object and those inherited from parent folders separately instead of effective.  Default false.' }
                }
                required   = @('path')
            }
            handler     = {
                param($Arguments, $TrustClient)

                $params = @{ TrustClient = $TrustClient }
                if ( Test-IsGuid $Arguments.path ) { $params.Guid = $Arguments.path } else { $params.Path = $Arguments.path }
                if ( $Arguments.identity ) { $params.IdentityId = $Arguments.identity }
                if ( $Arguments.explicit -eq $true ) { $params.Explicit = $true }

                # list allowed permissions by name, eg. IsPrivateKeyReadAllowed -> privateKeyRead.
                # this keeps the output small and avoids the sanitizer redacting the private key permissions by property name.
                $toAllowed = {
                    param($Permission)
                    @(
                        foreach ( $prop in $Permission.PSObject.Properties ) {
                            if ( $prop.Value -eq $true ) {
                                $n = $prop.Name -replace '^Is' -replace 'Allowed$'
                                $n.Substring(0, 1).ToLower() + $n.Substring(1)
                            }
                        }
                    )
                }

                $permissions = @(Get-CmPermission @params)

                [ordered]@{
                    path        = if ( $permissions ) { $permissions[0].Path } else { $Arguments.path }
                    total       = $permissions.Count
                    permissions = @(
                        foreach ( $p in $permissions ) {
                            $out = [ordered]@{
                                identityId   = $p.IdentityId
                                identityName = $p.IdentityName
                                identityPath = $p.IdentityPath
                            }
                            # @() so a single permission stays an array
                            if ( $params.Explicit ) {
                                $out.explicit = @(& $toAllowed $p.ExplicitPermissions)
                                $out.inherited = @(& $toAllowed $p.ImplicitPermissions)
                            }
                            else {
                                $out.effective = @(& $toAllowed $p.EffectivePermissions)
                            }
                            $out
                        }
                    )
                }
            }
        }
        #endregion

        #region get_identity
        @{
            name        = 'get_identity'
            platforms   = 'CM'
            description = 'Resolve users and groups, eg. a contact or approver value such as local:{guid} or AD+domain:guid returned by other tools, or search identities by name.  Returns name, prefixed id, and whether it is a group.'
            inputSchema = @{
                type       = 'object'
                properties = [ordered]@{
                    id              = @{ type = 'string'; description = 'Prefixed identity, eg. local:{guid}, or guid' }
                    name            = @{ type = 'string'; description = 'Search users and groups by name, partial match.  Used when id is not provided.' }
                    include_members = @{ type = 'boolean'; description = 'For a group id, also return its members, including nested.  Default false.' }
                    first           = $firstSchema
                }
            }
            handler     = {
                param($Arguments, $TrustClient)

                if ( $Arguments.id ) {
                    Get-CmIdentity -ID $Arguments.id -IncludeMembers:($Arguments.include_members -eq $true) -TrustClient $TrustClient
                }
                elseif ( $Arguments.name ) {
                    @(Find-CmIdentity -Name $Arguments.name -First (Resolve-TrustMcpFirst $Arguments.first) -TrustClient $TrustClient)
                }
                else {
                    throw 'id or name is required'
                }
            }
        }

        @{
            name        = 'get_identity'
            platforms   = 'CMS', 'NGTS'
            description = 'Resolve a user or team, eg. an owner id returned by other tools, to its name and details.  Provide a user id or username, or a team id or name.'
            inputSchema = @{
                type       = 'object'
                properties = [ordered]@{
                    id   = @{ type = 'string'; description = 'User or team id, username, or team name' }
                    type = @{ type = 'string'; enum = @('user', 'team'); description = 'Identity type.  Both are tried, user first, if not provided.' }
                }
                required   = @('id')
            }
            handler     = {
                param($Arguments, $TrustClient)

                $out = $null
                if ( $Arguments.type -ne 'team' ) {
                    $out = try { Get-CmsUser -User $Arguments.id -TrustClient $TrustClient } catch { if ( $Arguments.type -eq 'user' ) { throw } }
                }
                if ( -not $out -and $Arguments.type -ne 'user' ) {
                    $out = Get-CmsTeam -Team $Arguments.id -TrustClient $TrustClient
                }
                if ( -not $out ) { throw "No user or team found for '$($Arguments.id)'" }
                $out
            }
        }
        #endregion

        #region list_applications
        @{
            name        = 'list_applications'
            platforms   = 'CMS', 'NGTS'
            description = 'List applications, which group certificates and define their owners and allowed issuing templates.  Provide a name or id for a single application, optionally with its renewal configuration.'
            inputSchema = @{
                type       = 'object'
                properties = [ordered]@{
                    application    = @{ type = 'string'; description = 'Application name or id.  All applications are returned if not provided.' }
                    include_config = @{ type = 'boolean'; description = 'Include issuing templates and auto renew/provision settings.  Default false.' }
                    first          = $firstSchema
                }
            }
            handler     = {
                param($Arguments, $TrustClient)

                $params = @{ TrustClient = $TrustClient; IncludeConfig = ($Arguments.include_config -eq $true) }
                if ( $Arguments.application ) { $params.Application = $Arguments.application } else { $params.All = $true }

                $apps = @(Get-CmsApplication @params)
                $first = Resolve-TrustMcpFirst $Arguments.first

                [ordered]@{
                    total        = $apps.Count
                    applications = @($apps | Select-Object -First $first)
                }
            }
        }
        #endregion

        #region find_certificate_requests
        @{
            name        = 'find_certificate_requests'
            platforms   = 'CMS', 'NGTS'
            description = 'Search certificate requests, most recent first, to troubleshoot issuance, eg. requests which failed, were rejected, or are pending approval.  Provide id for a single request.'
            inputSchema = @{
                type       = 'object'
                properties = [ordered]@{
                    id               = @{ type = 'string'; description = 'Certificate request id.  Other arguments are ignored.' }
                    status           = @{ type = 'array'; items = @{ type = 'string'; enum = @('NEW', 'PENDING', 'PENDING_APPROVAL', 'PENDING_FINAL_APPROVAL', 'REJECTED_APPROVAL', 'REQUESTED', 'ISSUED', 'REJECTED', 'CANCELLED', 'REVOKED', 'FAILED', 'DELETED') }; description = 'Only requests with any of these statuses' }
                    application      = @{ type = 'string'; description = 'Application name or id' }
                    issuing_template = @{ type = 'string'; description = 'Issuing template name or id' }
                    since_hours      = @{ type = 'integer'; minimum = 1; description = 'Only requests created in the last N hours.  Default 168, 7 days.' }
                    first            = $firstSchema
                }
            }
            handler     = {
                param($Arguments, $TrustClient)

                # the csr is large and not useful to a model
                $exclude = 'certificateSigningRequest', 'csr'

                if ( $Arguments.id ) {
                    return (Get-TrustCertificateRequest -CertificateRequest $Arguments.id -TrustClient $TrustClient | Select-Object -Property * -ExcludeProperty $exclude)
                }

                $params = @{
                    TrustClient    = $TrustClient
                    CreateDateFrom = (Get-Date).AddHours( - $(if ( $Arguments.since_hours ) { [int]$Arguments.since_hours } else { 168 }))
                    First          = Resolve-TrustMcpFirst $Arguments.first
                    Order          = @{ 'creationDate' = 'desc' }
                }
                if ( $Arguments.status ) { $params.Status = @($Arguments.status) }
                if ( $Arguments.application ) { $params.Application = $Arguments.application }
                if ( $Arguments.issuing_template ) { $params.IssuingTemplate = $Arguments.issuing_template }

                Find-TrustCertificateRequest @params | Select-Object -Property * -ExcludeProperty $exclude
            }
        }
        #endregion

        #region list_vsatellites
        @{
            name        = 'list_vsatellites'
            platforms   = 'CMS', 'NGTS'
            description = 'List VSatellites, the on-premises agents which perform discovery and provisioning, with their status, version, and last seen details, optionally with their workers.  Use this to troubleshoot discovery or provisioning that is not running.'
            inputSchema = @{
                type       = 'object'
                properties = [ordered]@{
                    vsatellite      = @{ type = 'string'; description = 'VSatellite name or id.  All VSatellites are returned if not provided.' }
                    include_workers = @{ type = 'boolean'; description = 'Include the workers for each VSatellite and their status.  Default false.' }
                }
            }
            handler     = {
                param($Arguments, $TrustClient)

                $params = @{ TrustClient = $TrustClient }
                if ( $Arguments.vsatellite ) { $params.VSatellite = $Arguments.vsatellite } else { $params.All = $true }

                # the encryption key is public but large and not useful to a model
                $vsats = @(Get-TrustSatellite @params | Select-Object -Property * -ExcludeProperty encryptionKey, encryptionKeyId)
                if ( $Arguments.include_workers ) {
                    foreach ( $v in $vsats ) {
                        $v | Add-Member -NotePropertyName workers -NotePropertyValue @(Get-TrustSatelliteWorker -VSatellite $v.vsatelliteId -TrustClient $TrustClient) -Force
                    }
                }

                [ordered]@{
                    total       = $vsats.Count
                    vsatellites = $vsats
                }
            }
        }
        #endregion

        #region list_connectors
        @{
            name        = 'list_connectors'
            platforms   = 'CMS', 'NGTS'
            description = 'List connectors, the plugins which integrate with machines, CAs, and credential managers, with their type, maintainer, image, and source.  source is GLOBAL for connectors published by Venafi and CUSTOM for those uploaded to this tenant; it is inferred from the maintainer and image registry as the API does not provide it.'
            inputSchema = @{
                type       = 'object'
                properties = [ordered]@{
                    connector      = @{ type = 'string'; description = 'Connector id, or name partial match' }
                    connector_type = @{ type = 'string'; enum = @('MACHINE', 'CA', 'CREDENTIAL_MANAGER', 'TPP') }
                    source         = @{ type = 'string'; enum = @('GLOBAL', 'CUSTOM') }
                }
            }
            handler     = {
                param($Arguments, $TrustClient)

                # get all and filter here, name lookup in Get-TrustConnector is exact match only
                $connectors = Get-TrustConnector -All -TrustClient $TrustClient | ForEach-Object {
                    $image = $_.manifest.deployment.image
                    # venafi published connectors have no maintainer and come from the public registry
                    $isGlobal = [string]::IsNullOrEmpty($_.maintainer) -and $image -like 'registry.venafi.cloud/public/*'
                    [pscustomobject]@{
                        connectorId     = $_.connectorId
                        name            = $_.name
                        connectorType   = $_.connectorType
                        source          = if ( $isGlobal ) { 'GLOBAL' } else { 'CUSTOM' }
                        maintainer      = $_.maintainer
                        disabled        = $_.disabled
                        revision        = $_.revision
                        workTypes       = $_.workTypes
                        executionTarget = $_.manifest.deployment.executionTarget
                        image           = $image
                        creationTime    = $_.creationTime
                        lastModifiedOn  = $_.lastModifiedOn
                    }
                }

                if ( $Arguments.connector ) {
                    $c = $Arguments.connector
                    $connectors = $connectors | Where-Object { $_.connectorId -eq $c -or $_.name -like "*$c*" }
                }
                if ( $Arguments.connector_type ) { $connectors = $connectors | Where-Object connectorType -eq $Arguments.connector_type }
                if ( $Arguments.source ) { $connectors = $connectors | Where-Object source -eq $Arguments.source }

                $connectors = @($connectors | Sort-Object source, name)
                [ordered]@{
                    total      = $connectors.Count
                    connectors = $connectors
                }
            }
        }
        #endregion

        #region find_machines
        @{
            name        = 'find_machines'
            platforms   = 'CMS', 'NGTS'
            description = 'Search machines, the servers and services where certificates are provisioned, eg. F5, Citrix, IIS, cloud keystores.  Connection details are not returned.'
            inputSchema = @{
                type       = 'object'
                properties = [ordered]@{
                    name         = @{ type = 'string'; description = 'Machine name, partial match' }
                    machine_type = @{ type = 'string'; description = 'Machine type, eg. F5 BIG-IP LTM, Microsoft IIS' }
                    status       = @{ type = 'string'; enum = @('DRAFT', 'VERIFIED', 'UNVERIFIED') }
                    first        = $firstSchema
                }
            }
            handler     = {
                param($Arguments, $TrustClient)

                $params = @{
                    TrustClient = $TrustClient
                    First       = Resolve-TrustMcpFirst $Arguments.first
                }
                if ( $Arguments.name ) { $params.Name = $Arguments.name }
                if ( $Arguments.machine_type ) { $params.MachineType = $Arguments.machine_type }
                if ( $Arguments.status ) { $params.Status = $Arguments.status }

                Find-TrustMachine @params | Select-Object -Property * -ExcludeProperty connectionDetails
            }
        }
        #endregion

        #region find_machine_identities
        @{
            name        = 'find_machine_identities'
            platforms   = 'CMS', 'NGTS'
            description = 'Find where certificates are installed: machine identities link a certificate to a machine and its binding, eg. an F5 virtual server, IIS site, or keystore.  Search by certificate to assess the impact of it expiring or being revoked, or by machine to see what it hosts.'
            inputSchema = @{
                type       = 'object'
                properties = [ordered]@{
                    certificate = @{ type = 'string'; description = 'Certificate name or id' }
                    machine     = @{ type = 'string'; description = 'Machine name or id' }
                    status      = @{ type = 'string'; enum = @('DISCOVERED', 'VALIDATED', 'INSTALLED') }
                    first       = $firstSchema
                }
            }
            handler     = {
                param($Arguments, $TrustClient)

                $params = @{
                    TrustClient = $TrustClient
                    First       = Resolve-TrustMcpFirst $Arguments.first
                }
                if ( $Arguments.certificate ) { $params.Certificate = $Arguments.certificate }
                if ( $Arguments.machine ) { $params.Machine = $Arguments.machine }
                if ( $Arguments.status ) { $params.Status = $Arguments.status }

                $identities = @(Find-TrustMachineIdentity @params)

                # identities only have the machine id, add the name.  machines are cached so this is one lookup.
                $machineNames = @{}
                foreach ( $id in @($identities.machineId | Where-Object { $_ } | Sort-Object -Unique) ) {
                    $machineNames[$id] = try { Get-TrustData -Type Machine -InputObject $id -Name } catch { $null }
                }

                [ordered]@{
                    returned     = $identities.Count
                    moreMayExist = $identities.Count -ge $params.First
                    identities   = @(
                        foreach ( $i in $identities ) {
                            # the key fields first, then everything else.  Select-Object -ExcludeProperty would also drop the named ones.
                            $out = [ordered]@{
                                machineIdentityId = $i.machineIdentityId
                                certificateName   = $i.certificateName
                                certificateId     = $i.certificateId
                                machineName       = $machineNames[$i.machineId]
                                machineId         = $i.machineId
                            }
                            foreach ( $prop in $i.PSObject.Properties ) {
                                if ( $prop.Name -notin @($out.Keys) + 'companyId' ) { $out[$prop.Name] = $prop.Value }
                            }
                            $out
                        }
                    )
                }
            }
        }
        #endregion

        #region list_certificate_authorities
        @{
            name        = 'list_certificate_authorities'
            platforms   = 'CMS', 'NGTS'
            description = 'List certificate authority accounts, eg. DigiCert, Sectigo, Entrust, the built-in CA, or a CA connector, with their type, status, and product options.  Use list_issuing_templates to see which templates use each CA.'
            inputSchema = @{
                type       = 'object'
                properties = @{
                    certificate_authority = @{ type = 'string'; description = 'Certificate authority account name or id.  All are returned if not provided.' }
                }
            }
            handler     = {
                param($Arguments, $TrustClient)

                $cas = @(
                    if ( $Arguments.certificate_authority ) {
                        Get-TrustCertificateAuthority -CertificateAuthority $Arguments.certificate_authority -TrustClient $TrustClient
                    }
                    else {
                        Get-TrustCertificateAuthority -All -TrustClient $TrustClient
                    }
                )

                [ordered]@{
                    total                  = $cas.Count
                    certificateAuthorities = @($cas | Select-Object -Property * -ExcludeProperty companyId)
                }
            }
        }
        #endregion

        #region find_certificates_by_ca
        @{
            name        = 'find_certificates_by_ca'
            platforms   = 'CMS', 'NGTS'
            description = 'Find active certificates issued by, or chaining to, a certificate authority, eg. to respond to a CA being distrusted or compromised.  Returns the matching issuers with their counts, how each matched, and the certificates.  With include_chain, each certificate''s intermediate and root CAs from the inventory are also matched.  Use find_machine_identities for where a certificate is installed.'
            inputSchema = @{
                type       = 'object'
                properties = [ordered]@{
                    ca            = @{ type = 'string'; description = 'Text in the CA subject DN, case-insensitive, eg. eMudhra, EM DV TLS CA - G3B, or a full DN' }
                    include_chain = @{ type = 'boolean'; description = 'Also match certificates whose issuer chains to a matching intermediate or root CA.  Default true.' }
                    first         = $firstSchema
                }
                required   = @('ca')
            }
            handler     = {
                param($Arguments, $TrustClient)

                $ca = "$($Arguments.ca)".Trim()
                if ( -not $ca ) { throw 'ca is required' }
                $first = Resolve-TrustMcpFirst $Arguments.first
                $includeChain = $Arguments.include_chain -ne $false
                $limit = 10000
                # one certificate is looked up for each distinct chain
                $maxChainLookups = 200

                $certs = @(Find-TrustCertificate -Status ACTIVE -First $limit -TrustClient $TrustClient)
                $contains = { param([string] $Text) $Text -and $Text.IndexOf($ca, [System.StringComparison]::OrdinalIgnoreCase) -ge 0 }
                $issuerOf = { param($Cert) if ( $Cert.issuerDN ) { $Cert.issuerDN } else { @($Cert.issuerCN)[0] } }

                # CA certificates are shared across tenants, so they can't be read by id.
                # a certificate's own details include its chain, so read one certificate for each distinct chain.
                $chainNames = @{}
                $warnings = [System.Collections.Generic.List[string]]::new()
                # adds the chain's CA names to $chainNames, keyed by its ids
                $loadChain = {
                    param($Cert, [string] $Key)
                    if ( $chainNames.ContainsKey($Key) -or $chainNames.Count -ge $maxChainLookups ) { return }
                    try {
                        $full = Get-TrustCertificate -Certificate $Cert.certificateId -TrustClient $TrustClient
                        $byId = @{}
                        $full.issuerCertificates | ForEach-Object { $byId[$_.id] = $_.subjectDN }
                        # in chain order, issuing CA first
                        $chainNames[$Key] = [string[]]@($Cert.issuerCertificateIds | ForEach-Object { $byId[$_] })
                    }
                    catch {
                        $warnings.Add("Unable to get the chain of $($Cert.certificateId): $($_.Exception.Message)")
                        $chainNames[$Key] = [string[]]@()
                    }
                }

                $hits = [ordered]@{}
                foreach ( $g in @($certs | Group-Object { & $issuerOf $_ } | Sort-Object Count -Descending) ) {
                    if ( & $contains $g.Name ) {
                        $hits[$g.Name] = [ordered]@{ issuer = $g.Name; count = $g.Count; matchedBy = 'issuer'; chain = @(); certs = $g.Group }
                        continue
                    }
                    if ( -not $includeChain ) { continue }

                    # certificates from the same issuer can chain differently, eg. cross signed, so check each distinct chain
                    foreach ( $c in @($g.Group | Group-Object { @($_.issuerCertificateIds) -join ',' }) ) {
                        if ( -not @($c.Group[0].issuerCertificateIds | Where-Object { $_ }) ) { continue }
                        & $loadChain $c.Group[0] $c.Name
                        $names = @($chainNames[$c.Name])
                        # the first is the issuing CA, which already didn't match, look above it
                        $above = @($names | Select-Object -Skip 1 | Where-Object { $_ })
                        if ( $above | Where-Object { & $contains $_ } ) {
                            if ( -not $hits.Contains($g.Name) ) {
                                $hits[$g.Name] = [ordered]@{ issuer = $g.Name; count = 0; matchedBy = 'chain'; chain = $above; certs = @() }
                            }
                            $hits[$g.Name].count += $c.Count
                            $hits[$g.Name].certs += $c.Group
                        }
                    }
                }

                $matched = @($hits.Values | ForEach-Object { $_.certs })
                [ordered]@{
                    ca                = $ca
                    totalCertificates = $matched.Count
                    scanned           = $certs.Count
                    truncated         = $certs.Count -ge $limit
                    chainsChecked     = $chainNames.Count
                    chainLimitReached = $chainNames.Count -ge $maxChainLookups
                    issuers           = @($hits.Values | ForEach-Object { [ordered]@{ issuer = $_.issuer; count = $_.count; matchedBy = $_.matchedBy; chainAboveIssuer = $_.chain } })
                    certificates      = @($matched | Select-Object -First $first | ForEach-Object { [ordered]@{ certificateId = $_.certificateId; name = $_.certificateName; issuer = & $issuerOf $_; validityEnd = $_.validityEnd } })
                    warnings          = @($warnings | Sort-Object -Unique | Select-Object -First 20)
                }
            }
        }
        #endregion

        #region list_issuing_templates
        @{
            name        = 'list_issuing_templates'
            platforms   = 'CMS', 'NGTS'
            description = 'List issuing templates, which define the CA, product, validity, allowed key types, and the subject and SAN patterns allowed for certificate requests, and which applications use each.  Use this to understand why a request was rejected or which template to request with.'
            inputSchema = @{
                type       = 'object'
                properties = [ordered]@{
                    issuing_template      = @{ type = 'string'; description = 'Issuing template name or id.  All are returned if not provided.' }
                    certificate_authority = @{ type = 'string'; description = 'Only templates which use this certificate authority account, name or id' }
                }
            }
            handler     = {
                param($Arguments, $TrustClient)

                $templates = @(
                    if ( $Arguments.issuing_template ) {
                        Get-TrustIssuingTemplate -IssuingTemplate $Arguments.issuing_template -TrustClient $TrustClient
                    }
                    else {
                        $params = @{ All = $true; TrustClient = $TrustClient }
                        if ( $Arguments.certificate_authority ) { $params.CertificateAuthority = $Arguments.certificate_authority }
                        Get-TrustIssuingTemplate @params
                    }
                )

                [ordered]@{
                    total             = $templates.Count
                    issuingTemplates  = @($templates | Select-Object -Property * -ExcludeProperty companyId)
                }
            }
        }
        #endregion
    )

    if ( -not $PSBoundParameters.ContainsKey('Platform') ) {
        return $tools
    }

    $tools = @($tools | Where-Object { $_.platforms -contains $Platform.ToString() })

    if ( $Platform -eq 'CM' ) {
        # the token scope a tool needs is that of the functions its handler calls, from the module's function config.
        # add it to the description so the model can explain a 401/403 and to cmTokenScope for docs and tests.
        foreach ( $tool in $tools ) {
            $commands = @($tool.handler.Ast.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $true) |
                    ForEach-Object { $_.GetCommandName() } | Where-Object { $_ } | Sort-Object -Unique)

            $scopes = [System.Collections.Generic.List[string]]::new()
            # cmScope is for api calls a handler makes directly, in the same format as the function config
            $configScopes = @($commands | ForEach-Object { $script:functionConfig.$_.CmTokenScope }) + $tool.cmScope
            foreach ( $configScope in $configScopes ) {
                if ( -not $configScope ) { continue }
                # eg. 'configuration=$null,certificate=manage' or 'restricted=manage,delete', any notes follow a period
                foreach ( $m in [regex]::Matches(($configScope -split '\.')[0], '(\w+)=(\$null|[a-z]+(?:,(?![a-z]+=)[a-z]+)*)') ) {
                    $name = $m.Groups[1].Value.ToLower()
                    $rights = $m.Groups[2].Value.ToLower()
                    $scopes.Add($(if ( $rights -eq '$null' ) { $name } else { '{0}:{1}' -f $name, $rights }))
                }
            }

            # certificate:manage includes certificate
            $unique = @($scopes | Sort-Object -Unique)
            $required = @($unique | Where-Object { $_ -match ':' -or -not ($unique -like "$($_):*") })
            $tool.cmTokenScope = if ( $required ) { $required -join ', ' } else { 'any' }
            $tool.description = '{0}  Requires token scope: {1}.' -f $tool.description.TrimEnd(), $tool.cmTokenScope
        }
    }

    $tools
}
