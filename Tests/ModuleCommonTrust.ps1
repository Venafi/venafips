
. $PSScriptRoot/ModuleCommon.ps1

Mock -CommandName 'Get-TrustClient' -MockWith {
    $tc = & (Get-Module VenafiPS) ([scriptblock]::Create('[TrustClient]::new()'))
    $tc.Platform = 'VC'
    $tc.Server = 'https://api.venafi.cloud'
    $tc.TimeoutSec = 0
    $tc.SkipCertificateCheck = $false
    $tc.ApiKey = New-Object System.Management.Automation.PSCredential('VcKey', ('c7afbda6-0ae4-43b2-b775-42ab2940ba9e' | ConvertTo-SecureString -AsPlainText -Force))
    return $tc
} -ModuleName $ModuleName
