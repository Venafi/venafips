BeforeAll {
    . $PSScriptRoot/ModuleCommonCm.ps1
}

Describe 'Export-CmCertificate' -Tags 'Unit' {

    BeforeEach {
        Mock -CommandName 'Invoke-SessionRefresh' -ModuleName $ModuleName -MockWith {}
        Mock -CommandName 'Invoke-TrustRestMethod' -ModuleName $ModuleName -MockWith {
            [pscustomobject]@{
                CertificateData = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("-----BEGIN CERTIFICATE-----`nMIIBdummy`n-----END CERTIFICATE-----"))
                FileName        = '"test.company.com.cer"'
                Format          = 'Base64'
            }
        }
    }

    Context 'WhatIf' {

        It 'Should return the certificate when the caller has WhatIf on and no OutPath is provided' {
            try {
                $global:WhatIfPreference = $true
                $result = Export-CmCertificate -Path '\VED\Policy\test.company.com' -X509
            }
            finally {
                $global:WhatIfPreference = $false
            }

            $result.CertificateData | Should -Not -BeNullOrEmpty
        }

        It 'Should not export to OutPath with -WhatIf' {
            Export-CmCertificate -Path '\VED\Policy\test.company.com' -X509 -OutPath $TestDrive -WhatIf

            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -ModuleName $ModuleName -Times 0 -Exactly
            @(Get-ChildItem -Path $TestDrive -File) | Should -HaveCount 0
        }

        It 'Should export to OutPath with -WhatIf:$false when the caller has WhatIf on' {
            try {
                $global:WhatIfPreference = $true
                Export-CmCertificate -Path '\VED\Policy\test.company.com' -X509 -OutPath $TestDrive -WhatIf:$false
            }
            finally {
                $global:WhatIfPreference = $false
            }

            Join-Path $TestDrive 'test.company.com.cer' | Should -Exist
        }
    }
}
