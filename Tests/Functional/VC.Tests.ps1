BeforeDiscovery {
    . $PSScriptRoot/FunctionalCommon.ps1
    $skipAll = Skip-IfNoSession -Platform 'VC' -RequiredEnvVars @('VENAFIPS_VC_APIKEY')
}

BeforeAll {
    . $PSScriptRoot/FunctionalCommon.ps1
}

Describe 'VC Connection' -Tags 'Functional', 'VC' -Skip:$skipAll {

    It 'Should create a session with API key' {
        $sess = New-VcFunctionalSession
        $sess | Should -Not -BeNullOrEmpty
        $sess.Platform | Should -Be 'VC'
        $sess.AuthType | Should -Be 'ApiKey'
        $sess.Server | Should -Not -BeNullOrEmpty
    }

    It 'Should set module-scoped session' {
        if (-not $env:VENAFIPS_VC_APIKEY) {
            Set-ItResult -Skipped -Because 'VENAFIPS_VC_APIKEY not set (using existing session)'
            return
        }
        $region = if ($env:VENAFIPS_VC_REGION) { $env:VENAFIPS_VC_REGION } else { 'us' }
        New-TrustClient -VcKey $env:VENAFIPS_VC_APIKEY -VcRegion $region
        $moduleClient = InModuleScope 'VenafiPS' { $Script:TrustClient }
        $moduleClient | Should -Not -BeNullOrEmpty
        $moduleClient.Platform | Should -Be 'VC'
    }
}

Describe 'VC Find Certificates' -Tags 'Functional', 'VC' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-VcFunctionalSession
    }

    It 'Should find certificates with -First' {
        $certs = Find-TrustCertificate -First 5 -TrustClient $script:vcSession
        $certs | Should -Not -BeNullOrEmpty
        @($certs).Count | Should -BeLessOrEqual 5
    }

    It 'Should return certificate objects with expected properties' {
        $certs = Find-TrustCertificate -First 1 -TrustClient $script:vcSession
        $cert = @($certs)[0]
        $cert.certificateId | Should -Not -BeNullOrEmpty
        $cert.certificateName | Should -Not -BeNullOrEmpty
    }

    It 'Should find by name filter' {
        # get a cert name first, then search for it
        $sample = Find-TrustCertificate -First 1 -TrustClient $script:vcSession
        if ($sample) {
            $name = @($sample)[0].certificateName
            $result = Find-TrustCertificate -Name $name -First 5 -TrustClient $script:vcSession
            $result | Should -Not -BeNullOrEmpty
        }
        else {
            Set-ItResult -Skipped -Because 'No certificates in environment'
        }
    }

    It 'Should find expired certificates' {
        $expired = Find-TrustCertificate -IsExpired -First 5 -TrustClient $script:vcSession
        # may be empty if none expired, that's ok
        if ($expired) {
            @($expired).Count | Should -BeGreaterThan 0
        }
    }
}

Describe 'VC Get Certificate' -Tags 'Functional', 'VC' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-VcFunctionalSession
        $script:sampleCert = Find-TrustCertificate -First 1 -TrustClient $script:vcSession
    }

    It 'Should get a certificate by ID' {
        if (-not $script:sampleCert) { Set-ItResult -Skipped -Because 'No sample certificate found'; return }
        $certId = @($script:sampleCert)[0].certificateId
        $cert = Get-TrustCertificate -Certificate $certId -TrustClient $script:vcSession
        $cert | Should -Not -BeNullOrEmpty
        $cert.certificateId | Should -Be $certId
    }
}

