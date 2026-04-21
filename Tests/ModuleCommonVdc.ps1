
. $PSScriptRoot/ModuleCommon.ps1

Mock -CommandName 'Get-TrustClient' -MockWith {
    $tc = & (Get-Module VenafiPS) ([scriptblock]::Create('[TrustClient]::new()'))
    $tc.Platform = 'VDC'
    $tc.Server = 'https://venafi.company.com'
    $tc.TimeoutSec = 0
    $tc.SkipCertificateCheck = $true
    $tc.AccessToken = New-Object System.Management.Automation.PSCredential('AccessToken', ('reallySecure!' | ConvertTo-SecureString -AsPlainText -Force))
    $tc.RefreshToken = New-Object System.Management.Automation.PSCredential('RefreshToken', ('reallySecure!' | ConvertTo-SecureString -AsPlainText -Force))
    $tc.Scope = ''
    $tc.ClientId = 'VenafiPS'
    $tc.Expires = (Get-Date)
    $tc.RefreshExpires = (Get-Date)
    $tc.Version = [version]'24.3.1.1989'
    $tc.CustomField = @(
        @{
            Label = 'Environment'
            Guid  = '2f04f078-046b-4ccb-9784-39e5127b588a'
        }
    )
    return $tc
} -ModuleName $ModuleName
