BeforeAll {
    . $PSScriptRoot/ModuleCommonVc.ps1

    $testMachineId = 'cf7cfdc0-2b2a-11ee-9546-5136c4b21504'
    $testTeamId = '59920180-a3e2-11ec-8dcd-3fcbf84c7da7'
    $testPluginId = 'ff645e14-bd1a-11ed-a009-ce063932f86d'
    $testVsatId = '0bc771e1-7abe-4339-9fcd-93fffe9cba7f'
    $testEncKeyId = 'aaaa1111-bbbb-2222-cccc-333344445555'
    $testEncKey = 'dGVzdGVuY3J5cHRpb25rZXk='

    $mockPlugin = [pscustomobject]@{
        pluginId = $testPluginId
        name     = 'Citrix ADC'
    }

    $mockVSat = [pscustomobject]@{
        vsatelliteId    = $testVsatId
        encryptionKeyId = $testEncKeyId
        encryptionKey   = $testEncKey
        edgeStatus      = 'ACTIVE'
    }

    $mockCreateResponse = [pscustomobject]@{
        id               = $testMachineId
        companyId        = '20b24f81-b22b-11ea-91f3-ebd6dea5453f'
        name             = 'c1'
        machineType      = 'Citrix ADC'
        pluginId         = $testPluginId
        integrationId    = 'cf7c8014-2b2a-11ee-9a03-fa8930555887'
        edgeInstanceId   = $testVsatId
        creationDate     = (Get-Date).ToString('o')
        modificationDate = (Get-Date).ToString('o')
        status           = 'UNVERIFIED'
        owningTeamId     = $testTeamId
    }

    $mockWorkflowResponse = [pscustomobject]@{
        Success    = $true
        Error      = $null
        WorkflowID = 'c39310ee-51fc-49f3-8b5b-e504e1bc43d2'
    }
}

