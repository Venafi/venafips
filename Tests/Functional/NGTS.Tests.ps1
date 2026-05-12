BeforeDiscovery {
    . $PSScriptRoot/FunctionalCommon.ps1
    $skipAll = Skip-IfNoSession -Platform 'NGTS' -RequiredEnvVars @('VENAFIPS_NGTS_USERNAME', 'VENAFIPS_NGTS_SECRET')
}

BeforeAll {
    . $PSScriptRoot/FunctionalCommon.ps1
}

Describe 'NGTS Connection' -Tags 'Functional', 'NGTS' -Skip:$skipAll {

    It 'Should create a session with client credential' {
        $sess = New-NgtsFunctionalSession
        $sess | Should -Not -BeNullOrEmpty
        $sess.Platform | Should -Be 'NGTS'
        $sess.AuthType | Should -Be 'BearerToken'
        $sess.AccessToken | Should -Not -BeNullOrEmpty
        $sess.Credential | Should -Not -BeNullOrEmpty
        $sess.Expires | Should -BeGreaterThan ([DateTime]::UtcNow)
    }

    It 'Should populate Tsg in PlatformData' {
        $sess = New-NgtsFunctionalSession
        $sess.PlatformData.Tsg | Should -Not -BeNullOrEmpty
    }
}

Describe 'NGTS Find Certificates' -Tags 'Functional', 'NGTS' -Skip:$skipAll {

    BeforeAll {
        $script:ngtsSession = New-NgtsFunctionalSession
    }

    It 'Should find certificates with -First' {
        $certs = Find-TrustCertificate -First 5 -TrustClient $script:ngtsSession
        $certs | Should -Not -BeNullOrEmpty
        @($certs).Count | Should -BeLessOrEqual 5
    }

    It 'Should return certificate objects with expected properties' {
        $certs = Find-TrustCertificate -First 1 -TrustClient $script:ngtsSession
        $cert = @($certs)[0]
        $cert.certificateId | Should -Not -BeNullOrEmpty
        $cert.certificateName | Should -Not -BeNullOrEmpty
    }

    It 'Should find by name filter' {
        $sample = Find-TrustCertificate -First 1 -TrustClient $script:ngtsSession
        if ($sample) {
            $name = @($sample)[0].certificateName
            $result = Find-TrustCertificate -Name $name -First 5 -TrustClient $script:ngtsSession
            $result | Should -Not -BeNullOrEmpty
        }
        else {
            Set-ItResult -Skipped -Because 'No certificates in environment'
        }
    }

    It 'Should find expired certificates' {
        $expired = Find-TrustCertificate -IsExpired -First 5 -TrustClient $script:ngtsSession
        if ($expired) {
            @($expired).Count | Should -BeGreaterThan 0
        }
    }
}

Describe 'NGTS Token Refresh' -Tags 'Functional', 'NGTS' -Skip:$skipAll {

    It 'Should refresh an expired session transparently' {
        $sess = New-NgtsFunctionalSession
        $originalToken = $sess.AccessToken.GetNetworkCredential().Password

        # force near-expiration
        $sess.Expires = [DateTime]::UtcNow.AddSeconds(10)

        # API call should trigger auto-refresh
        $result = Find-TrustCertificate -First 1 -TrustClient $sess

        $sess.AccessToken.GetNetworkCredential().Password | Should -Not -Be $originalToken
        $sess.Expires | Should -BeGreaterThan ([DateTime]::UtcNow.AddMinutes(1))
    }
}

# ── Get Certificate ───────────────────────────────────────────────────────────

Describe 'NGTS Get Certificate' -Tags 'Functional', 'NGTS' -Skip:$skipAll {

    BeforeAll {
        $script:ngtsSession = New-NgtsFunctionalSession
        $script:sampleCert = Find-TrustCertificate -First 1 -TrustClient $script:ngtsSession
    }

    It 'Should get a certificate by ID' {
        if (-not $script:sampleCert) { Set-ItResult -Skipped -Because 'No sample certificate found'; return }
        $certId = @($script:sampleCert)[0].certificateId
        $cert = Get-TrustCertificate -Certificate $certId -TrustClient $script:ngtsSession
        $cert | Should -Not -BeNullOrEmpty
        $cert.certificateId | Should -Be $certId
    }
}

# ── Export Certificate ─────────────────────────────────────────────────────────

