# New-TrustCertificate

## SYNOPSIS
Create certificate request

## SYNTAX

### ASK (Default)
```
New-TrustCertificate -CommonName <String> [-Application <String>] -IssuingTemplate <String>
 [-Organization <String>] [-OrganizationalUnit <String[]>] [-City <String>] [-State <String>]
 [-Country <String>] [-KeySize <Int32>] [-KeyCurve <String>] [-SanDns <String[]>] [-SanIP <String[]>]
 [-SanUri <String[]>] [-SanEmail <String[]>] [-ValidUntil <DateTime>] [-Tag <String[]>] [-Wait] [-PassThru]
 [-TrustClient <TrustClient>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### CSR
```
New-TrustCertificate -Csr <String> [-Application <String>] -IssuingTemplate <String> [-SanDns <String[]>]
 [-ValidUntil <DateTime>] [-Tag <String[]>] [-OverwriteSan] [-Wait] [-PassThru] [-TrustClient <TrustClient>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Create certificate request from automated secure keypair details or CSR

## EXAMPLES

### EXAMPLE 1
```
New-TrustCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com'
```

Create certificate

### EXAMPLE 2
```
New-TrustCertificate -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com'
```

Create certificate with NGTS, no Application needed

### EXAMPLE 3
```
New-TrustCertificate -Application 'ff23962b-661c-4a83-964b-d86855f1bb93' -IssuingTemplate '2e4a0355-70bf-4ffc-919f-fcfcd4d15e84' -CommonName 'app.mycert.com'
```

Create certificate bypassing application and template name resolution, needed for token based authentication which does not have access to these APIs.

### EXAMPLE 4
```
New-TrustCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com' -Tag 'tag1','tag2:value'
```

Create certificate and associate 1 or more tags

### EXAMPLE 5
```
New-TrustCertificate -Application 'MyApp' -CommonName 'app.mycert.com'
```

Create certificate with the template associated with the application.
This only works when only 1 template is associated with an application.

### EXAMPLE 6
```
New-TrustCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com' -SanIP '1.2.3.4'
```

Create certificate with optional SAN data

### EXAMPLE 7
```
New-TrustCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com' -ValidUntil (Get-Date).AddMonths(6)
```

Create certificate with specific validity

### EXAMPLE 8
```
New-TrustCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com' -PassThru
```

Create certificate and return the created object

### EXAMPLE 9
```
New-TrustCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -CommonName 'app.mycert.com' -Wait -PassThru
```

Create certificate and wait for it to reach a terminal state before returning the result.
The cmdlet will poll the certificate request status until it has been issued or failed.

### EXAMPLE 10
```
New-TrustCertificate -Application 'MyApp' -IssuingTemplate 'MSCA - 1 year' -Csr "-----BEGIN CERTIFICATE REQUEST-----\nMIICYzCCAUsCAQAwHj....BoiNIqtVQxFsfT+\n-----END CERTIFICATE REQUEST-----\n"
```

Create certificate by providing a CSR

## PARAMETERS

### -CommonName
Common name (CN). 
Required if not providing a CSR.

```yaml
Type: String
Parameter Sets: ASK
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Csr
CSR in PKCS#10 format which conforms to the rules of the issuing template

```yaml
Type: String
Parameter Sets: CSR
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Application
Application name or id to associate this certificate with, only applicable to CMSaaS, not NGTS.
Tab completion is supported.

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

### -IssuingTemplate
Issuing template id, name, or alias.
Tab completion is supported.

For CMSaaS, the template must be associated with the provided -Application.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Organization
The Organization field for the certificate Subject DN

```yaml
Type: String
Parameter Sets: ASK
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OrganizationalUnit
One or more departments or divisions within the organization that is responsible for maintaining the certificate

```yaml
Type: String[]
Parameter Sets: ASK
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -City
The City/Locality field for the certificate Subject DN

```yaml
Type: String
Parameter Sets: ASK
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -State
The State field for the certificate Subject DN

```yaml
Type: String
Parameter Sets: ASK
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Country
The Country field for the certificate Subject DN

```yaml
Type: String
Parameter Sets: ASK
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -KeySize
Specify a key size for RSA keys
Valid values are: 2048, 3072, 4096
If not provided, the default from the issuing template will be used.
Cannot be used with -KeyCurve.

```yaml
Type: Int32
Parameter Sets: ASK
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -KeyCurve
Specify the elliptic curve for key generation.
Valid values are: P256, P384, P521, ED25519
If not provided, the default from the issuing template will be used.
Cannot be used with -KeySize.

```yaml
Type: String
Parameter Sets: ASK
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SanDns
One or more subject alternative name dns entries.
Defaults to the common name if not provided.
The default can be overridden by providing $null or an empty array to use no SANs, or by providing specific values.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SanIP
One or more subject alternative name ip address entries

```yaml
Type: String[]
Parameter Sets: ASK
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SanUri
One or more subject alternative name uri entries

```yaml
Type: String[]
Parameter Sets: ASK
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SanEmail
One or more subject alternative name email entries

```yaml
Type: String[]
Parameter Sets: ASK
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ValidUntil
Date at which the certificate becomes invalid.
The day and hour will be set and not to the minute level.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Tag
One or more tags to assign to the certificate at creation.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OverwriteSan
When creating a certificate request from a CSR, any SANs included in the CSR will be used by default.
Use this switch to overwrite the DNS SANs in the CSR with the values provided in the -SanDns parameter.

This parameter only applies to DNS SAN, not other SANs.

```yaml
Type: SwitchParameter
Parameter Sets: CSR
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Wait
Wait for the certificate to be issued, or we hit a failure, before returning.
If not specified, the cmdlet will return as soon as the certificate request is created, and the certificate can be retrieved later using Get-TrustCertificate with the returned certificateRequestId.

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

### -PassThru
Return the certificate request.
If the certificate was successfully issued, the end entity certificate will be returned as the property 'certificate'.
'certificateId' will also be included in the output when the certificate is issued and contain the IDs of all certificates in the chain.

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

### none
## OUTPUTS

### pscustomobject, if PassThru is provided
## NOTES

## RELATED LINKS

[https://developer.venafi.com/tlsprotectcloud/reference/certificaterequests_create](https://developer.venafi.com/tlsprotectcloud/reference/certificaterequests_create)

