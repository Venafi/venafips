BeforeAll {
    . $PSScriptRoot/ModuleCommonTrust.ps1
}

Describe 'Export-TrustReport' -Tags 'Unit' {

    BeforeEach {
        $reportId = '11111111-1111-1111-1111-111111111111'
        Mock -CommandName 'Invoke-TrustGraphQL' -ModuleName $ModuleName -MockWith {
            [pscustomobject]@{ reportDownloadDetails = [pscustomobject]@{ url = 'https://download.example.com/report.csv' } }
        }
        # write with .net so the mock isn't affected by -WhatIf
        Mock -CommandName 'Invoke-WebRequest' -ModuleName $ModuleName -MockWith {
            [IO.File]::WriteAllText($OutFile, "name,count`r`nexpiring,3`r`n")
        }
    }

    Context 'WhatIf' {

        It 'Should return the report when the caller has WhatIf on and no OutPath is provided' {
            try {
                $global:WhatIfPreference = $true
                $result = Export-TrustReport -Report $reportId
            }
            finally {
                $global:WhatIfPreference = $false
            }

            # the report is downloaded to a temporary file first, so this fails if the temporary file is not created
            $result.name | Should -Be 'expiring'
        }

        It 'Should not write the report to OutPath with -WhatIf' {
            Export-TrustReport -Report $reportId -OutPath $TestDrive -WhatIf

            Should -Invoke -CommandName 'Invoke-WebRequest' -ModuleName $ModuleName -Times 0 -Exactly
            Join-Path $TestDrive "$reportId.csv" | Should -Not -Exist
        }

        It 'Should write the report to OutPath with -WhatIf:$false when the caller has WhatIf on' {
            try {
                $global:WhatIfPreference = $true
                Export-TrustReport -Report $reportId -OutPath $TestDrive -WhatIf:$false
            }
            finally {
                $global:WhatIfPreference = $false
            }

            Join-Path $TestDrive "$reportId.csv" | Should -Exist
        }
    }
}
