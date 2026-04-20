BeforeAll {
    . $PSScriptRoot/ModuleCommonVc.ps1

    $testMachineId  = 'a7dafd20-505e-11f0-b79d-d398ba415d06'
    $testSatelliteId = 'b8ebfe31-616f-22f1-c8ae-e409cb526e17'

    $mockMachine = [pscustomobject]@{
        machineId         = $testMachineId
        name              = 'MyMachine'
        connectionDetails = [pscustomobject]@{
            hostnameOrAddress = 'old-host.example.com'
            https             = $false
            kerberos          = [pscustomobject]@{
                domain                 = 'mydomain.example.com'
                keyDistributionCenter  = 'old-kdc.example.com'
                servicePrincipalName   = 'WSMAN/old-host.example.com'
            }
        }
    }

    $mockUpdatedMachine = [pscustomobject]@{
        machineId = $testMachineId
        name      = 'MyMachine'
    }
}

Describe 'Set-VcMachine' -Tags 'Unit' {

    BeforeEach {
        Mock -CommandName 'Test-TrustClient'    -MockWith {} -ModuleName $ModuleName
        Mock -CommandName 'Get-VcMachine'         -MockWith { $mockMachine } -ModuleName $ModuleName
        Mock -CommandName 'Get-VcData' -ParameterFilter { $Type -eq 'VSatellite' } -MockWith { $testSatelliteId } -ModuleName $ModuleName
        Mock -CommandName 'Invoke-TrustRestMethod' -MockWith { $mockUpdatedMachine } -ModuleName $ModuleName
    }

    Context 'Machine not found' {

        It 'Should write an error when machine is not found' {
            Mock -CommandName 'Get-VcMachine' -MockWith { $null } -ModuleName $ModuleName
            Set-VcMachine -Machine 'missing-machine' -Name 'NewName' -ErrorVariable err -ErrorAction SilentlyContinue
            $err | Should -Not -BeNullOrEmpty
        }

        It 'Should not call Invoke-TrustRestMethod when machine not found' {
            Mock -CommandName 'Get-VcMachine' -MockWith { $null } -ModuleName $ModuleName
            Set-VcMachine -Machine 'missing-machine' -Name 'NewName' -ErrorAction SilentlyContinue
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 0 -ModuleName $ModuleName
        }
    }

    Context 'No update parameters' {

        It 'Should write an error when no updatable parameters are provided' {
            Set-VcMachine -Machine $testMachineId -ErrorVariable err -ErrorAction SilentlyContinue
            $err | Should -Not -BeNullOrEmpty
        }

        It 'Should not call Invoke-TrustRestMethod when nothing to update' {
            Set-VcMachine -Machine $testMachineId -ErrorAction SilentlyContinue
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 0 -ModuleName $ModuleName
        }
    }

    Context '-Name update' {

        It 'Should call PATCH on machines/{id}' {
            Set-VcMachine -Machine $testMachineId -Name 'NewName' -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Method -eq 'Patch' -and $UriLeaf -eq "machines/$testMachineId"
            }
        }

        It 'Should include name in the body' {
            Set-VcMachine -Machine $testMachineId -Name 'NewName' -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.name -eq 'NewName'
            }
        }
    }

    Context '-ConnectionDetail update' {

        It 'Should call PATCH with connectionDetails in the body' {
            Set-VcMachine -Machine $testMachineId -ConnectionDetail @{ hostnameOrAddress = 'new-host.example.com' } -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.connectionDetails -ne $null
            }
        }

        It 'Should merge top-level connection detail key' {
            Set-VcMachine -Machine $testMachineId -ConnectionDetail @{ hostnameOrAddress = 'new-host.example.com' } -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.connectionDetails.hostnameOrAddress -eq 'new-host.example.com'
            }
        }

        It 'Should preserve existing top-level values not in the update' {
            Set-VcMachine -Machine $testMachineId -ConnectionDetail @{ hostnameOrAddress = 'new-host.example.com' } -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.connectionDetails.ContainsKey('https')
            }
        }

        It 'Should deep-merge nested connection detail hashtable' {
            Set-VcMachine -Machine $testMachineId -ConnectionDetail @{ kerberos = @{ keyDistributionCenter = 'new-kdc.example.com' } } -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.connectionDetails.kerberos.keyDistributionCenter -eq 'new-kdc.example.com' -and
                $Body.connectionDetails.kerberos.domain -eq 'mydomain.example.com'
            }
        }
    }

    Context '-Satellite update' {

        It 'Should look up satellite ID via Get-VcData' {
            Set-VcMachine -Machine $testMachineId -Satellite 'MySat' -Confirm:$false
            Should -Invoke -CommandName 'Get-VcData' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Type -eq 'VSatellite' -and $InputObject -eq 'MySat'
            }
        }

        It 'Should include edgeInstanceId in the body' {
            Set-VcMachine -Machine $testMachineId -Satellite 'MySat' -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.edgeInstanceId -eq $testSatelliteId
            }
        }
    }

    Context '-PassThru' {

        It 'Should not return output without PassThru' {
            $result = Set-VcMachine -Machine $testMachineId -Name 'NewName' -Confirm:$false
            $result | Should -BeNullOrEmpty
        }

        It 'Should return updated machine with PassThru' {
            Mock -CommandName 'Get-VcMachine' -MockWith { $mockUpdatedMachine } -ModuleName $ModuleName -ParameterFilter { $Machine -eq $testMachineId }
            $result = Set-VcMachine -Machine $testMachineId -Name 'NewName' -PassThru -Confirm:$false
            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Pipeline input' {

        It 'Should accept machineId from pipeline' {
            [pscustomobject]@{ machineId = $testMachineId } | Set-VcMachine -Name 'PipelineName' -Confirm:$false
            Should -Invoke -CommandName 'Get-VcMachine' -Times 1 -ModuleName $ModuleName
        }
    }
}