Describe 'VC Export Certificate' -Tags 'Functional', 'VC' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-VcFunctionalSession
        $script:sampleCert = Find-TrustCertificate -First 1 -TrustClient $script:vcSession
        $script:exportDir = Join-Path ([System.IO.Path]::GetTempPath()) 'VenafiPS-Functional'
        if (-not (Test-Path $script:exportDir)) { New-Item -Path $script:exportDir -ItemType Directory | Out-Null }
    }

    It 'Should export certificate as PEM' {
        if (-not $script:sampleCert) { Set-ItResult -Skipped -Because 'No sample certificate found'; return }
        $certId = @($script:sampleCert)[0].certificateId
        $result = Export-TrustCertificate -ID $certId -OutPath $script:exportDir -TrustClient $script:vcSession
        $result | Should -Not -BeNullOrEmpty
    }

    AfterAll {
        if (Test-Path $script:exportDir) {
            Remove-Item -Path $script:exportDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Describe 'VC Certificate Lifecycle' -Tags 'Functional', 'VC', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-VcFunctionalSession
        $script:testCertId = $null
    }

    It 'Should request a new certificate' {
        if (-not $env:VENAFIPS_VC_ISSUING_TEMPLATE) {
            Set-ItResult -Skipped -Because 'VENAFIPS_VC_ISSUING_TEMPLATE not set'
            return
        }

        $testName = New-TestName -Prefix 'venafips-func'
        $params = @{
            CommonName       = "$testName.example.com"
            IssuingTemplate  = $env:VENAFIPS_VC_ISSUING_TEMPLATE
            TrustClient      = $script:vcSession
        }

        $result = New-TrustCertificate @params
        $result | Should -Not -BeNullOrEmpty
        $script:testCertId = $result.certificateId
    }

    It 'Should validate the test certificate' {
        if (-not $script:testCertId) { Set-ItResult -Skipped -Because 'No test certificate created'; return }
        { Invoke-TrustCertificateAction -ID $script:testCertId -Validate -TrustClient $script:vcSession } |
            Should -Not -Throw
    }

    It 'Should retire the test certificate' {
        if (-not $script:testCertId) { Set-ItResult -Skipped -Because 'No test certificate created'; return }
        { Invoke-TrustCertificateAction -ID $script:testCertId -Retire -TrustClient $script:vcSession } |
            Should -Not -Throw
    }

    It 'Should recover the retired certificate' {
        if (-not $script:testCertId) { Set-ItResult -Skipped -Because 'No test certificate created'; return }
        { Invoke-TrustCertificateAction -ID $script:testCertId -Recover -TrustClient $script:vcSession } |
            Should -Not -Throw
    }

    It 'Should delete the test certificate' {
        if (-not $script:testCertId) { Set-ItResult -Skipped -Because 'No test certificate created'; return }
        { Invoke-TrustCertificateAction -ID $script:testCertId -Delete -TrustClient $script:vcSession -Confirm:$false } |
            Should -Not -Throw
    }
}

# ── Application Lifecycle ─────────────────────────────────────────────────────

Describe 'VC Application Lifecycle' -Tags 'Functional', 'VC', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-VcFunctionalSession
        $script:testAppId = $null
        $script:testAppName = $null
        $script:testTeamId = $null

        # create a temp team to own the application (Owner must be a team, not a user)
        $me = Get-VcUser -Me -TrustClient $script:vcSession
        $teamName = New-TestName -Prefix 'venafips-appowner'
        New-VcTeam -Name $teamName -Owner @($me.userId) -Member @($me.userId) -Role 'Resource Owner' -TrustClient $script:vcSession
        $team = Get-VcTeam -All -TrustClient $script:vcSession | Where-Object { $_.name -eq $teamName }
        if ($team) { $script:testTeamId = $team.teamId }
    }

    It 'Should create a new application' {
        if (-not $script:testTeamId) { Set-ItResult -Skipped -Because 'Could not create owner team'; return }
        $script:testAppName = New-TestName -Prefix 'venafips-app'
        $result = New-VcApplication -Name $script:testAppName -Owner $script:testTeamId -PassThru -TrustClient $script:vcSession
        $result | Should -Not -BeNullOrEmpty
        $script:testAppId = $result.applicationId
    }

    It 'Should get the created application' {
        if (-not $script:testAppId) { Set-ItResult -Skipped -Because 'No test application created'; return }
        $app = Get-VcApplication -Application $script:testAppId -TrustClient $script:vcSession
        $app | Should -Not -BeNullOrEmpty
        $app.name | Should -Be $script:testAppName
    }

    It 'Should update the application name' {
        if (-not $script:testAppId) { Set-ItResult -Skipped -Because 'No test application created'; return }
        $newName = New-TestName -Prefix 'venafips-app-upd'
        { Set-VcApplication -Application $script:testAppId -Name $newName -TrustClient $script:vcSession } | Should -Not -Throw
        $script:testAppName = $newName
    }

    It 'Should verify the name was updated' {
        if (-not $script:testAppId) { Set-ItResult -Skipped -Because 'No test application created'; return }
        $app = Get-VcApplication -Application $script:testAppId -TrustClient $script:vcSession
        $app.name | Should -Be $script:testAppName
    }

    It 'Should delete the application' {
        if (-not $script:testAppId) { Set-ItResult -Skipped -Because 'No test application created'; return }
        { Remove-VcApplication -ID $script:testAppId -TrustClient $script:vcSession -Confirm:$false } | Should -Not -Throw
    }

    AfterAll {
        if ($script:testTeamId) {
            Remove-VcTeam -ID $script:testTeamId -TrustClient $script:vcSession -Confirm:$false -ErrorAction SilentlyContinue
        }
    }
}

