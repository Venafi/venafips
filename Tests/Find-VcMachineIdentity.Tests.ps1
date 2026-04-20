BeforeAll {
    . $PSScriptRoot/ModuleCommonVc.ps1

    $testMachineId    = 'a7dafd20-505e-11f0-b79d-d398ba415d06'
    $testCertId       = 'b8ebfe31-616f-22f1-c8ae-e409cb526e17'
    $testMachineIdentityId = 'c9fce042-727f-33f2-d9bf-f51adc637f28'

    $mockMachineIdentity = [pscustomobject]@{
        machineIdentityId = $testMachineIdentityId
        machineId         = $testMachineId
        certificateId     = $testCertId
        status            = 'INSTALLED'
    }
}

Describe 'Find-VcMachineIdentity' -Tags 'Unit' {

    BeforeEach {
        Mock -CommandName 'Test-TrustClient' -MockWith {} -ModuleName $ModuleName
        Mock -CommandName 'Find-VcObject'      -MockWith { $mockMachineIdentity } -ModuleName $ModuleName
        Mock -CommandName 'Get-VcData' -ParameterFilter { $Type -eq 'Machine' } -MockWith { $testMachineId } -ModuleName $ModuleName
        Mock -CommandName 'Get-VcData' -ParameterFilter { $Type -eq 'Certificate' } -MockWith { $testCertId } -ModuleName $ModuleName
    }

    Context 'No filter - get all' {

        It 'Should call Find-VcObject with type MachineIdentity' {
            Find-VcMachineIdentity
            Should -Invoke -CommandName 'Find-VcObject' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Type -eq 'MachineIdentity'
            }
        }

        It 'Should not set a Filter when no parameters provided' {
            Find-VcMachineIdentity
            Should -Invoke -CommandName 'Find-VcObject' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $null -eq $Filter
            }
        }
    }

    Context '-Status filter' {

        It 'Should pass a single status filter without AND prefix' {
            Find-VcMachineIdentity -Status INSTALLED
            Should -Invoke -CommandName 'Find-VcObject' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Filter -ne $null -and
                $Filter.Count -eq 1 -and
                $Filter[0][0] -eq 'status'
            }
        }

        It 'Should use MATCH operator for status' {
            Find-VcMachineIdentity -Status DISCOVERED
            Should -Invoke -CommandName 'Find-VcObject' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Filter[0][1] -eq 'MATCH'
            }
        }

        It 'Should uppercase the status value' {
            Find-VcMachineIdentity -Status VALIDATED
            Should -Invoke -CommandName 'Find-VcObject' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Filter[0][2] -eq 'VALIDATED'
            }
        }
    }

    Context '-Machine filter' {

        It 'Should look up machine ID via Get-VcData' {
            Find-VcMachineIdentity -Machine 'my-machine'
            Should -Invoke -CommandName 'Get-VcData' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Type -eq 'Machine' -and $InputObject -eq 'my-machine'
            }
        }

        It 'Should pass machineId filter with eq operator' {
            Find-VcMachineIdentity -Machine 'my-machine'
            Should -Invoke -CommandName 'Find-VcObject' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Filter.Count -eq 1 -and
                $Filter[0][0] -eq 'machineId' -and
                $Filter[0][1] -eq 'eq' -and
                $Filter[0][2] -eq $testMachineId
            }
        }

        It 'Should not prefix AND when only Machine is provided' {
            Find-VcMachineIdentity -Machine 'my-machine'
            Should -Invoke -CommandName 'Find-VcObject' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Filter[0] -isnot [string]
            }
        }
    }

    Context '-Certificate filter' {

        It 'Should look up certificate ID via Get-VcData' {
            Find-VcMachineIdentity -Certificate 'my-cert'
            Should -Invoke -CommandName 'Get-VcData' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Type -eq 'Certificate' -and $InputObject -eq 'my-cert'
            }
        }

        It 'Should pass certificateId filter with in operator' {
            Find-VcMachineIdentity -Certificate 'my-cert'
            Should -Invoke -CommandName 'Find-VcObject' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Filter.Count -eq 1 -and
                $Filter[0][0] -eq 'certificateId' -and
                $Filter[0][1] -eq 'in'
            }
        }
    }

    Context 'Multiple filters - two clauses passed to Find-VcObject' {

        It 'Should pass two filter clauses when both Status and Machine are provided' {
            Find-VcMachineIdentity -Status INSTALLED -Machine 'my-machine'
            Should -Invoke -CommandName 'Find-VcObject' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Filter.Count -eq 2
            }
        }

        It 'Should pass two filter clauses when Status and Certificate are provided' {
            Find-VcMachineIdentity -Status DISCOVERED -Certificate 'my-cert'
            Should -Invoke -CommandName 'Find-VcObject' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Filter.Count -eq 2
            }
        }

        It 'Should pass two filter clauses when Machine and Certificate are provided' {
            Find-VcMachineIdentity -Machine 'my-machine' -Certificate 'my-cert'
            Should -Invoke -CommandName 'Find-VcObject' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Filter.Count -eq 2
            }
        }
    }

    Context '-Filter parameter set' {

        It 'Should pass the provided filter directly to Find-VcObject' {
            $customFilter = [System.Collections.Generic.List[object]]@('AND', @('status', 'EQ', 'INSTALLED'))
            Find-VcMachineIdentity -Filter $customFilter
            Should -Invoke -CommandName 'Find-VcObject' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $null -ne $Filter -and $Filter[0] -eq 'AND'
            }
        }
    }

    Context '-First parameter' {

        It 'Should pass First to Find-VcObject' {
            Find-VcMachineIdentity -First 5
            Should -Invoke -CommandName 'Find-VcObject' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $First -eq 5
            }
        }
    }

    Context 'Output' {

        It 'Should return results from Find-VcObject' {
            $result = Find-VcMachineIdentity
            $result | Should -Not -BeNullOrEmpty
        }
    }
}
