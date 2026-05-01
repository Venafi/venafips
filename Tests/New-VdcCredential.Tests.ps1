BeforeAll {
    . $PSScriptRoot/ModuleCommonVdc.ps1

    $testPath = '\VED\Policy\mycred'
    $testFullPath = '\VED\Policy\mycred'
    $testPassword = 'myP@ssword!'
    $testUsername = 'myuser'

    $mockSuccessResponse = [pscustomobject]@{ Result = 1 }
    $mockFailureResponse = [pscustomobject]@{ Result = 0; ErrorMessage = 'Something went wrong' }

    $mockVdcObject = [pscustomobject]@{
        Path     = $testFullPath
        Name     = 'mycred'
        TypeName = 'X509 Certificate Credential'
    }
}

Describe 'New-VdcCredential' -Tags 'Unit' {

    BeforeEach {
        Mock -CommandName 'ConvertTo-VdcFullPath' -MockWith { $testFullPath } -ModuleName $ModuleName
        Mock -CommandName 'Invoke-TrustRestMethod' -MockWith { $mockSuccessResponse } -ModuleName $ModuleName
        Mock -CommandName 'Get-VdcObject' -MockWith { $mockVdcObject } -ModuleName $ModuleName
    }

    Context 'Password Credential with String' {

        It 'Should create a Password credential' {
            New-VdcCredential -Path $testPath -Secret $testPassword -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.FriendlyName -eq 'Password'
            }
        }

        It 'Should set Password value in body' {
            New-VdcCredential -Path $testPath -Secret $testPassword -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                ($Body.Values | Where-Object { $_.Name -eq 'Password' }).Value -eq $testPassword
            }
        }

        It 'Should call Credentials/Create endpoint' {
            New-VdcCredential -Path $testPath -Secret $testPassword -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $UriLeaf -eq 'Credentials/Create' -and $Method -eq 'Post'
            }
        }

        It 'Should not return output without PassThru' {
            $result = New-VdcCredential -Path $testPath -Secret $testPassword -Confirm:$false
            $result | Should -BeNullOrEmpty
        }

        It 'Should return object with PassThru' {
            $result = New-VdcCredential -Path $testPath -Secret $testPassword -PassThru -Confirm:$false
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke -CommandName 'Get-VdcObject' -Times 1 -ModuleName $ModuleName
        }
    }

    Context 'Password Credential with SecureString' {

        BeforeAll {
            $securePassword = $testPassword | ConvertTo-SecureString -AsPlainText -Force
        }

        It 'Should create a Password credential' {
            New-VdcCredential -Path $testPath -Secret $securePassword -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.FriendlyName -eq 'Password'
            }
        }

        It 'Should have Password in Values' {
            New-VdcCredential -Path $testPath -Secret $securePassword -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                ($Body.Values | Where-Object { $_.Name -eq 'Password' }) -ne $null
            }
        }
    }

    Context 'Username Password Credential with PSCredential' {

        BeforeAll {
            $psCred = New-Object System.Management.Automation.PSCredential(
                $testUsername,
                ($testPassword | ConvertTo-SecureString -AsPlainText -Force)
            )
        }

        It 'Should create a UsernamePassword credential' {
            New-VdcCredential -Path $testPath -Secret $psCred -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.FriendlyName -eq 'UsernamePassword'
            }
        }

        It 'Should include Username in Values' {
            New-VdcCredential -Path $testPath -Secret $psCred -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                ($Body.Values | Where-Object { $_.Name -eq 'Username' }).Value -eq $testUsername
            }
        }

        It 'Should include Password in Values' {
            New-VdcCredential -Path $testPath -Secret $psCred -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                ($Body.Values | Where-Object { $_.Name -eq 'Password' }).Value -eq $testPassword
            }
        }
    }

    Context 'Certificate Credential' {

        BeforeAll {
            # Create a self-signed certificate for testing
            $certPassword = 'certP@ss!'
            $rsa = [System.Security.Cryptography.RSA]::Create(2048)
            $req = [System.Security.Cryptography.X509Certificates.CertificateRequest]::new(
                'CN=TestCert',
                $rsa,
                [System.Security.Cryptography.HashAlgorithmName]::SHA256,
                [System.Security.Cryptography.RSASignaturePadding]::Pkcs1
            )
            $cert = $req.CreateSelfSigned(
                [System.DateTimeOffset]::Now,
                [System.DateTimeOffset]::Now.AddYears(1)
            )
            $pfxBytes = $cert.Export(
                [System.Security.Cryptography.X509Certificates.X509ContentType]::Pfx,
                $certPassword
            )
            $tempCertPath = Join-Path ([System.IO.Path]::GetTempPath()) 'test-vdc-cred.pfx'
            [System.IO.File]::WriteAllBytes($tempCertPath, $pfxBytes)
        }

        AfterAll {
            if (Test-Path $tempCertPath) {
                Remove-Item $tempCertPath -Force
            }
        }

        It 'Should create a Certificate credential' {
            New-VdcCredential -Path $testPath -Secret $certPassword -CertificatePath $tempCertPath -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.FriendlyName -eq 'Certificate'
            }
        }

        It 'Should include Certificate byte array in Values' {
            New-VdcCredential -Path $testPath -Secret $certPassword -CertificatePath $tempCertPath -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $certValue = $Body.Values | Where-Object { $_.Name -eq 'Certificate' }
                $certValue -ne $null -and $certValue.Type -eq 'byte[]' -and $certValue.Value.Length -gt 0
            }
        }

        It 'Should include Password in Values' {
            New-VdcCredential -Path $testPath -Secret $certPassword -CertificatePath $tempCertPath -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                ($Body.Values | Where-Object { $_.Name -eq 'Password' }).Value -eq $certPassword
            }
        }

        It 'Should not include Username in Values' {
            $psCred = New-Object System.Management.Automation.PSCredential(
                $testUsername,
                ($certPassword | ConvertTo-SecureString -AsPlainText -Force)
            )
            New-VdcCredential -Path $testPath -Secret $psCred -CertificatePath $tempCertPath -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                ($Body.Values | Where-Object { $_.Name -eq 'Username' }) -eq $null
            }
        }

        It 'Should throw on invalid certificate path' {
            { New-VdcCredential -Path $testPath -Secret $certPassword -CertificatePath 'C:\nonexistent.pfx' -Confirm:$false } |
                Should -Throw
        }

        It 'Should throw on wrong certificate password' {
            { New-VdcCredential -Path $testPath -Secret 'wrongpassword' -CertificatePath $tempCertPath -Confirm:$false } |
                Should -Throw -ExpectedMessage '*Failed to load certificate*'
        }
    }

    Context 'API failure' {

        It 'Should throw when API returns failure' {
            Mock -CommandName 'Invoke-TrustRestMethod' -MockWith { $mockFailureResponse } -ModuleName $ModuleName
            { New-VdcCredential -Path $testPath -Secret $testPassword -Confirm:$false } |
                Should -Throw -ExpectedMessage '*Failed to create credential*'
        }
    }

    Context 'Path handling' {

        It 'Should call ConvertTo-VdcFullPath with the provided path' {
            New-VdcCredential -Path $testPath -Secret $testPassword -Confirm:$false
            Should -Invoke -CommandName 'ConvertTo-VdcFullPath' -Times 1 -ModuleName $ModuleName
        }

        It 'Should set CredentialPath in body' {
            New-VdcCredential -Path $testPath -Secret $testPassword -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.CredentialPath -eq $testFullPath
            }
        }
    }
}