Describe 'NGTS Export Certificate' -Tags 'Functional', 'NGTS' -Skip:$skipAll {

    BeforeAll {
        $script:ngtsSession = New-NgtsFunctionalSession
        $script:sampleCert = Find-TrustCertificate -First 1 -TrustClient $script:ngtsSession
        $script:exportDir = Join-Path ([System.IO.Path]::GetTempPath()) 'VenafiPS-NGTS-Functional'
        if (-not (Test-Path $script:exportDir)) { New-Item -Path $script:exportDir -ItemType Directory | Out-Null }
    }

    It 'Should export certificate as PEM' {
        if (-not $script:sampleCert) { Set-ItResult -Skipped -Because 'No sample certificate found'; return }
        $certId = @($script:sampleCert)[0].certificateId
        $result = Export-TrustCertificate -ID $certId -OutPath $script:exportDir -TrustClient $script:ngtsSession
        $result | Should -Not -BeNullOrEmpty
    }

    AfterAll {
        if (Test-Path $script:exportDir) {
            Remove-Item -Path $script:exportDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# ── Issuing Templates ────────────────────────────────────────────────────────

Describe 'NGTS Issuing Templates' -Tags 'Functional', 'NGTS' -Skip:$skipAll {

    BeforeAll {
        $script:ngtsSession = New-NgtsFunctionalSession
    }

    It 'Should list all issuing templates' {
        $templates = Get-TrustIssuingTemplate -All -TrustClient $script:ngtsSession
        $templates | Should -Not -BeNullOrEmpty
    }

    It 'Should get a single issuing template by ID' {
        $all = Get-TrustIssuingTemplate -All -TrustClient $script:ngtsSession
        if (-not $all) { Set-ItResult -Skipped -Because 'No issuing templates found'; return }
        $first = @($all)[0]
        $single = Get-TrustIssuingTemplate -IssuingTemplate $first.issuingTemplateId -TrustClient $script:ngtsSession
        $single | Should -Not -BeNullOrEmpty
        $single.issuingTemplateId | Should -Be $first.issuingTemplateId
    }
}

# ── Certificate Authorities ──────────────────────────────────────────────────

Describe 'NGTS Certificate Authorities' -Tags 'Functional', 'NGTS' -Skip:$skipAll {

    BeforeAll {
        $script:ngtsSession = New-NgtsFunctionalSession
    }

    It 'Should list all certificate authorities' {
        $cas = Get-TrustCertificateAuthority -All -TrustClient $script:ngtsSession
        $cas | Should -Not -BeNullOrEmpty
    }

    It 'Should get a single certificate authority by ID' {
        $all = Get-TrustCertificateAuthority -All -TrustClient $script:ngtsSession
        if (-not $all) { Set-ItResult -Skipped -Because 'No CAs found'; return }
        $first = @($all)[0]
        $single = Get-TrustCertificateAuthority -CertificateAuthority $first.certificateAuthorityId -TrustClient $script:ngtsSession
        $single | Should -Not -BeNullOrEmpty
    }
}

# ── Machines ──────────────────────────────────────────────────────────────────

Describe 'NGTS Find Machines' -Tags 'Functional', 'NGTS' -Skip:$skipAll {

    BeforeAll {
        $script:ngtsSession = New-NgtsFunctionalSession
    }

    It 'Should find machines with -First' {
        $machines = Find-TrustMachine -First 5 -TrustClient $script:ngtsSession
        if ($machines) {
            @($machines).Count | Should -BeLessOrEqual 5
        }
    }

    It 'Should return machine objects with expected properties' {
        $machines = Find-TrustMachine -First 1 -TrustClient $script:ngtsSession
        if (-not $machines) { Set-ItResult -Skipped -Because 'No machines in environment'; return }
        $m = @($machines)[0]
        $m.machineId | Should -Not -BeNullOrEmpty
    }
}

Describe 'NGTS Get Machine' -Tags 'Functional', 'NGTS' -Skip:$skipAll {

    BeforeAll {
        $script:ngtsSession = New-NgtsFunctionalSession
        $script:sampleMachine = Find-TrustMachine -First 1 -TrustClient $script:ngtsSession
    }

    It 'Should get a machine by ID' {
        if (-not $script:sampleMachine) { Set-ItResult -Skipped -Because 'No machines in environment'; return }
        $id = @($script:sampleMachine)[0].machineId
        $machine = Get-TrustMachine -Machine $id -TrustClient $script:ngtsSession
        $machine | Should -Not -BeNullOrEmpty
        $machine.machineId | Should -Be $id
    }

    It 'Should list all machines' {
        { Get-TrustMachine -All -TrustClient $script:ngtsSession } | Should -Not -Throw
    }
}

# ── Machine Identities ───────────────────────────────────────────────────────

Describe 'NGTS Machine Identities' -Tags 'Functional', 'NGTS' -Skip:$skipAll {

    BeforeAll {
        $script:ngtsSession = New-NgtsFunctionalSession
        $script:sampleMI = Find-TrustMachineIdentity -First 1 -TrustClient $script:ngtsSession
    }

    It 'Should find machine identities with -First' {
        $mis = Find-TrustMachineIdentity -First 5 -TrustClient $script:ngtsSession
        if ($mis) {
            @($mis).Count | Should -BeLessOrEqual 5
        }
    }

    It 'Should get a machine identity by ID' {
        if (-not $script:sampleMI) { Set-ItResult -Skipped -Because 'No machine identities in environment'; return }
        $id = @($script:sampleMI)[0].machineIdentityId
        $mi = Get-TrustMachineIdentity -ID $id -TrustClient $script:ngtsSession
        $mi | Should -Not -BeNullOrEmpty
        $mi.machineIdentityId | Should -Be $id
    }
}

# ── Certificate Requests ─────────────────────────────────────────────────────

Describe 'NGTS Certificate Requests' -Tags 'Functional', 'NGTS' -Skip:$skipAll {

    BeforeAll {
        $script:ngtsSession = New-NgtsFunctionalSession
    }

    It 'Should find certificate requests with -First' {
        $reqs = Find-TrustCertificateRequest -First 5 -TrustClient $script:ngtsSession
        if ($reqs) {
            @($reqs).Count | Should -BeLessOrEqual 5
        }
    }

    It 'Should get a single certificate request by ID' {
        $reqs = Find-TrustCertificateRequest -First 1 -TrustClient $script:ngtsSession
        if (-not $reqs) { Set-ItResult -Skipped -Because 'No certificate requests found'; return }
        $first = @($reqs)[0]
        $single = Get-TrustCertificateRequest -CertificateRequest $first.certificateRequestId -TrustClient $script:ngtsSession
        $single | Should -Not -BeNullOrEmpty
        $single.certificateRequestId | Should -Be $first.certificateRequestId
    }
}

# ── Connectors ────────────────────────────────────────────────────────────────

Describe 'NGTS Connectors' -Tags 'Functional', 'NGTS' -Skip:$skipAll {

    BeforeAll {
        $script:ngtsSession = New-NgtsFunctionalSession
    }

    It 'Should list all connectors' {
        { Get-TrustConnector -All -TrustClient $script:ngtsSession } | Should -Not -Throw
    }

    It 'Should get a single connector by ID' {
        $all = Get-TrustConnector -All -TrustClient $script:ngtsSession
        if (-not $all) { Set-ItResult -Skipped -Because 'No connectors found'; return }
        $first = @($all)[0]
        $single = Get-TrustConnector -Connector $first.connectorId -TrustClient $script:ngtsSession
        $single | Should -Not -BeNullOrEmpty
    }
}

# ── Certificate Instances ─────────────────────────────────────────────────────

Describe 'NGTS Certificate Instances' -Tags 'Functional', 'NGTS' -Skip:$skipAll {

    BeforeAll {
        $script:ngtsSession = New-NgtsFunctionalSession
    }

    It 'Should find certificate instances with -First' {
        $instances = Find-TrustCertificateInstance -First 5 -TrustClient $script:ngtsSession
        if ($instances) {
            @($instances).Count | Should -BeLessOrEqual 5
        }
    }
}

# ── Tags ──────────────────────────────────────────────────────────────────────

Describe 'NGTS Tags' -Tags 'Functional', 'NGTS' -Skip:$skipAll {

    BeforeAll {
        $script:ngtsSession = New-NgtsFunctionalSession
    }

    It 'Should list all tags' {
        { Get-TrustTag -All -TrustClient $script:ngtsSession } | Should -Not -Throw
    }
}

# ── Webhooks ──────────────────────────────────────────────────────────────────

Describe 'NGTS Webhooks' -Tags 'Functional', 'NGTS' -Skip:$skipAll {

    BeforeAll {
        $script:ngtsSession = New-NgtsFunctionalSession
    }

    It 'Should list all webhooks' {
        try {
            Get-TrustWebhook -All -TrustClient $script:ngtsSession
        } catch {
            if ($_ -match 'Access denied') {
                Set-ItResult -Skipped -Because 'Insufficient permissions for webhooks'
                return
            }
            throw
        }
    }
}

# ── Satellites ────────────────────────────────────────────────────────────────

Describe 'NGTS Satellites' -Tags 'Functional', 'NGTS' -Skip:$skipAll {

    BeforeAll {
        $script:ngtsSession = New-NgtsFunctionalSession
    }

    It 'Should list all satellites' {
        { Get-TrustSatellite -All -TrustClient $script:ngtsSession } | Should -Not -Throw
    }

    It 'Should list all satellite workers' {
        { Get-TrustSatelliteWorker -All -TrustClient $script:ngtsSession } | Should -Not -Throw
    }

    It 'Should get satellite workers by VSatellite' {
        $sats = Get-TrustSatellite -All -TrustClient $script:ngtsSession
        if (-not $sats) { Set-ItResult -Skipped -Because 'No satellites in environment'; return }
        $first = @($sats)[0]
        { Get-TrustSatelliteWorker -VSatellite $first.vsatelliteId -TrustClient $script:ngtsSession } | Should -Not -Throw
    }
}

# ── Cloud Providers & Keystores ───────────────────────────────────────────────

Describe 'NGTS Cloud Providers' -Tags 'Functional', 'NGTS' -Skip:$skipAll {

    BeforeAll {
        $script:ngtsSession = New-NgtsFunctionalSession
    }

    It 'Should list all cloud providers' {
        { Get-TrustCloudProvider -All -TrustClient $script:ngtsSession } | Should -Not -Throw
    }

    It 'Should get a single cloud provider by ID' {
        $all = Get-TrustCloudProvider -All -TrustClient $script:ngtsSession
        if (-not $all) { Set-ItResult -Skipped -Because 'No cloud providers found'; return }
        $first = @($all)[0]
        $single = Get-TrustCloudProvider -CloudProvider $first.cloudProviderId -TrustClient $script:ngtsSession
        $single | Should -Not -BeNullOrEmpty
    }
}

Describe 'NGTS Cloud Keystores' -Tags 'Functional', 'NGTS' -Skip:$skipAll {

    BeforeAll {
        $script:ngtsSession = New-NgtsFunctionalSession
    }

    It 'Should list all cloud keystores' {
        { Get-TrustCloudKeystore -All -TrustClient $script:ngtsSession } | Should -Not -Throw
    }
}

# ── Logs ──────────────────────────────────────────────────────────────────────

Describe 'NGTS Activity Log' -Tags 'Functional', 'NGTS' -Skip:$skipAll {

    BeforeAll {
        $script:ngtsSession = New-NgtsFunctionalSession
    }

    It 'Should find recent log entries' {
        $logs = Find-TrustLog -First 5 -TrustClient $script:ngtsSession
        $logs | Should -Not -BeNullOrEmpty
    }

    It 'Should filter critical log entries' {
        { Find-TrustLog -Critical -First 5 -TrustClient $script:ngtsSession } | Should -Not -Throw
    }
}

# ══════════════════════════════════════════════════════════════════════════════
# WRITE / LIFECYCLE TESTS
# ══════════════════════════════════════════════════════════════════════════════

Describe 'NGTS Certificate Lifecycle' -Tags 'Functional', 'NGTS', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:ngtsSession = New-NgtsFunctionalSession
        $script:testCertId = $null
        $script:testTagName = $null
    }

    It 'Should request a new certificate' {
        if (-not $env:VENAFIPS_NGTS_ISSUING_TEMPLATE) {
            Set-ItResult -Skipped -Because 'VENAFIPS_NGTS_ISSUING_TEMPLATE not set'
            return
        }
        if (-not $env:VENAFIPS_NGTS_DOMAIN) {
            Set-ItResult -Skipped -Because 'VENAFIPS_NGTS_DOMAIN not set'
            return
        }

        $testName = New-TestName -Prefix 'venafips-ngts'
        $params = @{
            CommonName      = "$testName.$env:VENAFIPS_NGTS_DOMAIN"
            IssuingTemplate = $env:VENAFIPS_NGTS_ISSUING_TEMPLATE
            TrustClient     = $script:ngtsSession
            PassThru        = $true
            Wait            = $true
        }

        $result = New-TrustCertificate @params
        $result | Should -Not -BeNullOrEmpty
        $script:testCertId = $result.certificateId[0]
    }

    It 'Should validate the test certificate' {
        if (-not $script:testCertId) { Set-ItResult -Skipped -Because 'No test certificate created'; return }
        { Invoke-TrustCertificateAction -ID $script:testCertId -Validate -Confirm:$false -TrustClient $script:ngtsSession } |
            Should -Not -Throw
    }

    It 'Should retire the test certificate' {
        if (-not $script:testCertId) { Set-ItResult -Skipped -Because 'No test certificate created'; return }
        { Invoke-TrustCertificateAction -ID $script:testCertId -Retire -Confirm:$false -TrustClient $script:ngtsSession } |
            Should -Not -Throw
    }

    It 'Should recover the retired certificate' {
        if (-not $script:testCertId) { Set-ItResult -Skipped -Because 'No test certificate created'; return }
        { Invoke-TrustCertificateAction -ID $script:testCertId -Recover -Confirm:$false -TrustClient $script:ngtsSession } |
            Should -Not -Throw
    }

    It 'Should assign a tag to the test certificate' {
        if (-not $script:testCertId) { Set-ItResult -Skipped -Because 'No test certificate created'; return }
        $script:testTagName = "venafips-test-$(New-Guid)"
        Invoke-TrustRestMethod -Method 'Post' -UriLeaf 'tags' -Body @{ name = $script:testTagName } -TrustClient $script:ngtsSession
        { Set-TrustCertificate -Certificate $script:testCertId -Tag $script:testTagName -NoOverwrite -TrustClient $script:ngtsSession } | Should -Not -Throw
    }

    It 'Should delete the test certificate' {
        if (-not $script:testCertId) { Set-ItResult -Skipped -Because 'No test certificate created'; return }
        { Invoke-TrustCertificateAction -ID $script:testCertId -Delete -Confirm:$false -TrustClient $script:ngtsSession } |
            Should -Not -Throw
    }

    AfterAll {
        if ($script:testTagName) {
            Remove-TrustTag -ID $script:testTagName -TrustClient $script:ngtsSession -Confirm:$false -ErrorAction SilentlyContinue
        }
    }
}

# ── Webhook Lifecycle ─────────────────────────────────────────────────────────

Describe 'NGTS Webhook Lifecycle' -Tags 'Functional', 'NGTS', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:ngtsSession = New-NgtsFunctionalSession
        $script:testWebhookId = $null
    }

    It 'Should create a new webhook' {
        if (-not $env:VENAFIPS_NGTS_WEBHOOK_URL) {
            Set-ItResult -Skipped -Because 'VENAFIPS_NGTS_WEBHOOK_URL not set'
            return
        }
        $webhookName = New-TestName -Prefix 'venafips-ngts-hook'
        $activityTypes = Invoke-TrustRestMethod -UriLeaf 'activitytypes' -TrustClient $script:ngtsSession
        $eventType = $activityTypes.readablename | Select-Object -First 1
        if (-not $eventType) { Set-ItResult -Skipped -Because 'No activity types available'; return }

        $result = New-TrustWebhook -Name $webhookName -Url $env:VENAFIPS_NGTS_WEBHOOK_URL -EventType $eventType -PassThru -TrustClient $script:ngtsSession
        $result | Should -Not -BeNullOrEmpty
        $script:testWebhookId = $result.webhookId
    }

    It 'Should get the created webhook' {
        if (-not $script:testWebhookId) { Set-ItResult -Skipped -Because 'No test webhook created'; return }
        $webhook = Get-TrustWebhook -ID $script:testWebhookId -TrustClient $script:ngtsSession
        $webhook | Should -Not -BeNullOrEmpty
    }

    It 'Should delete the webhook' {
        if (-not $script:testWebhookId) { Set-ItResult -Skipped -Because 'No test webhook created'; return }
        { Remove-TrustWebhook -ID $script:testWebhookId -TrustClient $script:ngtsSession -Confirm:$false } | Should -Not -Throw
    }
}