# ── Team Lifecycle ────────────────────────────────────────────────────────────

Describe 'VC Team Lifecycle' -Tags 'Functional', 'VC', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-VcFunctionalSession
        $script:testTeamId = $null
        # get the current user GUID to use as owner and member
        $me = Get-VcUser -Me -TrustClient $script:vcSession
        $script:myUserId = $me.userId
    }

    It 'Should create a new team' {
        $teamName = New-TestName -Prefix 'venafips-team'
        $team = New-VcTeam -Name $teamName -Owner @($script:myUserId) -Member @($script:myUserId) -Role 'Resource Owner' -PassThru -TrustClient $script:vcSession
        $team | Should -Not -BeNullOrEmpty
        $script:testTeamId = $team.teamId
    }

    It 'Should get the created team' {
        if (-not $script:testTeamId) { Set-ItResult -Skipped -Because 'No test team created'; return }
        $team = Get-VcTeam -Team $script:testTeamId -TrustClient $script:vcSession
        $team | Should -Not -BeNullOrEmpty
    }

    It 'Should update the team role' {
        if (-not $script:testTeamId) { Set-ItResult -Skipped -Because 'No test team created'; return }
        { Set-VcTeam -Team $script:testTeamId -Role 'Guest' -TrustClient $script:vcSession } | Should -Not -Throw
    }

    It 'Should add a team member' {
        if (-not $script:testTeamId) { Set-ItResult -Skipped -Because 'No test team created'; return }
        # adding the same user again should be a no-op or succeed silently
        { Add-VcTeamMember -Team $script:testTeamId -Member @($script:myUserId) -TrustClient $script:vcSession } | Should -Not -Throw
    }

    It 'Should delete the team' {
        if (-not $script:testTeamId) { Set-ItResult -Skipped -Because 'No test team created'; return }
        { Remove-VcTeam -ID $script:testTeamId -TrustClient $script:vcSession -Confirm:$false } | Should -Not -Throw
    }
}

# ── Webhook Lifecycle ─────────────────────────────────────────────────────────

