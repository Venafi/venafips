function Get-TrustCertificateRequest {
    <#
    .SYNOPSIS
    Get certificate request details

    .DESCRIPTION
    Get certificate request details including status, csr, creation date, etc

    .PARAMETER CertificateRequest
    Certificate Request ID

    .PARAMETER All
    Get all certificate requests

    .PARAMETER TrustClient
    Authentication for the function.
    The value defaults to the script session object $TrustClient created by New-TrustClient.

    .INPUTS
    CertificateRequest

    .EXAMPLE
    Get-TrustCertificateRequest -CertificateRequest '9719975f-6e06-4d4b-82b9-bd829e5528f0'

    Get single certificate request

    .EXAMPLE
    Find-TrustCertificateRequest -Status ISSUED | Get-TrustCertificateRequest

    Get certificate request details from a search

    .EXAMPLE
    Get-TrustCertificateRequest -All

    Get all certificate requests

    #>

    [CmdletBinding(DefaultParameterSetName = 'ID')]
    [Alias('Get-VcCertificateRequest')]

    param (

        [Parameter(Mandatory, ParameterSetName = 'ID', ValueFromPipelineByPropertyName, Position = 0)]
        [Alias('certificateRequestId')]
        [string] $CertificateRequest,

        [Parameter(Mandatory, ParameterSetName = 'All')]
        [switch] $All,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [TrustClient] $TrustClient
    )

    begin {
    }

    process {

        $params = @{
            UriRoot = 'outagedetection/v1'
            UriLeaf = 'certificaterequests'
        }

        if ( $PSBoundParameters.ContainsKey('CertificateRequest') ) {
            $params.UriLeaf += "/{0}" -f $CertificateRequest
        }

        $response = Invoke-TrustRestMethod @params

        if ( $response.PSObject.Properties.Name -contains 'certificateRequests' ) {
            $certificateRequests = $response | Select-Object -ExpandProperty 'certificateRequests'
        }
        else {
            $certificateRequests = $response
        }

        if ( $certificateRequests ) {
            $certificateRequests | Select-Object @{ 'n' = 'certificateRequestId'; 'e' = { $_.Id } }, * -ExcludeProperty Id
        }
    }
}

