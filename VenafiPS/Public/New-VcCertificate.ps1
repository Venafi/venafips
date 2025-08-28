function New-VcCertificate {
    <#
    .SYNOPSIS
    Create certificate request

    .DESCRIPTION
    Create certificate request from automated secure keypair details or CSR

    .PARAMETER Application
    Application name or id to associate this certificate with.

    .PARAMETER IssuingTemplate
    Issuing template id, name, or alias.
    The template must be associated with the provided Application.
    If the application has only one template, this parameter is optional.

    .PARAMETER CommonName
    Common name (CN).  Required if not providing a CSR.

    .PARAMETER Organization
    The Organization field for the certificate Subject DN

    .PARAMETER OrganizationalUnit
    One or more departments or divisions within the organization that is responsible for maintaining the certificate

    .PARAMETER City
    The City/Locality field for the certificate Subject DN

    .PARAMETER State
    The State field for the certificate Subject DN

    .PARAMETER Country
    The Country field for the certificate Subject DN

    .PARAMETER Csr
    CSR in PKCS#10 format which conforms to the rules of the issuing template

    .PARAMETER SanDns
    One or more subject alternative name dns entries

    .PARAMETER SanIP
    One or more subject alternative name ip address entries

    .PARAMETER SanUri
    One or more subject alternative name uri entries

    .PARAMETER SanEmail
    One or more subject alternative name email entries

    .PARAMETER KeySize
    Specify a key size for RSA keys
    Valid values are: 2048, 3072, 4096
    If not provided, the default from the issuing template will be used.
    Cannot be used with -KeyCurve.

    .PARAMETER KeyCurve
    Specify the elliptic curve for key generation.
    Valid values are: P256, P384, P521, ED25519
    If not provided, the default from the issuing template will be used.
    Cannot be used with -KeySize.

    .PARAMETER ValidUntil
    Date at which the certificate becomes invalid.
    The day and hour will be set and not to the minute level.

    .PARAMETER Tag
    One or more tags to assign to the certificate at creation.

    .PARAMETER PassThru
    Return the certificate request.
    If the certificate was successfully issued, it will be returned as the property 'certificate'.

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A TLSPC key can also provided directly.

    .INPUTS
    CommonName

    .OUTPUTS
    pscustomobject, if PassThru is provided

    .EXAMPLE
    New-VcCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com'

    Create certificate

    .EXAMPLE
    New-VcCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com' -Tag 'tag1','tag2:value'

    Create certificate and associate 1 or more tags

    .EXAMPLE
    New-VcCertificate -Application 'MyApp' -CommonName 'app.mycert.com'

    Create certificate with the template associated with the application.
    This only works when only 1 template is associated with an application.

    .EXAMPLE
    New-VcCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com' -SanIP '1.2.3.4'

    Create certificate with optional SAN data

    .EXAMPLE
    New-VcCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com' -ValidUntil (Get-Date).AddMonths(6)

    Create certificate with specific validity

    .EXAMPLE
    New-VcCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com' -PassThru

    Create certificate and return the created object

    .EXAMPLE
    New-VcCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -Csr "-----BEGIN CERTIFICATE REQUEST-----\nMIICYzCCAUsCAQAwHj....BoiNIqtVQxFsfT+\n-----END CERTIFICATE REQUEST-----\n"

    Create certificate by providing a CSR

    .LINK
    https://developer.venafi.com/tlsprotectcloud/reference/certificaterequests_create

    #>

    [CmdletBinding(DefaultParameterSetName = 'ASK', SupportsShouldProcess)]
    [Alias('New-VaasCertificate')]

    param (

        [Parameter(Mandatory)]
        [String] $Application,

        [Parameter()]
        [String] $IssuingTemplate,

        [Parameter(ParameterSetName = 'ASK', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $CommonName,

        [Parameter(ParameterSetName = 'ASK')]
        [ValidateNotNullOrEmpty()]
        [String] $Organization,

        [Parameter(ParameterSetName = 'ASK')]
        [ValidateNotNullOrEmpty()]
        [String[]] $OrganizationalUnit,

        [Parameter(ParameterSetName = 'ASK')]
        [ValidateNotNullOrEmpty()]
        [String] $City,

        [Parameter(ParameterSetName = 'ASK')]
        [ValidateNotNullOrEmpty()]
        [String] $State,

        [Parameter(ParameterSetName = 'ASK')]
        [ValidateNotNullOrEmpty()]
        [String] $Country,

        [Parameter(ParameterSetName = 'CSR', Mandatory)]
        [string] $Csr,

        # [Parameter(ParameterSetName = 'ExistingCSR', Mandatory, ValueFromPipelineByPropertyName)]
        # [Alias('certificateId', 'ID')]
        # [string] $Certificate,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String[]] $SanDns,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String[]] $SanIP,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String[]] $SanUri,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String[]] $SanEmail,

        [Parameter(ParameterSetName = 'ASK')]
        [ValidateSet(2048, 3072, 4096)]
        [Int32] $KeySize,

        [Parameter(ParameterSetName = 'ASK')]
        [ValidateSet('P256', 'P384', 'P521', 'ED25519')]
        [string] $KeyCurve,

        [Parameter()]
        [ValidateScript(
            {
                $span = $_ - (Get-Date)
                if ( $span.Days -ge 0 -or $span.Hours -ge 0 ) {
                    $true
                }
                else {
                    throw 'ValidUntil must be a date in the future'
                }
            }
        )]
        [DateTime] $ValidUntil,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String[]] $Tag,

        [Parameter()]
        [switch] $PassThru,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {

        Test-VenafiSession $PSCmdlet.MyInvocation

        # validation
        $thisApp = Get-VcData -Type Application -InputObject $Application -Object -FailOnNotFound

        if ( $thisApp.issuingTemplate.Count -eq 0 ) {
            throw 'No templates associated with this application'
        }

        if ( -not $IssuingTemplate ) {
            # issuing template not provided, see if the app has one
            switch ($thisApp.issuingTemplate.Count) {
                1 {
                    # there is only one template, use it
                    $thisTemplate = Get-VcData -Type IssuingTemplate -InputObject $thisApp.issuingTemplate[0].issuingTemplateId -Object
                    break
                }

                Default {
                    throw 'IssuingTemplate is required when the application has more than 1 template associated'
                }
            }
        }
        else {
            # template provided, check if name or alias or id
            if ( $IssuingTemplate -in $thisApp.issuingTemplate.name ) {
                # name is an alias, get template
                $templateId = $thisApp.issuingTemplate | Where-Object { $_.name -eq $IssuingTemplate } | Select-Object -ExpandProperty issuingTemplateId
                $thisTemplate = Get-VcData -Type IssuingTemplate -InputObject $templateId -Object
            }
            else {
                # lookup provided value, name or id
                $thisTemplate = Get-VcData -Type IssuingTemplate -InputObject $IssuingTemplate -Object -FailOnNotFound
            }
        }

        if ( $ValidUntil ) {
            $span = New-TimeSpan -Start (Get-Date) -End $ValidUntil
            $validity = 'P{0}DT{1}H' -f $span.Days, $span.Hours
        }
        else {
            # end date not provided, use default from template
            $validity = $thisTemplate.product.validityPeriod
        }

        if ( $KeySize -and $KeyCurve ) {
            throw 'You cannot specify both -KeySize and -KeyCurve'
        }
    }

    process {

        $params = @{

            Method  = 'Post'
            UriRoot = 'outagedetection/v1'
            UriLeaf = 'certificaterequests'
            Body    = @{
                isVaaSGenerated              = $PSCmdlet.ParameterSetName -eq 'ASK'
                applicationId                = $thisApp.applicationId
                certificateIssuingTemplateId = $thisTemplate.issuingTemplateId
                validityPeriod               = $validity
                reuseCSR                     = $false
            }
        }

        switch ($PSCmdlet.ParameterSetName) {
            'ASK' {
                $params.Body.csrAttributes = @{
                    commonName = $CommonName
                }
                $target = $CommonName

                if ( $PSBoundParameters.ContainsKey('Organization') ) {
                    $params.Body.csrAttributes.organization = $Organization
                }
                elseif ( $thisTemplate.recommendedSettings.subjectOValue ) {
                    $params.Body.csrAttributes.organization = $thisTemplate.recommendedSettings.subjectOValue
                }

                if ( $PSBoundParameters.ContainsKey('OrganizationalUnit') ) {
                    $params.Body.csrAttributes.organizationalUnits = @($OrganizationalUnit)
                }
                elseif ( $thisTemplate.recommendedSettings.subjectOUValue ) {
                    $params.Body.csrAttributes.organizationalUnits = $thisTemplate.recommendedSettings.subjectOUValue
                }

                if ( $PSBoundParameters.ContainsKey('City') ) {
                    $params.Body.csrAttributes.locality = $City
                }
                elseif ( $thisTemplate.recommendedSettings.subjectLValue ) {
                    $params.Body.csrAttributes.locality = $thisTemplate.recommendedSettings.subjectLValue
                }

                if ( $PSBoundParameters.ContainsKey('State') ) {
                    $params.Body.csrAttributes.state = $State
                }
                elseif ( $thisTemplate.recommendedSettings.subjectSTValue ) {
                    $params.Body.csrAttributes.state = $thisTemplate.recommendedSettings.subjectSTValue
                }

                if ( $PSBoundParameters.ContainsKey('Country') ) {
                    $params.Body.csrAttributes.country = $Country
                }
                elseif ( $thisTemplate.recommendedSettings.subjectCValue ) {
                    $params.Body.csrAttributes.country = $thisTemplate.recommendedSettings.subjectCValue
                }

                if ( $KeySize ) {
                    $params.Body.csrAttributes.keyTypeParameters = @{
                        keyType   = 'RSA'
                        keyLength = $KeySize
                    }
                }
                elseif ( $thisTemplate.recommendedSettings.key.type -eq 'RSA' ) {
                    $params.Body.csrAttributes.keyTypeParameters = @{
                        keyType   = 'RSA'
                        keyLength = $thisTemplate.recommendedSettings.key.length
                    }
                }

                if ( $KeyCurve ) {
                    $params.Body.csrAttributes.keyTypeParameters = @{
                        keyType  = 'EC'
                        keyCurve = $KeyCurve
                    }
                }
                elseif ( $thisTemplate.recommendedSettings.key.type -eq 'EC' ) {
                    $params.Body.csrAttributes.keyTypeParameters = @{
                        keyType   = 'EC'
                        keyLength = $thisTemplate.recommendedSettings.key.curve
                    }
                }
            }

            'CSR' {
                $params.Body.certificateSigningRequest = $Csr
                $target = 'CSR'
            }

            'ExistingCSR' {
                $params.Body.reuseCSR = $true

                if ( Test-IsGuid($Certificate) ) {
                    $params.Body.existingCertificateId = $Certificate
                }
                else {
                    $findCerts = Find-VcCertificate -Name $Certificate -VersionType CURRENT -Status ACTIVE
                    if ( $findCerts ) {
                        $c = @($findCerts).Count
                        if ($c -gt 1) {
                            throw [System.Management.Automation.InvalidOperationException]::new("Expected only one Active and Current certificate, but found $c")
                        }
                        # we only found 1 cert
                        $params.Body.existingCertificateId = $findCerts.certificateId
                    }
                    else {
                        throw [System.Management.Automation.ItemNotFoundException]::new("An Active and Current certificate named $Certificate could not be found")
                    }
                }

                $target = 'Existing CSR'
            }
        }

        # common fields between ASK and CSR

        if ( $SanDns -or $SanEmail -or $SanIP -or $SanUri ) {
            $params.Body.csrAttributes.subjectAlternativeNamesByType = @{}
        }

        if ( $PSBoundParameters.ContainsKey('SanDns') ) {
            $params.Body.csrAttributes.subjectAlternativeNamesByType.dnsNames = @($SanDns)
        }

        if ( $PSBoundParameters.ContainsKey('SanEmail') ) {
            $params.Body.csrAttributes.subjectAlternativeNamesByType.rfc822Names = @($SanEmail)
        }

        if ( $PSBoundParameters.ContainsKey('SanIP') ) {
            $params.Body.csrAttributes.subjectAlternativeNamesByType.ipAddresses = @($SanIP)
        }

        if ( $PSBoundParameters.ContainsKey('SanUri') ) {
            $params.Body.csrAttributes.subjectAlternativeNamesByType.uniformResourceIdentifiers = @($SanUri)
        }

        if ($PSBoundParameters.ContainsKey('Tag')) {
            $params.Body.tags = @($Tag)
        }

        if ( $PSCmdlet.ShouldProcess("$target", 'New certificate request') ) {

            try {
                $response = Invoke-VenafiRestMethod @params

                if ( $PassThru ) {
                    $certRequest = $response | Select-Object -ExpandProperty certificateRequests

                    if ( $certRequest.certificateIds ) {
                        $actualCert = Get-VcCertificate -CertificateId $certRequest.certificateIds[0]
                        $certRequest | Add-Member @{ 'certificate' = $actualCert }
                    }

                    $certRequest | Select-Object @{'n' = 'certificateRequestId'; 'e' = { $_.id } }, *, @{'n' = 'certificateId'; 'e' = { $_.certificateIds } } -ExcludeProperty id, certificateIds
                }
            }
            catch {
                Write-Error $_
                continue
            }
        }
    }
}


