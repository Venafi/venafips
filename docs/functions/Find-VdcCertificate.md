# Find-VdcCertificate

## SYNOPSIS
Find certificates in Certificate Manager, Self-Hosted based on various attributes

## SYNTAX

```
Find-VdcCertificate [[-Path] <String>] [[-Guid] <Guid>] [-Recursive] [[-Country] <String>]
 [[-CommonName] <String>] [[-Issuer] <String>] [[-KeyAlgorithm] <String[]>] [[-KeySize] <Int32[]>]
 [[-KeySizeGreaterThan] <Int32>] [[-KeySizeLessThan] <Int32>] [[-Locale] <String[]>]
 [[-Organization] <String[]>] [[-OrganizationUnit] <String[]>] [[-State] <String[]>] [[-SanDns] <String>]
 [[-SanEmail] <String>] [[-SanIP] <String>] [[-SanUpn] <String>] [[-SanUri] <String>]
 [[-SerialNumber] <String>] [[-SignatureAlgorithm] <String>] [[-Thumbprint] <String>] [[-IssueDate] <DateTime>]
 [[-IssueDateAfter] <DateTime>] [[-IssueDateBefore] <DateTime>] [[-ExpireDate] <DateTime>]
 [[-ExpireAfter] <DateTime>] [[-ExpireBefore] <DateTime>] [-Enabled] [-InError] [-IsSelfSigned] [-IsWildcard]
 [-IsExpired] [[-NetworkValidationEnabled] <Boolean>] [[-CreatedDate] <DateTime>] [[-CreatedAfter] <DateTime>]
 [[-CreatedBefore] <DateTime>] [[-CertificateType] <String[]>] [[-ManagementType] <TppManagementType[]>]
 [-PendingWorkflow] [[-Stage] <TppCertificateStage[]>] [[-StageGreaterThan] <TppCertificateStage>]
 [[-StageLessThan] <TppCertificateStage>] [-ValidationEnabled] [[-ValidationState] <String[]>]
 [[-Algorithm] <String>] [-CountOnly] [[-VenafiSession] <PSObject>] [-ProgressAction <ActionPreference>]
 [-IncludeTotalCount] [-Skip <UInt64>] [-First <UInt64>] [<CommonParameters>]
```

## DESCRIPTION
Find certificates based on various attributes.
Supports standard PS paging parameters First and Skip.
If -First not provided, the default return is 1000 records.

## EXAMPLES

### EXAMPLE 1
```
Find-VdcCertificate
```

Find first 1000 certificates

### EXAMPLE 2
```
Find-VdcCertificate -IsExpired
```

Find expired certificates

### EXAMPLE 3
```
Find-VdcCertificate -ExpireBefore '2018-01-01'
```

Find certificates expiring before a certain date

### EXAMPLE 4
```
Find-VdcCertificate -ExpireBefore "2018-01-01" -First 5
```

Find 5 certificates expiring before a certain date

### EXAMPLE 5
```
Find-VdcCertificate -ExpireBefore "2018-01-01" -First 5 -Skip 2
```

Find 5 certificates expiring before a certain date, starting at the 3rd certificate found.

### EXAMPLE 6
```
Find-VdcCertificate -Path '\VED\Policy\My Policy'
```

Find certificates in a specific path

### EXAMPLE 7
```
Find-VdcCertificate -Issuer 'CN=Example Root CA, O=Venafi,Inc., L=Salt Lake City, S=Utah, C=US'
```

Find certificates by issuer

### EXAMPLE 8
```
Find-VdcCertificate -Path '\VED\Policy\My Policy' -Recursive
```

Find certificates in a specific path and all subfolders

### EXAMPLE 9
```
Find-VdcCertificate | Get-VdcCertificate
```

Get detailed certificate info

### EXAMPLE 10
```
Find-VdcCertificate -ExpireBefore "2019-09-01" | Invoke-VdcCertificateAction -Renew
```

Renew all certificates expiring before a certain date

### EXAMPLE 11
```
Find-VdcCertificate -First 500
```

Find the first 500 certificates

## PARAMETERS

### -Path
Starting path to search from. 
If not provided, the default is \ved\policy.

```yaml
Type: String
Parameter Sets: (All)
Aliases: DN

Required: False
Position: 1
Default value: \ved\policy
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Guid
Guid which represents a starting path.

```yaml
Type: Guid
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Recursive
Search recursively starting from the search path.

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

### -Country
Find certificates by Country attribute of Subject DN.

```yaml
Type: String
Parameter Sets: (All)
Aliases: C

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CommonName
Find certificates by Common name attribute of Subject DN.

```yaml
Type: String
Parameter Sets: (All)
Aliases: CN

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Issuer
Find certificates by issuer.
Use the CN, O, L, S, and C values from the certificate request.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -KeyAlgorithm
Find certificates by algorithm for the public key.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -KeySize
Find certificates by public key size.

