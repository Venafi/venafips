function Invoke-VenafiRestMethod {
    <#
    .SYNOPSIS
    Ability to execute REST API calls which don't exist in a dedicated function yet

    .DESCRIPTION
    Ability to execute REST API calls which don't exist in a dedicated function yet

    .PARAMETER VenafiSession
    VenafiSession object from New-VenafiSession.
    For typical calls to New-VenafiSession, the object will be stored as a session object named $VenafiSession.
    Otherwise, if -PassThru was used, provide the resulting object.

    .PARAMETER Method
    API method, either get, post, patch, put or delete.

    .PARAMETER UriLeaf
    Path to the api endpoint excluding the base url and site, eg. certificates/import

    .PARAMETER Header
    Optional additional headers.  The authorization header will be included automatically.

    .PARAMETER Body
    Optional body to pass to the endpoint

    .PARAMETER VcRegion
    Certificate Manager, SaaS region to target.  Only supported if VenafiSession is an api key otherwise the comes from VenafiSession directly.

    .PARAMETER Platform
    Venafi Platform to target, either VC or VDC.
    If not provided, the platform will be determined based on the VenafiSession or the calling function name.

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
    Invoke-VenafiRestMethod -Method Delete -UriLeaf 'Discovery/{1345311e-83c5-4945-9b4b-1da0a17c45c6}'
    Api call

    .EXAMPLE
    Invoke-VenafiRestMethod -Method Post -UriLeaf 'Certificates/Revoke' -Body @{'CertificateDN'='\ved\policy\mycert.com'}
    Api call with optional payload

    #>

    [CmdletBinding(DefaultParameterSetName = 'Session')]
    [Alias('Invoke-TppRestMethod')]

    param (
        [Parameter(ParameterSetName = 'Session')]
        [ValidateNotNullOrEmpty()]
        [Alias('Key', 'AccessToken')]
        [psobject] $VenafiSession,

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
        [ValidateScript(
            {
                if ( $_ -notin ($script:VcRegions).Keys ) {
                    throw ('{0} is not a valid region.  Valid regions include {1}.' -f $_, (($script:VcRegions).Keys -join ','))
                }
                $true
            }
        )]
        [string] $VcRegion = 'us',

        [Parameter()]
        [ValidateSet('VC', 'VDC')]
        [string] $Platform,

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

    # VC supports both apiley and token based auth, VDC only token

    $authType = 'token'

    $params = @{
        Method          = $Method
        ContentType     = 'application/json'
        UseBasicParsing = $true
        TimeoutSec      = $TimeoutSec
    }

    # default parameter set, no explicit session will come here
    if ( $PSCmdLet.ParameterSetName -eq 'Session' ) {

        if ( -not $VenafiSession ) { $VenafiSession = Get-VenafiSession }

        switch ($VenafiSession.GetType().Name) {
            'PSCustomObject' {
                $Server = $VenafiSession.Server
                $thisPlatform = $VenafiSession.Platform
                if ( $null -ne $VenafiSession.Key ) {
                    $auth = $VenafiSession.Key.GetNetworkCredential().password
                    $authType = 'apikey'
                }
                elseif ( $null -ne $VenafiSession.Token ) {
                    $auth = $VenafiSession.Token.AccessToken.GetNetworkCredential().password
                }
                else {
                    throw [System.ArgumentException]::new('Neither an api key or token could be found in VenafiSession')
                }
                $SkipCertificateCheck = $VenafiSession.SkipCertificateCheck
                $params.TimeoutSec = $VenafiSession.TimeoutSec
                break
            }

            'String' {
                $auth = $VenafiSession

                if ( Test-IsGuid($VenafiSession) ) {
                    # if we were provided a key directly and not a full session, determine which region to contact

                    $Server = ($script:VcRegions).$VcRegion
                    $thisPlatform = 'VC'
                    $authType = 'apikey'
                }
                else {
                    # access token auth for both VC and VDC, determine which one
                    $thisPlatform = if ( $PSBoundParameters.ContainsKey('Platform') ) {
                        $Platform
                    }
                    elseif ( $MyInvocation.InvocationName -match '-Vdc' ) {
                        'VDC'
                    }
                    elseif ( $MyInvocation.InvocationName -match '-Vc' ) {
                        'VC'
                    }
                    else {
                        throw 'Venafi Platform, VC or VDC, could not be determined'
                    }
                }
            }

            Default {
                throw "Unknown session '$VenafiSession'.  Please run New-VenafiSession or provide a Certificate Manager, SaaS key or Certificate Manager, Self-Hosted token."
            }
        }

        # set auth header
        $params.Headers = if ( $authType -eq 'token' ) {
            # vc and vdc
            @{
                'Authorization' = "Bearer $auth"
            }
        }
        else {
            # vc only
            @{
                "tppl-api-key" = $auth
            }
        }
        if ( $null -ne $Header ) { $params.Headers += $Header }
    }

    if ( $thisPlatform -eq 'VC' ) {
        # switch the default uri root for VC
        if ( $UriRoot -eq 'vedsdk' ) {
            $UriRoot = 'v1'
        }
    }
    else {
        # VDC specific
        if ( $UseDefaultCredential.IsPresent ) {
            $params.Add('UseDefaultCredentials', $true)
        }

        if ( $null -ne $Certificate ) {
            $params.Add('Certificate', $Certificate)
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
                if ( $thisPlatform -eq 'VDC' ) {
                    $callingFunction = @(Get-PSCallStack)[1].InvocationInfo.MyCommand.Name
                    $callingFunctionScope = ($script:functionConfig).$callingFunction.TppTokenScope
                    if ( $callingFunctionScope ) { $permMsg += "$callingFunction requires a token scope of '$callingFunctionScope'." }

                    $rejectedScope = Select-String -InputObject $originalError.ErrorDetails.Message -Pattern 'Grant rejected scope ([^.]+)'

                    if ( $rejectedScope.Matches.Groups.Count -gt 1 ) {
                        $permMsg += ("  The current scope of {0} is insufficient." -f $rejectedScope.Matches.Groups[1].Value.Replace('\u0027', "'"))
                    }
                    $permMsg += '  Call New-VenafiSession with the correct scope.'
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

