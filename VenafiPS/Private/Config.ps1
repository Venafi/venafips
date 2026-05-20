$script:CmsRegions = @{
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
    'Add-CmAdaptableHash'             = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'restricted=manage,delete'
    }
    'Add-CmCertificateAssociation'    = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'certificate=manage'
    }
    'Add-CmEngineFolder'              = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=manage'
    }
    'Add-CmTeamMember'                = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=manage'
    }
    'Add-CmTeamOwner'                 = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=manage'
    }
    'Convert-CmObject'                = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=manage'
    }
    'Export-CmCertificate'            = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'certificate=manage'
    }
    'Find-CmClient'                   = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'agent=$null'
    }
    'Find-CmEngine'                   = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=$null'
    }
    'Find-CmIdentity'                 = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=$null'
    }
    'Find-CmObject'                   = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=$null'
    }
    'Find-CmVaultId'                  = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'restricted=$null'
    }
    'Find-CmCertificate'              = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'certificate=$null'
    }
    'Get-CmAttribute'                 = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=$null'
    }
    'Get-CmClassAttribute'            = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'any scope'
    }
    'Get-CmCredential'                = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'security=manage'
    }
    'Get-CmCustomField'               = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'any scope'
    }
    'Get-CmEngineFolder'              = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=manage'
    }
    'Get-CmIdentityAttribute'         = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=$null'
    }
    'Get-CmObject'                    = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'any scope'
    }
    'Get-CmPermission'                = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'security=$null'
    }
    'Get-CmSystemStatus'              = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'any scope'
    }
    'Get-CmWorkflowTicket'            = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'any scope'
    }
    'Get-CmCertificate'               = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'certificate=$null'
    }
    'Get-CmIdentity'                  = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=$null'
    }
    'Get-CmTeam'                      = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=manage'
    }
    'Import-CmCertificate'            = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'certificate=discover'
    }
    'Import-TrustCertificate'             = @{
        'CmVersion'    = ''
        'CmTokenScope' = ''
    }
    'Invoke-CmCertificateAction'      = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'certificate=manage for Reset, Renew, Push, and Validate.  certificate=revoke for Revoke.  certificate=delete for Delete.'
    }
    'Move-CmObject'                   = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=manage'
    }
    'New-CmCapiApplication'           = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=manage'
    }
    'New-CmCertificate'               = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'certificate=manage'
    }
    'New-CmCustomField'               = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=manage'
    }
    'New-CmDevice'                    = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=manage'
    }
    'New-CmObject'                    = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=manage.  If a certificate is provided as an attribute, certificate=manage as well.'
    }
    'New-CmPolicy'                    = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=manage'
    }
    'New-CmToken'                     = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'any scope'
    }
    'Remove-CmCertificate'            = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'certificate=delete.  If using KeepAssociatedApps, configuration=$null,certificate=manage as well.'
    }
    'Remove-CmCertificateAssociation' = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'certificate=manage.  If using -All, configuration=$null as well.'
    }
    'Remove-CmClient'                 = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'agent=delete'
    }
    'Remove-CmEngineFolder'           = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=delete'
    }
    'Remove-CmObject'                 = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=delete'
    }
    'Remove-CmPermission'             = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'security=delete'
    }
    'Rename-CmObject'                 = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=manage'
    }
    'Revoke-CmGrant'                  = @{
        'CmVersion'    = '22.3'
        'CmTokenScope' = 'admin=delete'
    }
    'Set-CmAttribute'                 = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=manage'
    }
    'Set-CmCredential'                = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'security=manage'
    }
    'Set-CmPermission'                = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'security=manage'
    }
    'Set-CmWorkflowTicketStatus'      = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'approve with any scope'
    }
    'Test-CmIdentity'                 = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=$null'
    }
    'Test-CmObject'                   = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=$null'
    }
    'Write-CmLog'                     = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'any scope'
    }
}