Describe 'VC Webhook Lifecycle' -Tags 'Functional', 'VC', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-VcFunctionalSession
        $script:testWebhookId = $null
    }

    It 'Should create a new webhook' {
        if (-not $env:VENAFIPS_VC_WEBHOOK_URL) {
            Set-ItResult -Skipped -Because 'VENAFIPS_VC_WEBHOOK_URL not set'
            return
        }
        $webhookName = New-TestName -Prefix 'venafips-hook'
        # get a valid event type from the API
        $activityTypes = Invoke-TrustRestMethod -UriLeaf 'activitytypes' -TrustClient $script:vcSession
        $eventType = $activityTypes.readablename | Select-Object -First 1
        if (-not $eventType) { Set-ItResult -Skipped -Because 'No activity types available'; return }

        $result = New-TrustWebhook -Name $webhookName -Url $env:VENAFIPS_VC_WEBHOOK_URL -EventType $eventType -PassThru -TrustClient $script:vcSession
        $result | Should -Not -BeNullOrEmpty
        $script:testWebhookId = $result.webhookId
    }

    It 'Should get the created webhook' {
        if (-not $script:testWebhookId) { Set-ItResult -Skipped -Because 'No test webhook created'; return }
        $webhook = Get-TrustWebhook -ID $script:testWebhookId -TrustClient $script:vcSession
        $webhook | Should -Not -BeNullOrEmpty
    }

    It 'Should delete the webhook' {
        if (-not $script:testWebhookId) { Set-ItResult -Skipped -Because 'No test webhook created'; return }
        { Remove-TrustWebhook -ID $script:testWebhookId -TrustClient $script:vcSession -Confirm:$false } | Should -Not -Throw
    }
}

# ── Certificate Tag/Application Assignment ────────────────────────────────────

Describe 'VC Set Certificate' -Tags 'Functional', 'VC', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-VcFunctionalSession
        $script:sampleCert = Find-TrustCertificate -First 1 -TrustClient $script:vcSession
        $script:testAppId = $null
        $script:testTeamId = $null
    }

    It 'Should assign an application to a certificate' {
        if (-not $script:sampleCert) { Set-ItResult -Skipped -Because 'No sample certificate found'; return }

        # create a temp team, then a temp app owned by that team
        $me = Get-VcUser -Me -TrustClient $script:vcSession
        $teamName = New-TestName -Prefix 'venafips-setcert'
        New-VcTeam -Name $teamName -Owner @($me.userId) -Member @($me.userId) -Role 'Resource Owner' -TrustClient $script:vcSession
        $team = Get-VcTeam -All -TrustClient $script:vcSession | Where-Object { $_.name -eq $teamName }
        if (-not $team) { Set-ItResult -Skipped -Because 'Could not create owner team'; return }
        $script:testTeamId = $team.teamId

        $appName = New-TestName -Prefix 'venafips-assign'
        $app = New-VcApplication -Name $appName -Owner $script:testTeamId -PassThru -TrustClient $script:vcSession
        $script:testAppId = $app.applicationId

        $certId = @($script:sampleCert)[0].certificateId
        { Set-TrustCertificate -Certificate $certId -Application $script:testAppId -NoOverwrite -TrustClient $script:vcSession } | Should -Not -Throw
    }

    It 'Should assign a tag to a certificate' {
        if (-not $script:sampleCert) { Set-ItResult -Skipped -Because 'No sample certificate found'; return }
        $tags = Get-TrustTag -All -TrustClient $script:vcSession
        if (-not $tags) { Set-ItResult -Skipped -Because 'No tags in environment'; return }
        $tagName = @($tags)[0].tagId
        if (-not $tagName) { Set-ItResult -Skipped -Because 'Tag has no name'; return }
        $certId = @($script:sampleCert)[0].certificateId
        { Set-TrustCertificate -Certificate $certId -Tag $tagName -NoOverwrite -TrustClient $script:vcSession } | Should -Not -Throw
    }

    AfterAll {
        if ($script:testAppId) {
            Remove-VcApplication -ID $script:testAppId -TrustClient $script:vcSession -Confirm:$false -ErrorAction SilentlyContinue
        }
        if ($script:testTeamId) {
            Remove-VcTeam -ID $script:testTeamId -TrustClient $script:vcSession -Confirm:$false -ErrorAction SilentlyContinue
        }
    }
}

# ── Issuing Templates & CAs ──────────────────────────────────────────────────

