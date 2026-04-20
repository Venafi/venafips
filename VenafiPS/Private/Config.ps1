$script:VcRegions = @{
    'us' = 'https://api.venafi.cloud'
    'eu' = 'https://api.eu.venafi.cloud'
    'au' = 'https://api.au.venafi.cloud'
    'uk' = 'https://api.uk.venafi.cloud'
    'sg' = 'https://api.sg.venafi.cloud'
    'ca' = 'https://api.ca.venafi.cloud'
}

# vaas fields to ensure the values are upper case
$script:vaasValuesToUpper = 'certificateStatus', 'signatureAlgorithm', 'signatureHashAlgorithm', 'encryptionType', 'versionType', 'certificateSource', 'deploymentStatus'

# vaas fields proper case
$script:vaasFields = @(
    'certificateId',
    'applicationIds',
    'companyId',
    'managedCertificateId',
    'fingerprint',
    'certificateName',
    'issuerCertificateIds',
    'certificateStatus',
    'statusModificationUserId',
    'modificationDate',
    'statusModificationDate',
    'validityStart',
    'validityEnd',
    'selfSigned',
    'signatureAlgorithm',
    'signatureHashAlgorithm',
    'encryptionType',
    'keyCurve',
    'subjectKeyIdentifierHash',
    'authorityKeyIdentifierHash',
    'serialNumber',
    'subjectDN',
    'subjectCN',
    'subjectO',
    'subjectST',
    'subjectC',
    'subjectAlternativeNamesByType',
    'subjectAlternativeNameDns',
    'issuerDN',
    'issuerCN',
    'issuerST',
    'issuerL',
    'issuerC',
    'keyUsage',
    'extendedKeyUsage',
    'ocspNoCheck',
    'versionType',
    'activityDate',
    'activityType',
    'activityName',
    'criticality'
)

$script:functionConfig = @{
    'Add-VdcAdaptableHash'             = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'restricted=manage,delete'
    }
    'Add-VdcCertificateAssociation'    = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'certificate=manage'
    }
    'Add-VdcEngineFolder'              = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=manage'
    }
    'Add-VdcTeamMember'                = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=manage'
    }
    'Add-VdcTeamOwner'                 = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=manage'
    }
    'Convert-VdcObject'                = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=manage'
    }
    'Export-VdcCertificate'            = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'certificate=manage'
    }
    'Find-VdcClient'                   = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'agent=$null'
    }
    'Find-VdcEngine'                   = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=$null'
    }
    'Find-VdcIdentity'                 = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=$null'
    }
    'Find-VdcObject'                   = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=$null'
    }
    'Find-VdcVaultId'                  = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'restricted=$null'
    }
    'Find-VdcCertificate'              = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'certificate=$null'
    }
    'Get-VdcAttribute'                 = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=$null'
    }
    'Get-VdcClassAttribute'            = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'any scope'
    }
    'Get-VdcCredential'                = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'security=manage'
    }
    'Get-VdcCustomField'               = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'any scope'
    }
    'Get-VdcEngineFolder'              = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=manage'
    }
    'Get-VdcIdentityAttribute'         = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=$null'
    }
    'Get-VdcObject'                    = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'any scope'
    }
    'Get-VdcPermission'                = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'security=$null'
    }
    'Get-VdcSystemStatus'              = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'any scope'
    }
    'Get-VdcWorkflowTicket'            = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'any scope'
    }
    'Get-VdcCertificate'               = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'certificate=$null'
    }
    'Get-VdcIdentity'                  = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=$null'
    }
    'Get-VdcTeam'                      = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=manage'
    }
    'Import-VdcCertificate'            = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'certificate=discover'
    }
    'Import-VcCertificate'             = @{
        'TppVersion'    = ''
        'TppTokenScope' = ''
    }
    'Invoke-VdcCertificateAction'      = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'certificate=manage for Reset, Renew, Push, and Validate.  certificate=revoke for Revoke.  certificate=delete for Delete.'
    }
    'Move-VdcObject'                   = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=manage'
    }
    'New-VdcCapiApplication'           = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=manage'
    }
    'New-VdcCertificate'               = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'certificate=manage'
    }
    'New-VdcCustomField'               = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=manage'
    }
    'New-VdcDevice'                    = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=manage'
    }
    'New-VdcObject'                    = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=manage.  If a certificate is provided as an attribute, certificate=manage as well.'
    }
    'New-VdcPolicy'                    = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=manage'
    }
    'New-VdcToken'                     = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'any scope'
    }
    'New-VcCertificate'                = @{
        'TppVersion'    = ''
        'TppTokenScope' = ''
    }
    'New-VcConnector'                  = @{
        'TppVersion'    = ''
        'TppTokenScope' = ''
    }
    'New-TrustClient'                = @{
        'TppVersion'    = ''
        'TppTokenScope' = ''
    }
    'Remove-VdcCertificate'            = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'certificate=delete.  If using KeepAssociatedApps, configuration=$null,certificate=manage as well.'
    }
    'Remove-VdcCertificateAssociation' = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'certificate=manage.  If using -All, configuration=$null as well.'
    }
    'Remove-VdcClient'                 = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'agent=delete'
    }
    'Remove-VdcEngineFolder'           = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=delete'
    }
    'Remove-VdcObject'                 = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=delete'
    }
    'Remove-VdcPermission'             = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'security=delete'
    }
    'Rename-VdcObject'                 = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=manage'
    }
    'Revoke-VdcGrant'                  = @{
        'TppVersion'    = '22.3'
        'TppTokenScope' = 'admin=delete'
    }
    'Set-VdcAttribute'                 = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=manage'
    }
    'Set-VdcCredential'                = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'security=manage'
    }
    'Set-VdcPermission'                = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'security=manage'
    }
    'Set-VdcWorkflowTicketStatus'      = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'approve with any scope'
    }
    'Test-VdcIdentity'                 = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=$null'
    }
    'Test-VdcObject'                   = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=$null'
    }
    'Write-VdcLog'                     = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'any scope'
    }
}