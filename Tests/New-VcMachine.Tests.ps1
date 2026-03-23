BeforeAll {
    . $PSScriptRoot/ModuleCommonVc.ps1

    # Ensure ConvertTo-SodiumEncryptedString is available in the module scope for mocking
    # PSSodium may not be installed (e.g., CI runners)
    InModuleScope $ModuleName {
        if (-not (Get-Command 'ConvertTo-SodiumEncryptedString' -ErrorAction SilentlyContinue)) {
            function script:ConvertTo-SodiumEncryptedString { param($Text, $PublicKey) }
        }
    }

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

    # This is the shape returned by Invoke-VenafiParallel after the scriptblock runs
    $mockParallelResponseNoVerify = [pscustomobject]@{
        machineId        = $testMachineId
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

    $mockParallelResponseWithVerify = [pscustomobject]@{
        machineId      = $testMachineId
        testConnection = [pscustomobject]@{
            Success    = $true
            Error      = $null
            WorkflowID = 'c39310ee-51fc-49f3-8b5b-e504e1bc43d2'
        }
        name           = 'c1'
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
        # Mock Invoke-VenafiParallel to avoid needing Invoke-VenafiRestMethod/Invoke-VcWorkflow inside scriptblock
        Mock -CommandName 'Invoke-VenafiParallel' -MockWith { $mockParallelResponseWithVerify } -ModuleName $ModuleName
    }

    Context 'Basic machine creation' {

        It 'Should call Invoke-VenafiParallel with VenafiSession' {
            $cred = New-Object PSCredential('user', ('pass' | ConvertTo-SecureString -AsPlainText -Force))
            New-VcMachine -Name 'c1' -MachineType 'Citrix ADC' -Owner 'MyTeam' -Credential $cred
            Should -Invoke -CommandName 'Invoke-VenafiParallel' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $null -ne $VenafiSession
            }
        }

        It 'Should pass machine data to Invoke-VenafiParallel' {
            $cred = New-Object PSCredential('user', ('pass' | ConvertTo-SecureString -AsPlainText -Force))
            New-VcMachine -Name 'c1' -MachineType 'Citrix ADC' -Owner 'MyTeam' -Credential $cred
            Should -Invoke -CommandName 'Invoke-VenafiParallel' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $InputObject.Count -eq 1 -and $InputObject[0].name -eq 'c1'
            }
        }

        It 'Should set pluginId from machine type lookup' {
            $cred = New-Object PSCredential('user', ('pass' | ConvertTo-SecureString -AsPlainText -Force))
            New-VcMachine -Name 'c1' -MachineType 'Citrix ADC' -Owner 'MyTeam' -Credential $cred
            Should -Invoke -CommandName 'Invoke-VenafiParallel' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $InputObject[0].pluginId -eq $testPluginId
            }
        }
    }

    Context 'PassThru' {

        It 'Should not return output without PassThru' {
            $cred = New-Object PSCredential('user', ('pass' | ConvertTo-SecureString -AsPlainText -Force))
            $result = New-VcMachine -Name 'c1' -MachineType 'Citrix ADC' -Owner 'MyTeam' -Credential $cred
            $result | Should -BeNullOrEmpty
        }

        It 'Should return machine details with PassThru' {
            $cred = New-Object PSCredential('user', ('pass' | ConvertTo-SecureString -AsPlainText -Force))
            $result = New-VcMachine -Name 'c1' -MachineType 'Citrix ADC' -Owner 'MyTeam' -Credential $cred -PassThru
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
            } | New-VcMachine
            Should -Invoke -CommandName 'Invoke-VenafiParallel' -Times 1 -ModuleName $ModuleName
        }
    }
}
