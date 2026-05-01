BeforeAll {
    . $PSScriptRoot/ModuleCommonTrust.ps1

    $testCertId = '3699b03e-ff62-4772-960d-82e53c34bf60'
    $testCertId2 = '4699b03e-ff62-4772-960d-82e53c34bf61'
    $testAppId = '10f71a12-daf3-4737-b589-6a9dd1cc5a97'
    $testTemplateId = '2e4a0355-70bf-4ffc-919f-fcfcd4d15e84'
    $testCertRequestId = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    $newCertId = '99999999-2222-3333-4444-555555555555'

    $mockCert = [pscustomobject]@{
        certificateId                  = $testCertId
        certificateName                = 'test.example.com'
        fingerprint                    = 'AB:CD:EF:12:34:56:78:90'
        versionType                    = 'CURRENT'
        subjectCN                      = @('test.example.com')
        subjectO                       = 'TestOrg'
        subjectOU                      = @('TestOU')
        subjectL                       = 'TestCity'
        subjectST                      = 'TestState'
        subjectC                       = 'US'
        subjectAlternativeNamesByType  = @{
            dNSName                    = @('test.example.com', 'www.test.example.com')
            iPAddress                  = @()
            rfc822Name                 = @()
            uniformResourceIdentifier  = @()
        }
        certificateRequestId           = $testCertRequestId
        application                    = @(
            [pscustomobject]@{
                applicationId = $testAppId
                name          = 'TestApp'
            }
        )
    }

    $mockCertOldVersion = [pscustomobject]@{
        certificateId = $testCertId
        versionType   = 'OLD'
    }

    $mockCertMultipleCN = [pscustomobject]@{
        certificateId        = $testCertId
        versionType          = 'CURRENT'
        subjectCN            = @('cn1.example.com', 'cn2.example.com')
        certificateRequestId = $testCertRequestId
        application          = @([pscustomobject]@{ applicationId = $testAppId; name = 'TestApp' })
    }

    $mockApp = [pscustomobject]@{
        applicationId   = $testAppId
        name            = 'TestApp'
        issuingTemplate = @(
            [pscustomobject]@{
                name              = 'MSCA - 1 year'
                issuingTemplateId = $testTemplateId
            }
        )
    }

    $mockCertRequest = [pscustomobject]@{
        id                           = $testCertRequestId
        applicationId                = $testAppId
        certificateIssuingTemplateId = $testTemplateId
        status                       = 'ISSUED'
    }

    $mockRenewResponse = [pscustomobject]@{
        certificateRequests = @([pscustomobject]@{
                id             = $testCertRequestId
                status         = 'ISSUED'
                certificateIds = @($newCertId)
            })
    }

    $mockRetireResponse = [pscustomobject]@{
        certificates = @([pscustomobject]@{ id = $testCertId })
    }

    $mockRecoverResponse = [pscustomobject]@{
        certificates = @([pscustomobject]@{ id = $testCertId })
    }
}

