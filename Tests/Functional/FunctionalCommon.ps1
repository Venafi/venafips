# Functional test bootstrap
# Sessions can come from two sources (checked in order):
#   1. An existing module-scoped session created before running tests
#      (e.g. New-TrustClient -VcKey ... in your shell, then Invoke-Pester)
#   2. Environment variables — a new session is created automatically
#
# Required env vars per platform (only needed when no session exists):
#   VDC:  VENAFIPS_VDC_SERVER, VENAFIPS_VDC_USERNAME, VENAFIPS_VDC_PASSWORD, VENAFIPS_VDC_CLIENTID, VENAFIPS_VDC_SCOPE
#   VC:   VENAFIPS_VC_APIKEY (and optionally VENAFIPS_VC_REGION)
#   NGTS: VENAFIPS_NGTS_USERNAME, VENAFIPS_NGTS_SECRET

$ModuleName = 'VenafiPS'
$ModulePath = "$PSScriptRoot/../../VenafiPS/VenafiPS.psd1"

# Only reimport if not already loaded — preserves an existing session
if (-not (Get-Module $ModuleName)) {
    Import-Module $ModulePath -Force
}

function Get-ExistingSession {
    <#
    .SYNOPSIS
    Returns the module-scoped TrustClient if it exists and matches the requested platform.
    #>
    param([string] $Platform)

    try {
        $client = & (Get-Module 'VenafiPS') { $Script:TrustClient }
        if ($client -and $client.Platform -eq $Platform) { return $client }
    }
    catch {}
    return $null
}

function Skip-IfMissingEnv {
    <#
    .SYNOPSIS
    Returns $true if any required env var is missing, signaling the test should be skipped.
    #>
    param([string[]] $Required)

    foreach ($var in $Required) {
        if (-not [Environment]::GetEnvironmentVariable($var)) {
            return $true
        }
    }
    return $false
}

function Skip-IfNoSession {
    <#
    .SYNOPSIS
    Returns $false if an existing module session matches the platform, or if all
    required env vars are present. Returns $true (skip) only when neither is available.
    #>
    param(
        [string]   $Platform,
        [string[]] $RequiredEnvVars
    )

    if (Get-ExistingSession -Platform $Platform) { return $false }
    return (Skip-IfMissingEnv -Required $RequiredEnvVars)
}

function New-VdcFunctionalSession {
    $existing = Get-ExistingSession -Platform 'VDC'
    if ($existing) { return $existing }

    $cred = [System.Management.Automation.PSCredential]::new(
        $env:VENAFIPS_VDC_USERNAME,
        ($env:VENAFIPS_VDC_PASSWORD | ConvertTo-SecureString -AsPlainText -Force)
    )
    $scope = $env:VENAFIPS_VDC_SCOPE | ConvertFrom-Json -AsHashtable

    New-TrustClient -Server $env:VENAFIPS_VDC_SERVER -Credential $cred -ClientId $env:VENAFIPS_VDC_CLIENTID -Scope $scope -PassThru
}

function New-VcFunctionalSession {
    $existing = Get-ExistingSession -Platform 'VC'
    if ($existing) { return $existing }

    $region = if ($env:VENAFIPS_VC_REGION) { $env:VENAFIPS_VC_REGION } else { 'us' }
    New-TrustClient -VcKey $env:VENAFIPS_VC_APIKEY -VcRegion $region -PassThru
}

function New-NgtsFunctionalSession {
    $existing = Get-ExistingSession -Platform 'NGTS'
    if ($existing) { return $existing }

    $cred = [System.Management.Automation.PSCredential]::new(
        $env:VENAFIPS_NGTS_USERNAME,
        ($env:VENAFIPS_NGTS_SECRET | ConvertTo-SecureString -AsPlainText -Force)
    )
    $params = @{ NgtsCredential = $cred; PassThru = $true }
    if ($env:VENAFIPS_NGTS_TSG) { $params.Tsg = [long]$env:VENAFIPS_NGTS_TSG }
    New-TrustClient @params
}

function New-TestName {
    <#
    .SYNOPSIS
    Generate a unique resource name for functional tests to avoid collisions.
    #>
    param([string] $Prefix = 'VenafiPS-Test')
    '{0}-{1}' -f $Prefix, [datetime]::UtcNow.ToString('yyyyMMddHHmmss')
}
