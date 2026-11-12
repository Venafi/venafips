BeforeAll {
    . $PSScriptRoot/ModuleCommonTrust.ps1

    $testVsatId = '0bc771e1-7abe-4339-9fcd-93fffe9cba7f'
    $testEncKeyId = 'aaaa1111-bbbb-2222-cccc-333344445555'
    $testEncKey = 'dGVzdGVuY3J5cHRpb25rZXk='

    $mockVSat = [pscustomobject]@{
        vsatelliteId           = $testVsatId
        encryptionKeyId        = $testEncKeyId
        encryptionKey          = $testEncKey
        encryptionKeyAlgorithm = 'VSAT_HPKE'
        companyId              = 'e2d60b61-9a8c-4a3a-985c-92498bd1fc77'
    }

    $mockKeyImportResults = @(
        [pscustomobject]@{
            fingerprint = 'AB:CD:EF:12:34:56'
            status      = 'IMPORTED'
            reason      = $null
        }
    )

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

    # PKCS12 data (does NOT start with LS0 or -----BEGIN)
    $testPkcs12Data = 'MIIBIjANBg=='

    # PEM cert only (no key)
    $testCertPem = @"
-----BEGIN CERTIFICATE-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA
-----END CERTIFICATE-----
"@

    # PEM cert + encrypted private key
    $testCertAndKeyPem = @"
-----BEGIN CERTIFICATE-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA
-----END CERTIFICATE-----
-----BEGIN ENCRYPTED PRIVATE KEY-----
MIIFLjBYBgkqhkiG9w0BBQ0wSzAqBgkqhkiG9w0BBQww
-----END ENCRYPTED PRIVATE KEY-----
"@

    # base64-encode PEM strings (simulating Export-CmCertificate / Export-TrustCertificate output)
    $testCertPemBase64 = [System.Convert]::ToBase64String(
        [System.Text.Encoding]::ASCII.GetBytes($testCertPem)
    )
    $testCertAndKeyPemBase64 = [System.Convert]::ToBase64String(
        [System.Text.Encoding]::ASCII.GetBytes($testCertAndKeyPem)
    )
}

