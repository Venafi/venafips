
. $PSScriptRoot/ModuleCommon.ps1

Mock -CommandName 'Get-TrustClient' -MockWith {
    return [pscustomobject]@{
        Platform             = 'VDC'
        Server               = 'https://venafi.company.com'
        TimeoutSec           = 0
        SkipCertificateCheck = $true
        Token                = @{
            Server         = 'https://venafi.company.com'
            AccessToken    = New-Object System.Management.Automation.PSCredential('AccessToken', ('reallySecure!' | ConvertTo-SecureString -AsPlainText -Force))
            RefreshToken   = New-Object System.Management.Automation.PSCredential('RefreshToken', ('reallySecure!' | ConvertTo-SecureString -AsPlainText -Force))
            Scope          = ''
            Identity       = ''
            TokenType      = 'Bearer'
            ClientId       = 'VenafiPS'
            Expires        = (Get-Date)
            RefreshExpires = (Get-Date)
        }
        Version              = [version]'24.3.1.1989'
        CustomField          = @(
            @{
                Label = 'Environment'
                Guid  = '2f04f078-046b-4ccb-9784-39e5127b588a'
            }
        )
    }
} -ModuleName $ModuleName
