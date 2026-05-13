BeforeAll {
    . $PSScriptRoot/ModuleCommonTrust.ps1

    $testMachineIdentityId = 'c9fce042-727f-33f2-d9bf-f51adc637f28'
    $testCertId            = 'b8ebfe31-616f-22f1-c8ae-e409cb526e17'

    $mockMachineIdentity = [pscustomobject]@{
        machineIdentityId = $testMachineIdentityId
        machineId         = 'a7dafd20-505e-11f0-b79d-d398ba415d06'
        certificateId     = $testCertId
        status            = 'INSTALLED'
        binding           = [pscustomobject]@{
            bindingIp   = '0.0.0.0'
            bindingPort = 443
        }
        keystore          = [pscustomobject]@{
            storeName     = 'My'
            keystoreAlias = 'old-alias'
        }
    }

    $mockCertificate = [pscustomobject]@{
        certificateId   = $testCertId
        certificateName = 'MyCert'
        Count           = 1
    }

    $mockUpdatedIdentity = [pscustomobject]@{
        machineIdentityId = $testMachineIdentityId
    }
}

Describe 'Set-TrustMachineIdentity' -Tags 'Unit' {

    BeforeEach {
        Mock -CommandName 'Get-TrustMachineIdentity'   -MockWith { $mockMachineIdentity } -ModuleName $ModuleName
        Mock -CommandName 'Find-TrustCertificate'      -MockWith { $mockCertificate } -ModuleName $ModuleName
        Mock -CommandName 'Invoke-TrustRestMethod' -MockWith { $mockUpdatedIdentity } -ModuleName $ModuleName
    }

    Context 'Machine identity not found' {

        It 'Should write an error when machine identity is not found' {
            Mock -CommandName 'Get-TrustMachineIdentity' -MockWith { $null } -ModuleName $ModuleName
            Set-TrustMachineIdentity -MachineIdentity $testMachineIdentityId -Certificate 'MyCert' `
                -ErrorVariable err -ErrorAction SilentlyContinue
            $err | Should -Not -BeNullOrEmpty
        }

        It 'Should not call Invoke-TrustRestMethod when identity not found' {
            Mock -CommandName 'Get-TrustMachineIdentity' -MockWith { $null } -ModuleName $ModuleName
            Set-TrustMachineIdentity -MachineIdentity $testMachineIdentityId -Certificate 'MyCert' `
                -ErrorAction SilentlyContinue
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 0 -ModuleName $ModuleName
        }
    }

    Context 'No update parameters' {

        It 'Should write an error when no updatable parameters are provided' {
            Set-TrustMachineIdentity -MachineIdentity $testMachineIdentityId `
                -ErrorVariable err -ErrorAction SilentlyContinue
            $err | Should -Not -BeNullOrEmpty
        }

        It 'Should not call Invoke-TrustRestMethod when nothing to update' {
            Set-TrustMachineIdentity -MachineIdentity $testMachineIdentityId -ErrorAction SilentlyContinue
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 0 -ModuleName $ModuleName
        }
    }

    Context '-Certificate update' {

        It 'Should look up certificate with Find-TrustCertificate' {
            Set-TrustMachineIdentity -MachineIdentity $testMachineIdentityId -Certificate 'MyCert' -Confirm:$false
            Should -Invoke -CommandName 'Find-TrustCertificate' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Name -eq 'MyCert'
            }
        }

        It 'Should call PATCH on machineidentities/{id}' {
            Set-TrustMachineIdentity -MachineIdentity $testMachineIdentityId -Certificate 'MyCert' -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Method -eq 'Patch' -and $UriLeaf -eq "machineidentities/$testMachineIdentityId"
            }
        }

        It 'Should include certificateId in the body' {
            Set-TrustMachineIdentity -MachineIdentity $testMachineIdentityId -Certificate 'MyCert' -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.certificateId -eq $testCertId
            }
        }

        It 'Should throw when multiple certificates are found without -Force' {
            Mock -CommandName 'Find-TrustCertificate' -MockWith {
                @(
                    [pscustomobject]@{ certificateId = $testCertId; certificateName = 'MyCert'; Count = 2 },
                    [pscustomobject]@{ certificateId = 'other-id'; certificateName = 'MyCert'; Count = 2 }
                )
            } -ModuleName $ModuleName
            { Set-TrustMachineIdentity -MachineIdentity $testMachineIdentityId -Certificate 'MyCert' -Confirm:$false } |
                Should -Throw
        }

        It 'Should throw when certificate is not found' {
            Mock -CommandName 'Find-TrustCertificate' -MockWith { @() } -ModuleName $ModuleName
            { Set-TrustMachineIdentity -MachineIdentity $testMachineIdentityId -Certificate 'MyCert' -Confirm:$false } |
                Should -Throw
        }

        It 'Should use CURRENT version lookup when -Force is specified' {
            Set-TrustMachineIdentity -MachineIdentity $testMachineIdentityId -Certificate 'MyCert' -Force -Confirm:$false
            Should -Invoke -CommandName 'Find-TrustCertificate' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Name -eq 'MyCert' -and $VersionType -eq 'CURRENT'
            }
        }
    }

    Context '-Binding update' {

        It 'Should include binding in the body' {
            Set-TrustMachineIdentity -MachineIdentity $testMachineIdentityId -Binding @{ bindingPort = 8443 } -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.binding -ne $null
            }
        }

        It 'Should merge top-level binding key' {
            Set-TrustMachineIdentity -MachineIdentity $testMachineIdentityId -Binding @{ bindingPort = 8443 } -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.binding.bindingPort -eq 8443
            }
        }

        It 'Should preserve existing binding values not in the update' {
            Set-TrustMachineIdentity -MachineIdentity $testMachineIdentityId -Binding @{ bindingPort = 8443 } -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.binding.ContainsKey('bindingIp')
            }
        }
    }

    Context '-Keystore update' {

        It 'Should include keystore in the body' {
            Set-TrustMachineIdentity -MachineIdentity $testMachineIdentityId -Keystore @{ keystoreAlias = 'new-alias' } -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.keystore -ne $null
            }
        }

        It 'Should merge keystore key' {
            Set-TrustMachineIdentity -MachineIdentity $testMachineIdentityId -Keystore @{ keystoreAlias = 'new-alias' } -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.keystore.keystoreAlias -eq 'new-alias'
            }
        }

        It 'Should preserve existing keystore values not in the update' {
            Set-TrustMachineIdentity -MachineIdentity $testMachineIdentityId -Keystore @{ keystoreAlias = 'new-alias' } -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.keystore.ContainsKey('storeName')
            }
        }
    }

    Context '-PassThru' {

        It 'Should not return output without PassThru' {
            $result = Set-TrustMachineIdentity -MachineIdentity $testMachineIdentityId -Certificate 'MyCert' -Confirm:$false
            $result | Should -BeNullOrEmpty
        }

        It 'Should return updated identity with PassThru' {
            $result = Set-TrustMachineIdentity -MachineIdentity $testMachineIdentityId -Certificate 'MyCert' -PassThru -Confirm:$false
            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Pipeline input (machineIdentityId alias)' {

        It 'Should accept machineIdentityId from pipeline by property name' {
            [pscustomobject]@{ machineIdentityId = $testMachineIdentityId } |
                Set-TrustMachineIdentity -Certificate 'MyCert' -Confirm:$false
            Should -Invoke -CommandName 'Get-TrustMachineIdentity' -Times 1 -ModuleName $ModuleName
        }
    }
}