Describe 'VC Issuing Templates' -Tags 'Functional', 'VC' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-VcFunctionalSession
    }

    It 'Should list all issuing templates' {
        $templates = Get-TrustIssuingTemplate -All -TrustClient $script:vcSession
        $templates | Should -Not -BeNullOrEmpty
    }

    It 'Should get a single issuing template by ID' {
        $all = Get-TrustIssuingTemplate -All -TrustClient $script:vcSession
        if (-not $all) { Set-ItResult -Skipped -Because 'No issuing templates found'; return }
        $first = @($all)[0]
        $single = Get-TrustIssuingTemplate -IssuingTemplate $first.issuingTemplateId -TrustClient $script:vcSession
        $single | Should -Not -BeNullOrEmpty
        $single.issuingTemplateId | Should -Be $first.issuingTemplateId
    }
}

Describe 'VC Certificate Authorities' -Tags 'Functional', 'VC' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-VcFunctionalSession
    }

    It 'Should list all certificate authorities' {
        $cas = Get-TrustCertificateAuthority -All -TrustClient $script:vcSession
        $cas | Should -Not -BeNullOrEmpty
    }

    It 'Should get a single certificate authority' {
        $all = Get-TrustCertificateAuthority -All -TrustClient $script:vcSession
        if (-not $all) { Set-ItResult -Skipped -Because 'No CAs found'; return }
        $first = @($all)[0]
        $single = Get-TrustCertificateAuthority -CertificateAuthority $first.certificateAuthorityId -TrustClient $script:vcSession
        $single | Should -Not -BeNullOrEmpty
    }
}

# ── Machines ──────────────────────────────────────────────────────────────────

Describe 'VC Find Machines' -Tags 'Functional', 'VC' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-VcFunctionalSession
    }

    It 'Should find machines with -First' {
        $machines = Find-TrustMachine -First 5 -TrustClient $script:vcSession
        # may be empty if tenant has no machines
        if ($machines) {
            @($machines).Count | Should -BeLessOrEqual 5
        }
    }

    It 'Should return machine objects with expected properties' {
        $machines = Find-TrustMachine -First 1 -TrustClient $script:vcSession
        if (-not $machines) { Set-ItResult -Skipped -Because 'No machines in environment'; return }
        $m = @($machines)[0]
        $m.machineId | Should -Not -BeNullOrEmpty
    }
}

Describe 'VC Get Machine' -Tags 'Functional', 'VC' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-VcFunctionalSession
        $script:sampleMachine = Find-TrustMachine -First 1 -TrustClient $script:vcSession
    }

    It 'Should get a machine by ID' {
        if (-not $script:sampleMachine) { Set-ItResult -Skipped -Because 'No machines in environment'; return }
        $id = @($script:sampleMachine)[0].machineId
        $machine = Get-TrustMachine -Machine $id -TrustClient $script:vcSession
        $machine | Should -Not -BeNullOrEmpty
        $machine.machineId | Should -Be $id
    }

    It 'Should list all machines' {
        $all = Get-TrustMachine -All -TrustClient $script:vcSession
        # may be empty but should not throw
        { Get-TrustMachine -All -TrustClient $script:vcSession } | Should -Not -Throw
    }
}

# ── Machine Identities ───────────────────────────────────────────────────────

Describe 'VC Machine Identities' -Tags 'Functional', 'VC' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-VcFunctionalSession
        $script:sampleMI = Find-TrustMachineIdentity -First 1 -TrustClient $script:vcSession
    }

    It 'Should find machine identities with -First' {
        $mis = Find-TrustMachineIdentity -First 5 -TrustClient $script:vcSession
        if ($mis) {
            @($mis).Count | Should -BeLessOrEqual 5
        }
    }

    It 'Should get a machine identity by ID' {
        if (-not $script:sampleMI) { Set-ItResult -Skipped -Because 'No machine identities in environment'; return }
        $id = @($script:sampleMI)[0].machineIdentityId
        $mi = Get-TrustMachineIdentity -ID $id -TrustClient $script:vcSession
        $mi | Should -Not -BeNullOrEmpty
        $mi.machineIdentityId | Should -Be $id
    }
}

# ── Applications ──────────────────────────────────────────────────────────────

