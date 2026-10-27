BeforeAll {
    . $PSScriptRoot/ModuleCommonCm.ps1
}

Describe 'Find-CmObject' -Tags 'Unit' {

    BeforeEach {
        Mock -CommandName 'Invoke-TrustRestMethod' -MockWith { [pscustomobject]@{ Result = 1; Objects = @() } } -ModuleName $ModuleName
    }

    It 'Should not search recursively with -Recursive:$false' -ForEach @(
        @{ Params = @{ Path = '\VED\Policy\a'; Recursive = $false } }
        @{ Params = @{ Path = '\VED\Policy\a'; Class = 'Policy'; Recursive = $false } }
    ) {
        Find-CmObject @Params
        Should -Invoke -CommandName 'Invoke-TrustRestMethod' -ModuleName $ModuleName -Times 1 -ParameterFilter { -not $Body.Recursive }
    }

    It 'Should search recursively with -Recursive' {
        Find-CmObject -Path '\VED\Policy\a' -Class 'Policy' -Recursive
        Should -Invoke -CommandName 'Invoke-TrustRestMethod' -ModuleName $ModuleName -Times 1 -ParameterFilter { $Body.Recursive -eq 'true' }
    }

    It 'Should search recursively by default when no path is provided' {
        Find-CmObject -Class 'Policy'
        Should -Invoke -CommandName 'Invoke-TrustRestMethod' -ModuleName $ModuleName -Times 1 -ParameterFilter { $Body.Recursive -eq 'true' }
    }
}