Describe 'Import-TrustCertificate' -Tags 'Unit' {

    BeforeEach {
        Mock -CommandName 'Get-TrustData' -ParameterFilter { $Type -eq 'VSatellite' } -MockWith { $mockVSat } -ModuleName $ModuleName
        Mock -CommandName 'ConvertTo-DekEncryptedString' -MockWith { 'encrypted-password' } -ModuleName $ModuleName
        Mock -CommandName 'ConvertTo-PlaintextString' -MockWith { 'plaintext' } -ModuleName $ModuleName
        Mock -CommandName 'Invoke-TrustParallel' -MockWith { $mockKeyImportResults } -ModuleName $ModuleName
    }

    Context 'PKCS12 auto-detection' {

        It 'Should detect PKCS12 data and import with key' {
            Import-TrustCertificate -Data $testPkcs12Data -PrivateKeyPassword 'pass'
            Should -Invoke -CommandName 'Invoke-TrustParallel' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $null -ne $TrustClient
            }
        }

        It 'Should return fingerprint and status' {
            $result = Import-TrustCertificate -Data $testPkcs12Data -PrivateKeyPassword 'pass'
            $result.fingerprint | Should -Be 'AB:CD:EF:12:34:56'
            $result.status | Should -Be 'IMPORTED'
        }
    }

    Context 'PEM auto-detection (base64-encoded)' {

        BeforeEach {
            Mock -CommandName 'Split-CertificateData' -MockWith {
                @{ CertPem = "-----BEGIN CERTIFICATE-----`nMIIBIj`n-----END CERTIFICATE-----"; KeyPem = "-----BEGIN ENCRYPTED PRIVATE KEY-----`nMIIFLj`n-----END ENCRYPTED PRIVATE KEY-----"; ChainPem = @() }
            } -ModuleName $ModuleName
        }

        It 'Should detect base64-encoded PEM (LS0 prefix) and call Split-CertificateData' {
            Import-TrustCertificate -Data $testCertAndKeyPemBase64 -PrivateKeyPassword 'pass'
            Should -Invoke -CommandName 'Split-CertificateData' -Times 1 -ModuleName $ModuleName
        }

        It 'Should add cert with key to keyed imports' {
            Import-TrustCertificate -Data $testCertAndKeyPemBase64 -PrivateKeyPassword 'pass'
            Should -Invoke -CommandName 'Invoke-TrustParallel' -Times 1 -ModuleName $ModuleName
        }
    }

    Context 'PEM auto-detection (raw PEM)' {

        BeforeEach {
            Mock -CommandName 'Split-CertificateData' -MockWith {
                @{ CertPem = "-----BEGIN CERTIFICATE-----`nMIIBIj`n-----END CERTIFICATE-----"; KeyPem = $null; ChainPem = @() }
            } -ModuleName $ModuleName
            Mock -CommandName 'Invoke-TrustParallel' -MockWith { $mockNoKeyImportResponse } -ModuleName $ModuleName
        }

        It 'Should detect raw PEM and call Split-CertificateData' {
            Import-TrustCertificate -Data $testCertPem
            Should -Invoke -CommandName 'Split-CertificateData' -Times 1 -ModuleName $ModuleName
        }

        It 'Should add cert without key to no-key imports' {
            $result = Import-TrustCertificate -Data $testCertPem
            $result.statistics | Should -Not -BeNullOrEmpty
        }
    }

    Context 'PrivateKeyPassword handling' {

        It 'Should convert PrivateKeyPassword in begin when passed directly' {
            Import-TrustCertificate -Data $testPkcs12Data -PrivateKeyPassword 'pass'
            Should -Invoke -CommandName 'ConvertTo-PlaintextString' -ModuleName $ModuleName
        }

        It 'Should accept SecureString for PrivateKeyPassword' {
            $secPass = 'pass' | ConvertTo-SecureString -AsPlainText -Force
            Import-TrustCertificate -Data $testPkcs12Data -PrivateKeyPassword $secPass
            Should -Invoke -CommandName 'ConvertTo-PlaintextString' -ModuleName $ModuleName
        }

        It 'Should accept PSCredential for PrivateKeyPassword' {
            $cred = New-Object PSCredential('user', ('pass' | ConvertTo-SecureString -AsPlainText -Force))
            Import-TrustCertificate -Data $testPkcs12Data -PrivateKeyPassword $cred
            Should -Invoke -CommandName 'ConvertTo-PlaintextString' -ModuleName $ModuleName
        }

        It 'Should accept PrivateKeyPassword via pipeline' {
            [pscustomobject]@{ Data = $testPkcs12Data; PrivateKeyPassword = 'pipelinePass' } | Import-TrustCertificate
            Should -Invoke -CommandName 'ConvertTo-PlaintextString' -ModuleName $ModuleName
        }
    }

    Context 'Error handling' {

        It 'Should throw when no active VSatellites found' {
            Mock -CommandName 'Get-TrustData' -ParameterFilter { $Type -eq 'VSatellite' } -MockWith { $null } -ModuleName $ModuleName
            { Import-TrustCertificate -Data $testPkcs12Data -PrivateKeyPassword 'pass' } | Should -Throw '*VSatellite*'
        }

        It 'Should throw when importing with key but no password' {
            Mock -CommandName 'Split-CertificateData' -MockWith {
                @{ CertPem = 'certdata'; KeyPem = 'keydata'; ChainPem = @() }
            } -ModuleName $ModuleName
            { Import-TrustCertificate -Data $testCertAndKeyPemBase64 } | Should -Throw '*PrivateKeyPassword*'
        }
    }

    Context 'TrustClient and ThrottleLimit' {

        It 'Should pass TrustClient to Invoke-TrustParallel' {
            Import-TrustCertificate -Data $testPkcs12Data -PrivateKeyPassword 'pass'
            Should -Invoke -CommandName 'Invoke-TrustParallel' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $null -ne $TrustClient
            }
        }

        It 'Should default ThrottleLimit to 1' {
            Import-TrustCertificate -Data $testPkcs12Data -PrivateKeyPassword 'pass'
            Should -Invoke -CommandName 'Invoke-TrustParallel' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $ThrottleLimit -eq 1
            }
        }
    }

    Context 'Pipeline input' {

        It 'Should accept Data via pipeline' {
            [pscustomobject]@{ Data = $testPkcs12Data; PrivateKeyPassword = 'pass' } | Import-TrustCertificate
            Should -Invoke -CommandName 'Invoke-TrustParallel' -Times 1 -ModuleName $ModuleName
        }

        It 'Should accept multiple objects via pipeline' {
            @(
                [pscustomobject]@{ Data = $testPkcs12Data; PrivateKeyPassword = 'pass' }
                [pscustomobject]@{ Data = $testPkcs12Data; PrivateKeyPassword = 'pass' }
            ) | Import-TrustCertificate
            Should -Invoke -CommandName 'Invoke-TrustParallel' -Times 1 -ModuleName $ModuleName
        }

        It 'Should accept CertificateData alias via pipeline' {
            [pscustomobject]@{ certificateData = $testPkcs12Data; PrivateKeyPassword = 'pass' } | Import-TrustCertificate
            Should -Invoke -CommandName 'Invoke-TrustParallel' -Times 1 -ModuleName $ModuleName
        }
    }

    Context 'Format parameter (legacy compatibility)' {

        It 'Should accept Format parameter without error' {
            Import-TrustCertificate -Data $testPkcs12Data -Format 'PKCS12' -PrivateKeyPassword 'pass'
            Should -Invoke -CommandName 'Invoke-TrustParallel' -Times 1 -ModuleName $ModuleName
        }
    }

    Context 'DEK encryption' {

        It 'Should encrypt the password with the VSatellite key, algorithm, and company' {
            Import-TrustCertificate -Data $testPkcs12Data -PrivateKeyPassword 'pass'
            Should -Invoke -CommandName 'ConvertTo-DekEncryptedString' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Text -eq 'plaintext' -and
                $PublicKey -eq $testEncKey -and
                $KeyAlgorithm -eq 'VSAT_HPKE' -and
                $CompanyId -eq 'e2d60b61-9a8c-4a3a-985c-92498bd1fc77'
            }
        }

        It 'Should include the encrypted password in the import payload' {
            Import-TrustCertificate -Data $testPkcs12Data -PrivateKeyPassword 'pass'
            Should -Invoke -CommandName 'Invoke-TrustParallel' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $InputObject[0].Body.importInformation[0].dekEncryptedPassword -eq 'encrypted-password'
            }
        }

        It 'Should stop and not import when encryption fails' {
            Mock -CommandName 'ConvertTo-DekEncryptedString' -MockWith { throw 'bad key' } -ModuleName $ModuleName
            { Import-TrustCertificate -Data $testPkcs12Data -PrivateKeyPassword 'pass' } | Should -Throw '*bad key*'
            Should -Invoke -CommandName 'Invoke-TrustParallel' -Times 0 -ModuleName $ModuleName
        }

        It 'Should not encrypt when importing certificates without keys' {
            Import-TrustCertificate -Data $testCertPemBase64
            Should -Invoke -CommandName 'ConvertTo-DekEncryptedString' -Times 0 -ModuleName $ModuleName
        }
    }
}