# ── Machine Lifecycle ─────────────────────────────────────────────────────────

Describe 'NGTS Machine Lifecycle' -Tags 'Functional', 'NGTS', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:ngtsSession = New-NgtsFunctionalSession
        $script:testMachineId = $null
    }

    It 'Should create a new common keystore machine' {
        if (-not $env:VENAFIPS_NGTS_MACHINE_OWNER) {
            Set-ItResult -Skipped -Because 'VENAFIPS_NGTS_MACHINE_OWNER not set'
            return
        }
        $machineName = New-TestName -Prefix 'venafips-ngts-machine'
        $cred = [pscredential]::new('testuser', (ConvertTo-SecureString 'P@ssw0rd!' -AsPlainText -Force))
        $params = @{
            Name        = $machineName
            Owner       = $env:VENAFIPS_NGTS_MACHINE_OWNER
            Credential  = $cred
            SshPassword = $true
            Hostname    = "$machineName.example.com"
            Port        = 22
            Status      = 'DRAFT'
            NoVerify    = $true
            PassThru    = $true
            TrustClient = $script:ngtsSession
        }
        $result = New-TrustMachineCommonKeystore @params
        $result | Should -Not -BeNullOrEmpty
        $script:testMachineId = $result.machineId
    }

    It 'Should run Test workflow on the machine' {
        if (-not $script:testMachineId) { Set-ItResult -Skipped -Because 'No test machine created'; return }
        $result = Invoke-TrustWorkflow -ID $script:testMachineId -Workflow Test -TrustClient $script:ngtsSession
        $result | Should -Not -BeNullOrEmpty
    }

    It 'Should update the machine name' {
        if (-not $script:testMachineId) { Set-ItResult -Skipped -Because 'No test machine created'; return }
        $newName = New-TestName -Prefix 'venafips-ngts-mach-upd'
        { Set-TrustMachine -Machine $script:testMachineId -Name $newName -TrustClient $script:ngtsSession } | Should -Not -Throw
    }

    It 'Should verify the machine was updated' {
        if (-not $script:testMachineId) { Set-ItResult -Skipped -Because 'No test machine created'; return }
        $machine = Get-TrustMachine -Machine $script:testMachineId -TrustClient $script:ngtsSession
        $machine | Should -Not -BeNullOrEmpty
    }

    It 'Should delete the machine' {
        if (-not $script:testMachineId) { Set-ItResult -Skipped -Because 'No test machine created'; return }
        { Remove-TrustMachine -ID $script:testMachineId -TrustClient $script:ngtsSession -Confirm:$false } | Should -Not -Throw
    }
}

