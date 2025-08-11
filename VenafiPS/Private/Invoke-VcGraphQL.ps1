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

        # [Parameter(Mandatory, ParameterSetName = 'URL')]
        # [ValidateNotNullOrEmpty()]
        # [Alias('ServerUrl')]
        # [String] $Server,

        # [Parameter(ParameterSetName = 'URL')]
        # [Alias('UseDefaultCredentials')]
        # [switch] $UseDefaultCredential,

        # [Parameter(ParameterSetName = 'URL')]
        # [X509Certificate] $Certificate,

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


    # if ( $PSCmdLet.ParameterSetName -eq 'Session' ) {

    $VenafiSession = Get-VenafiSession

    $Server = $VenafiSession.Server
    $auth = $VenafiSession.Key.GetNetworkCredential().password
    $SkipCertificateCheck = $VenafiSession.SkipCertificateCheck
    $params.TimeoutSec = $VenafiSession.TimeoutSec
    # switch ($VenafiSession.GetType().Name) {
    #     'PSCustomObject' {
    #         break
    #     }

    #     'String' {
    #         $auth = $VenafiSession
    #         # TODO: defaults to US, add other region support
    #         $Server = ($script:VcRegions).'us'
    #     }

    #     Default {
    #         throw "Unknown session '$VenafiSession'.  Please run New-VenafiSession or provide a TLSPC key."
    #     }
    # }

    $allHeaders = @{
        "tppl-api-key" = $auth
    }
    # }

    $params.Uri = "$Server/graphql"

    # append any headers passed in
    if ( $Header ) { $allHeaders += $Header }
    # if there are any headers, add to the rest payload
    # in the case of inital authentication, eg, there won't be any
    if ( $allHeaders ) { $params.Headers = $allHeaders }

    # if ( $UseDefaultCredential.IsPresent -and $Certificate ) {
    #     throw 'You cannot use UseDefaultCredential and Certificate parameters together'
    # }

    # if ( $UseDefaultCredential.IsPresent ) {
    #     $params.Add('UseDefaultCredentials', $true)
    # }

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

    # ConvertTo-Json, used in Write-VerboseWithSecret, has an issue with certificates
    # add this param after
    # if ( $Certificate ) {
    #     $params.Add('Certificate', $Certificate)
    # }

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

    $oldProgressPreference = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'

    try {
        $verboseOutput = $($response = Invoke-WebRequest @params -ErrorAction Stop) 4>&1
        $verboseOutput.Message | Write-VerboseWithSecret
    }
    catch {

        # if trying with a slash below doesn't work, we want to provide the original error
        $originalError = $_

        $statusCode = [int]$originalError.Exception.Response.StatusCode
        Write-Verbose ('Response status code {0}' -f $statusCode)

        switch ($statusCode) {
            # 403 {

            #     $permMsg = ''

            #     # get scope details for tpp
            #     # if ( $platform -ne 'VC' ) {
            #     $callingFunction = @(Get-PSCallStack)[1].InvocationInfo.MyCommand.Name
            #     $callingFunctionScope = ($script:functionConfig).$callingFunction.TppTokenScope
            #     if ( $callingFunctionScope ) { $permMsg += "$callingFunction requires a token scope of '$callingFunctionScope'." }

            #     $rejectedScope = Select-String -InputObject $originalError.ErrorDetails.Message -Pattern 'Grant rejected scope ([^.]+)'

            #     if ( $rejectedScope.Matches.Groups.Count -gt 1 ) {
            #         $permMsg += ("  The current scope of {0} is insufficient." -f $rejectedScope.Matches.Groups[1].Value.Replace('\u0027', "'"))
            #     }
            #     $permMsg += '  Call New-VenafiSession with the correct scope.'
            #     # }
            #     # else {
            #     #     $permMsg = $originalError.ErrorDetails.Message
            #     # }


            #     throw $permMsg
            # }

            # 409 {
            #     # 409 = item already exists.  some functions use this for a 'force' option, eg. Set-VdcPermission
            #     # treat this as non error/exception if FullResponse provided
            #     if ( $FullResponse ) {
            #         $response = [pscustomobject] @{
            #             StatusCode = $statusCode
            #             Error      =
            #             try {
            #                 $originalError.ErrorDetails.Message | ConvertFrom-Json
            #             }
            #             catch {
            #                 $originalError.ErrorDetails.Message
            #             }
            #         }
            #     }
            #     else {
            #         throw $originalError
            #     }
            # }

            Default {
                throw $originalError
            }
        }

    }
    finally {
        $ProgressPreference = $oldProgressPreference
    }

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