Describe 'VC Applications' -Tags 'Functional', 'VC' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-VcFunctionalSession
    }

    It 'Should list all applications' {
        $apps = Get-VcApplication -All -TrustClient $script:vcSession
        $apps | Should -Not -BeNullOrEmpty
    }

    It 'Should get a single application by ID' {
        $all = Get-VcApplication -All -TrustClient $script:vcSession
        if (-not $all) { Set-ItResult -Skipped -Because 'No applications found'; return }
        $first = @($all)[0]
        $single = Get-VcApplication -Application $first.applicationId -TrustClient $script:vcSession
        $single | Should -Not -BeNullOrEmpty
        $single.applicationId | Should -Be $first.applicationId
    }

    It 'Should include config details with -IncludeConfig' {
        $all = Get-VcApplication -All -TrustClient $script:vcSession
        if (-not $all) { Set-ItResult -Skipped -Because 'No applications found'; return }
        $first = @($all)[0]
        $app = Get-VcApplication -Application $first.applicationId -IncludeConfig -TrustClient $script:vcSession
        $app | Should -Not -BeNullOrEmpty
    }
}

# ── Certificate Requests ──────────────────────────────────────────────────────

Describe 'VC Certificate Requests' -Tags 'Functional', 'VC' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-VcFunctionalSession
    }

    It 'Should find certificate requests with -First' {
        $reqs = Find-TrustCertificateRequest -First 5 -TrustClient $script:vcSession
        if ($reqs) {
            @($reqs).Count | Should -BeLessOrEqual 5
        }
    }

    It 'Should get a single certificate request by ID' {
        $reqs = Find-TrustCertificateRequest -First 1 -TrustClient $script:vcSession
        if (-not $reqs) { Set-ItResult -Skipped -Because 'No certificate requests found'; return }
        $first = @($reqs)[0]
        $single = Get-TrustCertificateRequest -CertificateRequest $first.certificateRequestId -TrustClient $script:vcSession
        $single | Should -Not -BeNullOrEmpty
        $single.certificateRequestId | Should -Be $first.certificateRequestId
    }
}

# ── Certificate Instances ─────────────────────────────────────────────────────

Describe 'VC Certificate Instances' -Tags 'Functional', 'VC' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-VcFunctionalSession
    }

    It 'Should find certificate instances with -First' {
        $instances = Find-TrustCertificateInstance -First 5 -TrustClient $script:vcSession
        if ($instances) {
            @($instances).Count | Should -BeLessOrEqual 5
        }
    }
}

# ── Teams ─────────────────────────────────────────────────────────────────────

Describe 'VC Teams' -Tags 'Functional', 'VC' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-VcFunctionalSession
    }

    It 'Should list all teams' {
        $teams = Get-VcTeam -All -TrustClient $script:vcSession
        $teams | Should -Not -BeNullOrEmpty
    }

    It 'Should get a single team by ID' {
        $all = Get-VcTeam -All -TrustClient $script:vcSession
        if (-not $all) { Set-ItResult -Skipped -Because 'No teams found'; return }
        $first = @($all)[0]
        $single = Get-VcTeam -Team $first.teamId -TrustClient $script:vcSession
        $single | Should -Not -BeNullOrEmpty
        $single.teamId | Should -Be $first.teamId
    }
}

# ── Users ─────────────────────────────────────────────────────────────────────

Describe 'VC Users' -Tags 'Functional', 'VC' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-VcFunctionalSession
    }

    It 'Should get the current user with -Me' {
        $me = Get-VcUser -Me -TrustClient $script:vcSession
        $me | Should -Not -BeNullOrEmpty
        $me.userId | Should -Not -BeNullOrEmpty
    }

    It 'Should list all users' {
        $users = Get-VcUser -All -TrustClient $script:vcSession
        $users | Should -Not -BeNullOrEmpty
    }

    It 'Should get a user by ID' {
        $me = Get-VcUser -Me -TrustClient $script:vcSession
        $user = Get-VcUser -User $me.userId -TrustClient $script:vcSession
        $user | Should -Not -BeNullOrEmpty
        $user.userId | Should -Be $me.userId
    }
}