Describe 'Invoke-TrustCertificateAction' -Tags 'Unit' {

    BeforeEach {
        Mock -CommandName 'Invoke-TrustRestMethod' -MockWith {} -ModuleName $ModuleName
        Mock -CommandName 'Get-TrustCertificate' -MockWith { $mockCert } -ModuleName $ModuleName
        Mock -CommandName 'Get-TrustData' -MockWith { $testAppId } -ModuleName $ModuleName
        Mock -CommandName 'Get-TrustData' -ParameterFilter { $Type -eq 'Application' -and $Object } -MockWith { $mockApp } -ModuleName $ModuleName
        Mock -CommandName 'Get-TrustData' -ParameterFilter { $Type -eq 'Certificate' } -MockWith { $testCertId } -ModuleName $ModuleName
        Mock -CommandName 'Get-TrustData' -ParameterFilter { $Type -eq 'IssuingTemplate' } -MockWith { $testTemplateId } -ModuleName $ModuleName
        Mock -CommandName 'Get-TrustData' -ParameterFilter { $Type -eq 'CloudKeystore' } -MockWith { 'ks-id-123' } -ModuleName $ModuleName
        Mock -CommandName 'Select-TrustBatch' -MockWith { , $InputObject } -ModuleName $ModuleName
        Mock -CommandName 'Invoke-TrustGraphQL' -MockWith {} -ModuleName $ModuleName
    }

    Context 'Retire' {

        BeforeEach {
            Mock -CommandName 'Invoke-TrustRestMethod' -MockWith { $mockRetireResponse } -ModuleName $ModuleName
        }

        It 'Should call the retirement API' {
            Invoke-TrustCertificateAction -ID $testCertId -Retire -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $UriLeaf -eq 'certificates/retirement' -and $Method -eq 'Post'
            }
        }

        It 'Should return success status' {
            $result = Invoke-TrustCertificateAction -ID $testCertId -Retire -Confirm:$false
            $result.CertificateID | Should -Be $testCertId
            $result.Success | Should -BeTrue
        }

        It 'Should support pipeline input' {
            $result = [guid]$testCertId | Invoke-TrustCertificateAction -Retire -Confirm:$false
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should batch multiple certificates' {
            $ids = @([guid]$testCertId, [guid]$testCertId2)
            $ids | Invoke-TrustCertificateAction -Retire -BatchSize 1 -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -ModuleName $ModuleName
        }
    }

    Context 'Recover' {

        BeforeEach {
            Mock -CommandName 'Invoke-TrustRestMethod' -MockWith { $mockRecoverResponse } -ModuleName $ModuleName
        }

        It 'Should call the recovery API' {
            Invoke-TrustCertificateAction -ID $testCertId -Recover -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $UriLeaf -eq 'certificates/recovery'
            }
        }
    }

    Context 'Renew' {

        BeforeEach {
            Mock -CommandName 'Invoke-TrustRestMethod' -ParameterFilter { $UriLeaf -eq 'certificaterequests' } -MockWith { $mockRenewResponse } -ModuleName $ModuleName
            Mock -CommandName 'Invoke-TrustRestMethod' -ParameterFilter { $UriLeaf -like 'certificaterequests/*' } -MockWith { $mockCertRequest } -ModuleName $ModuleName
        }

        It 'Should call the certificate request API' {
            Invoke-TrustCertificateAction -ID $testCertId -Renew -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $UriLeaf -eq 'certificaterequests' -and $Method -eq 'Post'
            }
        }

        It 'Should return renewal details on success' {
            $result = Invoke-TrustCertificateAction -ID $testCertId -Renew -Confirm:$false
            $result.oldCertificateId | Should -Be $testCertId
            $result.success | Should -BeTrue
            $result.certificateID | Should -Be $newCertId
        }

        It 'Should include CSR attributes in request body' {
            Invoke-TrustCertificateAction -ID $testCertId -Renew -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.csrAttributes.commonName -eq 'test.example.com' -and
                $Body.csrAttributes.organization -eq 'TestOrg' -and
                $Body.isVaaSGenerated -eq $true
            }
        }

        It 'Should fail for non-CURRENT certificates' {
            Mock -CommandName 'Get-TrustCertificate' -MockWith { $mockCertOldVersion } -ModuleName $ModuleName
            $result = Invoke-TrustCertificateAction -ID $testCertId -Renew -Confirm:$false
            $result.success | Should -BeFalse
            $result.error | Should -BeLike '*CURRENT*'
        }

        It 'Should fail with multiple CNs without Force' {
            Mock -CommandName 'Get-TrustCertificate' -MockWith { $mockCertMultipleCN } -ModuleName $ModuleName
            $result = Invoke-TrustCertificateAction -ID $testCertId -Renew -Confirm:$false
            $result.success | Should -BeFalse
            $result.error | Should -BeLike '*more than 1*'
        }

        It 'Should succeed with multiple CNs when Force is used' {
            Mock -CommandName 'Get-TrustCertificate' -MockWith { $mockCertMultipleCN } -ModuleName $ModuleName
            $result = Invoke-TrustCertificateAction -ID $testCertId -Renew -Force -Confirm:$false
            $result.success | Should -BeTrue
        }

        It 'Should use provided Application parameter' {
            Invoke-TrustCertificateAction -ID $testCertId -Renew -Application $testAppId -Confirm:$false
            Should -Invoke -CommandName 'Get-TrustData' -ModuleName $ModuleName -ParameterFilter {
                $Type -eq 'Application' -and $Object -eq $true
            }
        }

        It 'Should use provided IssuingTemplate parameter' {
            Invoke-TrustCertificateAction -ID $testCertId -Renew -IssuingTemplate $testTemplateId -Confirm:$false
            Should -Invoke -CommandName 'Get-TrustData' -ModuleName $ModuleName -ParameterFilter {
                $Type -eq 'IssuingTemplate'
            }
        }

        It 'Should merge AdditionalParameters into renewal body' {
            Invoke-TrustCertificateAction -ID $testCertId -Renew -AdditionalParameters @{ validityPeriod = 'P365D' } -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.validityPeriod -eq 'P365D'
            }
        }
    }

    Context 'Revoke' {

        It 'Should call GraphQL revoke mutation' {
            Invoke-TrustCertificateAction -ID $testCertId -Revoke -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustGraphQL' -Times 1 -ModuleName $ModuleName
        }

        It 'Should use default reason UNSPECIFIED' {
            Invoke-TrustCertificateAction -ID $testCertId -Revoke -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustGraphQL' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Variables.revocationReason -eq 'UNSPECIFIED'
            }
        }

        It 'Should accept a custom reason' {
            Invoke-TrustCertificateAction -ID $testCertId -Revoke -Reason KEY_COMPROMISE -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustGraphQL' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Variables.revocationReason -eq 'KEY_COMPROMISE'
            }
        }

        It 'Should accept a custom comment' {
            Invoke-TrustCertificateAction -ID $testCertId -Revoke -Comment 'test revoke' -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustGraphQL' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Variables.revocationComment -eq 'test revoke'
            }
        }

        It 'Should return success on revoke' {
            $result = Invoke-TrustCertificateAction -ID $testCertId -Revoke -Confirm:$false
            $result.success | Should -BeTrue
            $result.CertificateId | Should -Be $testCertId
        }

        It 'Should return error on failure' {
            Mock -CommandName 'Invoke-TrustGraphQL' -MockWith { throw 'Revoke failed' } -ModuleName $ModuleName
            $result = Invoke-TrustCertificateAction -ID $testCertId -Revoke -Confirm:$false
            $result.success | Should -BeFalse
            $result.error | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Validate' {

        It 'Should call the validation API' {
            Invoke-TrustCertificateAction -ID $testCertId -Validate -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $UriLeaf -eq 'certificates/validation'
            }
        }
    }

    Context 'Delete' {

        BeforeEach {
            Mock -CommandName 'Invoke-TrustCertificateAction' -MockWith {} -ModuleName $ModuleName
        }

        It 'Should call the deletion API' {
            Invoke-TrustCertificateAction -ID $testCertId -Delete -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -ModuleName $ModuleName -ParameterFilter {
                $UriLeaf -eq 'certificates/deletion'
            }
        }
    }

    Context 'Provision' {

        BeforeEach {
            Mock -CommandName 'Find-TrustMachineIdentity' -MockWith {
                [pscustomobject]@{ machineIdentityId = 'mi-123' }
            } -ModuleName $ModuleName
            Mock -CommandName 'Invoke-TrustWorkflow' -MockWith {} -ModuleName $ModuleName
        }

        It 'Should find machine identities and invoke workflow' {
            Invoke-TrustCertificateAction -ID $testCertId -Provision -Confirm:$false
            Should -Invoke -CommandName 'Find-TrustMachineIdentity' -Times 1 -ModuleName $ModuleName
            Should -Invoke -CommandName 'Invoke-TrustWorkflow' -Times 1 -ModuleName $ModuleName
        }

        It 'Should throw when no machine identities found' {
            Mock -CommandName 'Find-TrustMachineIdentity' -MockWith {} -ModuleName $ModuleName
            { Invoke-TrustCertificateAction -ID $testCertId -Provision -Confirm:$false } | Should -Throw '*No machine identities*'
        }
    }

    Context 'Provision to CloudKeystore' {

        It 'Should call GraphQL provision mutation' {
            Invoke-TrustCertificateAction -ID $testCertId -Provision -CloudKeystore 'my-keystore' -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustGraphQL' -Times 1 -ModuleName $ModuleName
        }

        It 'Should return success' {
            $result = Invoke-TrustCertificateAction -ID $testCertId -Provision -CloudKeystore 'my-keystore' -Confirm:$false
            $result.success | Should -BeTrue
            $result.certificateId | Should -Be $testCertId
        }
    }
}