```yaml
Type: Int32[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -KeySizeGreaterThan
Find certificates with a key size greater than the specified value.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -KeySizeLessThan
Find certificates with a key size less than the specified value.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 9
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Locale
Find certificates by Locality/City attribute of Subject Distinguished Name (DN).

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: L

Required: False
Position: 10
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Organization
Find certificates by Organization attribute of Subject DN.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: O

Required: False
Position: 11
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OrganizationUnit
Find certificates by Organization Unit (OU).

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: OU

Required: False
Position: 12
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -State
Find certificates by State/Province attribute of Subject DN.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: S

Required: False
Position: 13
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SanDns
Find certificates by Subject Alternate Name (SAN) Distinguished Name Server (DNS).

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 14
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SanEmail
Find certificates by SAN Email RFC822.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 15
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SanIP
Find certificates by SAN IP Address.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 16
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SanUpn
Find certificates by SAN User Principal Name (UPN) or OtherName.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 17
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SanUri
Find certificates by SAN Uniform Resource Identifier (URI).

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 18
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SerialNumber
Find certificates by Serial number.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 19
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SignatureAlgorithm
Find certificates by the algorithm used to sign the certificate (e.g.
SHA1RSA).

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 20
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Thumbprint
Find certificates by one or more SHA-1 thumbprints.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 21
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IssueDate
Find certificates by the date of issue.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases: ValidFrom

Required: False
Position: 22
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IssueDateAfter
Find certificates issued after a certain date

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases: ValidFromGreater

Required: False
Position: 23
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IssueDateBefore
Find certificates issued before a certain date

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases: ValidFromLess

Required: False
Position: 24
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExpireDate
Find certificates by expiration date.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases: ValidTo

Required: False
Position: 25
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExpireAfter
Find certificates that expire after a certain date.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases: ValidToGreater

Required: False
Position: 26
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExpireBefore
Find certificates that expire before a certain date.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases: ValidToLess

Required: False
Position: 27
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Enabled
Include only certificates that are enabled or disabled.

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

### -InError
Only include certificates in an error state.

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

### -IsSelfSigned
Only include self-signed certificates

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

### -IsWildcard
Only include wilcard certificates

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

### -IsExpired
Only include expired certificates

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

### -NetworkValidationEnabled
Only include certificates with network validation enabled or disabled.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 28
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -CreatedDate
Find certificates that were created at an exact date and time.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases: CreatedOn

Required: False
Position: 29
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CreatedAfter
Find certificate created after this date and time.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases: CreatedOnGreater

Required: False
Position: 30
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CreatedBefore
Find certificate created before this date and time.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases: CreatedOnLess

Required: False
Position: 31
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CertificateType
Find certificate by category of usage.
Use CodeSigning, Device, Server, and/or User.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 32
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ManagementType
Find certificates with a Management type of Unassigned, Monitoring, Enrollment, or Provisioning.

```yaml
Type: TppManagementType[]
Parameter Sets: (All)
Aliases:
Accepted values: Unassigned, Monitoring, Enrollment, Provisioning

Required: False
Position: 33
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PendingWorkflow
Only include certificates that have a pending workflow resolution (have an outstanding workflow ticket).

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

### -Stage
Find certificates by one or more stages in the certificate lifecycle.

```yaml
Type: TppCertificateStage[]
Parameter Sets: (All)
Aliases:
Accepted values: CheckStore, CreateConfigureStore, CreateKey, CreateCSR, PostCSR, ApproveRequest, RetrieveCertificate, InstallCertificate, CheckConfiguration, ConfigureApplication, RestartApplication, EndProcessing, Revocation, UpdateTrustStore, EndTrustStoreProcessing

Required: False
Position: 34
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -StageGreaterThan
Find certificates with a stage greater than the specified stage (does not include specified stage).

```yaml
Type: TppCertificateStage
Parameter Sets: (All)
Aliases: StageGreater
Accepted values: CheckStore, CreateConfigureStore, CreateKey, CreateCSR, PostCSR, ApproveRequest, RetrieveCertificate, InstallCertificate, CheckConfiguration, ConfigureApplication, RestartApplication, EndProcessing, Revocation, UpdateTrustStore, EndTrustStoreProcessing

Required: False
Position: 35
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -StageLessThan
Find certificates with a stage less than the specified stage (does not include specified stage).

```yaml
Type: TppCertificateStage
Parameter Sets: (All)
Aliases: StageLess
Accepted values: CheckStore, CreateConfigureStore, CreateKey, CreateCSR, PostCSR, ApproveRequest, RetrieveCertificate, InstallCertificate, CheckConfiguration, ConfigureApplication, RestartApplication, EndProcessing, Revocation, UpdateTrustStore, EndTrustStoreProcessing

Required: False
Position: 36
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ValidationEnabled
Only include certificates with validation enabled or disabled.

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

### -ValidationState
Find certificates with a validation state of Blank, Success, or Failure.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 37
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Algorithm
Name or OID for the PKIX algorithm, first introduced in v25.1.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 38
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CountOnly
Return the count of certificates found from the query as opposed to the certificates themselves

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
Position: 39
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeTotalCount
Reports the total number of objects in the data set (an integer) followed by the selected objects.
If the cmdlet cannot determine the total count, it displays "Unknown total count." The integer has an Accuracy property that indicates the reliability of the total count value.
The value of Accuracy ranges from 0.0 to 1.0 where 0.0 means that the cmdlet could not count the objects, 1.0 means that the count is exact, and a value between 0.0 and 1.0 indicates an increasingly reliable estimate.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Skip
Ignores the specified number of objects and then gets the remaining objects.
Enter the number of objects to skip.

```yaml
Type: UInt64
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -First
Gets only the specified number of objects.
Enter the number of objects to get.

```yaml
Type: UInt64
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

### Path
## OUTPUTS

### pscustomobject, Int when CountOnly provided
## NOTES

## RELATED LINKS

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-GET-Certificates.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-GET-Certificates.php)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-GET-Certificates-guid.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-GET-Certificates-guid.php)

[https://msdn.microsoft.com/en-us/library/system.web.httputility(v=vs.110).aspx](https://msdn.microsoft.com/en-us/library/system.web.httputility(v=vs.110).aspx)

