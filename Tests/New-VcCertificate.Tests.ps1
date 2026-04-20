BeforeAll {
    . $PSScriptRoot/ModuleCommonVc.ps1

    $appId = 'ff23962b-661c-4a83-964b-d86855f1bb93'
    $templateId = '2e4a0355-70bf-4ffc-919f-fcfcd4d15e84'
    $certRequestId = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    $certId = '11111111-2222-3333-4444-555555555555'

    $mockApp = [pscustomobject]@{
        applicationId   = $appId
        name            = 'MyApp'
        issuingTemplate = @(
            [pscustomobject]@{
                name              = 'MSCA - 1 year'
                issuingTemplateId = $templateId
            }
        )
    }

    $mockTemplate = [pscustomobject]@{
        issuingTemplateId   = $templateId
        name                = 'MSCA - 1 year'
        product             = @{ validityPeriod = 'P365D' }
        recommendedSettings = @{
            subjectOValue  = 'DefaultOrg'
            subjectOUValue = 'DefaultOU'
            subjectLValue  = 'DefaultCity'
            subjectSTValue = 'DefaultState'
            subjectCValue  = 'US'
            key            = @{
                type   = 'RSA'
                length = 2048
            }
        }
    }

    $mockCertRequestResponse = [pscustomobject]@{
        certificateRequests = [pscustomobject]@{
            id             = $certRequestId
            status         = 'REQUESTED'
            certificateIds = @()
        }
    }

    $mockCertRequestIssuedResponse = [pscustomobject]@{
        certificateRequests = [pscustomobject]@{
            id             = $certRequestId
            status         = 'ISSUED'
            certificateIds = @($certId)
        }
    }

    $mockCertificate = [pscustomobject]@{
        certificateId = $certId
        commonName    = 'app.mycert.com'
        status        = 'ACTIVE'
    }
}

