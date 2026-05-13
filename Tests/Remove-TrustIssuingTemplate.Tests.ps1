BeforeAll {
    . $PSScriptRoot/ModuleCommonTrust.ps1

    $testId = 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2'
    $testId2 = 'da8ff666-99e3-5cfd-a0fb-3741bd55d2e3'
}

Describe 'Remove-TrustIssuingTemplate' -Tags 'Unit' {

    BeforeEach {
        Mock -CommandName 'Invoke-TrustRestMethod' -MockWith {} -ModuleName $ModuleName
    }

    It 'Should call the delete API with the correct endpoint' {
        Remove-TrustIssuingTemplate -ID $testId -Confirm:$false
        Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
            $Method -eq 'Delete' -and $UriLeaf -eq "certificateissuingtemplates/$testId"
        }
    }

    It 'Should accept pipeline input' {
        $testId | Remove-TrustIssuingTemplate -Confirm:$false
        Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName
    }

    It 'Should process multiple items' {
        $testId, $testId2 | Remove-TrustIssuingTemplate -Confirm:$false
        Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 2 -ModuleName $ModuleName
    }

    It 'Should not produce output' {
        $result = Remove-TrustIssuingTemplate -ID $testId -Confirm:$false
        $result | Should -BeNullOrEmpty
    }
}
