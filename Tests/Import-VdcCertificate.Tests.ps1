BeforeAll {
    . $PSScriptRoot/ModuleCommonVdc.ps1

    $testPolicyPath = '\VED\Policy\certificates'
    $testCertGuid = '{12345678-1234-1234-1234-123456789012}'

    # PEM cert only (no key)
    $testCertPem = @"
-----BEGIN CERTIFICATE-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA
-----END CERTIFICATE-----
"@

    # PEM cert + encrypted private key (PKCS8)
    $testCertAndKeyPem = @"
-----BEGIN CERTIFICATE-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA
-----END CERTIFICATE-----
-----BEGIN ENCRYPTED PRIVATE KEY-----
MIIFLjBYBgkqhkiG9w0BBQ0wSzAqBgkqhkiG9w0BBQww
-----END ENCRYPTED PRIVATE KEY-----
"@

    # base64-encode the PEM strings (simulating Export-TrustCertificate output)
    $testCertPemBase64 = [System.Convert]::ToBase64String(
        [System.Text.Encoding]::ASCII.GetBytes($testCertPem)
    )
    $testCertAndKeyPemBase64 = [System.Convert]::ToBase64String(
        [System.Text.Encoding]::ASCII.GetBytes($testCertAndKeyPem)
    )

    # PKCS12 data (does NOT start with LS0)
    $testPkcs12Data = 'MIIKYQIBAzCCCicGCSqGSIb3DQEHAaCCChg=='

    $mockImportResponse = [pscustomobject]@{
        CertificateDN    = "$testPolicyPath\test.venafi.com"
        CertificateVaultId = 12345
        Guid             = $testCertGuid
        PrivateKeyVaultId = 67890
    }

    $mockVdcObject = [pscustomobject]@{
        Path     = "$testPolicyPath\test.venafi.com"
        Name     = 'test.venafi.com'
        TypeName = 'X509 Server Certificate'
        Guid     = $testCertGuid
    }
}

