BeforeAll {
    . $PSScriptRoot/ModuleCommonCm.ps1
}

Describe 'Export-CmVaultObject' -Tags 'Unit' {

    BeforeEach {
        Mock -CommandName 'Invoke-TrustRestMethod' -ModuleName $ModuleName -MockWith {
            [pscustomobject]@{ Result = 0; VaultType = 2; Base64Data = 'MIIBdummy' }
        }
    }

    Context 'WhatIf' {

        It 'Should return the vault object when the caller has WhatIf on and no OutPath is provided' {
            try {
                $global:WhatIfPreference = $true
                $result = Export-CmVaultObject -ID 12345
            }
            finally {
                $global:WhatIfPreference = $false
            }

            $result.Format | Should -Be 'X509'
        }

        It 'Should not write any file to OutPath with -WhatIf' {
            Export-CmVaultObject -ID 12345, 67890 -OutPath $TestDrive -WhatIf

            @(Get-ChildItem -Path $TestDrive -File) | Should -HaveCount 0
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -ModuleName $ModuleName -Times 2 -Exactly
        }

        It 'Should write every file to OutPath with -WhatIf:$false when the caller has WhatIf on' {
            try {
                $global:WhatIfPreference = $true
                Export-CmVaultObject -ID 12345, 67890 -OutPath $TestDrive -WhatIf:$false
            }
            finally {
                $global:WhatIfPreference = $false
            }

            (Get-ChildItem -Path $TestDrive -File).Name | Sort-Object | Should -Be @('12345.cer', '67890.cer')
        }
    }
}
