# Export-VdcCertificate

## SYNOPSIS
Export certificate data from TLSPDC

## SYNTAX

### X509ByPath (Default)
```
Export-VdcCertificate -Path <String> [-X509] [-IncludeChain] [-FriendlyName <String>] [-OutPath <String>]
 [-ThrottleLimit <Int32>] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### JksByPath
```
Export-VdcCertificate -Path <String> [-Jks] [-PrivateKeyPassword <PSObject>] [-IncludeChain]
 -FriendlyName <String> -KeystorePassword <PSObject> [-OutPath <String>] [-ThrottleLimit <Int32>]
 [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Pkcs12ByPath
```
Export-VdcCertificate -Path <String> [-Pkcs12] -PrivateKeyPassword <PSObject> [-IncludeChain]
 [-FriendlyName <String>] [-OutPath <String>] [-ThrottleLimit <Int32>] [-VenafiSession <PSObject>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### DerByPath
```
Export-VdcCertificate -Path <String> [-Der] [-OutPath <String>] [-ThrottleLimit <Int32>]
 [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Pkcs8ByPath
```
Export-VdcCertificate -Path <String> [-Pkcs8] [-PrivateKeyPassword <PSObject>] [-IncludeChain]
 [-OutPath <String>] [-ThrottleLimit <Int32>] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### Pkcs7ByPath
```
Export-VdcCertificate -Path <String> [-Pkcs7] [-IncludeChain] [-OutPath <String>] [-ThrottleLimit <Int32>]
 [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### JksByVault
```
Export-VdcCertificate -VaultId <PSObject> [-Jks] [-PrivateKeyPassword <PSObject>] [-IncludeChain]
 -FriendlyName <String> -KeystorePassword <PSObject> [-OutPath <String>] [-ThrottleLimit <Int32>]
 [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Pkcs12ByVault
```
Export-VdcCertificate -VaultId <PSObject> [-Pkcs12] -PrivateKeyPassword <PSObject> [-IncludeChain]
 [-FriendlyName <String>] [-OutPath <String>] [-ThrottleLimit <Int32>] [-VenafiSession <PSObject>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### DerByVault
```
Export-VdcCertificate -VaultId <PSObject> [-Der] [-OutPath <String>] [-ThrottleLimit <Int32>]
 [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Pkcs8ByVault
```
Export-VdcCertificate -VaultId <PSObject> [-Pkcs8] [-PrivateKeyPassword <PSObject>] [-IncludeChain]
 [-OutPath <String>] [-ThrottleLimit <Int32>] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### Pkcs7ByVault
```
Export-VdcCertificate -VaultId <PSObject> [-Pkcs7] [-IncludeChain] [-OutPath <String>] [-ThrottleLimit <Int32>]
 [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### X509ByVault
```
Export-VdcCertificate -VaultId <PSObject> [-X509] [-IncludeChain] [-FriendlyName <String>] [-OutPath <String>]
 [-ThrottleLimit <Int32>] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Export certificate data including certificate, key, and chain.
Export certificates by path or vault id, the latter is helpful for historical certificates.

## EXAMPLES

### EXAMPLE 1
```
Export-VdcCertificate -Path '\ved\policy\mycert.com'
```

Get certificate data in X509 format, the default

### EXAMPLE 2
```
$cert | Export-VdcCertificate -PKCS7 -OutPath 'c:\temp'
```

Get certificate data in a specific format and save to a file

### EXAMPLE 3
```
$cert | Export-VdcCertificate -PKCS7 -IncludeChain
```

Get one or more certificates with the certificate chain included

### EXAMPLE 4
```
$cert | Export-VdcCertificate -PKCS12 -PrivateKeyPassword 'mySecretPassword!'
```

Get one or more certificates with private key included

### EXAMPLE 5
```
Export-VdcCertificate -VaultId 12345 -PKCS12 -PrivateKeyPassword 'mySecretPassword!'
```

Export certificate and private key from the vault

### EXAMPLE 6
```
$cert | Export-VdcCertificate -PKCS8 -PrivateKeyPassword 'mySecretPassword!' -OutPath '~/temp'
```

Save certificate info to a file. 
PKCS8 with private key will save 3 files, .pem (cert+key), .pem.cer (cert only), and .pem.key (key only)

### EXAMPLE 7
```
$cert | Export-VdcCertificate -Jks -FriendlyName 'MyFriendlyName' -KeystorePassword $cred.password
```

Get certificates in JKS format.

## PARAMETERS

### -Path
Full path to the certificate

```yaml
Type: String
Parameter Sets: X509ByPath, JksByPath, Pkcs12ByPath, DerByPath, Pkcs8ByPath, Pkcs7ByPath
Aliases: id

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -VaultId
Vault ID to the certificate

```yaml
Type: PSObject
Parameter Sets: JksByVault, Pkcs12ByVault, DerByVault, Pkcs8ByVault, Pkcs7ByVault, X509ByVault
Aliases: Certificate Vault Id, PreviousVersions

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -X509
Provide output in X509 Base64 format. 
This is the default if no format is provided.

```yaml
Type: SwitchParameter
Parameter Sets: X509ByPath, X509ByVault
Aliases: Base64

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Pkcs7
Provide output in PKCS #7 format

```yaml
Type: SwitchParameter
Parameter Sets: Pkcs7ByPath, Pkcs7ByVault
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Pkcs8
Provide output in PKCS #8 format

```yaml
Type: SwitchParameter
Parameter Sets: Pkcs8ByPath, Pkcs8ByVault
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Der
Provide output in DER format

```yaml
Type: SwitchParameter
Parameter Sets: DerByPath, DerByVault
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Pkcs12
Provide output in PKCS #12 format. 
Requires a value for PrivateKeyPassword.

```yaml
Type: SwitchParameter
Parameter Sets: Pkcs12ByPath, Pkcs12ByVault
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Jks
Provide output in JKS format. 
Requires a value for FriendlyName.

```yaml
Type: SwitchParameter
Parameter Sets: JksByPath, JksByVault
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -PrivateKeyPassword
Password required to include the private key.
You can either provide a String, SecureString, or PSCredential.
You must adhere to the following rules:
- Password is at least 12 characters.
- Comprised of at least three of the following:
    - Uppercase alphabetic letters
    - Lowercase alphabetic letters
    - Numeric characters
    - Special characters

```yaml
Type: PSObject
Parameter Sets: JksByPath, Pkcs8ByPath, JksByVault, Pkcs8ByVault
Aliases: SecurePassword

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: PSObject
Parameter Sets: Pkcs12ByPath, Pkcs12ByVault
Aliases: SecurePassword

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeChain
Include the certificate chain with the exported certificate.
The end entity will be first and the root last.

```yaml
Type: SwitchParameter
Parameter Sets: X509ByPath, JksByPath, Pkcs12ByPath, Pkcs8ByPath, Pkcs7ByPath, JksByVault, Pkcs12ByVault, Pkcs8ByVault, Pkcs7ByVault, X509ByVault
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -FriendlyName
Label or alias to use. 
Permitted with Base64 and PKCS #12 formats. 
Required when exporting JKS.

```yaml
Type: String
Parameter Sets: X509ByPath, Pkcs12ByPath, Pkcs12ByVault, X509ByVault
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: JksByPath, JksByVault
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -KeystorePassword
Password required to retrieve the certificate in JKS format.
You can either provide a String, SecureString, or PSCredential.
You must adhere to the following rules:
- Password is at least 12 characters.
- Comprised of at least three of the following:
    - Uppercase alphabetic letters
    - Lowercase alphabetic letters
    - Numeric characters
    - Special characters

```yaml
Type: PSObject
Parameter Sets: JksByPath, JksByVault
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OutPath
Folder path to save the certificate/key to. 
The name of the file will be determined automatically.

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

### -VenafiSession
Authentication for the function.
The value defaults to the script session object $VenafiSession created by New-VenafiSession.

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

### Path, VaultId
## OUTPUTS

### PSCustomObject
## NOTES

## RELATED LINKS