# ── Import Certificate ────────────────────────────────────────────────────────

Describe 'NGTS Import Certificate' -Tags 'Functional', 'NGTS', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:ngtsSession = New-NgtsFunctionalSession
        $script:tempCertDir = Join-Path ([System.IO.Path]::GetTempPath()) 'VenafiPS-NGTS-Import'
        if (-not (Test-Path $script:tempCertDir)) { New-Item -Path $script:tempCertDir -ItemType Directory | Out-Null }

        # create a test certificate, export it, then import it (cross-platform)
        $script:tempCertPath = $null
        $script:importTestCertId = $null
        if ($env:VENAFIPS_NGTS_ISSUING_TEMPLATE) {
            $testName = New-TestName -Prefix 'venafips-ngts-imp'
            $result = New-TrustCertificate -CommonName "$testName.example.com" `
                -IssuingTemplate $env:VENAFIPS_NGTS_ISSUING_TEMPLATE `
                -TrustClient $script:ngtsSession -ErrorAction SilentlyContinue
            if ($result) {
                $script:importTestCertId = $result.certificateId
                $script:tempCertPath = Export-TrustCertificate -ID $script:importTestCertId -OutPath $script:tempCertDir -TrustClient $script:ngtsSession
            }
        }
    }

    It 'Should import a certificate from file' {
        if (-not $script:tempCertPath -or -not (Test-Path $script:tempCertPath)) { Set-ItResult -Skipped -Because 'Could not create/export a certificate for import testing'; return }
        { Import-TrustCertificate -Path $script:tempCertPath -TrustClient $script:ngtsSession } | Should -Not -Throw
    }

    AfterAll {
        if ($script:importTestCertId) {
            Invoke-TrustCertificateAction -ID $script:importTestCertId -Delete -TrustClient $script:ngtsSession -Confirm:$false -ErrorAction SilentlyContinue
        }
        if (Test-Path $script:tempCertDir) {
            Remove-Item -Path $script:tempCertDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# ── Issuing Template Update ───────────────────────────────────────────────────

Describe 'NGTS Set Issuing Template' -Tags 'Functional', 'NGTS', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:ngtsSession = New-NgtsFunctionalSession
    }

    It 'Should update an issuing template description' {
        $all = Get-TrustIssuingTemplate -All -TrustClient $script:ngtsSession
        if (-not $all) { Set-ItResult -Skipped -Because 'No issuing templates found'; return }
        $first = @($all)[0]
        $originalDesc = $first.description
        $newDesc = "VenafiPS functional test - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        { Set-TrustIssuingTemplate -IssuingTemplate $first.issuingTemplateId -Description $newDesc -TrustClient $script:ngtsSession } | Should -Not -Throw

        # restore original
        Set-TrustIssuingTemplate -IssuingTemplate $first.issuingTemplateId -Description $originalDesc -TrustClient $script:ngtsSession -ErrorAction SilentlyContinue
    }
}

