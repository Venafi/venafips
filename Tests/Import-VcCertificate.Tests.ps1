BeforeAll {
    . $PSScriptRoot/ModuleCommonVc.ps1

    $testVsatId = '0bc771e1-7abe-4339-9fcd-93fffe9cba7f'
    $testEncKeyId = 'aaaa1111-bbbb-2222-cccc-333344445555'
    $testEncKey = 'dGVzdGVuY3J5cHRpb25rZXk='
    $testImportId = 'import-1234-5678-abcd'

    $mockVSat = [pscustomobject]@{
        vsatelliteId    = $testVsatId
        encryptionKeyId = $testEncKeyId
        encryptionKey   = $testEncKey
    }

    $mockImportResponse = [pscustomobject]@{
        id = $testImportId
    }

    $mockJobCompleted = [pscustomobject]@{
        status  = 'COMPLETED'
        results = @(
            [pscustomobject]@{
                fingerprint = 'AB:CD:EF:12:34:56'
                status      = 'IMPORTED'
                reason      = $null
            }
        )
    }

    $mockNoKeyImportResponse = [pscustomobject]@{
        certificateInformations = @(
            [pscustomobject]@{
                id          = '11111111-2222-3333-4444-555555555555'
                fingerprint = 'AB:CD:EF:12:34:56'
            }
        )
        statistics = [pscustomobject]@{
            totalCount   = 1
            successCount = 1
            failureCount = 0
        }
    }

    # minimal PKCS12 data (base64 placeholder)
    $testPkcs12Data = 'MIIBIjANBg=='

    # minimal PEM cert (no key)
    $testCertPem = @"
-----BEGIN CERTIFICATE-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA
-----END CERTIFICATE-----
"@
}

Describe 'Import-VcCertificate' -Tags 'Unit' {

    BeforeEach {
        Mock -CommandName 'Test-VenafiSession' -MockWith {} -ModuleName $ModuleName
        Mock -CommandName 'Initialize-PSSodium' -MockWith {} -ModuleName $ModuleName
        Mock -CommandName 'Get-VcData' -ParameterFilter { $Type -eq 'VSatellite' } -MockWith { $mockVSat } -ModuleName $ModuleName
        Mock -CommandName 'ConvertTo-SodiumEncryptedString' -MockWith { 'encrypted-password' } -ModuleName $ModuleName
        Mock -CommandName 'ConvertTo-PlaintextString' -MockWith { 'plaintext' } -ModuleName $ModuleName
    }

    Context 'PKCS12 import with key' {

        BeforeEach {
            Mock -CommandName 'Invoke-VenafiRestMethod' -ParameterFilter { $UriLeaf -eq 'certificates/imports' } -MockWith { $mockImportResponse } -ModuleName $ModuleName
            Mock -CommandName 'Invoke-VenafiRestMethod' -ParameterFilter { $UriLeaf -like 'certificates/imports/*' } -MockWith { $mockJobCompleted } -ModuleName $ModuleName
        }

        It 'Should call the keystore import endpoint' {
            Import-VcCertificate -Data $testPkcs12Data -PKCS12 -PrivateKeyPassword 'pass'
            Should -Invoke -CommandName 'Invoke-VenafiRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $UriLeaf -eq 'certificates/imports' -and $Method -eq 'POST'
            }
        }

        It 'Should include vSatellite info in the request body' {
            Import-VcCertificate -Data $testPkcs12Data -PKCS12 -PrivateKeyPassword 'pass'
            Should -Invoke -CommandName 'Invoke-VenafiRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.edgeInstanceId -eq $testVsatId -and $Body.encryptionKeyId -eq $testEncKeyId
            }
        }

        It 'Should return fingerprint and status' {
            $result = Import-VcCertificate -Data $testPkcs12Data -PKCS12 -PrivateKeyPassword 'pass'
            $result.fingerprint | Should -Be 'AB:CD:EF:12:34:56'
            $result.status | Should -Be 'IMPORTED'
        }
    }

    Context 'Certificate import without key' {

        BeforeEach {
            Mock -CommandName 'Invoke-VenafiRestMethod' -ParameterFilter { $UriLeaf -eq 'certificates' -and $Method -eq 'POST' } -MockWith { $mockNoKeyImportResponse } -ModuleName $ModuleName
            Mock -CommandName 'Split-CertificateData' -MockWith {
                @{ CertPem = 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA'; KeyPem = $null }
            } -ModuleName $ModuleName
        }

        It 'Should call the no-key import endpoint' {
            Import-VcCertificate -Data $testCertPem -Format 'X509'
            Should -Invoke -CommandName 'Invoke-VenafiRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $UriLeaf -eq 'certificates' -and $UriRoot -eq 'outagedetection/v1'
            }
        }

        It 'Should include overrideBlocklist in the body' {
            Import-VcCertificate -Data $testCertPem -Format 'X509'
            Should -Invoke -CommandName 'Invoke-VenafiRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $null -ne $Body.overrideBlocklist
            }
        }

        It 'Should return certificate info and statistics' {
            $result = Import-VcCertificate -Data $testCertPem -Format 'X509'
            $result.statistics | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Error handling' {

        It 'Should throw when no active VSatellites found' {
            Mock -CommandName 'Get-VcData' -ParameterFilter { $Type -eq 'VSatellite' } -MockWith { $null } -ModuleName $ModuleName
            { Import-VcCertificate -Data $testPkcs12Data -PKCS12 -PrivateKeyPassword 'pass' } | Should -Throw '*VSatellite*'
        }

        It 'Should throw when importing with key but no password' {
            Mock -CommandName 'Invoke-VenafiRestMethod' -MockWith { $mockImportResponse } -ModuleName $ModuleName
            Mock -CommandName 'Split-CertificateData' -MockWith {
                @{ CertPem = 'certdata'; KeyPem = 'keydata' }
            } -ModuleName $ModuleName
            { Import-VcCertificate -Data $testCertPem -Format 'PKCS8' } | Should -Throw '*PrivateKeyPassword*'
        }
    }

    Context 'Format parameter' {

        BeforeEach {
            Mock -CommandName 'Invoke-VenafiRestMethod' -ParameterFilter { $UriLeaf -eq 'certificates/imports' } -MockWith { $mockImportResponse } -ModuleName $ModuleName
            Mock -CommandName 'Invoke-VenafiRestMethod' -ParameterFilter { $UriLeaf -like 'certificates/imports/*' } -MockWith { $mockJobCompleted } -ModuleName $ModuleName
        }

        It 'Should accept PKCS12 format' {
            Import-VcCertificate -Data $testPkcs12Data -Format 'PKCS12' -PrivateKeyPassword 'pass'
            Should -Invoke -CommandName 'Invoke-VenafiRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $UriLeaf -eq 'certificates/imports'
            }
        }

        It 'Should warn about deprecated PKCS12 switch' {
            Import-VcCertificate -Data $testPkcs12Data -PKCS12 -PrivateKeyPassword 'pass' -WarningVariable warn -WarningAction SilentlyContinue
            $warn | Should -Not -BeNullOrEmpty
        }
    }
}
