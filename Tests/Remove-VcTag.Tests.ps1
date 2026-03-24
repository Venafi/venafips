BeforeAll {
    . $PSScriptRoot/ModuleCommonVc.ps1

    $testId = 'MyTag'
    $testId2 = 'AnotherTag'
}

Describe 'Remove-VcTag' -Tags 'Unit' {

    BeforeEach {
        Mock -CommandName 'Test-VenafiSession' -MockWith {} -ModuleName $ModuleName
        Mock -CommandName 'Invoke-VenafiRestMethod' -MockWith {} -ModuleName $ModuleName
    }

    It 'Should call the delete API with the correct endpoint' {
        Remove-VcTag -ID $testId -Confirm:$false
        Should -Invoke -CommandName 'Invoke-VenafiRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
            $Method -eq 'Delete' -and $UriLeaf -eq "tags/$testId"
        }
    }

    It 'Should accept pipeline input' {
        $testId | Remove-VcTag -Confirm:$false
        Should -Invoke -CommandName 'Invoke-VenafiRestMethod' -Times 1 -ModuleName $ModuleName
    }

    It 'Should process multiple items' {
        $testId, $testId2 | Remove-VcTag -Confirm:$false
        Should -Invoke -CommandName 'Invoke-VenafiRestMethod' -Times 2 -ModuleName $ModuleName
    }

    It 'Should not produce output' {
        $result = Remove-VcTag -ID $testId -Confirm:$false
        $result | Should -BeNullOrEmpty
    }
}