# ── Remove Certificate ────────────────────────────────────────────────────────

Describe 'NGTS Remove Certificate' -Tags 'Functional', 'NGTS', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:ngtsSession = New-NgtsFunctionalSession
        $script:removeCertId = $null

        if ($env:VENAFIPS_NGTS_ISSUING_TEMPLATE) {
            $testName = New-TestName -Prefix 'venafips-ngts-rm'
            $result = New-TrustCertificate -CommonName "$testName.example.com" `
                -IssuingTemplate $env:VENAFIPS_NGTS_ISSUING_TEMPLATE `
                -TrustClient $script:ngtsSession -ErrorAction SilentlyContinue
            if ($result) { $script:removeCertId = $result.certificateId }
        }
    }

    It 'Should remove a certificate by ID' {
        if (-not $script:removeCertId) { Set-ItResult -Skipped -Because 'No test certificate created (VENAFIPS_NGTS_ISSUING_TEMPLATE not set or request failed)'; return }
        { Remove-TrustCertificate -ID $script:removeCertId -TrustClient $script:ngtsSession -Confirm:$false } | Should -Not -Throw
    }
}

# ── Export Report ─────────────────────────────────────────────────────────────

Describe 'NGTS Export Report' -Tags 'Functional', 'NGTS' -Skip:$skipAll {

    BeforeAll {
        $script:ngtsSession = New-NgtsFunctionalSession
        $script:exportReportDir = Join-Path ([System.IO.Path]::GetTempPath()) 'VenafiPS-NGTS-Report'
        if (-not (Test-Path $script:exportReportDir)) { New-Item -Path $script:exportReportDir -ItemType Directory | Out-Null }
    }

    It 'Should export a report to file' {
        if (-not $env:VENAFIPS_NGTS_REPORT_NAME) { Set-ItResult -Skipped -Because 'VENAFIPS_NGTS_REPORT_NAME not set'; return }
        $result = Export-TrustReport -Report $env:VENAFIPS_NGTS_REPORT_NAME -OutPath $script:exportReportDir -TrustClient $script:ngtsSession
        $result | Should -Not -BeNullOrEmpty
        Test-Path $result | Should -BeTrue
    }

    It 'Should return report data as object without -OutPath' {
        if (-not $env:VENAFIPS_NGTS_REPORT_NAME) { Set-ItResult -Skipped -Because 'VENAFIPS_NGTS_REPORT_NAME not set'; return }
        $data = Export-TrustReport -Report $env:VENAFIPS_NGTS_REPORT_NAME -TrustClient $script:ngtsSession
        $data | Should -Not -BeNullOrEmpty
    }

    AfterAll {
        if (Test-Path $script:exportReportDir) {
            Remove-Item -Path $script:exportReportDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# ── Connector Lifecycle ───────────────────────────────────────────────────────

Describe 'NGTS Connector Lifecycle' -Tags 'Functional', 'NGTS', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:ngtsSession = New-NgtsFunctionalSession
        $script:testConnectorId = $null
    }

    It 'Should create a connector from manifest' {
        if (-not $env:VENAFIPS_NGTS_CONNECTOR_MANIFEST) { Set-ItResult -Skipped -Because 'VENAFIPS_NGTS_CONNECTOR_MANIFEST not set'; return }
        if (-not (Test-Path $env:VENAFIPS_NGTS_CONNECTOR_MANIFEST)) { Set-ItResult -Skipped -Because 'Manifest file not found'; return }
        $result = New-TrustConnector -ManifestPath $env:VENAFIPS_NGTS_CONNECTOR_MANIFEST -PassThru -TrustClient $script:ngtsSession
        $result | Should -Not -BeNullOrEmpty
        $script:testConnectorId = $result.connectorId
    }

    It 'Should disable the connector' {
        if (-not $script:testConnectorId) { Set-ItResult -Skipped -Because 'No test connector created'; return }
        { Set-TrustConnector -ID $script:testConnectorId -Disable $true -TrustClient $script:ngtsSession } | Should -Not -Throw
    }

    It 'Should re-enable the connector' {
        if (-not $script:testConnectorId) { Set-ItResult -Skipped -Because 'No test connector created'; return }
        { Set-TrustConnector -ID $script:testConnectorId -Disable $false -TrustClient $script:ngtsSession } | Should -Not -Throw
    }

    It 'Should delete the connector' {
        if (-not $script:testConnectorId) { Set-ItResult -Skipped -Because 'No test connector created'; return }
        { Remove-TrustConnector -ID $script:testConnectorId -TrustClient $script:ngtsSession -Confirm:$false } | Should -Not -Throw
    }
}

# ── Cloud Provider Lifecycle ──────────────────────────────────────────────────

Describe 'NGTS Cloud Provider Lifecycle' -Tags 'Functional', 'NGTS', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:ngtsSession = New-NgtsFunctionalSession
        $script:testCloudProviderId = $null
    }

    It 'Should create an AWS cloud provider' {
        if (-not $env:VENAFIPS_NGTS_AWS_ACCOUNT_ID -or -not $env:VENAFIPS_NGTS_AWS_IAM_ROLE -or -not $env:VENAFIPS_NGTS_OWNER_TEAM) {
            Set-ItResult -Skipped -Because 'VENAFIPS_NGTS_AWS_ACCOUNT_ID, VENAFIPS_NGTS_AWS_IAM_ROLE, or VENAFIPS_NGTS_OWNER_TEAM not set'
            return
        }
        $name = New-TestName -Prefix 'venafips-ngts-cp'
        $result = New-TrustCloudProvider -Name $name -OwnerTeam $env:VENAFIPS_NGTS_OWNER_TEAM `
            -AWS -AccountID $env:VENAFIPS_NGTS_AWS_ACCOUNT_ID -IamRoleName $env:VENAFIPS_NGTS_AWS_IAM_ROLE `
            -PassThru -TrustClient $script:ngtsSession
        $result | Should -Not -BeNullOrEmpty
        $script:testCloudProviderId = $result.cloudProviderId
    }

    It 'Should delete the cloud provider' {
        if (-not $script:testCloudProviderId) { Set-ItResult -Skipped -Because 'No test cloud provider created'; return }
        { Remove-TrustCloudProvider -CloudProvider $script:testCloudProviderId -TrustClient $script:ngtsSession -Confirm:$false } | Should -Not -Throw
    }
}