$script:pssodiumHash = @(
  @{
    "Hash" = "1F737BA71E3974A46C433EC0BE5FC3AAC192947EB49E57FED81BA03974C9FFB0"
    "Path" = "PSSodium.psd1"
  },
  @{
    "Hash" = "2386BA5A4BD0D58A9C54D2BC9C2CEC0996510A62CEBCE03BC3C6ADEE58A2323C"
    "Path" = "PSSodium.psm1"
  },
  @{
    "Hash" = "544A41BAC3F077EA8D407714BAF4B5B920AA64A361F4D48F5DD0FFE18129EF3A"
    "Path" = "osx-x64/libsodium.dylib"
  },
  @{
    "Hash" = "7B3F9117E75E08FB62C02800B81954CFCCD8AC786F0E7B8252A75168198CFFDF"
    "Path" = "osx-x64/PSSodium.deps.json"
  },
  @{
    "Hash" = "661B80657EA21EBC2FF227E1F8DEBAE62010720F76EBC20A99276492AABE0A3E"
    "Path" = "osx-x64/PSSodium.dll"
  },
  @{
    "Hash" = "184AF6E3C1DD9C9F5CF4F21F6E2E108AF17AE7A1A374AD5F096F7CFD631E250C"
    "Path" = "osx-x64/PSSodium.pdb"
  },
  @{
    "Hash" = "6F6FB019102CBCD23E526CE174F8D0FDE82E69368C5388EE4C2BA5D24E2A079A"
    "Path" = "osx-x64/Sodium.Core.dll"
  },
  @{
    "Hash" = "E8CA128061F7F1D718CA970DDEC21F5B1AFDF6A23BADF5B2AC847957B25BCD68"
    "Path" = "win-x86/libsodium.dll"
  },
  @{
    "Hash" = "3DE1CF1703324F9FE86E335B23F8BA0144863FF4680C7AC572E844D45E30E794"
    "Path" = "win-x86/PSSodium.deps.json"
  },
  @{
    "Hash" = "1CB8D482A5C3E06CA553F833C721E0FBBDBEDB266DE092D0B2E5EF5D5BD2821A"
    "Path" = "win-x86/PSSodium.dll"
  },
  @{
    "Hash" = "6BF8E46B7A3B4DBA9E79F1C58E9320EAF5E1B80E2FB24FBE2018B95EDD98E866"
    "Path" = "win-x86/PSSodium.pdb"
  },
  @{
    "Hash" = "6F6FB019102CBCD23E526CE174F8D0FDE82E69368C5388EE4C2BA5D24E2A079A"
    "Path" = "win-x86/Sodium.Core.dll"
  },
  @{
    "Hash" = "45FB67A2EF1A5381F3855C340F09E9C365C8912371497C25B2A71B8105437492"
    "Path" = "osx-arm64/libsodium.dylib"
  },
  @{
    "Hash" = "EB525F0593B0EA09E24FD280753AD3C2CA336261BE1390C79B78760846FF2AFF"
    "Path" = "osx-arm64/PSSodium.deps.json"
  },
  @{
    "Hash" = "8268DD42E59C60F3385D5E33F431DEC3B7C1ED05DE0AFE1127CF5189DBD707E5"
    "Path" = "osx-arm64/PSSodium.dll"
  },
  @{
    "Hash" = "77AE8E2A955EB5E619B8D60AC3464B8937A8E188052926DB2570C42F31012D7E"
    "Path" = "osx-arm64/PSSodium.pdb"
  },
  @{
    "Hash" = "6F6FB019102CBCD23E526CE174F8D0FDE82E69368C5388EE4C2BA5D24E2A079A"
    "Path" = "osx-arm64/Sodium.Core.dll"
  },
  @{
    "Hash" = "7B5E4DF6431661C1CF4F6442124AC0BF5371B1DBCCDED702044DDFF98A43ECAA"
    "Path" = "win-x64/libsodium.dll"
  },
  @{
    "Hash" = "295881CBA6BF3E1CEA7DC1961D1BD1F02D987C6EEC5D4EB6C3B13E7D26B2A927"
    "Path" = "win-x64/PSSodium.deps.json"
  },
  @{
    "Hash" = "8DB26262355DDA7C8CFCBF55A75EF47ADE5B62C6BCBD7C7F3518DD462B59D1F0"
    "Path" = "win-x64/PSSodium.dll"
  },
  @{
    "Hash" = "DACBCF039B31E05D01C0D190B08C546395EE7B8C007E9C0560593B597CB314C7"
    "Path" = "win-x64/PSSodium.pdb"
  },
  @{
    "Hash" = "6F6FB019102CBCD23E526CE174F8D0FDE82E69368C5388EE4C2BA5D24E2A079A"
    "Path" = "win-x64/Sodium.Core.dll"
  },
  @{
    "Hash" = "EF0795CBE3D3840E28F60435AD78E89DA5C8BE47C17F7B293252C9F69FAFD1F0"
    "Path" = "linux-x64/libsodium.so"
  },
  @{
    "Hash" = "273944F263C3B74E8ABE3E5B856CBCE1C91E8D15505BD12B70EA8EADBCA40F6C"
    "Path" = "linux-x64/PSSodium.deps.json"
  },
  @{
    "Hash" = "BC7C9C53DFD2FECBC59B9A423C4CA9218F1B54E11BC622423950F58E154946BA"
    "Path" = "linux-x64/PSSodium.dll"
  },
  @{
    "Hash" = "998D99E24D368CE873974701D6799991714B9071D63EBCECE893FB00771A65AA"
    "Path" = "linux-x64/PSSodium.pdb"
  },
  @{
    "Hash" = "6F6FB019102CBCD23E526CE174F8D0FDE82E69368C5388EE4C2BA5D24E2A079A"
    "Path" = "linux-x64/Sodium.Core.dll"
  }
)