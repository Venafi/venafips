BeforeAll {
    . $PSScriptRoot/ModuleCommonTrust.ps1

    $testId = 'MyTag'
    $testId2 = 'AnotherTag'
}

Describe 'Remove-TrustTag' -Tags 'Unit' {

    BeforeEach {
        Mock -CommandName 'Invoke-TrustRestMethod' -MockWith {} -ModuleName $ModuleName
    }

    It 'Should call the delete API with the correct endpoint' {
        Remove-TrustTag -ID $testId -Confirm:$false
        Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
            $Method -eq 'Delete' -and $UriLeaf -eq "tags/$testId"
        }
    }

    It 'Should accept pipeline input' {
        $testId | Remove-TrustTag -Confirm:$false
        Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName
    }

    It 'Should process multiple items' {
        $testId, $testId2 | Remove-TrustTag -Confirm:$false
        Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 2 -ModuleName $ModuleName
    }

    It 'Should not produce output' {
        $result = Remove-TrustTag -ID $testId -Confirm:$false
        $result | Should -BeNullOrEmpty
    }
}
