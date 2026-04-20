BeforeAll {
    . $PSScriptRoot/ModuleCommonVc.ps1

    $testId = 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2'
    $testId2 = 'da8ff666-99e3-5cfd-a0fb-3741bd55d2e3'
}

Describe 'Remove-VcMachineIdentity' -Tags 'Unit' {

    BeforeEach {
        Mock -CommandName 'Invoke-TrustRestMethod' -MockWith {} -ModuleName $ModuleName
    }

    It 'Should call the delete API with the correct endpoint' {
        Remove-VcMachineIdentity -ID $testId -Confirm:$false
        Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
            $Method -eq 'Delete' -and $UriLeaf -eq "machineidentities/$testId"
        }
    }

    It 'Should accept pipeline input' {
        $testId | Remove-VcMachineIdentity -Confirm:$false
        Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName
    }

    It 'Should process multiple items' {
        $testId, $testId2 | Remove-VcMachineIdentity -Confirm:$false
        Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 2 -ModuleName $ModuleName
    }

    It 'Should not produce output' {
        $result = Remove-VcMachineIdentity -ID $testId -Confirm:$false
        $result | Should -BeNullOrEmpty
    }
}
