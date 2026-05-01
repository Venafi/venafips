function Invoke-TrustRestMethod {
    <#
    .SYNOPSIS
    Ability to execute REST API calls which don't exist in a dedicated function yet

    .DESCRIPTION
    Ability to execute REST API calls which don't exist in a dedicated function yet

    .PARAMETER TrustClient
    TrustClient object from New-TrustClient.
    For typical calls to New-TrustClient, the object will be stored as a session object named $TrustClient.

    .PARAMETER Method
    API method, either get, post, patch, put or delete.

    .PARAMETER UriLeaf
    Path to the api endpoint excluding the base url and site, eg. certificates/import

    .PARAMETER Header
    Optional additional headers.  The authorization header will be included automatically.

    .PARAMETER Body
    Optional body to pass to the endpoint

    .PARAMETER Server
    Server or url to access vedsdk, venafi.company.com or https://venafi.company.com.

    .PARAMETER UseDefaultCredential
    Use Windows Integrated authentication

    .PARAMETER Certificate
    Certificate for Certificate Manager, Self-Hosted token-based authentication

    .PARAMETER UriRoot
    Path between the server and endpoint.

    .PARAMETER FullResponse
    Provide the full response including headers as opposed to just the response content

    .PARAMETER TimeoutSec
    Connection timeout.  Default to 0, no timeout.

    .PARAMETER SkipCertificateCheck
    Skip certificate checking, eg. self signed certificate on server

    .INPUTS
    None

    .OUTPUTS
    PSCustomObject

    .EXAMPLE
    Invoke-TrustRestMethod -Method Delete -UriLeaf 'Discovery/{1345311e-83c5-4945-9b4b-1da0a17c45c6}'
    Api call

    .EXAMPLE
    Invoke-TrustRestMethod -Method Post -UriLeaf 'Certificates/Revoke' -Body @{'CertificateDN'='\ved\policy\mycert.com'}
    Api call with optional payload

    #>

    [CmdletBinding(DefaultParameterSetName = 'Session')]

    param (
        [Parameter(ParameterSetName = 'Session')]
        [ValidateNotNullOrEmpty()]
        [TrustClient] $TrustClient,

        [Parameter(Mandatory, ParameterSetName = 'URL')]
        [ValidateNotNullOrEmpty()]
        [Alias('ServerUrl')]
        [String] $Server,

        [Parameter(ParameterSetName = 'URL')]
        [Alias('UseDefaultCredentials')]
        [switch] $UseDefaultCredential,

        [Parameter(ParameterSetName = 'URL')]
        [X509Certificate] $Certificate,

        [Parameter()]
        [ValidateSet("Get", "Post", "Patch", "Put", "Delete", 'Head')]
        [String] $Method = 'Get',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String] $UriRoot = 'vedsdk',

        # [Parameter(Mandatory)]
        # [ValidateNotNullOrEmpty()]
        [Parameter()]
        [String] $UriLeaf,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [hashtable] $Header,

        [Parameter()]
        [Hashtable] $Body,

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

    # default parameter set, no explicit session will come here
    if ( $PSCmdLet.ParameterSetName -eq 'Session' ) {

        if ( -not $TrustClient ) { $TrustClient = Get-TrustClient }

        # When a TrustClient is explicitly provided, validate the platform matches the calling function
        $callingCmd = @(Get-PSCallStack)[1].Command
        $expectedPlatform = switch -Regex ($callingCmd) {
            '-Ngts' { 'NGTS' }
            '-Vc' { 'VC' }
            '-Vdc' { 'VDC' }
            default { $null }
        }
        if ($expectedPlatform -and $expectedPlatform -ne $TrustClient.Platform) {
            throw "You are attempting to call a $expectedPlatform function with a $($TrustClient.Platform) session.  Please provide the correct session or call New-TrustClient for the target platform."
        }

        # Get-TrustClient auto-refreshes script/nested sessions.
        # For explicitly provided class sessions, ensure we also refresh when expiring soon.
        if ($PSBoundParameters.ContainsKey('TrustClient')) {
            if ($TrustClient.Expires -and $TrustClient.Expires -gt [datetime]::MinValue) {
                $secondsRemaining = [math]::Round((($TrustClient.Expires.ToUniversalTime()) - [DateTime]::UtcNow).TotalSeconds, 0)
                Write-Verbose ("Access token expires in {0} seconds" -f $secondsRemaining)
            }

            if ($TrustClient.IsExpired()) {
                if ($TrustClient.CanRefresh()) {
                    Write-Verbose 'Access token is expired or nearing expiration; refreshing provided session.'
                    Invoke-SessionRefresh -Session $TrustClient
                }
                else {
                    throw 'Access token has expired (or will expire within 60 seconds) and cannot be automatically refreshed. Please authenticate again with New-TrustClient.'
                }
            }
        }

        $Server = $TrustClient.Server

        # set auth header based on TrustClient auth type
        $params.Headers = switch ($TrustClient.AuthType) {
            'ApiKey' {
                @{ 'tppl-api-key' = $TrustClient.ApiKey.GetNetworkCredential().password }
            }
            default {
                @{ 'Authorization' = 'Bearer {0}' -f $TrustClient.AccessToken.GetNetworkCredential().password }
            }
        }

        if ( $null -ne $Header ) { $params.Headers += $Header }
        $SkipCertificateCheck = $TrustClient.SkipCertificateCheck
        $params.TimeoutSec = $TrustClient.TimeoutSec
    }

    if ( $TrustClient.Platform -eq 'VDC' ) {
        if ( $UseDefaultCredential.IsPresent ) {
            $params.Add('UseDefaultCredentials', $true)
        }

        if ( $null -ne $Certificate ) {
            $params.Add('Certificate', $Certificate)
        }
    }
    else {

        # switch the default uri root for VC and NGTS

        if ( -not $PSBoundParameters.ContainsKey('UriRoot') ) {
            $UriRoot = 'v1'
        }

        if ( $TrustClient.Platform -eq 'NGTS' ) {
            $UriRoot = 'ngts/{0}' -f $UriRoot.TrimStart('/')
        }
    }

    $params.Uri = '{0}/{1}/{2}' -f $Server, $UriRoot, $UriLeaf

    if ( $null -ne $Body ) {
        switch ($Method.ToLower()) {
            'head' {
                # a head method requires the params be provided as a query string, not body
                # invoke-webrequest does not do this so we have to build the string manually
                $newUri = New-HttpQueryString -Uri $params.Uri -QueryParameter $Body
                $params.Uri = $newUri
                $params.Body = $null
            }

            'get' {
                $params.Body = $Body
            }

            Default {
                $preJsonBody = $Body
                $params.Body = (ConvertTo-Json $Body -Depth 20 -Compress)
                # for special characters, we need to set the content type to utf-8
                $params.ContentType = "application/json; charset=utf-8"
            }
        }
    }

    if ( $preJsonBody ) {
        $paramsToWrite = $params.Clone()
        $paramsToWrite.Body = $preJsonBody
        $paramsToWrite | Write-VerboseWithSecret
        Write-Debug -Message ($paramsToWrite | ConvertTo-Json -Depth 10)
    }
    else {
        $params | Write-VerboseWithSecret
        Write-Debug -Message ($params | ConvertTo-Json -Depth 10)
    }

    # ConvertTo-Json, used in Write-VerboseWithSecret, has an issue with certificates
    # add this param after
    if ( $Certificate ) {
        $params.Add('Certificate', $Certificate)
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

    $oldProgressPreference = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'

    try {
        if ( $FullResponse ) {
            $response = Invoke-WebRequest @params -ErrorAction Stop
        }
        else {
            $response = Invoke-RestMethod @params -ErrorAction Stop
        }
        try { if ($DebugPreference -eq 'Continue') { $response | ConvertTo-Json -Depth 10 | Write-Debug } } catch {}
        $verboseOutput = $response 4>&1
        $verboseOutput.Message | Write-VerboseWithSecret
    }
    catch {

        # if trying with a slash below doesn't work, we want to provide the original error
        $originalError = $_

        $statusCode = [int]$originalError.Exception.Response.StatusCode
        Write-Verbose ('Response status code {0}' -f $statusCode)

        switch ($statusCode) {
            403 {

                $permMsg = ''

                # get scope details for tpp
                if ( $TrustClient.Platform -eq 'VDC' ) {
                    $callingFunction = @(Get-PSCallStack)[1].InvocationInfo.MyCommand.Name
                    $callingFunctionScope = ($script:functionConfig).$callingFunction.VdcTokenScope
                    if ( $callingFunctionScope ) { $permMsg += "$callingFunction requires a token scope of '$callingFunctionScope'." }

                    $rejectedScope = Select-String -InputObject $originalError.ErrorDetails.Message -Pattern 'Grant rejected scope ([^.]+)'

                    if ( $rejectedScope.Matches.Groups.Count -gt 1 ) {
                        $permMsg += ("  The current scope of {0} is insufficient." -f $rejectedScope.Matches.Groups[1].Value.Replace('\u0027', "'"))
                    }
                    $permMsg += '  Call New-TrustClient with the correct scope.'
                }
                else {
                    $permMsg = $originalError.ErrorDetails.Message
                }


                throw $permMsg
            }

            409 {
                # 409 = item already exists.  some functions use this for a 'force' option, eg. Set-VdcPermission
                # treat this as non error/exception if FullResponse provided
                if ( $FullResponse ) {
                    $response = [pscustomobject] @{
                        StatusCode = $statusCode
                        Error      =
                        try {
                            $originalError.ErrorDetails.Message | ConvertFrom-Json
                        }
                        catch {
                            $originalError.ErrorDetails.Message
                        }
                    }
                }
                else {
                    throw $originalError
                }
            }

            Default {
                throw $originalError
            }
        }

    }
    finally {
        $ProgressPreference = $oldProgressPreference
    }

    $response
}