# ── Tags ──────────────────────────────────────────────────────────────────────

Describe 'VC Tags' -Tags 'Functional', 'VC' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-VcFunctionalSession
    }

    It 'Should list all tags' {
        $tags = Get-TrustTag -All -TrustClient $script:vcSession
        # may be empty but should not throw
        { Get-TrustTag -All -TrustClient $script:vcSession } | Should -Not -Throw
    }
}

# ── Connectors ────────────────────────────────────────────────────────────────

Describe 'VC Connectors' -Tags 'Functional', 'VC' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-VcFunctionalSession
    }

    It 'Should list all connectors' {
        $connectors = Get-TrustConnector -All -TrustClient $script:vcSession
        # may be empty but should not throw
        { Get-TrustConnector -All -TrustClient $script:vcSession } | Should -Not -Throw
    }

    It 'Should get a single connector by ID' {
        $all = Get-TrustConnector -All -TrustClient $script:vcSession
        if (-not $all) { Set-ItResult -Skipped -Because 'No connectors found'; return }
        $first = @($all)[0]
        $single = Get-TrustConnector -Connector $first.connectorId -TrustClient $script:vcSession
        $single | Should -Not -BeNullOrEmpty
    }
}

# ── Webhooks ──────────────────────────────────────────────────────────────────

Describe 'VC Webhooks' -Tags 'Functional', 'VC' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-VcFunctionalSession
    }

    It 'Should list all webhooks' {
        { Get-TrustWebhook -All -TrustClient $script:vcSession } | Should -Not -Throw
    }
}

# ── Satellites ────────────────────────────────────────────────────────────────

Describe 'VC Satellites' -Tags 'Functional', 'VC' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-VcFunctionalSession
    }

    It 'Should list all satellites' {
        { Get-TrustSatellite -All -TrustClient $script:vcSession } | Should -Not -Throw
    }

    It 'Should get a satellite with workers' {
        $all = Get-TrustSatellite -All -TrustClient $script:vcSession
        if (-not $all) { Set-ItResult -Skipped -Because 'No satellites found'; return }
        $first = @($all)[0]
        $sat = Get-TrustSatellite -VSatellite $first.vsatelliteId -IncludeWorkers -TrustClient $script:vcSession
        $sat | Should -Not -BeNullOrEmpty
    }
}

# ── Cloud Keystores & Providers ───────────────────────────────────────────────

Describe 'VC Cloud Providers' -Tags 'Functional', 'VC' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-VcFunctionalSession
    }

    It 'Should list all cloud providers' {
        { Get-TrustCloudProvider -All -TrustClient $script:vcSession } | Should -Not -Throw
    }

    It 'Should get a single cloud provider by ID' {
        $all = Get-TrustCloudProvider -All -TrustClient $script:vcSession
        if (-not $all) { Set-ItResult -Skipped -Because 'No cloud providers found'; return }
        $first = @($all)[0]
        $single = Get-TrustCloudProvider -CloudProvider $first.cloudProviderId -TrustClient $script:vcSession
        $single | Should -Not -BeNullOrEmpty
    }
}

Describe 'VC Cloud Keystores' -Tags 'Functional', 'VC' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-VcFunctionalSession
    }

    It 'Should list all cloud keystores' {
        { Get-TrustCloudKeystore -All -TrustClient $script:vcSession } | Should -Not -Throw
    }
}

# ── Logs ──────────────────────────────────────────────────────────────────────

Describe 'VC Activity Log' -Tags 'Functional', 'VC' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-VcFunctionalSession
    }

    It 'Should find recent log entries' {
        $logs = Find-TrustLog -First 5 -TrustClient $script:vcSession
        $logs | Should -Not -BeNullOrEmpty
    }

    It 'Should filter critical log entries' {
        $logs = Find-TrustLog -Critical -First 5 -TrustClient $script:vcSession
        # may be empty — just verify it does not throw
        { Find-TrustLog -Critical -First 5 -TrustClient $script:vcSession } | Should -Not -Throw
    }
}
