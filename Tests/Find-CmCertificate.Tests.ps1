BeforeAll {
    . $PSScriptRoot/ModuleCommonCm.ps1

    $testFullPath = '\VED\Policy'

    # Find-CmCertificate reads this header differently depending on engine:
    # PS 5.1 (Windows PowerShell) casts the value directly, PS 6+ indexes into it as an array.
    # Match both real-world shapes so the mock doesn't throw on either engine.
    $mockResponse = [pscustomobject]@{
        content = '{"Certificates":[]}'
        Headers = if ($PSVersionTable.PSVersion.Major -lt 6) {
            @{ 'X-Record-Count' = '0' }
        }
        else {
            @{ 'X-Record-Count' = @('0') }
        }
    }
}

Describe 'Find-CmCertificate' -Tags 'Unit' {

    BeforeEach {
        Mock -CommandName 'ConvertTo-CmFullPath' -MockWith { $testFullPath } -ModuleName $ModuleName
        Mock -CommandName 'Invoke-TrustRestMethod' -MockWith { $mockResponse } -ModuleName $ModuleName
    }

    Context 'Conflicting combinations (new validation)' {

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
    }

    Context 'Non-conflicting combinations (must remain unaffected by the fix)' {

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

        It 'Should not throw for the cross combination -IsExpired and -ExpireAfter (different filter keys)' {
            { Find-CmCertificate -IsExpired -ExpireAfter (Get-Date).AddDays(-30) } | Should -Not -Throw
        }

        It 'Should not throw for the cross combination -IsExpired:$false and -ExpireBefore (different filter keys)' {
            { Find-CmCertificate -IsExpired:$false -ExpireBefore (Get-Date) } | Should -Not -Throw
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

        It 'Should set both ValidToLess (from IsExpired) and ValidToGreater (from ExpireAfter) for the cross combination' {
            Find-CmCertificate -IsExpired -ExpireAfter (Get-Date).AddDays(-30)
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.ContainsKey('ValidToGreater') -and $Body.ContainsKey('ValidToLess')
            }
        }
    }
}