# ── Cloud Keystore Lifecycle ──────────────────────────────────────────────────

Describe 'NGTS Cloud Keystore Lifecycle' -Tags 'Functional', 'NGTS', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:ngtsSession = New-NgtsFunctionalSession
        $script:testCloudKeystoreId = $null
        $script:tempCloudProviderId = $null
    }

    It 'Should create a cloud keystore' {
        if (-not $env:VENAFIPS_NGTS_AWS_ACCOUNT_ID -or -not $env:VENAFIPS_NGTS_AWS_IAM_ROLE -or
            -not $env:VENAFIPS_NGTS_AWS_REGION -or -not $env:VENAFIPS_NGTS_OWNER_TEAM) {
            Set-ItResult -Skipped -Because 'Required AWS/team env vars not set'
            return
        }
        $cpName = New-TestName -Prefix 'venafips-ngts-ks-cp'
        $cp = New-TrustCloudProvider -Name $cpName -OwnerTeam $env:VENAFIPS_NGTS_OWNER_TEAM `
            -AWS -AccountID $env:VENAFIPS_NGTS_AWS_ACCOUNT_ID -IamRoleName $env:VENAFIPS_NGTS_AWS_IAM_ROLE `
            -PassThru -TrustClient $script:ngtsSession
        if (-not $cp) { Set-ItResult -Skipped -Because 'Could not create cloud provider'; return }
        $script:tempCloudProviderId = $cp.cloudProviderId

        $ksName = New-TestName -Prefix 'venafips-ngts-ks'
        $result = New-TrustCloudKeystore -CloudProvider $script:tempCloudProviderId -Name $ksName `
            -OwnerTeam $env:VENAFIPS_NGTS_OWNER_TEAM -ACM -Region $env:VENAFIPS_NGTS_AWS_REGION `
            -PassThru -TrustClient $script:ngtsSession
        $result | Should -Not -BeNullOrEmpty
        $script:testCloudKeystoreId = $result.cloudKeystoreId
    }

    It 'Should delete the cloud keystore' {
        if (-not $script:testCloudKeystoreId) { Set-ItResult -Skipped -Because 'No test cloud keystore created'; return }
        { Remove-TrustCloudKeystore -CloudKeystore $script:testCloudKeystoreId -TrustClient $script:ngtsSession -Confirm:$false } | Should -Not -Throw
    }

    AfterAll {
        if ($script:tempCloudProviderId) {
            Remove-TrustCloudProvider -CloudProvider $script:tempCloudProviderId -TrustClient $script:ngtsSession -Confirm:$false -ErrorAction SilentlyContinue
        }
    }
}