Describe 'Import-VdcCertificate' -Tags 'Unit' {

    BeforeEach {
        Mock -CommandName 'ConvertTo-VdcFullPath' -MockWith { $testPolicyPath } -ModuleName $ModuleName
        Mock -CommandName 'Test-VdcObject' -MockWith { $true } -ModuleName $ModuleName
        Mock -CommandName 'ConvertTo-PlaintextString' -MockWith { 'plaintext' } -ModuleName $ModuleName
        Mock -CommandName 'Invoke-TrustParallel' -MockWith {
            # simulate the scriptblock execution by returning the mock response
            $mockImportResponse
        } -ModuleName $ModuleName
        Mock -CommandName 'Get-VdcObject' -MockWith { $mockVdcObject } -ModuleName $ModuleName
    }

    Context 'PKCS12 data import via -Data' {

        It 'Should pass PKCS12 data directly as CertificateData' {
            Import-VdcCertificate -PolicyPath $testPolicyPath -Data $testPkcs12Data
            Should -Invoke -CommandName 'Invoke-TrustParallel' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $InputObject[0].Data -eq $testPkcs12Data
            }
        }

        It 'Should set the policy path in the body' {
            Import-VdcCertificate -PolicyPath $testPolicyPath -Data $testPkcs12Data
            Should -Invoke -CommandName 'Invoke-TrustParallel' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $InputObject[0].InvokeParams.Body.PolicyDN -eq $testPolicyPath
            }
        }

        It 'Should call certificates/import endpoint' {
            Import-VdcCertificate -PolicyPath $testPolicyPath -Data $testPkcs12Data
            Should -Invoke -CommandName 'Invoke-TrustParallel' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $InputObject[0].InvokeParams.UriLeaf -eq 'certificates/import' -and
                $InputObject[0].InvokeParams.Method -eq 'Post'
            }
        }
    }

    Context 'Base64-encoded PEM cert-only import' {

        It 'Should detect PEM data starting with LS0' {
            $testCertPemBase64 | Should -Match '^LS0'
        }

        It 'Should pass base64-encoded PEM to Invoke-TrustParallel' {
            Import-VdcCertificate -PolicyPath $testPolicyPath -Data $testCertPemBase64
            Should -Invoke -CommandName 'Invoke-TrustParallel' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $InputObject[0].Data -eq $testCertPemBase64
            }
        }
    }

    Context 'Base64-encoded PEM cert+key (PKCS8) import' {

        It 'Should pass full cert+key base64 data to Invoke-TrustParallel' {
            Import-VdcCertificate -PolicyPath $testPolicyPath -Data $testCertAndKeyPemBase64 -PrivateKeyPassword 'pass'
            Should -Invoke -CommandName 'Invoke-TrustParallel' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $InputObject[0].Data -eq $testCertAndKeyPemBase64
            }
        }
    }

    Context 'Separate PrivateKey parameter' {

        It 'Should set PrivateKeyData in the body when -PrivateKey is provided' {
            $testKeyData = 'base64keydata=='
            Import-VdcCertificate -PolicyPath $testPolicyPath -Data $testCertPemBase64 -PrivateKey $testKeyData -PrivateKeyPassword 'pass'
            Should -Invoke -CommandName 'Invoke-TrustParallel' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $InputObject[0].InvokeParams.Body.PrivateKeyData -eq $testKeyData
            }
        }
    }

    Context 'PrivateKeyPassword handling' {

        It 'Should set Password in body when PrivateKeyPassword provided as string' {
            Import-VdcCertificate -PolicyPath $testPolicyPath -Data $testPkcs12Data -PrivateKeyPassword 'myPassword!'
            Should -Invoke -CommandName 'ConvertTo-PlaintextString' -Times 1 -ModuleName $ModuleName
            Should -Invoke -CommandName 'Invoke-TrustParallel' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $InputObject[0].InvokeParams.Body.Password -eq 'plaintext'
            }
        }

        It 'Should accept SecureString for PrivateKeyPassword' {
            $secPass = 'myPassword!' | ConvertTo-SecureString -AsPlainText -Force
            Import-VdcCertificate -PolicyPath $testPolicyPath -Data $testPkcs12Data -PrivateKeyPassword $secPass
            Should -Invoke -CommandName 'ConvertTo-PlaintextString' -Times 1 -ModuleName $ModuleName
        }

        It 'Should accept PSCredential for PrivateKeyPassword' {
            $cred = New-Object PSCredential('user', ('pass' | ConvertTo-SecureString -AsPlainText -Force))
            Import-VdcCertificate -PolicyPath $testPolicyPath -Data $testPkcs12Data -PrivateKeyPassword $cred
            Should -Invoke -CommandName 'ConvertTo-PlaintextString' -Times 1 -ModuleName $ModuleName
        }

        It 'Should not set Password when PrivateKeyPassword not provided' {
            Import-VdcCertificate -PolicyPath $testPolicyPath -Data $testPkcs12Data
            Should -Invoke -CommandName 'Invoke-TrustParallel' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                -not $InputObject[0].InvokeParams.Body.ContainsKey('Password')
            }
        }
    }

    Context 'Reconcile' {

        It 'Should set Reconcile in body when switch is used' {
            Import-VdcCertificate -PolicyPath $testPolicyPath -Data $testPkcs12Data -Reconcile
            Should -Invoke -CommandName 'Invoke-TrustParallel' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $InputObject[0].InvokeParams.Body.Reconcile -eq 'true'
            }
        }

        It 'Should not set Reconcile when switch is not used' {
            Import-VdcCertificate -PolicyPath $testPolicyPath -Data $testPkcs12Data
            Should -Invoke -CommandName 'Invoke-TrustParallel' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                -not $InputObject[0].InvokeParams.Body.ContainsKey('Reconcile')
            }
        }
    }

    Context 'Name parameter' {

        It 'Should set ObjectName when -Name is provided' {
            Import-VdcCertificate -PolicyPath $testPolicyPath -Data $testPkcs12Data -Name 'MyCert'
            Should -Invoke -CommandName 'Invoke-TrustParallel' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $InputObject[0].InvokeParams.Body.ObjectName -eq 'MyCert'
            }
        }

        It 'Should not set ObjectName when -Name is not provided' {
            Import-VdcCertificate -PolicyPath $testPolicyPath -Data $testPkcs12Data
            Should -Invoke -CommandName 'Invoke-TrustParallel' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                -not $InputObject[0].InvokeParams.Body.ContainsKey('ObjectName')
            }
        }
    }

    Context 'EnrollmentAttribute' {

        It 'Should set CASpecificAttributes when EnrollmentAttribute is provided' {
            $attrs = @{ 'san-dns' = 'test.com'; 'Validity' = '365' }
            Import-VdcCertificate -PolicyPath $testPolicyPath -Data $testPkcs12Data -EnrollmentAttribute $attrs
            Should -Invoke -CommandName 'Invoke-TrustParallel' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $null -ne $InputObject[0].InvokeParams.Body.CASpecificAttributes
            }
        }
    }

    Context 'Policy path handling' {

        It 'Should call ConvertTo-VdcFullPath to normalize the path' {
            Import-VdcCertificate -PolicyPath 'certificates' -Data $testPkcs12Data
            Should -Invoke -CommandName 'ConvertTo-VdcFullPath' -Times 1 -ModuleName $ModuleName
        }

        It 'Should check if the policy path exists' {
            Import-VdcCertificate -PolicyPath $testPolicyPath -Data $testPkcs12Data
            Should -Invoke -CommandName 'Test-VdcObject' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Path -eq $testPolicyPath -and $ExistOnly -eq $true
            }
        }

        It 'Should write error when policy path does not exist without Force' {
            Mock -CommandName 'Test-VdcObject' -MockWith { $false } -ModuleName $ModuleName
            Import-VdcCertificate -PolicyPath $testPolicyPath -Data $testPkcs12Data -ErrorVariable err -ErrorAction SilentlyContinue
            $err | Should -Not -BeNullOrEmpty
            $err[0].Exception.Message | Should -Match 'does not exist'
        }

        It 'Should create policy path when Force is used and path does not exist' {
            Mock -CommandName 'Test-VdcObject' -MockWith { $false } -ModuleName $ModuleName
            Mock -CommandName 'New-VdcPolicy' -MockWith {} -ModuleName $ModuleName
            Import-VdcCertificate -PolicyPath $testPolicyPath -Data $testPkcs12Data -Force
            Should -Invoke -CommandName 'New-VdcPolicy' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Path -eq $testPolicyPath -and $Force -eq $true
            }
        }

        It 'Should not create policy path when it already exists' {
            Mock -CommandName 'New-VdcPolicy' -MockWith {} -ModuleName $ModuleName
            Import-VdcCertificate -PolicyPath $testPolicyPath -Data $testPkcs12Data -Force
            Should -Invoke -CommandName 'New-VdcPolicy' -Times 0 -ModuleName $ModuleName
        }
    }

    Context 'TrustClient parameter' {

        It 'Should pass TrustClient to Invoke-TrustParallel' {
            Import-VdcCertificate -PolicyPath $testPolicyPath -Data $testPkcs12Data
            Should -Invoke -CommandName 'Invoke-TrustParallel' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $null -ne $TrustClient
            }
        }
    }

    Context 'ThrottleLimit' {

        It 'Should pass ThrottleLimit to Invoke-TrustParallel' {
            Import-VdcCertificate -PolicyPath $testPolicyPath -Data $testPkcs12Data -ThrottleLimit 5
            Should -Invoke -CommandName 'Invoke-TrustParallel' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $ThrottleLimit -eq 5
            }
        }

        It 'Should default ThrottleLimit to 100' {
            Import-VdcCertificate -PolicyPath $testPolicyPath -Data $testPkcs12Data
            Should -Invoke -CommandName 'Invoke-TrustParallel' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $ThrottleLimit -eq 100
            }
        }
    }

    Context 'Pipeline input' {

        It 'Should accept multiple objects via pipeline' {
            @(
                [pscustomobject]@{ Data = $testPkcs12Data; PolicyPath = $testPolicyPath }
                [pscustomobject]@{ Data = $testPkcs12Data; PolicyPath = $testPolicyPath }
            ) | Import-VdcCertificate
            Should -Invoke -CommandName 'Invoke-TrustParallel' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $InputObject.Count -eq 2
            }
        }

        It 'Should accept CertificateData alias' {
            [pscustomobject]@{ CertificateData = $testPkcs12Data; PolicyPath = $testPolicyPath } | Import-VdcCertificate
            Should -Invoke -CommandName 'Invoke-TrustParallel' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $InputObject[0].Data -eq $testPkcs12Data
            }
        }
    }

    Context 'ScriptBlock PEM splitting logic' {

        # The scriptblock inside Invoke-TrustParallel does the PEM detection/splitting.
        # We can't easily test the real scriptblock in isolation, so we verify the
        # data that flows INTO Invoke-TrustParallel is correct, and that the
        # detection patterns work as expected.

        It 'Should detect base64-encoded PEM (LS0 prefix) correctly' {
            $testCertAndKeyPemBase64 | Should -Match '^LS0'
        }

        It 'Should NOT detect PKCS12 data as PEM' {
            $testPkcs12Data | Should -Not -Match '^LS0'
            $testPkcs12Data | Should -Not -Match '-----BEGIN'
        }

        It 'Should detect raw PEM data correctly' {
            $testCertAndKeyPem | Should -Match '-----BEGIN'
        }

        It 'Should pass base64-encoded cert+key PEM as-is to Invoke-TrustParallel Data' {
            Import-VdcCertificate -PolicyPath $testPolicyPath -Data $testCertAndKeyPemBase64 -PrivateKeyPassword 'pass'
            Should -Invoke -CommandName 'Invoke-TrustParallel' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $InputObject[0].Data -eq $testCertAndKeyPemBase64
            }
        }

        It 'Should pass PKCS12 as-is to Invoke-TrustParallel Data' {
            Import-VdcCertificate -PolicyPath $testPolicyPath -Data $testPkcs12Data
            Should -Invoke -CommandName 'Invoke-TrustParallel' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $InputObject[0].Data -eq $testPkcs12Data
            }
        }
    }

    Context 'Split-CertificateData behavior' {

        # Verify that Split-CertificateData correctly splits the test PEM data
        # that would be passed through the scriptblock

        It 'Should split base64-encoded cert+key PEM into CertPem and KeyPem' {
            InModuleScope $ModuleName -Parameters @{ data = $testCertAndKeyPemBase64 } {
                param($data)
                $result = Split-CertificateData -InputObject $data
                $result.CertPem | Should -Match '-----BEGIN CERTIFICATE-----'
                $result.KeyPem | Should -Match '-----BEGIN ENCRYPTED PRIVATE KEY-----'
            }
        }

        It 'Should split base64-encoded cert-only PEM with no key' {
            InModuleScope $ModuleName -Parameters @{ data = $testCertPemBase64 } {
                param($data)
                $result = Split-CertificateData -InputObject $data
                $result.CertPem | Should -Match '-----BEGIN CERTIFICATE-----'
                $result.KeyPem | Should -BeNullOrEmpty
            }
        }

        It 'Should split raw PEM cert+key into parts' {
            InModuleScope $ModuleName -Parameters @{ data = $testCertAndKeyPem } {
                param($data)
                $result = Split-CertificateData -InputObject $data
                $result.CertPem | Should -Match '-----BEGIN CERTIFICATE-----'
                $result.KeyPem | Should -Match '-----BEGIN ENCRYPTED PRIVATE KEY-----'
            }
        }
    }
}