Describe "New-VcCertificate" -Tags 'Unit' {

    BeforeEach {
        Mock -CommandName 'Test-TrustClient' -MockWith {} -ModuleName $ModuleName
        Mock -CommandName 'Get-VcData' -ParameterFilter { $Type -eq 'Application' } -MockWith { $mockApp } -ModuleName $ModuleName
        Mock -CommandName 'Get-VcData' -ParameterFilter { $Type -eq 'IssuingTemplate' } -MockWith { $mockTemplate } -ModuleName $ModuleName
        Mock -CommandName 'Invoke-TrustRestMethod' -MockWith { $mockCertRequestResponse } -ModuleName $ModuleName
    }

    Context "Basic certificate request with ASK" {

        It "Should call the certificate request API" {
            New-VcCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com' -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Method -eq 'Post' -and $UriLeaf -eq 'certificaterequests'
            }
        }

        It "Should not return output without PassThru" {
            $result = New-VcCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com' -Confirm:$false
            $result | Should -BeNullOrEmpty
        }

        It "Should set isVaaSGenerated to true for ASK" {
            New-VcCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com' -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.isVaaSGenerated -eq $true
            }
        }

        It "Should include common name in csrAttributes" {
            New-VcCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com' -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.csrAttributes.commonName -eq 'app.mycert.com'
            }
        }
    }

    Context "CSR parameter set" {

        It "Should set isVaaSGenerated to false for CSR" {
            $csr = "-----BEGIN CERTIFICATE REQUEST-----`nMIICYzCCAUsCAQAwHj`n-----END CERTIFICATE REQUEST-----"
            New-VcCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -Csr $csr -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.isVaaSGenerated -eq $false -and $Body.certificateSigningRequest -eq $csr
            }
        }
    }

    Context "Optional subject fields" {

        It "Should include Organization when provided" {
            New-VcCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com' -Organization 'MyOrg' -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.csrAttributes.organization -eq 'MyOrg'
            }
        }

        It "Should use template default for Organization when not provided" {
            New-VcCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com' -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.csrAttributes.organization -eq 'DefaultOrg'
            }
        }

        It "Should include OrganizationalUnit when provided" {
            New-VcCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com' -OrganizationalUnit 'IT', 'Dev' -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.csrAttributes.organizationalUnits.Count -eq 2
            }
        }

        It "Should include City when provided" {
            New-VcCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com' -City 'Newton' -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.csrAttributes.locality -eq 'Newton'
            }
        }

        It "Should include State when provided" {
            New-VcCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com' -State 'MA' -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.csrAttributes.state -eq 'MA'
            }
        }

        It "Should include Country when provided" {
            New-VcCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com' -Country 'US' -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.csrAttributes.country -eq 'US'
            }
        }
    }

    Context "Key parameters" {

        It "Should set RSA key type when KeySize provided" {
            New-VcCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com' -KeySize 4096 -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.csrAttributes.keyTypeParameters.keyType -eq 'RSA' -and
                $Body.csrAttributes.keyTypeParameters.keyLength -eq 4096
            }
        }

        It "Should set EC key type when KeyCurve provided" {
            New-VcCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com' -KeyCurve 'P256' -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.csrAttributes.keyTypeParameters.keyType -eq 'EC' -and
                $Body.csrAttributes.keyTypeParameters.keyCurve -eq 'P256'
            }
        }
    }

    Context "SAN entries" {

        It "Should include DNS SANs" {
            New-VcCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com' -SanDns 'www.mycert.com', 'api.mycert.com' -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.csrAttributes.subjectAlternativeNamesByType.dnsNames.Count -eq 2
            }
        }

        It "Should include IP SANs" {
            New-VcCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com' -SanIP '1.2.3.4' -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.csrAttributes.subjectAlternativeNamesByType.ipAddresses[0] -eq '1.2.3.4'
            }
        }

        It "Should include URI SANs" {
            New-VcCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com' -SanUri 'https://app.mycert.com' -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.csrAttributes.subjectAlternativeNamesByType.uniformResourceIdentifiers[0] -eq 'https://app.mycert.com'
            }
        }

        It "Should include Email SANs" {
            New-VcCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com' -SanEmail 'admin@mycert.com' -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.csrAttributes.subjectAlternativeNamesByType.rfc822Names[0] -eq 'admin@mycert.com'
            }
        }
    }

    Context "Tags" {

        It "Should include tags when provided" {
            New-VcCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com' -Tag 'env:prod', 'team:infra' -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.tags.Count -eq 2
            }
        }
    }

    Context "Application with single template" {

        It "Should auto-select the only template when IssuingTemplate is not provided" {
            New-VcCertificate -Application 'MyApp' -CommonName 'app.mycert.com' -Confirm:$false
            Should -Invoke -CommandName 'Get-VcData' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Type -eq 'IssuingTemplate' -and $InputObject -eq $templateId
            }
        }
    }

    Context "Application with multiple templates" {

        It "Should throw when IssuingTemplate is not provided and app has multiple templates" {
            Mock -CommandName 'Get-VcData' -ParameterFilter { $Type -eq 'Application' } -MockWith {
                [pscustomobject]@{
                    applicationId   = $appId
                    name            = 'MyApp'
                    issuingTemplate = @(
                        [pscustomobject]@{ name = 'Template1'; issuingTemplateId = 'id1' },
                        [pscustomobject]@{ name = 'Template2'; issuingTemplateId = 'id2' }
                    )
                }
            } -ModuleName $ModuleName

            { New-VcCertificate -Application 'MyApp' -CommonName 'app.mycert.com' -Confirm:$false } | Should -Throw '*IssuingTemplate is required*'
        }
    }

    Context "Application with no templates" {

        It "Should throw when application has no templates" {
            Mock -CommandName 'Get-VcData' -ParameterFilter { $Type -eq 'Application' } -MockWith {
                [pscustomobject]@{
                    applicationId   = $appId
                    name            = 'MyApp'
                    issuingTemplate = @()
                }
            } -ModuleName $ModuleName

            { New-VcCertificate -Application 'MyApp' -CommonName 'app.mycert.com' -Confirm:$false } | Should -Throw '*No templates associated*'
        }
    }

    Context "Template name as alias" {

        It "Should resolve template by alias name from application" {
            New-VcCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com' -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName
        }
    }

    Context "PassThru" {

        It "Should return certificate request details with PassThru" {
            $result = New-VcCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com' -PassThru -Confirm:$false
            $result | Should -Not -BeNullOrEmpty
            $result.certificateRequestId | Should -Be $certRequestId
        }

        It "Should include certificate when certificateIds is present" {
            Mock -CommandName 'Invoke-TrustRestMethod' -MockWith { $mockCertRequestIssuedResponse } -ModuleName $ModuleName
            Mock -CommandName 'Get-VcCertificate' -MockWith { $mockCertificate } -ModuleName $ModuleName

            $result = New-VcCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com' -PassThru -Confirm:$false
            $result.certificate | Should -Not -BeNullOrEmpty
            $result.certificate.certificateId | Should -Be $certId
        }

        It "Should not include certificate when certificateIds is empty" {
            $result = New-VcCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com' -PassThru -Confirm:$false
            $result.certificate | Should -BeNullOrEmpty
        }
    }

    Context "Wait - terminal status immediately" {

        It "Should not poll when initial status is ISSUED" {
            Mock -CommandName 'Invoke-TrustRestMethod' -MockWith { $mockCertRequestIssuedResponse } -ModuleName $ModuleName
            Mock -CommandName 'Get-VcCertificateRequest' -ModuleName $ModuleName

            New-VcCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com' -Wait -Confirm:$false
            Should -Invoke -CommandName 'Get-VcCertificateRequest' -Times 0 -ModuleName $ModuleName
        }

        It "Should not poll when initial status is FAILED" {
            Mock -CommandName 'Invoke-TrustRestMethod' -MockWith {
                [pscustomobject]@{
                    certificateRequests = [pscustomobject]@{
                        id     = $certRequestId
                        status = 'FAILED'
                    }
                }
            } -ModuleName $ModuleName
            Mock -CommandName 'Get-VcCertificateRequest' -ModuleName $ModuleName

            New-VcCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com' -Wait -Confirm:$false
            Should -Invoke -CommandName 'Get-VcCertificateRequest' -Times 0 -ModuleName $ModuleName
        }

        It "Should not poll when initial status is REJECTED" {
            Mock -CommandName 'Invoke-TrustRestMethod' -MockWith {
                [pscustomobject]@{
                    certificateRequests = [pscustomobject]@{
                        id     = $certRequestId
                        status = 'REJECTED'
                    }
                }
            } -ModuleName $ModuleName
            Mock -CommandName 'Get-VcCertificateRequest' -ModuleName $ModuleName

            New-VcCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com' -Wait -Confirm:$false
            Should -Invoke -CommandName 'Get-VcCertificateRequest' -Times 0 -ModuleName $ModuleName
        }

        It "Should not poll when initial status is CANCELLED" {
            Mock -CommandName 'Invoke-TrustRestMethod' -MockWith {
                [pscustomobject]@{
                    certificateRequests = [pscustomobject]@{
                        id     = $certRequestId
                        status = 'CANCELLED'
                    }
                }
            } -ModuleName $ModuleName
            Mock -CommandName 'Get-VcCertificateRequest' -ModuleName $ModuleName

            New-VcCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com' -Wait -Confirm:$false
            Should -Invoke -CommandName 'Get-VcCertificateRequest' -Times 0 -ModuleName $ModuleName
        }

        It "Should not poll when initial status is REVOKED" {
            Mock -CommandName 'Invoke-TrustRestMethod' -MockWith {
                [pscustomobject]@{
                    certificateRequests = [pscustomobject]@{
                        id     = $certRequestId
                        status = 'REVOKED'
                    }
                }
            } -ModuleName $ModuleName
            Mock -CommandName 'Get-VcCertificateRequest' -ModuleName $ModuleName

            New-VcCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com' -Wait -Confirm:$false
            Should -Invoke -CommandName 'Get-VcCertificateRequest' -Times 0 -ModuleName $ModuleName
        }

        It "Should not poll when initial status is DELETED" {
            Mock -CommandName 'Invoke-TrustRestMethod' -MockWith {
                [pscustomobject]@{
                    certificateRequests = [pscustomobject]@{
                        id     = $certRequestId
                        status = 'DELETED'
                    }
                }
            } -ModuleName $ModuleName
            Mock -CommandName 'Get-VcCertificateRequest' -ModuleName $ModuleName

            New-VcCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com' -Wait -Confirm:$false
            Should -Invoke -CommandName 'Get-VcCertificateRequest' -Times 0 -ModuleName $ModuleName
        }

        It "Should not poll when initial status is REJECTED_APPROVAL" {
            Mock -CommandName 'Invoke-TrustRestMethod' -MockWith {
                [pscustomobject]@{
                    certificateRequests = [pscustomobject]@{
                        id     = $certRequestId
                        status = 'REJECTED_APPROVAL'
                    }
                }
            } -ModuleName $ModuleName
            Mock -CommandName 'Get-VcCertificateRequest' -ModuleName $ModuleName

            New-VcCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com' -Wait -Confirm:$false
            Should -Invoke -CommandName 'Get-VcCertificateRequest' -Times 0 -ModuleName $ModuleName
        }
    }

    Context "Wait - polling non-terminal to terminal" {

        It "Should poll until status transitions from REQUESTED to ISSUED" {
            Mock -CommandName 'Get-VcCertificateRequest' -MockWith {
                [pscustomobject]@{
                    id             = $certRequestId
                    status         = 'ISSUED'
                    certificateIds = @($certId)
                }
            } -ModuleName $ModuleName

            New-VcCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com' -Wait -Confirm:$false
            Should -Invoke -CommandName 'Get-VcCertificateRequest' -Times 1 -ModuleName $ModuleName
        }

        It "Should poll until status transitions from NEW to ISSUED" {
            Mock -CommandName 'Invoke-TrustRestMethod' -MockWith {
                [pscustomobject]@{
                    certificateRequests = [pscustomobject]@{
                        id     = $certRequestId
                        status = 'NEW'
                    }
                }
            } -ModuleName $ModuleName

            Mock -CommandName 'Get-VcCertificateRequest' -MockWith {
                [pscustomobject]@{
                    id             = $certRequestId
                    status         = 'ISSUED'
                    certificateIds = @($certId)
                }
            } -ModuleName $ModuleName

            New-VcCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com' -Wait -Confirm:$false
            Should -Invoke -CommandName 'Get-VcCertificateRequest' -Times 1 -ModuleName $ModuleName
        }

        It "Should poll until status transitions from PENDING to FAILED" {
            Mock -CommandName 'Invoke-TrustRestMethod' -MockWith {
                [pscustomobject]@{
                    certificateRequests = [pscustomobject]@{
                        id     = $certRequestId
                        status = 'PENDING'
                    }
                }
            } -ModuleName $ModuleName

            Mock -CommandName 'Get-VcCertificateRequest' -MockWith {
                [pscustomobject]@{
                    id     = $certRequestId
                    status = 'FAILED'
                }
            } -ModuleName $ModuleName

            New-VcCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com' -Wait -Confirm:$false
            Should -Invoke -CommandName 'Get-VcCertificateRequest' -Times 1 -ModuleName $ModuleName
        }

        It "Should poll multiple times through PENDING_APPROVAL then PENDING_FINAL_APPROVAL before ISSUED" {
            $script:pollCount = 0
            Mock -CommandName 'Invoke-TrustRestMethod' -MockWith {
                [pscustomobject]@{
                    certificateRequests = [pscustomobject]@{
                        id     = $certRequestId
                        status = 'PENDING_APPROVAL'
                    }
                }
            } -ModuleName $ModuleName

            Mock -CommandName 'Get-VcCertificateRequest' -MockWith {
                $script:pollCount++
                if ($script:pollCount -eq 1) {
                    [pscustomobject]@{ id = $certRequestId; status = 'PENDING_FINAL_APPROVAL' }
                }
                else {
                    [pscustomobject]@{ id = $certRequestId; status = 'ISSUED'; certificateIds = @($certId) }
                }
            } -ModuleName $ModuleName

            New-VcCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com' -Wait -Confirm:$false
            Should -Invoke -CommandName 'Get-VcCertificateRequest' -Times 2 -ModuleName $ModuleName
        }
    }

    Context "Wait with PassThru" {

        It "Should return final polled state with certificate when Wait and PassThru are combined" {
            $script:pollCount = 0
            Mock -CommandName 'Invoke-TrustRestMethod' -MockWith {
                [pscustomobject]@{
                    certificateRequests = [pscustomobject]@{
                        id     = $certRequestId
                        status = 'REQUESTED'
                    }
                }
            } -ModuleName $ModuleName

            Mock -CommandName 'Get-VcCertificateRequest' -MockWith {
                [pscustomobject]@{
                    id             = $certRequestId
                    status         = 'ISSUED'
                    certificateIds = @($certId)
                }
            } -ModuleName $ModuleName

            Mock -CommandName 'Get-VcCertificate' -MockWith { $mockCertificate } -ModuleName $ModuleName

            $result = New-VcCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com' -Wait -PassThru -Confirm:$false
            $result | Should -Not -BeNullOrEmpty
            $result.certificate | Should -Not -BeNullOrEmpty
            $result.certificate.certificateId | Should -Be $certId
        }

        It "Should return final polled state without certificate when Wait ends in FAILED" {
            Mock -CommandName 'Invoke-TrustRestMethod' -MockWith {
                [pscustomobject]@{
                    certificateRequests = [pscustomobject]@{
                        id     = $certRequestId
                        status = 'REQUESTED'
                    }
                }
            } -ModuleName $ModuleName

            Mock -CommandName 'Get-VcCertificateRequest' -MockWith {
                [pscustomobject]@{
                    id     = $certRequestId
                    status = 'FAILED'
                }
            } -ModuleName $ModuleName

            $result = New-VcCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com' -Wait -PassThru -Confirm:$false
            $result | Should -Not -BeNullOrEmpty
            $result.certificate | Should -BeNullOrEmpty
        }
    }

    Context "Without Wait" {

        It "Should not call Get-VcCertificateRequest when Wait is not specified" {
            Mock -CommandName 'Get-VcCertificateRequest' -ModuleName $ModuleName
            New-VcCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com' -Confirm:$false
            Should -Invoke -CommandName 'Get-VcCertificateRequest' -Times 0 -ModuleName $ModuleName
        }
    }

    Context "API errors" {

        It "Should write error when API call fails" {
            Mock -CommandName 'Invoke-TrustRestMethod' -MockWith { throw 'API error' } -ModuleName $ModuleName
            New-VcCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com' -Confirm:$false -ErrorVariable err -ErrorAction SilentlyContinue
            $err | Should -Not -BeNullOrEmpty
        }
    }

    Context "ValidUntil" {

        It "Should set validity period from ValidUntil" {
            New-VcCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com' -ValidUntil (Get-Date).AddDays(90) -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.validityPeriod -match '^P\d+DT\d+H$'
            }
        }
    }
}