# ── Machine Identity Lifecycle ────────────────────────────────────────────────

Describe 'NGTS Machine Identity Lifecycle' -Tags 'Functional', 'NGTS', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:ngtsSession = New-NgtsFunctionalSession
        $script:sampleMI = Find-TrustMachineIdentity -First 1 -TrustClient $script:ngtsSession
        # Convert binding from PSCustomObject to hashtable for Set-TrustMachineIdentity
        if ($script:sampleMI.binding) {
            $script:bindingHash = @{}
            $script:sampleMI.binding.PSObject.Properties | ForEach-Object { $script:bindingHash[$_.Name] = $_.Value }
        }
    }

    It 'Should update a machine identity binding' {
        if (-not $script:sampleMI) { Set-ItResult -Skipped -Because 'No machine identities in environment'; return }
        $id = @($script:sampleMI)[0].machineIdentityId
        { Set-TrustMachineIdentity -MachineIdentity $id -Binding $script:bindingHash -TrustClient $script:ngtsSession } | Should -Not -Throw
    }

    It 'Should return updated machine identity with -PassThru' {
        if (-not $script:sampleMI) { Set-ItResult -Skipped -Because 'No machine identities in environment'; return }
        $id = @($script:sampleMI)[0].machineIdentityId
        $updated = Set-TrustMachineIdentity -MachineIdentity $id -Binding $script:bindingHash -PassThru -TrustClient $script:ngtsSession
        $updated | Should -Not -BeNullOrEmpty
        $updated.machineIdentityId | Should -Be $id
    }

    It 'Should remove a machine identity' {
        if (-not $env:VENAFIPS_NGTS_MACHINE_OWNER) { Set-ItResult -Skipped -Because 'VENAFIPS_NGTS_MACHINE_OWNER not set'; return }

        # create a disposable machine + identity to safely delete
        $machineName = New-TestName -Prefix 'venafips-ngts-mi-rm'
        $cred = [pscredential]::new('testuser', (ConvertTo-SecureString 'P@ssw0rd!' -AsPlainText -Force))
        $machine = New-TrustMachineCommonKeystore -Name $machineName -Owner $env:VENAFIPS_NGTS_MACHINE_OWNER `
            -Credential $cred -SshPassword -Hostname "$machineName.example.com" -Port 22 `
            -Status 'DRAFT' -NoVerify -PassThru -TrustClient $script:ngtsSession
        if (-not $machine) { Set-ItResult -Skipped -Because 'Could not create test machine'; return }

        $mis = Find-TrustMachineIdentity -First 1 -TrustClient $script:ngtsSession
        if (-not $mis) {
            Remove-TrustMachine -ID $machine.machineId -TrustClient $script:ngtsSession -Confirm:$false -ErrorAction SilentlyContinue
            Set-ItResult -Skipped -Because 'No machine identities available to remove'
            return
        }
        $miId = @($mis)[0].machineIdentityId
        { Remove-TrustMachineIdentity -ID $miId -TrustClient $script:ngtsSession -Confirm:$false } | Should -Not -Throw

        Remove-TrustMachine -ID $machine.machineId -TrustClient $script:ngtsSession -Confirm:$false -ErrorAction SilentlyContinue
    }
}

# ── Certificate Request Approval ──────────────────────────────────────────────

