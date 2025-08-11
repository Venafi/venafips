function Invoke-VcGraphQL {
    <#
    .SYNOPSIS
    Execute a GraphQL query against the Venafi Cloud API

    #>

    [CmdletBinding()]

    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession,

        [Parameter()]
        [ValidateSet('Post')]
        [String] $Method = 'Post',

        [Parameter()]
        [hashtable] $Header,

        [Parameter(Mandatory)]
        [string] $Query,

        [Parameter()]
        [hashtable] $Variables,

        [Parameter()]
        [switch] $FullResponse,

        [Parameter()]
        [Int32] $TimeoutSec = 0,

        [Parameter()]
        [switch] $SkipCertificateCheck
    )

    $params = @{
        Method          = $Method
        ContentType     = 'application/json'
        UseBasicParsing = $true
        TimeoutSec      = $TimeoutSec
    }

    $VenafiSession = Get-VenafiSession

    $Server = $VenafiSession.Server
    $auth = $VenafiSession.Key.GetNetworkCredential().password
    $SkipCertificateCheck = $VenafiSession.SkipCertificateCheck
    $params.TimeoutSec = $VenafiSession.TimeoutSec

    $allHeaders = @{
        "tppl-api-key" = $auth
    }

    $params.Uri = "$Server/graphql"

    # append any headers passed in
    if ( $Header ) { $allHeaders += $Header }
    # if there are any headers, add to the rest payload
    # in the case of inital authentication, eg, there won't be any
    if ( $allHeaders ) { $params.Headers = $allHeaders }

    $body = @{'query' = $Query }
    if ( $Variables ) {
        $body['variables'] = $Variables
    }
    $params.Body = (ConvertTo-Json $body -Depth 20 -Compress)
    $params.ContentType = "application/json; charset=utf-8"

    if ( $preJsonBody ) {
        $paramsToWrite = $params.Clone()
        $paramsToWrite.Body = $preJsonBody
        $paramsToWrite | Write-VerboseWithSecret
    }
    else {
        $params | Write-VerboseWithSecret
    }

    if ( $SkipCertificateCheck -or $env:VENAFIPS_SKIP_CERT_CHECK -eq '1' ) {
        if ( $PSVersionTable.PSVersion.Major -lt 6 ) {
            if ( [System.Net.ServicePointManager]::CertificatePolicy.GetType().FullName -ne 'TrustAllCertsPolicy' ) {
                add-type @"
                using System.Net;
                using System.Security.Cryptography.X509Certificates;
                public class TrustAllCertsPolicy : ICertificatePolicy {
                    public bool CheckValidationResult(ServicePoint srvPoint, X509Certificate certificate, WebRequest request, int certificateProblem) {
                        return true;
                    }
                }
"@
                [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
            }
        }
        else {
            $params.Add('SkipCertificateCheck', $true)
        }
    }

    $verboseOutput = $($response = Invoke-WebRequest @params -ErrorAction Stop -ProgressAction SilentlyContinue) 4>&1
    $verboseOutput.Message | Write-VerboseWithSecret

    if ( $FullResponse ) {
        $response
    }
    else {
        if ( $response.Content ) {
            try {
                $response.Content | ConvertFrom-Json | Select-Object -ExpandProperty 'data'
            }
            catch {
                throw ('Invalid JSON response {0}' -f $response.Content)
            }
        }
    }
}
