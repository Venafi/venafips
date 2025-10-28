function Invoke-VcCertificateAction {
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
    If more than 1 application is associated with the certificate, provide -AdditionalParameters @{'Application'='application id'} to specify the id.
    Use -AdditionalParameters to provide additional parameters to the renewal request, see https://developer.venafi.com/tlsprotectcloud/reference/certificaterequests_create.

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
    As only retired certificates can be deleted, this will be performed first.

    .PARAMETER Provision
    By default, provision a certificate to all associated machine identities.
    When used with CloudKeystore, provision there instead.

    .PARAMETER CloudKeystore
    Name or ID of a cloud keystore to provision to

    .PARAMETER BatchSize
    How many certificates to retire per retirement API call. Useful to prevent API call timeouts.
    Defaults to 1000.
    Not applicable to Renew or Provision.

    .PARAMETER AdditionalParameters
    Additional items specific to the action being taken, if needed.
    See the api documentation for appropriate items, many are in the links in this help.

    .PARAMETER Force
    Force the operation under certain circumstances.
    - During a renewal, force choosing the first CN in the case of multiple CNs as only 1 is supported.

    .PARAMETER Wait
    Wait for a long running operation to complete before returning
    - During a renewal, wait for the certificate to pass the Requested state

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A TLSPC key can also provided.

    .INPUTS
    ID

    .OUTPUTS
    When using retire and recover, PSCustomObject with the following properties:
        CertificateID - Certificate uuid
        Success - A value of true indicates that the action was successful

    .EXAMPLE
    Invoke-VcCertificateAction -ID '3699b03e-ff62-4772-960d-82e53c34bf60' -Retire

    Perform an action against 1 certificate

    .EXAMPLE
    Invoke-VcCertificateAction -ID '3699b03e-ff62-4772-960d-82e53c34bf60' -Renew -AdditionalParameters @{'Application'='10f71a12-daf3-4737-b589-6a9dd1cc5a97'}

    Perform an action against 1 certificate with additional parameters.
    In this case we are renewing a certificate, but the certificate has multiple applications associated with it.
    Only one certificate and application combination can be renewed at a time so provide the specific application to be renewed.

    .EXAMPLE
    Find-VcCertificate -Version CURRENT -Issuer i1 | Invoke-VcCertificateAction -Renew -AdditionalParameters @{'certificateIssuingTemplateId'='10f71a12-daf3-4737-b589-6a9dd1cc5a97'}

    Find all current certificates issued by i1 and renew them with a different issuer.

    .EXAMPLE
    Find-VcCertificate -Version CURRENT -Name 'mycert' | Invoke-VcCertificateAction -Renew -Wait

    Renew a certificate and wait for it to pass the Requested state (and hopefully Issued).
    This can be helpful if an Issuer takes a bit to enroll the certificate.

    .EXAMPLE
    Invoke-VcCertificateAction -ID '3699b03e-ff62-4772-960d-82e53c34bf60' -Renew -Force

    Renewals can only support 1 CN assigned to a certificate.  To force this function to renew and automatically select the first CN, use -Force.

    .EXAMPLE
    Invoke-VcCertificateAction -ID '3699b03e-ff62-4772-960d-82e53c34bf60' -Delete

    Delete a certificate.  As only retired certificates can be deleted, it will be retired first.

    .EXAMPLE
    Invoke-VcCertificateAction -ID '3699b03e-ff62-4772-960d-82e53c34bf60' -Delete -Confirm:$false

    Perform an action bypassing the confirmation prompt.  Only applicable to Delete.

    .EXAMPLE
    Find-VcCertificate -Status RETIRED | Invoke-VcCertificateAction -Delete -BatchSize 100

    Search for all retired certificates and delete them using a non default batch size of 100

    .EXAMPLE
    Find-VcCertificate -Version CURRENT -Name 'mycert' | Invoke-VcCertificateAction -CloudKeystore

    Provision the certificate to a cloud keystore

    .LINK
    https://api.venafi.cloud/webjars/swagger-ui/index.html?configUrl=%2Fv3%2Fapi-docs%2Fswagger-config&urls.primaryName=outagedetection-service

    .LINK
    https://api.venafi.cloud/webjars/swagger-ui/index.html?urls.primaryName=outagedetection-service#/Certificates/certificateretirement_deleteCertificates

    .NOTES
    If performing a renewal and subjectCN has more than 1 value, only the first will be submitted with the renewal.
    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Params being used in paramset check, not by variable')]

    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('certificateID')]
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

        [Parameter(ParameterSetName = 'Provision')]
        [string] $CloudKeystore,

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
        [psobject] $VenafiSession
    )

    begin {
        Test-VenafiSession $PSCmdlet.MyInvocation

        $params = @{
            Method  = 'Post'
            UriRoot = 'outagedetection/v1'
        }

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
                        certificateId   = (Get-VcData -InputObject $ID -Type Certificate -FailOnNotFound)
                        cloudKeystoreId = (Get-VcData -InputObject $CloudKeystore -Type CloudKeystore -FailOnNotFound)
                        wsClientId      = (New-Guid).ToString()
                    }

                    try {
                        if ( -not $PSCmdlet.ShouldProcess($ID, 'Provision certificate to cloud keystore') ) {
                            return
                        }

                        $null = Invoke-VcGraphQL -Query $provisionCloudKeystoreQuery -Variables $variables

                        $out.success = $true
                    }
                    catch {
                        $out.error = $_
                    }

                    return [pscustomobject]$out

                }
                else {
                    # get all machine identities associated with certificate
                    # since ID is a guid, ensure its converted to string otherwise Find will think it's another filter
                    $mi = Find-VcMachineIdentity -Filter @('certificateId', 'eq', $ID.ToString()) | Select-Object -ExpandProperty machineIdentityId

                    if ( -not $mi ) {
                        throw "No machine identities found for certificate ID $ID"
                    }

                    Write-Verbose ('Provisioning certificate ID {0} to machine identities {1}' -f $ID, ($mi -join ','))
                    $mi | Invoke-VcWorkflow -Workflow 'Provision'
                }
            }

            'Renew' {

                $out = [pscustomobject] @{
                    oldCertificateId = $ID
                    success          = $false
                    error            = $null
                }

                $thisCert = Get-VcCertificate -ID $ID

                # only current certs can be renewed
                if ( $thisCert.versionType -ne 'CURRENT' ) {
                    $out.error = 'Only certificates with a versionType of CURRENT can be renewed'
                    return $out
                }

                # multiple CN certs are supported by tlspc, but the request/renew api does not support it
                if ( $thisCert.subjectCN.count -gt 1 ) {
                    if ( -not $Force ) {
                        $out.error = 'The certificate you are trying to renew has more than 1 common name.  You can either use -Force to automatically choose the first common name or utilize a different process to renew.'
                        return $out
                    }
                }

                switch (([array]$thisCert.application).count) {
                    1 {
                        $thisAppId = $thisCert.application.applicationId
                    }

                    0 {
                        throw 'To renew a certificate at least one application must be assigned'
                    }

                    Default {
                        # more than 1 application assigned
                        if ( $AdditionalParameters.Application ) {
                            $thisAppId = $AdditionalParameters.Application
                        }
                        else {
                            $out.error = 'Multiple applications associated, {0}.  Only 1 application can be renewed at a time.  Rerun Invoke-VcCertificateAction and add ''-AdditionalParameter @{{''Application''=''application id''}}'' and provide the actual id you would like to renew.' -f (($thisCert.application | ForEach-Object { '{0} ({1})' -f $_.name, $_.applicationId }) -join ',')
                            return $out
                        }
                    }
                }

                if ( -not $thisCert.certificateRequestId ) {
                    $out.error = 'An initial certificate request could not be found.  This is required to renew a certificate.'
                    return $out
                }

                $thisCertRequest = Invoke-VenafiRestMethod -UriRoot 'outagedetection/v1' -UriLeaf "certificaterequests/$($thisCert.certificateRequestId)"

                $renewParams = @{
                    existingCertificateId        = $ID
                    certificateIssuingTemplateId = $thisCertRequest.certificateIssuingTemplateId
                    applicationId                = $thisAppId
                    isVaaSGenerated              = $true
                    validityPeriod               = $thisCertRequest.validityPeriod
                    certificateOwnerUserId       = $thisCertRequest.certificateOwnerUserId
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

                    $renewResponse = Invoke-VenafiRestMethod -Method 'Post' -UriRoot 'outagedetection/v1' -UriLeaf 'certificaterequests' -Body $renewParams -ErrorAction Stop

                    $out | Add-Member @{ renew = $renewResponse.certificateRequests | Select-Object @{
                            n = 'certificateRequestId'
                            e = { $_.id }
                        }, * -ExcludeProperty id
                    }

                    if ( $Wait -and $out.renew.status -eq 'REQUESTED' ) {

                        $status = $out.renew.status
                        Write-Verbose "Current renewal status: $status.  Waiting to pass the 'Requested' state"

                        while ( $status -eq 'REQUESTED' ) {
                            Start-Sleep 1
                            $request = Get-VcCertificateRequest -CertificateRequest $out.renew[0].certificateRequestId
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

                            $provisionResponse = Invoke-VcCertificateAction -ID $newCertId -Provision
                            $out | Add-Member @{'provision' = $provisionResponse }
                        }
                    }
                    else {
                        Write-Verbose "Renewal request was successful, but the certificate hasn't been created yet.  Check the status with Get-VcCertificateRequest."
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

                $thisCert = Get-VcCertificate -ID $ID

                $variables = @{
                    fingerprint       = $thisCert.fingerprint
                    revocationReason  = $Reason
                    revocationComment = $Comment
                }

                try {
                    if ( -not $PSCmdlet.ShouldProcess(('{0} (id: {1})' -f $thisCert.certificateName, $ID), 'Revoke certificate') ) {
                        return
                    }

                    $null = Invoke-VcGraphQL -Query $revokeQuery -Variables $variables

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
                $params.UriLeaf = "certificates/retirement"

                if ( $AdditionalParameters ) {
                    $params.Body += $AdditionalParameters
                }

                if ( $PSCmdlet.ShouldProcess('TLSPC', ('Retire {0} certificate(s) in batches of {1}' -f $allCerts.Count, $BatchSize) ) ) {
                    $allCerts | Select-VenBatch -Activity 'Retiring certificates' -BatchSize $BatchSize -BatchType 'string' -TotalCount $allCerts.Count | ForEach-Object {
                        $params.Body = @{"certificateIds" = $_ }

                        $response = Invoke-VenafiRestMethod @params

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
                $params.UriLeaf = "certificates/recovery"

                if ( $AdditionalParameters ) {
                    $params.Body += $AdditionalParameters
                }

                if ( $PSCmdlet.ShouldProcess('TLSPC', ('Recover {0} certificate(s) in batches of {1}' -f $allCerts.Count, $BatchSize) ) ) {
                    $allCerts | Select-VenBatch -Activity 'Recovering certificates' -BatchSize $BatchSize -BatchType 'string' -TotalCount $allCerts.Count | ForEach-Object {
                        $params.Body = @{"certificateIds" = $_ }

                        $response = Invoke-VenafiRestMethod @params

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
                $params.UriLeaf = "certificates/validation"

                if ( $PSCmdlet.ShouldProcess('TLSPC', ('Validate {0} certificate(s) in batches of {1}' -f $allCerts.Count, $BatchSize) ) ) {
                    $allCerts | Select-VenBatch -Activity 'Validating certificates' -BatchSize $BatchSize -BatchType 'string' -TotalCount $allCerts.Count | ForEach-Object {
                        $params.Body = @{"certificateIds" = $_ }

                        $null = Invoke-VenafiRestMethod @params
                    }
                }
            }

            'Delete' {

                $params.UriLeaf = "certificates/deletion"

                if ( $PSCmdlet.ShouldProcess('TLSPC', ('Delete {0} certificate(s) in batches of {1}' -f $allCerts.Count, $BatchSize) ) ) {

                    # only retired certs can be deleted, product requirement
                    $null = $allCerts | Invoke-VcCertificateAction -Retire -BatchSize $BatchSize -Confirm:$false

                    $allCerts | Select-VenBatch -Activity 'Deleting certificates' -BatchSize $BatchSize -BatchType 'string' -TotalCount $allCerts.Count | ForEach-Object {
                        $params.Body = @{"certificateIds" = $_ }

                        $null = Invoke-VenafiRestMethod @params
                    }
                }
            }
        }

    }
}

