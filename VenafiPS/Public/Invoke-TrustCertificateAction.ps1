function Invoke-TrustCertificateAction {
    <#
    .SYNOPSIS
    Perform an action against one or more certificates

    .DESCRIPTION
    One stop shop for certificate actions.
    You can Retire, Recover, Renew, Validate, Provision, or Delete.

    .PARAMETER ID
    ID of the certificate

    .PARAMETER Retire
    Retire a certificate

    .PARAMETER Recover
    Recover a retired certificate

    .PARAMETER Renew
    Requests immediate renewal for an existing certificate.
    Use `-AdditionalParameters` to provide additional parameters to the renewal request, see https://developer.venafi.com/tlsprotectcloud/reference/certificaterequests_create.

    .PARAMETER Revoke
    Revoke a certificate.
    Requires a reason and optionally you can provide a comment.

    .PARAMETER Reason
    Provide a revocation reason; defaults to UNSPECIFIED.
    Allowed values are 'UNSPECIFIED', 'KEY_COMPROMISE', 'AFFILIATION_CHANGED', 'SUPERSEDED', 'CESSATION_OF_OPERATION'.

    .PARAMETER Comment
    Provide a revocation comment; defaults to 'revoked by VenafiPS'

    .PARAMETER Validate
    Initiates SSL/TLS network validation

    .PARAMETER Delete
    Delete a certificate.
    As only retired certificates can be deleted, this will be performed first, if needed.

    .PARAMETER Provision
    By default, provision a certificate to all associated machine identities.
    When used with -MachineIdentity, provision to that machine identity instead of all associated machine identities.
    When used with -CloudKeystore, provision there instead.
    When used with -Renew, it will wait for the renewal to complete and then provision the renewed certificate, assuming the renewal was successful.

    .PARAMETER MachineIdentity
    Name or ID of a machine identity to provision to.
    When used with -Provision, provision to this machine identity instead of all associated machine identities.

    .PARAMETER CloudKeystore
    Name or ID of a cloud keystore to provision to

    .PARAMETER BatchSize
    How many certificates to retire per retirement API call. Useful to prevent API call timeouts.
    Defaults to 1000.
    Not applicable to Renew or Provision.

    .PARAMETER Application
    Optional name or ID of an application.
    Only needed in circumstances where the application can't be determined automatically.

    If not provided for renewal, get the application from the original certificate request.
    If not available, check for associated applications with the certificate.  If more than 1, throw an error as we don't know which to use, otherwise use that one application.

    Associate a recovered certificate with an application.

    .PARAMETER IssuingTemplate
    Optional name or ID of an issuing template.
    Only needed in circumstances where the issuing template can't be determined automatically.

    If not provided, get the issuing template from the original certificate request.  It might be this is available, but no longer valid for the application.  In this case, check how many templates the application has.  If only 1, use it, otherwise we can't continue.
    If not available from the original certificate request, perform the same 1 template check against the application to find a suitable template.

    Renew only.

    .PARAMETER AdditionalParameters
    Additional items specific to the action being taken, if needed.
    See the api documentation for appropriate items, many are in the links in this help.

    .PARAMETER Force
    Force the operation under certain circumstances.
    - During a renewal, force choosing the first CN in the case of multiple CNs as only 1 is supported via the API.

    .PARAMETER Wait
    Wait for a long running operation to complete before returning
    - During a renewal, wait for enrollment to either succeed or fail

    .PARAMETER TrustClient
    Authentication for the function.
    The value defaults to the script session object $TrustClient created by New-TrustClient.

    .INPUTS
    ID

    .OUTPUTS
    For most, but not all actions, PSCustomObject with the following properties:
        certificateID - Certificate uuid
        success - A value of true indicates that the action was successful
        error - error message if we failed

    Renewals will also have oldCertificateId and renew properties

    .EXAMPLE
    Invoke-TrustCertificateAction -ID '3699b03e-ff62-4772-960d-82e53c34bf60' -Retire

    Perform an action against 1 certificate

    .EXAMPLE
    Invoke-TrustCertificateAction -ID '3699b03e-ff62-4772-960d-82e53c34bf60' -Renew -Application '10f71a12-daf3-4737-b589-6a9dd1cc5a97'

    Perform an action against 1 certificate overriding the application used for renewal.

    .EXAMPLE
    Find-TrustCertificate -Version CURRENT -Issuer i1 | Invoke-TrustCertificateAction -Renew -IssuingTemplate 10f71a12-daf3-4737-b589-6a9dd1cc5a97

    Find all current certificates issued by i1 and renew them with a different template.

    .EXAMPLE
    Find-TrustCertificate -Version CURRENT -Name 'mycert' | Invoke-TrustCertificateAction -Renew -Wait

    Renew a certificate and wait for it to finish, either success or failure, before returning.
    This can be helpful if an Issuer takes a bit to enroll the certificate.

    .EXAMPLE
    Invoke-TrustCertificateAction -ID '3699b03e-ff62-4772-960d-82e53c34bf60' -Renew -Force

    Renewals can only support 1 CN assigned to a certificate.  To force this function to renew and automatically select the first CN, use -Force.

    .EXAMPLE
    Invoke-TrustCertificateAction -ID '3699b03e-ff62-4772-960d-82e53c34bf60' -Delete

    Delete a certificate.  As only retired certificates can be deleted, it will be retired first.

    .EXAMPLE
    Invoke-TrustCertificateAction -ID '3699b03e-ff62-4772-960d-82e53c34bf60' -Delete -Confirm:$false

    Perform an action bypassing the confirmation prompt.  Only applicable to Delete.

    .EXAMPLE
    Find-TrustCertificate -Status RETIRED | Invoke-TrustCertificateAction -Delete -BatchSize 100

    Search for all retired certificates and delete them using a non default batch size of 100

    .EXAMPLE
    Find-TrustCertificate -Version CURRENT -Name 'mycert' | Invoke-TrustCertificateAction -CloudKeystore

    Provision the certificate to a cloud keystore

    .EXAMPLE
    Invoke-TrustCertificateAction -Provision -MachineIdentity '3f4d8db9-6f83-4c9b-9a53-6f8e2a9d6d2b'

    Provision the certificate associated with a specific machine identity

    .LINK
    https://developer.venafi.com/tlsprotectcloud/reference/certificateretirement_recovercertificates

    .LINK
    https://developer.venafi.com/tlsprotectcloud/reference/certificateretirement_retirecertificates

    .LINK
    https://developer.venafi.com/tlsprotectcloud/reference/certificateretirement_deletecertificates

    .LINK
    https://developer.venafi.com/tlsprotectcloud/reference/certificaterequests_create

    .LINK
    https://developer.venafi.com/tlsprotectcloud/reference/certificates_validation

    .NOTES
    If performing a renewal and subjectCN has more than 1 value, only the first will be submitted with the renewal.
    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High', DefaultParameterSetName = 'Provision')]
    [Alias('Invoke-VcCertificateAction')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Params being used in paramset check, not by variable')]

    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('certificateId')]
        [guid] $ID,

        [Parameter(Mandatory, ParameterSetName = 'Retire')]
        [switch] $Retire,

        [Parameter(Mandatory, ParameterSetName = 'Recover')]
        [switch] $Recover,

        [Parameter(Mandatory, ParameterSetName = 'Renew')]
        [switch] $Renew,

        [Parameter(Mandatory, ParameterSetName = 'Validate')]
        [switch] $Validate,

        [Parameter(Mandatory, ParameterSetName = 'Revoke')]
        [switch] $Revoke,

        [Parameter(ParameterSetName = 'Revoke')]
        [ValidateSet('UNSPECIFIED', 'KEY_COMPROMISE', 'AFFILIATION_CHANGED', 'SUPERSEDED', 'CESSATION_OF_OPERATION')]
        [string] $Reason = 'UNSPECIFIED',

        [Parameter(ParameterSetName = 'Revoke')]
        [string] $Comment = 'revoked by VenafiPS',

        [Parameter(Mandatory, ParameterSetName = 'Delete')]
        [switch] $Delete,

        [Parameter(Mandatory, ParameterSetName = 'Provision')]
        [Parameter(ParameterSetName = 'Renew')]
        [switch] $Provision,

        [Parameter(ParameterSetName = 'Provision', ValueFromPipelineByPropertyName)]
        [Alias('machineIdentityId')]
        [string] $MachineIdentity,

        [Parameter(ParameterSetName = 'Provision')]
        [Alias('cloudKeystoreId')]
        [string] $CloudKeystore,

        [Parameter(ParameterSetName = 'Renew')]
        [Parameter(ParameterSetName = 'Recover')]
        [ValidateNotNullOrEmpty()]
        [String] $Application,

        [Parameter(ParameterSetName = 'Renew')]
        [ValidateNotNullOrEmpty()]
        [String] $IssuingTemplate,

        [Parameter(ParameterSetName = 'Retire')]
        [Parameter(ParameterSetName = 'Recover')]
        [Parameter(ParameterSetName = 'Validate')]
        [Parameter(ParameterSetName = 'Delete')]
        [ValidateRange(1, 10000)]
        [int] $BatchSize = 1000,

        [Parameter(ParameterSetName = 'Renew')]
        [switch] $Wait,

        [Parameter(ParameterSetName = 'Renew')]
        [switch] $Force,

        [Parameter()]
        [hashtable] $AdditionalParameters,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [TrustClient] $TrustClient = (Get-TrustClient)
    )

    begin {

        $allCerts = [System.Collections.Generic.List[string]]::new()
        Write-Verbose $PSCmdlet.ParameterSetName

        $revokeQuery = 'mutation RevokeCertificateRequest($fingerprint: ID!, $certificateAuthorityAccountId: UUID, $revocationReason: RevocationReason!, $revocationComment: String ) {
            revokeCertificate(fingerprint: $fingerprint, certificateAuthorityAccountId: $certificateAuthorityAccountId, revocationReason: $revocationReason, revocationComment: $revocationComment) {
                id
                fingerprint
                revocation {
                    status
                    error {
                        arguments
                        code
                        message
                    }
                    approvalDetails {
                        rejectionReason
                    }
                }
                serialNumber
            }
            }
            '

        $provisionCloudKeystoreQuery = '
            mutation ProvisionCertificate($certificateId: UUID!, $cloudKeystoreId: UUID!, $wsClientId: UUID!, $options: CertificateProvisioningOptionsInput) {
            provisionToCloudKeystore(
                certificateId: $certificateId
                cloudKeystoreId: $cloudKeystoreId
                wsClientId: $wsClientId
                options: $options
            ) {
                workflowId
                workflowName
                __typename
            }
            }
        '
    }

    process {

        switch ($PSCmdlet.ParameterSetName) {
            'Provision' {
                if ( $CloudKeystore ) {
                    $out = @{
                        certificateId = $ID
                        success       = $false
                        error         = $null
                    }

                    $variables = @{
                        certificateId   = (Get-TrustData -InputObject $ID -Type Certificate -FailOnNotFound)
                        cloudKeystoreId = (Get-TrustData -InputObject $CloudKeystore -Type CloudKeystore -FailOnNotFound)
                        wsClientId      = (New-Guid).ToString()
                    }

                    try {
                        if ( -not $PSCmdlet.ShouldProcess($ID, 'Provision certificate to cloud keystore') ) {
                            return
                        }

                        $null = Invoke-TrustGraphQL -Query $provisionCloudKeystoreQuery -Variables $variables

                        $out.success = $true
                    }
                    catch {
                        $out.error = $_
                    }

                    return [pscustomobject]$out

                }
                else {
                    $mi = if ( $MachineIdentity ) {
                        $MachineIdentity
                    }
                    else {
                        # get all machine identities associated with certificate
                        Find-TrustMachineIdentity -Certificate $ID
                    }

                    if ( -not $mi ) {
                        throw "No machine identities found for certificate ID $ID"
                    }

                    Write-Verbose ('Provisioning certificate ID {0} to machine identities {1}' -f $ID, ($mi -join ','))
                    $mi | Invoke-TrustWorkflow -Workflow 'Provision'
                }
            }

            'Renew' {

                $out = [pscustomobject] @{
                    oldCertificateId = $ID
                    success          = $false
                    error            = $null
                }

                $thisCert = Get-TrustCertificate -Certificate $ID

                # only current certs can be renewed
                if ( $thisCert.versionType -ne 'CURRENT' ) {
                    $out.error = 'Only certificates with a versionType of CURRENT can be renewed'
                    return $out
                }

                # multiple CN certs are supported by Certificate Manager, SaaS, but the request/renew api does not support it
                if ( $thisCert.subjectCN.count -gt 1 ) {
                    if ( -not $Force ) {
                        $out.error = 'The certificate you are trying to renew has more than 1 common name.  You can either use -Force to automatically choose the first common name or utilize a different process to renew.'
                        return $out
                    }
                }

                if ( $thisCert.certificateRequestId ) {
                    $thisCertRequest = Invoke-TrustRestMethod -UriRoot 'outagedetection/v1' -UriLeaf "certificaterequests/$($thisCert.certificateRequestId)"
                }

                # to get the appropriate application:
                # 1. use the provided application parameter
                # 2. if not provided, check the certificate request for an applicationId
                # 3. if not there, check the certificate for associated applications.  if more than 1, throw an error, otherwise use that one application
                if ( $Application ) {
                    $thisApp = Get-TrustData -Type Application -InputObject $Application -Object -FailOnNotFound
                    $thisAppId = $thisApp.applicationId
                    Write-Verbose "Using provided application $Application with id $thisAppId for renewal"
                }
                elseif ($thisCertRequest) {
                    $thisAppId = $thisCertRequest.applicationId
                    $thisApp = Get-TrustData -Type Application -InputObject $thisAppId -Object -FailOnNotFound
                    Write-Verbose "Using application ID $thisAppId from prior certificate request for renewal"
                }
                else {
                    switch (([array]$thisCert.application).count) {
                        1 {
                            $thisAppId = $thisCert.application.applicationId
                            $thisApp = Get-TrustData -Type Application -InputObject $thisAppId -Object -FailOnNotFound
                            Write-Verbose "Using application ID $thisAppId, the only application associated with the certificate, for renewal"
                        }

                        0 {
                            throw 'To renew a certificate at least one application must be assigned'
                        }

                        Default {
                            $out.error = 'Multiple applications associated, {0}.  Only 1 application can be renewed at a time.  Rerun Invoke-TrustCertificateAction and add ''-AdditionalParameter @{{''Application''=''application id''}}'' and provide the actual id you would like to renew.' -f (($thisCert.application | ForEach-Object { '{0} ({1})' -f $_.name, $_.applicationId }) -join ',')
                            return $out
                        }
                    }
                }

                # get current template id from app if only one
                # this might be different from the template used to enroll the current cert
                $templateIdFromCurrentApp = $null
                if ( $thisApp.issuingTemplate.Count -eq 1 ) {
                    $templateIdFromCurrentApp = $thisApp.issuingTemplate.issuingTemplateId
                }

                # to get the appropriate issuing template:
                # 1. use the provided issuing template parameter
                # 2. if not provided, check the certificate request for an issuingTemplateId
                # 3. if not there, check the issuing templates for the application.  if just 1, use it, otherwise, throw an error
                if ( $IssuingTemplate ) {
                    $thisTemplateId = Get-TrustData -Type IssuingTemplate -InputObject $IssuingTemplate -FailOnNotFound
                    Write-Verbose "Using provided issuing template $IssuingTemplate with id $thisTemplateId for renewal"
                }
                elseif ($thisCertRequest) {
                    $thisTemplateId = $thisCertRequest.certificateIssuingTemplateId
                    Write-Verbose "Using issuing template ID $thisTemplateId from prior certificate request for renewal"
                }
                else {

                    switch ($thisApp.issuingTemplate.count) {
                        1 {
                            $thisTemplateId = $thisApp.issuingTemplate.issuingTemplateId
                            Write-Verbose "Using issuing template ID $thisTemplateId, the only issuing template associated with the application, for renewal"
                        }

                        0 {
                            $out.error = 'To renew a certificate, at least one issuing template must be associated with application {0}' -f $appForTemplates.name
                            return $out
                        }

                        Default {
                            $out.error = 'Multiple issuing templates associated, {0}.  Only 1 issuing template can be renewed at a time.  Rerun Invoke-TrustCertificateAction and add ''-AdditionalParameter @{{''IssuingTemplate''=''issuing template id''}}'' and provide the actual id you would like to renew.' -f (($appForTemplates.issuingTemplate | ForEach-Object { '{0} ({1})' -f $_.name, $_.issuingTemplateId }) -join ',')
                            return $out
                        }
                    }

                    throw 'An issuing template must be provided to renew a certificate.  Rerun Invoke-TrustCertificateAction and add ''-IssuingTemplate TemplateNameOrId'''
                }

                # if the issuing template isn't valid for the app, and we have only 1 template currently available in the app, use it
                # otherwise we can't continue
                if ( $thisTemplateId -notin $thisApp.issuingTemplate.issuingTemplateId ) {
                    Write-Verbose "Template $thisTemplateId is not associated with the application"
                    if ( $templateIdFromCurrentApp ) {
                        $thisTemplateId = $templateIdFromCurrentApp
                        Write-Verbose "Using issuing template ID $thisTemplateId, the only issuing template associated with the application"
                    }
                    else {
                        $out.error = 'The issuing template provided or found was not associated with the application provided or found.  Please provide -Application and -IssuingTemplate that are associated with each other.'
                        return $out
                    }
                }

                $renewParams = @{
                    existingCertificateId        = $ID
                    certificateIssuingTemplateId = $thisTemplateId
                    applicationId                = $thisAppId
                    isVaaSGenerated              = $true
                    csrAttributes                = @{}
                }

                switch ($thisCert.PSObject.Properties.Name) {
                    'subjectCN' { $renewParams.csrAttributes.commonName = $thisCert.subjectCN[0] }
                    'subjectO' { $renewParams.csrAttributes.organization = $thisCert.subjectO }
                    'subjectOU' { $renewParams.csrAttributes.organizationalUnits = $thisCert.subjectOU }
                    'subjectL' { $renewParams.csrAttributes.locality = $thisCert.subjectL }
                    'subjectST' { $renewParams.csrAttributes.state = $thisCert.subjectST }
                    'subjectC' { $renewParams.csrAttributes.country = $thisCert.subjectC }
                    'subjectAlternativeNamesByType' {
                        $renewParams.csrAttributes.subjectAlternativeNamesByType = @{
                            'dnsNames'                   = $thisCert.subjectAlternativeNamesByType.dNSName
                            'ipAddresses'                = $thisCert.subjectAlternativeNamesByType.iPAddress
                            'rfc822Names'                = $thisCert.subjectAlternativeNamesByType.rfc822Name
                            'uniformResourceIdentifiers' = $thisCert.subjectAlternativeNamesByType.uniformResourceIdentifier
                        }
                    }
                }

                if ( $AdditionalParameters ) {
                    foreach ($key in $AdditionalParameters.Keys) {
                        $renewParams[$key] = $AdditionalParameters[$key]
                    }
                }

                try {

                    $renewResponse = Invoke-TrustRestMethod -Method 'Post' -UriRoot 'outagedetection/v1' -UriLeaf 'certificaterequests' -Body $renewParams -ErrorAction Stop

                    $out | Add-Member @{ renew = $renewResponse.certificateRequests | Select-Object @{
                            n = 'certificateRequestId'
                            e = { $_.id }
                        }, * -ExcludeProperty id
                    }

                    if ( $Wait -or $Provision ) {

                        $terminalStatuses = @('ISSUED', 'REJECTED_APPROVAL', 'REJECTED', 'CANCELLED', 'REVOKED', 'FAILED', 'DELETED')
                        $status = $out.renew.status
                        Write-Verbose "Current renewal status: $status"

                        while ( $status -notin $terminalStatuses ) {
                            Start-Sleep -Seconds 2
                            $request = Get-TrustCertificateRequest -CertificateRequest $out.renew[0].certificateRequestId
                            $status = $request.status
                            Write-Verbose "Current renewal status: $status"
                        }

                        $out.renew = $request
                    }

                    if ( $out.renew.certificateIds ) {
                        # cert has been issued
                        $newCertId = $out.renew.certificateIds[0]
                        Write-Verbose "Renewal request was successful, certificate ID is $newCertId"

                        $out | Add-Member @{ 'certificateID' = $newCertId }

                        if ( $Provision ) {
                            Write-Verbose "Provisioning..."

                            # wait a few seconds for machine identities to be reassociated with the new certificate
                            # TODO: perform a check instead of random sleep
                            Start-Sleep -Seconds 5

                            $provisionResponse = Invoke-TrustCertificateAction -ID $newCertId -Provision
                            $out | Add-Member @{'provision' = $provisionResponse }
                        }
                    }
                    else {
                        Write-Verbose "Renewal request was successful, but the certificate hasn't been created yet.  Check the status with Get-TrustCertificateRequest."
                        if ( $Provision ) {
                            Write-Verbose "Skipping provisioning as the certificate hasn't been created yet"
                        }
                    }

                    $out.success = $true
                }
                catch {
                    $out.error = $_
                }

                return $out
            }

            'Revoke' {
                $out = @{
                    CertificateId = $ID
                    success       = $false
                    error         = $null
                }

                $thisCert = Get-TrustCertificate -Certificate $ID

                $variables = @{
                    fingerprint       = $thisCert.fingerprint
                    revocationReason  = $Reason
                    revocationComment = $Comment
                }

                try {
                    if ( -not $PSCmdlet.ShouldProcess(('{0} (id: {1})' -f $thisCert.certificateName, $ID), 'Revoke certificate') ) {
                        return
                    }

                    $null = Invoke-TrustGraphQL -Query $revokeQuery -Variables $variables

                    $out.success = $true
                }
                catch {
                    $out.error = $_
                }

                return [pscustomobject]$out
            }

            Default {
                # queue these up to process in batches in the end block
                $allCerts.Add($ID)
            }
        }
    }

    end {

        if ( $allCerts.Count -eq 0 ) { return }

        switch ($PSCmdLet.ParameterSetName) {

            'Renew' {
                # handled in Process
            }

            'Retire' {
                $params = @{
                    Method  = 'Post'
                    UriRoot = 'outagedetection/v1'
                    UriLeaf = "certificates/retirement"
                    Body    = @{
                        'certificateIds' = $null
                    }
                }

                if ( $AdditionalParameters ) {
                    $params.Body += $AdditionalParameters
                }

                if ( $PSCmdlet.ShouldProcess('Certificate Manager, SaaS', ('Retire {0} certificate(s) in batches of {1}' -f $allCerts.Count, $BatchSize) ) ) {
                    $allCerts | Select-TrustBatch -Activity 'Retiring certificates' -BatchSize $BatchSize -BatchType 'string' -TotalCount $allCerts.Count | ForEach-Object {
                        $params.Body.certificateIds = $_

                        $response = Invoke-TrustRestMethod @params

                        $processedIds = $response.certificates.id

                        foreach ($certId in $_) {
                            [pscustomobject] @{
                                CertificateID = $certId
                                Success       = ($certId -in $processedIds)
                            }
                        }
                    }
                }
            }

            'Recover' {
                $params = @{
                    Method  = 'Post'
                    UriRoot = 'outagedetection/v1'
                    UriLeaf = "certificates/recovery"
                    Body    = @{
                        'certificateIds' = $null
                    }
                }

                if ( $Application ) {
                    $thisApp = Get-TrustData -Type Application -InputObject $Application -Object -FailOnNotFound
                    $thisAppId = $thisApp.applicationId

                    $params.Body.applicationIds = @($thisAppId)
                }

                if ( $AdditionalParameters ) {
                    $params.Body += $AdditionalParameters
                }

                if ( $PSCmdlet.ShouldProcess('Certificate Manager, SaaS', ('Recover {0} certificate(s) in batches of {1}' -f $allCerts.Count, $BatchSize) ) ) {
                    $allCerts | Select-TrustBatch -Activity 'Recovering certificates' -BatchSize $BatchSize -BatchType 'string' -TotalCount $allCerts.Count | ForEach-Object {
                        $params.Body.certificateIds = $_

                        $response = Invoke-TrustRestMethod @params

                        $processedIds = $response.certificates.id

                        foreach ($certId in $_) {
                            [pscustomobject] @{
                                CertificateID = $certId
                                Success       = ($certId -in $processedIds)
                            }
                        }
                    }
                }
            }

            'Validate' {
                $params = @{
                    Method  = 'Post'
                    UriRoot = 'outagedetection/v1'
                    UriLeaf = "certificates/validation"
                    Body    = @{
                        'certificateIds' = $null
                    }
                }

                if ( $PSCmdlet.ShouldProcess('Certificate Manager, SaaS', ('Validate {0} certificate(s) in batches of {1}' -f $allCerts.Count, $BatchSize) ) ) {
                    $allCerts | Select-TrustBatch -Activity 'Validating certificates' -BatchSize $BatchSize -BatchType 'string' -TotalCount $allCerts.Count | ForEach-Object {
                        $params.Body.certificateIds = $_

                        $null = Invoke-TrustRestMethod @params
                    }
                }
            }

            'Delete' {
                $params = @{
                    Method  = 'Post'
                    UriRoot = 'outagedetection/v1'
                    UriLeaf = "certificates/deletion"
                    Body    = @{
                        'certificateIds' = $null
                    }
                }

                if ( $PSCmdlet.ShouldProcess('Certificate Manager, SaaS', ('Delete {0} certificate(s) in batches of {1}' -f $allCerts.Count, $BatchSize) ) ) {

                    # only retired certs can be deleted, product requirement
                    $null = $allCerts | Invoke-TrustCertificateAction -Retire -BatchSize $BatchSize -Confirm:$false

                    $allCerts | Select-TrustBatch -Activity 'Deleting certificates' -BatchSize $BatchSize -BatchType 'string' -TotalCount $allCerts.Count | ForEach-Object {
                        $params.Body.certificateIds = $_

                        $null = Invoke-TrustRestMethod @params
                    }
                }
            }
        }

    }
}

