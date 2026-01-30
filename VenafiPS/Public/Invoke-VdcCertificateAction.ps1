function Invoke-VdcCertificateAction {
    <#
    .SYNOPSIS
    Perform an action against a certificate

    .DESCRIPTION
    One stop shop for basic certificate actions.
    You can Retire, Reset, Renew, Push, Validate, Revoke, or Delete.
    If using PowerShell v7+, this will be run in parallel.

    .PARAMETER Path
    Full path to the certificate

    .PARAMETER Disable
    Disable a certificate

    .PARAMETER Reset
    Reset the state of a certificate and its associated applications

    .PARAMETER Renew
    Requests immediate renewal for an existing certificate

    .PARAMETER Push
    Provisions the same certificate and private key to one or more devices or servers.
    The certificate must be associated with one or more Application objects.
    By default, this will provision the certificate to all associated applications.
    To specify a subset of applications, use the AdditionalParameter parameter as shown in the examples.

    .PARAMETER Validate
    Initiates SSL/TLS network validation

    .PARAMETER Revoke
    Sends a revocation request to the certificate CA

    .PARAMETER Delete
    Delete a certificate.

    .PARAMETER AdditionalParameter
    Additional items specific to the action being taken, if needed.
    See the examples for suggestions.

    .PARAMETER ThrottleLimit
    Limit the number of threads when running in parallel; the default is 100.
    Setting the value to 1 will disable multithreading.
    On PS v5 the ThreadJob module is required.  If not found, multithreading will be disabled.

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.

    .INPUTS
    Path

    .OUTPUTS
    PSCustomObject with the following properties:
        CertificateID - Certificate path
        Success - A value of true indicates that the action was successful
        Error - Indicates any errors that occurred. Not returned when Success is true

    .EXAMPLE
    Invoke-VdcCertificateAction -Path '\VED\Policy\My folder\app.mycompany.com' -Revoke

    Perform an action

    .EXAMPLE
    Invoke-VdcCertificateAction -Path '\VED\Policy\My folder\app.mycompany.com' -Delete -Confirm:$false

    Perform an action bypassing the confirmation prompt.  Only applicable to revoke, disable, and delete.

    .EXAMPLE
    Invoke-VdcCertificateAction -Path '\VED\Policy\My folder\app.mycompany.com' -Revoke -Confirm:$false | Invoke-VdcCertificateAction -Delete -Confirm:$false

    Chain multiple actions together

    .EXAMPLE
    Invoke-VdcCertificateAction -Path '\VED\Policy\My folder\app.mycompany.com' -Push -AdditionalParameter @{'PushToAll'=$false; 'ApplicationDN'=@('\VED\Policy\My folder\app.mycompany.com\app1','\VED\Policy\My folder\app.mycompany.com\app2')}

    Perform a push to a subset of associated applications overwriting the default of pushing to all.

    .EXAMPLE
    Invoke-VdcCertificateAction -Path '\VED\Policy\My folder\app.mycompany.com' -Revoke -AdditionalParameter @{'Comments'='Key compromised'; 'Reason'='3'}

    Perform a revoke sending additional parameters.

    Comments: The details about why the certificate is being revoked. Be sure the comment length does not exceed the limitation from the CA. When accepting a revocation request, they may handle data outside their limits differently. For Entrust CA or EntrustPKI CA, the maximum character limit is 250.

    Values for Reason can be:
        0: None
        1: User key compromised
        2: CA key compromised
        3: User changed affiliation
        4: Certificate superseded
        5: Original use no longer valid


    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Certificates-Reset.php

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Certificates-renew.php

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Certificates-Push.php

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Certificates-Validate.php

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Certificates-revoke.php

    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Params being used in paramset check, not by variable')]

    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('CertificateID', 'id')]
        [string] $Path,

        [Parameter(Mandatory, ParameterSetName = 'Disable')]
        [Alias('Retire')]
        [switch] $Disable,

        [Parameter(Mandatory, ParameterSetName = 'Reset')]
        [switch] $Reset,

        [Parameter(Mandatory, ParameterSetName = 'Renew')]
        [switch] $Renew,

        [Parameter(Mandatory, ParameterSetName = 'Push')]
        [switch] $Push,

        [Parameter(Mandatory, ParameterSetName = 'Validate')]
        [switch] $Validate,

        [Parameter(Mandatory, ParameterSetName = 'Revoke')]
        [switch] $Revoke,

        [Parameter(Mandatory, ParameterSetName = 'Delete')]
        [switch] $Delete,

        [Parameter()]
        [hashtable] $AdditionalParameter,

        [Parameter()]
        [int32] $ThrottleLimit = 100,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession = (Get-VenafiSession)
    )

    begin {
        Test-VenafiSession $PSCmdlet.MyInvocation

        $allCerts = [System.Collections.Generic.List[string]]::new()
    }

    process {

        $addThis = $true

        if ( $PsCmdlet.ParameterSetName -in 'Delete', 'Revoke', 'Disable' ) {
            $addThis = $PSCmdlet.ShouldProcess($Path, ('{0} certificate' -f $PsCmdlet.ParameterSetName))
        }

        if ( $addThis ) { $allCerts.Add($Path) }

    }

    end {

        if ( $allCerts.Count -eq 0 ) { return }
        $action = $PsCmdlet.ParameterSetName

        $parallelParams = @{
            InputObject   = $allCerts
            ThrottleLimit = $ThrottleLimit
            ProgressTitle = "$action certificates"
            VenafiSession = $VenafiSession
            ScriptBlock   = {

                $action = $using:action
                $thisCert = $PSItem

                $params = @{
                    Method = 'Post'
                }

                $returnObject = [PSCustomObject]@{
                    Path    = $PSItem
                    Success = $true
                    Error   = $null
                }

                # at times, we don't want to call an api in the process block
                $performInvoke = $true

                switch ($action) {
                    'Disable' {
                        $performInvoke = $false

                        try {
                            Set-VdcAttribute -Path $thisCert -Attribute @{ 'Disabled' = '1' }
                        }
                        catch {
                            $returnObject.Success = $false
                            $returnObject.Error = $_
                        }
                    }

                    'Reset' {
                        $params.UriLeaf = 'Certificates/Reset'
                        $params.Body = @{CertificateDN = $thisCert }
                    }

                    'Renew' {
                        $params.UriLeaf = 'Certificates/Renew'
                        $params.Body = @{CertificateDN = $thisCert }
                    }

                    'Push' {
                        $params.UriLeaf = 'Certificates/Push'
                        $params.Body = @{
                            CertificateDN = $thisCert
                            'PushToAll'   = $true
                        }
                    }

                    'Validate' {
                        $params.UriLeaf = 'Certificates/Validate'
                        $params.Body = @{CertificateDNs = @($thisCert) }
                    }

                    'Revoke' {
                        $params.UriLeaf = 'Certificates/Revoke'
                        $params.Body = @{CertificateDN = $thisCert }
                    }

                    'Delete' {
                        $performInvoke = $false
                        Remove-VdcCertificate -Path $thisCert -Confirm:$false
                    }
                }

                if ( $AdditionalParameter ) {
                    $params.Body += $AdditionalParameter
                }

                if ( $performInvoke ) {
                    try {
                        $null = Invoke-VenafiRestMethod @params -FullResponse
                    }
                    catch {
                        $returnObject.Success = $false
                        $returnObject.Error = $_
                    }
                }

                # return path so another function can be called
                $returnObject

            }
        }

        Invoke-VenafiParallel @parallelParams

    }
}


