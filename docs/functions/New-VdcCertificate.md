# New-VdcCertificate

## SYNOPSIS
Enrolls or provisions a new certificate

## SYNTAX

### ByName (Default)
```
New-VdcCertificate -Path <String> -Name <String> [-CommonName <String>] [-Csr <String>]
 [-CertificateType <String>] [-CertificateAuthorityPath <String>] [-CertificateAuthorityAttribute <Hashtable>]
 [-ManagementType <TppManagementType>] [-SubjectAltName <Hashtable[]>] [-CustomField <Hashtable>] [-NoWorkToDo]
 [-Device <Hashtable[]>] [-TimeoutSec <Int32>] [-PassThru] [-VenafiSession <PSObject>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### ByNameWithDevice
```
New-VdcCertificate -Path <String> -Name <String> [-CommonName <String>] [-Csr <String>]
 [-CertificateType <String>] [-CertificateAuthorityPath <String>] [-CertificateAuthorityAttribute <Hashtable>]
 [-ManagementType <TppManagementType>] [-SubjectAltName <Hashtable[]>] [-CustomField <Hashtable>] [-NoWorkToDo]
 -Device <Hashtable[]> [-Application <Hashtable[]>] [-TimeoutSec <Int32>] [-PassThru]
 [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Enrolls or provisions a new certificate

## EXAMPLES

### EXAMPLE 1
```
New-VdcCertificate -Path '\ved\policy\folder' -Name 'mycert.com'
Create certificate by name.  A CA template policy must be defined.
```

### EXAMPLE 2
```
New-VdcCertificate -Path '\ved\policy\folder' -Name 'mycert.com' -CertificateAuthorityPath '\ved\policy\CA Templates\my template'
Create certificate by name with specific CA template
```

### EXAMPLE 3
```
New-VdcCertificate -Path '\ved\policy\folder' -CertificateAuthorityPath '\ved\policy\CA Templates\my template' -Csr '-----BEGIN CERTIFICATE REQUEST-----\nMIIDJDCCAgwCAQAw...-----END CERTIFICATE REQUEST-----'
Create certificate using a CSR
```

### EXAMPLE 4
```
New-VdcCertificate -Path '\ved\policy\folder' -Name 'mycert.com' -CertificateAuthorityPath '\ved\policy\CA Templates\my template' -CustomField @{''=''}
Create certificate and update custom fields
```

### EXAMPLE 5
```
New-VdcCertificate -Path '\ved\policy\folder' -CommonName 'mycert.com' -CertificateAuthorityPath '\ved\policy\CA Templates\my template' -PassThru
Create certificate using common name.  Return the created object.
```

### EXAMPLE 6
```
New-VdcCertificate -Path '\ved\policy\folder' -Name 'mycert.com' -CertificateAuthorityPath '\ved\policy\CA Templates\my template' -SubjectAltName @{'Email'='me@x.com'},@{'IPAddress'='1.2.3.4'}
Create certificate including subject alternate names
```

### EXAMPLE 7
```
New-VdcCertificate -Path '\ved\policy\folder' -Name 'mycert.com' -Device @{'PolicyDN'=$DevicePath; 'ObjectName'='MyDevice'; 'Host'='1.2.3.4'} -Application @{'DeviceName'='MyDevice'; 'ObjectName'='BasicApp'; 'DriverName'='appbasic'}
Create a new certificate with associated device and app objects
```

### EXAMPLE 8
```
New-VdcCertificate -Path '\ved\policy\certs' -Name 'www.barron.com' -CertificateAuthorityPath '\ved\policy\CA Templates\my template' -TimeoutSec 30 -PassThru | Export-VdcCertificate -PKCS12 -PrivateKeyPassword 'mySecretPassword!'
```

Wait up to 30 seconds for the CA to create the certificate and then export it

## PARAMETERS

### -Path
The folder DN path for the new certificate.

```yaml
Type: String
Parameter Sets: (All)
Aliases: PolicyDN

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
Name of the certifcate object.
If CommonName isn't provided, this value will be used.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -CommonName
Subject Common Name. 
If CommonName isn't provided, Name will be used.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Subject

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Csr
The PKCS#10 Certificate Signing Request (CSR).
If this value is provided, any Subject DN fields and the KeyBitSize in the request are ignored.

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

### -CertificateType
Type of certificate to be created. 
The default is X.509 Server Certificate.

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

### -CertificateAuthorityPath
The path of the Certificate Authority Template object for enrolling the certificate.
If the value is missing, it is expected a policy has been applied to Path.

```yaml
Type: String
Parameter Sets: (All)
Aliases: CADN, CertificateAuthorityDN

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CertificateAuthorityAttribute
Name/value pairs providing any CA attributes to store with the Certificate object.
During enrollment, these values will be submitted to the CA.

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

### -ManagementType
The level of management that Trust Protection Platform applies to the certificate:
- Enrollment: Default.
Issue a new certificate, renewed certificate, or key generation request to a CA for enrollment.
Do not automatically provision the certificate.
- Provisioning:  Issue a new certificate, renewed certificate, or key generation request to a CA for enrollment.
Automatically install or provision the certificate.
- Monitoring:  Allow Trust Protection Platform to monitor the certificate for expiration and renewal.
- Unassigned: Certificates are neither enrolled or monitored by Trust Protection Platform.

```yaml
Type: TppManagementType
Parameter Sets: (All)
Aliases:
Accepted values: Unassigned, Monitoring, Enrollment, Provisioning

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SubjectAltName
A list of Subject Alternate Names.
The value must be 1 or more hashtables with the SAN type and value.
Acceptable SAN types are OtherName, Email, DNS, URI, and IPAddress.
You can provide more than 1 of the same SAN type with multiple hashtables.

```yaml
Type: Hashtable[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CustomField
Hashtable of custom field(s) to be updated when creating the certificate.
This is required when the custom fields are mandatory.
The key is the name, not guid, of the custom field.

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

### -NoWorkToDo
Turn off lifecycle processing for this certificate update

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

### -Device
An array of hashtables for devices to be created.
Available parameters can be found at https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Certificates-request.php.
If provisioning applications as well, those should be provided with the Application parameter.

```yaml
Type: Hashtable[]
Parameter Sets: ByName
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: Hashtable[]
Parameter Sets: ByNameWithDevice
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Application
An array of hashtables for applications to be created.
Available parameters can be found at https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Certificates-request-ApplicationsParameter.php.
In addition to the application parameters, a key/value must be provided for the associated device.
The key needs to be 'DeviceName' and the value is the ObjectName from the device.
See the example.

```yaml
Type: Hashtable[]
Parameter Sets: ByNameWithDevice
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TimeoutSec
Control the wait time, in seconds, for a CA to issue/renew a certificate.
Can be set globally in the product, https://docs.venafi.com/Docs/currentSDK/TopNav/Content/SDK/WebSDK/r-SDK-Certificates-API-settings.php.
Use this as an override to the global setting.
The product default of 0 will cause this function to return immediately, before the certificate has been created.
This property is useful if you are wanting to immediately access the certificate when New-VdcCertificate is finished, eg.
to pipe to Export-VdcCertificate.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases: WorkToDoTimeout

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
Return an object representing the newly created certificate.
If devices and/or applications were created, a 'Device' property will be available as well.

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

### None
## OUTPUTS

### PSCustomObject, if PassThru is provided
### If devices and/or applications were created, a 'Device' property will be available as well.
## NOTES

## RELATED LINKS

[https://venafi.github.io/VenafiPS/functions/New-VdcCertificate/](https://venafi.github.io/VenafiPS/functions/New-VdcCertificate/)

[https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/New-VdcCertificate.ps1](https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/New-VdcCertificate.ps1)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Certificates-request.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Certificates-request.php)

