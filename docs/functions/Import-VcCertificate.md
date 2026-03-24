# Import-VcCertificate

## SYNOPSIS
Import one or more certificates

## SYNTAX

### ByFile (Default)
```
Import-VcCertificate -Path <String> [-PrivateKeyPassword <PSObject>] [-ThrottleLimit <Int32>] [-Recurse]
 [-Force] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### ByData
```
Import-VcCertificate -Data <String> [-Format <String>] [-PrivateKeyPassword <PSObject>]
 [-ThrottleLimit <Int32>] [-Force] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Import one or more certificates and their private keys.
PKCS8 (.pem), PKCS12 (.pfx or .p12), and X509 (.pem, .cer, or .crt) certificates are supported.
Certificates/keys can be imported from a file or from data provided directly to the function, eg.
exporting from Certificate Manager, Self-Hosted and importing into Certificate Manager, SaaS.

## EXAMPLES

### EXAMPLE 1
```
Import-VcCertificate -CertificatePath c:\www.VenafiPS.com.pfx
```

Import a certificate/key

### EXAMPLE 2
```
Export-VdcCertificate -Path '\ved\policy\my.cert.com' -Pkcs12 -PrivateKeyPassword 'myPassw0rd!' | Import-VcCertificate -VenafiSession $vaas_key
```

Export from Certificate Manager, Self-Hosted and import into Certificate Manager, SaaS.
As $VenafiSession can only point to one platform at a time, in this case Certificate Manager, Self-Hosted, the session needs to be overridden for the import.

### EXAMPLE 3
```
Find-VdcCertificate -Path '\ved\policy\certs' -Recursive | Export-VdcCertificate -Pkcs12 -PrivateKeyPassword 'myPassw0rd!' | Import-VcCertificate -VenafiSession $vaas_key
```

Bulk export from Certificate Manager, Self-Hosted and import into Certificate Manager, SaaS.
As $VenafiSession can only point to one platform at a time, in this case Certificate Manager, Self-Hosted, the session needs to be overridden for the import.

### EXAMPLE 4
```
Find-VcCertificate | Export-VcCertificate -PrivateKeyPassword 'secretPassword#' -PKCS12 | Import-VcCertificate -VenafiSession $tenant2_key
```

Export from 1 Certificate Manager, SaaS tenant and import to another.
This assumes New-VenafiSession has been run for the source tenant.

## PARAMETERS

### -Path
Path to a certificate file or folder with multiple certificates.
Wildcards are also supported, eg.
/my/path/*.pfx.
Provide either this or -Data.

```yaml
Type: String
Parameter Sets: ByFile
Aliases: FullName, CertificatePath, FilePath

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Data
Contents of a certificate/key to import.
Provide either this or -Path.

```yaml
Type: String
Parameter Sets: ByData
Aliases: certificateData

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Format
Specify the format provided in -Data.
PKCS12, PKCS8, and X509 are supported.

The format is now automatically detected, so this parameter is not required or used.

```yaml
Type: String
Parameter Sets: ByData
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PrivateKeyPassword
Password the private key was encrypted with

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ThrottleLimit
Limit the number of threads when running in parallel; the default is 1.
100 keystores will be imported at a time so it's less important to have a very high throttle limit.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 1
Accept pipeline input: False
Accept wildcard characters: False
```

### -Recurse
When providing a folder path, include subfolders in the search for certificates to import.

```yaml
Type: SwitchParameter
Parameter Sets: ByFile
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Force installation of PSSodium if not already installed. 
This is required for the import of keys.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -VenafiSession
Authentication for the function.
The value defaults to the script session object $VenafiSession created by New-VenafiSession.
A Certificate Manager, SaaS key can also provided.

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: (Get-VenafiSession)
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

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

### Data
## OUTPUTS

## NOTES
This function requires the use of sodium encryption via the PSSodium PowerShell module.
Dotnet standard 2.0 or greater is required via PS Core (recommended) or supporting .net runtime.
On Windows, the latest Visual C++ redist must be installed. 
See https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist.

Non keystore imports, just certs no keys, will override the blocklist by default.
To honor the blocklist, set the environment variable VC_ENABLE_BLOCKLIST to 'true'.

## RELATED LINKS

[https://developer.venafi.com/tlsprotectcloud/reference/certificates_import](https://developer.venafi.com/tlsprotectcloud/reference/certificates_import)