Describe 'New-VcMachine' -Tags 'Unit' {

    BeforeEach {
        Mock -CommandName 'Test-VenafiSession' -MockWith {} -ModuleName $ModuleName
        Mock -CommandName 'Initialize-PSSodium' -MockWith {} -ModuleName $ModuleName
        Mock -CommandName 'Get-VcData' -ParameterFilter { $Type -eq 'Plugin' } -MockWith { $mockPlugin } -ModuleName $ModuleName
        Mock -CommandName 'Get-VcData' -ParameterFilter { $Type -eq 'Team' } -MockWith { $testTeamId } -ModuleName $ModuleName
        Mock -CommandName 'Get-VcData' -ParameterFilter { $Type -eq 'VSatellite' } -MockWith { $mockVSat } -ModuleName $ModuleName
        Mock -CommandName 'ConvertTo-SodiumEncryptedString' -MockWith { 'encrypted' } -ModuleName $ModuleName
        Mock -CommandName 'Invoke-VenafiRestMethod' -MockWith { $mockCreateResponse } -ModuleName $ModuleName
        Mock -CommandName 'Invoke-VcWorkflow' -MockWith { $mockWorkflowResponse } -ModuleName $ModuleName
    }

    Context 'Basic machine creation' {

        It 'Should call the create API' {
            $cred = New-Object PSCredential('user', ('pass' | ConvertTo-SecureString -AsPlainText -Force))
            New-VcMachine -Name 'c1' -MachineType 'Citrix ADC' -Owner 'MyTeam' -Credential $cred
            Should -Invoke -CommandName 'Invoke-VenafiRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Method -eq 'Post' -and $UriLeaf -eq 'machines'
            }
        }

        It 'Should use hostname as name when hostname not provided' {
            $cred = New-Object PSCredential('user', ('pass' | ConvertTo-SecureString -AsPlainText -Force))
            New-VcMachine -Name 'c1.company.com' -MachineType 'Citrix ADC' -Owner 'MyTeam' -Credential $cred
            Should -Invoke -CommandName 'Invoke-VenafiRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.connectionDetails.hostnameOrAddress -eq 'c1.company.com'
            }
        }

        It 'Should use explicit hostname when provided' {
            $cred = New-Object PSCredential('user', ('pass' | ConvertTo-SecureString -AsPlainText -Force))
            New-VcMachine -Name 'c1' -MachineType 'Citrix ADC' -Owner 'MyTeam' -Hostname 'c1.company.com' -Credential $cred
            Should -Invoke -CommandName 'Invoke-VenafiRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.connectionDetails.hostnameOrAddress -eq 'c1.company.com'
            }
        }
    }

    Context 'Test connection' {

        It 'Should invoke test workflow by default' {
            $cred = New-Object PSCredential('user', ('pass' | ConvertTo-SecureString -AsPlainText -Force))
            New-VcMachine -Name 'c1' -MachineType 'Citrix ADC' -Owner 'MyTeam' -Credential $cred
            Should -Invoke -CommandName 'Invoke-VcWorkflow' -Times 1 -ModuleName $ModuleName
        }

        It 'Should skip test workflow with NoVerify' {
            $cred = New-Object PSCredential('user', ('pass' | ConvertTo-SecureString -AsPlainText -Force))
            New-VcMachine -Name 'c1' -MachineType 'Citrix ADC' -Owner 'MyTeam' -Credential $cred -NoVerify
            Should -Invoke -CommandName 'Invoke-VcWorkflow' -Times 0 -ModuleName $ModuleName
        }
    }

    Context 'PassThru' {

        It 'Should not return output without PassThru' {
            $cred = New-Object PSCredential('user', ('pass' | ConvertTo-SecureString -AsPlainText -Force))
            $result = New-VcMachine -Name 'c1' -MachineType 'Citrix ADC' -Owner 'MyTeam' -Credential $cred -NoVerify
            $result | Should -BeNullOrEmpty
        }

        It 'Should return machine details with PassThru' {
            $cred = New-Object PSCredential('user', ('pass' | ConvertTo-SecureString -AsPlainText -Force))
            $result = New-VcMachine -Name 'c1' -MachineType 'Citrix ADC' -Owner 'MyTeam' -Credential $cred -NoVerify -PassThru
            $result | Should -Not -BeNullOrEmpty
            $result.machineId | Should -Be $testMachineId
        }
    }

    Context 'Invalid input' {

        It 'Should error on invalid machine type' {
            Mock -CommandName 'Get-VcData' -ParameterFilter { $Type -eq 'Plugin' } -MockWith { $null } -ModuleName $ModuleName
            $cred = New-Object PSCredential('user', ('pass' | ConvertTo-SecureString -AsPlainText -Force))
            New-VcMachine -Name 'c1' -MachineType 'BadType' -Owner 'MyTeam' -Credential $cred -ErrorVariable err -ErrorAction SilentlyContinue
            $err | Should -Not -BeNullOrEmpty
        }

        It 'Should error on invalid owner' {
            Mock -CommandName 'Get-VcData' -ParameterFilter { $Type -eq 'Team' } -MockWith { $null } -ModuleName $ModuleName
            $cred = New-Object PSCredential('user', ('pass' | ConvertTo-SecureString -AsPlainText -Force))
            New-VcMachine -Name 'c1' -MachineType 'Citrix ADC' -Owner 'BadTeam' -Credential $cred -ErrorVariable err -ErrorAction SilentlyContinue
            $err | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Pipeline input' {

        It 'Should accept pipeline input' {
            $cred = New-Object PSCredential('user', ('pass' | ConvertTo-SecureString -AsPlainText -Force))
            [pscustomobject]@{
                Name        = 'c1'
                MachineType = 'Citrix ADC'
                Owner       = 'MyTeam'
                Credential  = $cred
            } | New-VcMachine -NoVerify
            Should -Invoke -CommandName 'Invoke-VenafiRestMethod' -Times 1 -ModuleName $ModuleName
        }
    }
}
