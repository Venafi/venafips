# Export-VcCertificate

## SYNOPSIS
Export certificate data from TLSPC

## SYNTAX

### PEM (Default)
```
Export-VcCertificate -ID <String> [-PrivateKeyPassword <PSObject>] [-IncludeChain] [-OutPath <String>]
 [-ThrottleLimit <Int32>] [-Force] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### PKCS12
```
Export-VcCertificate -ID <String> -PrivateKeyPassword <PSObject> [-OutPath <String>] [-PKCS12] [-UseLegacy]
 [-ThrottleLimit <Int32>] [-Force] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Export certificate data in PEM format. 
You can retrieve the certificate, chain, and key.
You can also save the certificate and private key in PEM or PKCS12 format.

## EXAMPLES

### EXAMPLE 1
```
$certId | Export-VcCertificate
```

Export certificate data

### EXAMPLE 2
```
$certId | Export-VcCertificate -PrivateKeyPassword 'myPassw0rd!'
```

Export certificate and private key data

### EXAMPLE 3
```
$certId | Export-VcCertificate -PrivateKeyPassword 'myPassw0rd!' -PKCS12 -OutPath '~/temp'
```

Export certificate and private key in PKCS12 format

### EXAMPLE 4
```
$cert | Export-VcCertificate -OutPath '~/temp'
```

Get certificate data and save to a file

### EXAMPLE 5
```
$cert | Export-VcCertificate -IncludeChain
```

Get certificate data with the certificate chain included.

## PARAMETERS

### -ID
Certificate ID, also known as uuid. 
Use Find-VcCertificate or Get-VcCertificate to determine the ID.
You can pipe those functions as well.

```yaml
Type: String
Parameter Sets: (All)
Aliases: certificateId

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -PrivateKeyPassword
Password required to include the private key.
You can either provide a String, SecureString, or PSCredential.
Requires PowerShell v7.0+.

```yaml
Type: PSObject
Parameter Sets: PEM
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: PSObject
Parameter Sets: PKCS12
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeChain
Include the certificate chain with the exported or saved PEM certificate data.

```yaml
Type: SwitchParameter
Parameter Sets: PEM
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -OutPath
Folder path to save the certificate to. 
The name of the file will be determined automatically.
For each certificate a directory will be created in this folder with the format Name-ID.
In the case of PKCS12, the file will be saved to the root of the folder.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PKCS12
Export the certificate and private key in PKCS12 format. 
The default is PEM.
This is the preferred approach if directly importing into VDC or another VC tenant.
Requires PowerShell v7.1+.

```yaml
Type: SwitchParameter
Parameter Sets: PKCS12
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseLegacy
Use legacy encryption algorithm when exporting in PKCS12 format.
Required for older systems that do not support modern algorithms.

```yaml
Type: SwitchParameter
Parameter Sets: PKCS12
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ThrottleLimit
Limit the number of threads when running in parallel; the default is 100.
Setting the value to 1 will disable multithreading.
On PS v5 the ThreadJob module is required. 
If not found, multithreading will be disabled.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 100
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Force installation of PSSodium if not already installed

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
A TLSPC key can also provided.

```yaml
Type: PSObject
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
This function requires PSSodium. 
Install it from the PSGallery or use -Force to automatically install.
PS v7.1+ is required.
On Windows, the latest Visual C++ redist must be installed. 
See https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist.

## RELATED LINKS
