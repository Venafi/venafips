function Get-VcCertificateRequest {
    <#
    .SYNOPSIS
    Get certificate request details

    .DESCRIPTION
    Get certificate request details including status, csr, creation date, etc

    .PARAMETER CertificateRequest
    Certificate Request ID

    .PARAMETER All
    Get all certificate requests

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A Certificate Manager, SaaS key can also provided.

    .INPUTS
    CertificateRequest

    .EXAMPLE
    Get-VcCertificateRequest -CertificateRequest '9719975f-6e06-4d4b-82b9-bd829e5528f0'

    Get single certificate request

    .EXAMPLE
    Find-VcCertificateRequest -Status ISSUED | Get-VcCertificateRequest

    Get certificate request details from a search

    .EXAMPLE
    Get-VcCertificateRequest -All

    Get all certificate requests

    #>

    [CmdletBinding(DefaultParameterSetName = 'ID')]

    param (

        [Parameter(Mandatory, ParameterSetName = 'ID', ValueFromPipelineByPropertyName, Position = 0)]
        [Alias('certificateRequestId', 'ID')]
        [string] $CertificateRequest,

        [Parameter(Mandatory, ParameterSetName = 'All')]
        [switch] $All,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {
        Test-VenafiSession $PSCmdlet.MyInvocation
    }

    process {

        $params = @{
            UriRoot = 'outagedetection/v1'
            UriLeaf = 'certificaterequests'
        }

        if ( $PSBoundParameters.ContainsKey('CertificateRequest') ) {
            $params.UriLeaf += "/{0}" -f $CertificateRequest
        }

        $response = Invoke-VenafiRestMethod @params

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

