BeforeAll {
    . $PSScriptRoot/ModuleCommonVc.ps1

    $testId = 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2'
    $testId2 = 'da8ff666-99e3-5cfd-a0fb-3741bd55d2e3'
}

Describe 'Remove-VcWebhook' -Tags 'Unit' {

    BeforeEach {
        Mock -CommandName 'Test-VenafiSession' -MockWith {} -ModuleName $ModuleName
        Mock -CommandName 'Invoke-VenafiRestMethod' -MockWith {} -ModuleName $ModuleName
    }

    It 'Should call the delete API with the correct endpoint' {
        Remove-VcWebhook -ID $testId -Confirm:$false
        Should -Invoke -CommandName 'Invoke-VenafiRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
            $Method -eq 'Delete' -and $UriLeaf -eq "connectors/$testId"
        }
    }

    It 'Should accept pipeline input' {
        $testId | Remove-VcWebhook -Confirm:$false
        Should -Invoke -CommandName 'Invoke-VenafiRestMethod' -Times 1 -ModuleName $ModuleName
    }

    It 'Should process multiple items' {
        $testId, $testId2 | Remove-VcWebhook -Confirm:$false
        Should -Invoke -CommandName 'Invoke-VenafiRestMethod' -Times 2 -ModuleName $ModuleName
    }

    It 'Should not produce output' {
        $result = Remove-VcWebhook -ID $testId -Confirm:$false
        $result | Should -BeNullOrEmpty
    }
}
