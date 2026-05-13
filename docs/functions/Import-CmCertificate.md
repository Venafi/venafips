# Import-CmCertificate

## SYNOPSIS
Import one or more certificates

## SYNTAX

### ByData (Default)
```
Import-CmCertificate -Data <String> -PolicyPath <String> [-Name <String>] [-EnrollmentAttribute <Hashtable>]
 [-PrivateKeyPassword <PSObject>] [-Reconcile] [-Force] [-ThrottleLimit <Int32>] [-PassThru]
 [-TrustClient <TrustClient>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### ByFileWithPrivateKey
```
Import-CmCertificate -Path <String> -PolicyPath <String> [-Name <String>] [-EnrollmentAttribute <Hashtable>]
 -PrivateKey <String> -PrivateKeyPassword <PSObject> [-Reconcile] [-Force] [-ThrottleLimit <Int32>] [-PassThru]
 [-TrustClient <TrustClient>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### ByFile
```
Import-CmCertificate -Path <String> -PolicyPath <String> [-Name <String>] [-EnrollmentAttribute <Hashtable>]
 [-PrivateKeyPassword <PSObject>] [-Reconcile] [-Force] [-ThrottleLimit <Int32>] [-PassThru]
 [-TrustClient <TrustClient>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### ByDataWithPrivateKey
```
Import-CmCertificate -Data <String> -PolicyPath <String> [-Name <String>] [-EnrollmentAttribute <Hashtable>]
 -PrivateKey <String> -PrivateKeyPassword <PSObject> [-Reconcile] [-Force] [-ThrottleLimit <Int32>] [-PassThru]
 [-TrustClient <TrustClient>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Import one or more certificates with or without private key.
PowerShell v5 will execute sequentially and v7 will run in parallel.

## EXAMPLES

### EXAMPLE 1
```
Import-CmCertificate -PolicyPath \ved\policy\mycerts -Path c:\www.VenafiPS.com.cer
```

Import a certificate

### EXAMPLE 2
```
gci c:\certs | Import-CmCertificate -PolicyPath \ved\policy\mycerts
```

Import multiple certificates. 
On PS v7+, the certificates will be imported in parallel.

### EXAMPLE 3
```
Import-CmCertificate -PolicyPath mycerts -Data $certData
```

Import a certificate from data instead of a path

### EXAMPLE 4
```
$sess = New-TrustClient -Server venafi.mycompany.com -Credential $cred -ClientId VenafiPS-MyApp -Scope @{'certificate'='manage'} -PassThru
Find-TrustCertificate -VersionType CURRENT | Export-TrustCertificate -PrivateKeyPassword 'myPassword!' -PKCS12 | Import-CmCertificate -PolicyPath 'certificates' -TrustClient $sess
```

Export 1 or more certificates from Certificate Manager, SaaS and import to Certificate Manager, Self-Hosted. 
Note the use of 2 sessions at once where the Certificate Manager, Self-Hosted session is stored in a variable.

## PARAMETERS

### -Path
Path to a certificate file. 
Provide either this or -Data.

```yaml
Type: String
Parameter Sets: ByFileWithPrivateKey, ByFile
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Data
Contents of a certificate or certificate/key to import in Base64. 
Provide either this or -Path.

```yaml
Type: String
Parameter Sets: ByData, ByDataWithPrivateKey
Aliases: CertificateData

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -PolicyPath
Policy path to import the certificate to.
\ved\policy is prepended if not provided.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Name
Optional name for the certificate object.
If not provided, the certificate Common Name (CN) is used.
The derived certificate object name references an existing object (of any class).
If another certificate has the same CN, a dash (-) integer appends to the CertificateDN.
For example, test.venafi.example - 3.
If not provided and the CN is also missing, the name becomes the first Domain Name System (DNS) Subject Alternative Name (SAN).
Finally, if none of the above are found, the serial number is used.

```yaml
Type: String
Parameter Sets: (All)
Aliases: FullName

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -EnrollmentAttribute
A hashtable providing any CA attributes to store with the Certificate object, and then submit to the CA during enrollment

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PrivateKey
Private key data; requires a value for PrivateKeyPassword.
For a PEM certificate, the private key is in either the RSA or PKCS#8 format.
Do not provide when the value for -Data is PKCS12 or PKCS8 as the private key is already included.

```yaml
Type: String
Parameter Sets: ByFileWithPrivateKey, ByDataWithPrivateKey
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PrivateKeyPassword
Password required if providing a private key.
You can either provide a String, SecureString, or PSCredential.

```yaml
Type: PSObject
Parameter Sets: ByData
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

```yaml
Type: PSObject
Parameter Sets: ByFileWithPrivateKey
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

```yaml
Type: PSObject
Parameter Sets: ByFile
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

```yaml
Type: PSObject
Parameter Sets: ByDataWithPrivateKey
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Reconcile
Controls certificate and corresponding private key replacement.
By default, this function will import and replace the certificate regardless of whether a past, future, or same version of the certificate exists in Trust Protection Platform.
By using this parameter, this function will import, but use newest.
Only import the certificate when no Certificate object exists with a past, present, or current version of the imported certificate.
If a match is found between the Certificate object and imported certificate, activate the certificate with the most current 'Valid From' date.
Archive the unused certificate, even if it is the imported certificate, to the History tab.
See https://docs.venafi.com/Docs/currentSDK/TopNav/Content/CA/c-CA-Import-ReconciliationRules-tpp.php for a flowchart of the reconciliation algorithm.

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

### -Force
Force the policy path to be created if it doesn't exist

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

### -PassThru
Return the newly imported object.

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

### -TrustClient
Authentication for the function.
The value defaults to the script session object $TrustClient created by New-TrustClient.

```yaml
Type: TrustClient
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: (Get-TrustClient)
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

### Path, Data, PolicyPath, PrivateKeyPassword
## OUTPUTS

### PSCustomObject, if PassThru provided
## NOTES

## RELATED LINKS

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Certificates-Import.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Certificates-Import.php)

