# Export-CmVaultObject

## SYNOPSIS
Export an object from the vault

## SYNTAX

### ToPipeline (Default)
```
Export-CmVaultObject -ID <PSObject> [-TrustClient <TrustClient>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### ToFile
```
Export-CmVaultObject -ID <PSObject> -OutPath <String> [-TrustClient <TrustClient>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Export different object types from the vault.
The currently supported types are certificate, key, and PKCS12.
If the type is not supported, the base64 data will be returned as is.

## EXAMPLES

### EXAMPLE 1
```
Export-CmVaultObject -ID 12345
```

Get vault object details

### EXAMPLE 2
```
Find-CmObject -Path '\VED\Intermediate and Root Certificates\Trusted Root Certification Authorities' | Get-CmAttribute -Attribute 'Certificate Vault Id' | Export-CmVaultObject
```

Get intermediate or root certificates. 
Export to the pipeline instead of to a file.

### EXAMPLE 3
```
Get-CmCertificate -Path 'certificates\www.greg.com' -IncludePreviousVersions | Export-CmVaultObject
```

Export historical certificates

### EXAMPLE 4
```
Export-CmVaultObject -ID 12345 -OutPath 'c:\temp'
```

Get vault object and save to a file

## PARAMETERS

### -ID
ID of the vault object to export

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases: VaultId, Certificate Vault Id, PreviousVersions

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -OutPath
Folder path to save the certificate/key to. 
The name of the file will be determined automatically.
If not provided, details will be provided to the pipeline.

```yaml
Type: String
Parameter Sets: ToFile
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TrustClient
Authentication for the function.
The value defaults to the script session object $TrustClient created by New-TrustClient.

```yaml
Type: TrustClient
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### ID
## OUTPUTS

### PSCustomObject
## NOTES

## RELATED LINKS