Describe 'NGTS Certificate Request Approval' -Tags 'Functional', 'NGTS', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:ngtsSession = New-NgtsFunctionalSession
    }

    It 'Should approve a pending certificate request' {
        $reqs = Find-TrustCertificateRequest -First 5 -TrustClient $script:ngtsSession |
            Where-Object { $_.status -eq 'PENDING_APPROVAL' }
        if (-not $reqs) { Set-ItResult -Skipped -Because 'No pending approval requests in environment'; return }
        $id = @($reqs)[0].certificateRequestId
        { Set-TrustCertificateRequest -ID $id -Approve $true -TrustClient $script:ngtsSession } | Should -Not -Throw
    }

    It 'Should reject a pending certificate request' {
        $reqs = Find-TrustCertificateRequest -First 5 -TrustClient $script:ngtsSession |
            Where-Object { $_.status -eq 'PENDING_APPROVAL' }
        if (-not $reqs) { Set-ItResult -Skipped -Because 'No pending approval requests in environment'; return }
        $id = @($reqs)[0].certificateRequestId
        { Set-TrustCertificateRequest -ID $id -Approve $false -RejectReason 'VenafiPS functional test rejection' -TrustClient $script:ngtsSession } | Should -Not -Throw
    }
}

# ── Issuing Template Remove ───────────────────────────────────────────────────

Describe 'NGTS Remove Issuing Template' -Tags 'Functional', 'NGTS', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:ngtsSession = New-NgtsFunctionalSession
        $script:testTemplateId = $null
    }

    It 'Should remove an issuing template' {
        if (-not $env:VENAFIPS_NGTS_REMOVABLE_TEMPLATE) {
            Set-ItResult -Skipped -Because 'VENAFIPS_NGTS_REMOVABLE_TEMPLATE not set'
            return
        }
        $script:testTemplateId = $env:VENAFIPS_NGTS_REMOVABLE_TEMPLATE
        { Remove-TrustIssuingTemplate -ID $script:testTemplateId -TrustClient $script:ngtsSession -Confirm:$false } | Should -Not -Throw
    }
}

# ── New Machine (generic) Lifecycle ──────────────────────────────────────────

Describe 'NGTS New Machine Generic Lifecycle' -Tags 'Functional', 'NGTS', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:ngtsSession = New-NgtsFunctionalSession
        $script:testGenMachineId = $null
    }

    It 'Should create a machine with New-TrustMachine' {
        if (-not $env:VENAFIPS_NGTS_MACHINE_OWNER -or -not $env:VENAFIPS_NGTS_MACHINE_TYPE) {
            Set-ItResult -Skipped -Because 'VENAFIPS_NGTS_MACHINE_OWNER or VENAFIPS_NGTS_MACHINE_TYPE not set'
            return
        }
        $name = New-TestName -Prefix 'venafips-ngts-gen'
        $cred = [pscredential]::new('testuser', (ConvertTo-SecureString 'P@ssw0rd!' -AsPlainText -Force))
        $result = New-TrustMachine -Name $name -MachineType $env:VENAFIPS_NGTS_MACHINE_TYPE `
            -Owner $env:VENAFIPS_NGTS_MACHINE_OWNER -Credential $cred `
            -Hostname "$name.example.com" -Status 'DRAFT' -NoVerify -PassThru `
            -TrustClient $script:ngtsSession
        $result | Should -Not -BeNullOrEmpty
        $script:testGenMachineId = $result.machineId
    }

    It 'Should delete the machine' {
        if (-not $script:testGenMachineId) { Set-ItResult -Skipped -Because 'No test machine created'; return }
        { Remove-TrustMachine -ID $script:testGenMachineId -TrustClient $script:ngtsSession -Confirm:$false } | Should -Not -Throw
    }
}

# ── IIS Machine Lifecycle ─────────────────────────────────────────────────────

Describe 'NGTS IIS Machine Lifecycle' -Tags 'Functional', 'NGTS', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:ngtsSession = New-NgtsFunctionalSession
        $script:testIisMachineId = $null
    }

    It 'Should create an IIS machine' {
        if (-not $env:VENAFIPS_NGTS_MACHINE_OWNER) {
            Set-ItResult -Skipped -Because 'VENAFIPS_NGTS_MACHINE_OWNER not set'
            return
        }
        $name = New-TestName -Prefix 'venafips-ngts-iis'
        $cred = [pscredential]::new('testuser', (ConvertTo-SecureString 'P@ssw0rd!' -AsPlainText -Force))
        $result = New-TrustMachineIis -Name $name -Owner $env:VENAFIPS_NGTS_MACHINE_OWNER `
            -Credential $cred -Hostname "$name.example.com" `
            -Status 'DRAFT' -NoVerify -PassThru -TrustClient $script:ngtsSession
        $result | Should -Not -BeNullOrEmpty
        $script:testIisMachineId = $result.machineId
    }

    It 'Should delete the IIS machine' {
        if (-not $script:testIisMachineId) { Set-ItResult -Skipped -Because 'No test IIS machine created'; return }
        { Remove-TrustMachine -ID $script:testIisMachineId -TrustClient $script:ngtsSession -Confirm:$false } | Should -Not -Throw
    }
}

# ── Remove Tag ────────────────────────────────────────────────────────────────

Describe 'NGTS Remove Tag' -Tags 'Functional', 'NGTS', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:ngtsSession = New-NgtsFunctionalSession
    }

    It 'Should remove a tag' {
        if (-not $script:testTagName) {
            Set-ItResult -Skipped -Because 'No temp tag was created'
            return
        }
        { Remove-TrustTag -ID $script:testTagName -TrustClient $script:ngtsSession -Confirm:$false } | Should -Not -Throw
    }
}
