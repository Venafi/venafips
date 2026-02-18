function Set-VcCertificateRequest {
    <#
    .SYNOPSIS
    Update an existing application

    .DESCRIPTION
    Update details of existing applications.
    Additional properties will be available in the future.

    .PARAMETER ID
    The certificate request id to process.

    .PARAMETER Approve
    Provide the switch to approve a request

    .PARAMETER RejectReason
    In the case of rejection, provide a reason.
    The default will be 'reject'.

    .PARAMETER Wait
    Wait for the certificate request to either be issued or fail.
    Depending on the speed of your CA, this could take some time.

    .PARAMETER PassThru
    Return the certificate request object.
    If -Wait is specified, the returned object will have details on the newly created certificate.

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A Certificate Manager, SaaS key can also provided.

    .INPUTS
    ID

    .OUTPUTS
    PSCustomObject

    .EXAMPLE
    Set-VcCertificateRequest -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2' -Approve

    Approve a request

    .EXAMPLE
    Set-VcCertificateRequest -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2' -Approve:$false

    Reject a request

    .EXAMPLE
    Set-VcCertificateRequest -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2' -Approve:$false -RejectReason 'not needed'

    Reject a request with a specific reason

    .EXAMPLE
    Set-VcCertificateRequest -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2' -Approve -Wait

    Approve a request and wait for the certificate request to finish processing

    .EXAMPLE
    Set-VcCertificateRequest -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2' -Approve -Wait -PassThru

    Approve a request and wait for the certificate request to finish processing.
    Once finished, return the resulting object which contains the newly created certificate details.

    .EXAMPLE
    Find-VcCertificateRequest -Status PENDING_APPROVAL | Set-VcCertificateRequest -Approve

    Get all requests pending approval and approve them all.
    Use the Find filter to narrow the scope of requests found.
    #>

    [CmdletBinding(SupportsShouldProcess)]

    param (

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('certificateRequestId')]
        [string] $ID,

        [Parameter(Mandatory, ParameterSetName = 'Approval')]
        [switch] $Approve,

        [Parameter(ParameterSetName = 'Approval')]
        [string] $RejectReason = 'Rejection processed by VenafiPS',

        [Parameter(ParameterSetName = 'Approval')]
        [switch] $Wait,

        [Parameter()]
        [switch] $PassThru,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Alias('Key')]
        [psobject] $VenafiSession
    )

    begin {
        Test-VenafiSession $PSCmdlet.MyInvocation
    }

    process {

        if ( $PSBoundParameters.ContainsKey('Approve') ) {
            $decision = if ($Approve) { 'APPROVE' } else { 'REJECT' }

            $params = @{
                Method  = 'Post'
                UriLeaf = 'certificaterequests/{0}/approval/{1}' -f $ID, $decision
            }

            if ( -not $Approval ) {
                $params.Body = @{'reason' = $RejectReason }
            }

            if ( $PSCmdlet.ShouldProcess($ID, "$decision certificate request") ) {
                $response = Invoke-VenafiRestMethod @params
            }

            if ( $Approve -and $Wait ) {
                Write-Verbose 'Request approved, waiting for a status of either issued or failed'
                do {
                    Start-Sleep -Seconds 1
                    $response = Invoke-VenafiRestMethod -UriRoot 'outagedetection/v1' -UriLeaf "certificaterequests/$ID"
                    Write-Verbose ('Current status: {0}' -f $response.status)
                } until (
                    $response.status -in 'ISSUED', 'FAILED'
                )
            }

            if ( $PassThru ) {
                $response
            }
        }
    }
}

