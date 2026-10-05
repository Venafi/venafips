BeforeAll {
    . $PSScriptRoot/ModuleCommonCm.ps1

    $testFullPath = '\VED\Policy'

    $mockResponse = [pscustomobject]@{
        content = '{"Certificates":[]}'
        Headers = @{ 'X-Record-Count' = @('0') }
    }
}

Describe 'Find-CmCertificate' -Tags 'Unit' {

    BeforeEach {
        Mock -CommandName 'ConvertTo-CmFullPath' -MockWith { $testFullPath } -ModuleName $ModuleName
        Mock -CommandName 'Invoke-TrustRestMethod' -MockWith { $mockResponse } -ModuleName $ModuleName
    }

    Context '-IsExpired and -ExpireBefore/-ExpireAfter conflict' {

        It 'Should throw when -IsExpired and -ExpireBefore are both provided' {
            { Find-CmCertificate -IsExpired -ExpireBefore (Get-Date) } |
                Should -Throw -ExpectedMessage '*-IsExpired and -ExpireBefore cannot be used together*'
        }

        It 'Should throw when -IsExpired:$false and -ExpireAfter are both provided' {
            { Find-CmCertificate -IsExpired:$false -ExpireAfter (Get-Date) } |
                Should -Throw -ExpectedMessage '*-IsExpired:$false and -ExpireAfter cannot be used together*'
        }

        It 'Should not call Invoke-TrustRestMethod when the conflicting combination is used' {
            { Find-CmCertificate -IsExpired -ExpireBefore (Get-Date) } | Should -Throw
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 0 -ModuleName $ModuleName
        }

        It 'Should not throw when only -IsExpired is provided' {
            { Find-CmCertificate -IsExpired } | Should -Not -Throw
        }

        It 'Should not throw when only -IsExpired:$false is provided' {
            { Find-CmCertificate -IsExpired:$false } | Should -Not -Throw
        }

        It 'Should not throw when only -ExpireBefore is provided' {
            { Find-CmCertificate -ExpireBefore (Get-Date) } | Should -Not -Throw
        }

        It 'Should not throw when only -ExpireAfter is provided' {
            { Find-CmCertificate -ExpireAfter (Get-Date) } | Should -Not -Throw
        }

        It 'Should not throw when -ExpireBefore and -ExpireAfter are both provided (date range)' {
            { Find-CmCertificate -ExpireAfter (Get-Date).AddDays(-30) -ExpireBefore (Get-Date) } | Should -Not -Throw
        }

        It 'Should set both ValidToGreater and ValidToLess for a date range query' {
            Find-CmCertificate -ExpireAfter (Get-Date).AddDays(-30) -ExpireBefore (Get-Date)
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.ContainsKey('ValidToGreater') -and $Body.ContainsKey('ValidToLess')
            }
        }

        It 'Should set ValidToLess when only -IsExpired is provided' {
            Find-CmCertificate -IsExpired
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.ContainsKey('ValidToLess') -and -not $Body.ContainsKey('ValidToGreater')
            }
        }

        It 'Should set ValidToGreater when only -IsExpired:$false is provided' {
            Find-CmCertificate -IsExpired:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.ContainsKey('ValidToGreater') -and -not $Body.ContainsKey('ValidToLess')
            }
        }
    }
}
