# Invoke-TrustCertificateAction

## SYNOPSIS
Perform an action against one or more certificates

## SYNTAX

### Provision (Default)
```
Invoke-TrustCertificateAction -ID <Guid> [-Provision] [-MachineIdentity <String>] [-CloudKeystore <String>]
 [-AdditionalParameters <Hashtable>] [-TrustClient <TrustClient>] [-ProgressAction <ActionPreference>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Retire
```
Invoke-TrustCertificateAction -ID <Guid> [-Retire] [-BatchSize <Int32>] [-AdditionalParameters <Hashtable>]
 [-TrustClient <TrustClient>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Recover
```
Invoke-TrustCertificateAction -ID <Guid> [-Recover] [-Application <String>] [-BatchSize <Int32>]
 [-AdditionalParameters <Hashtable>] [-TrustClient <TrustClient>] [-ProgressAction <ActionPreference>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Renew
```
Invoke-TrustCertificateAction -ID <Guid> [-Renew] [-Provision] [-Application <String>]
 [-IssuingTemplate <String>] [-Wait] [-Force] [-AdditionalParameters <Hashtable>] [-TrustClient <TrustClient>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Validate
```
Invoke-TrustCertificateAction -ID <Guid> [-Validate] [-BatchSize <Int32>] [-AdditionalParameters <Hashtable>]
 [-TrustClient <TrustClient>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Revoke
```
Invoke-TrustCertificateAction -ID <Guid> [-Revoke] [-Reason <String>] [-Comment <String>]
 [-AdditionalParameters <Hashtable>] [-TrustClient <TrustClient>] [-ProgressAction <ActionPreference>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Delete
```
Invoke-TrustCertificateAction -ID <Guid> [-Delete] [-BatchSize <Int32>] [-AdditionalParameters <Hashtable>]
 [-TrustClient <TrustClient>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
One stop shop for certificate actions.
You can Retire, Recover, Renew, Validate, Provision, or Delete.

## EXAMPLES

### EXAMPLE 1
```
Invoke-TrustCertificateAction -ID '3699b03e-ff62-4772-960d-82e53c34bf60' -Retire
```

Perform an action against 1 certificate

### EXAMPLE 2
```
Invoke-TrustCertificateAction -ID '3699b03e-ff62-4772-960d-82e53c34bf60' -Renew -Application '10f71a12-daf3-4737-b589-6a9dd1cc5a97'
```

Perform an action against 1 certificate overriding the application used for renewal.

### EXAMPLE 3
```
Find-TrustCertificate -Version CURRENT -Issuer i1 | Invoke-TrustCertificateAction -Renew -IssuingTemplate 10f71a12-daf3-4737-b589-6a9dd1cc5a97
```

Find all current certificates issued by i1 and renew them with a different template.

### EXAMPLE 4
```
Find-TrustCertificate -Version CURRENT -Name 'mycert' | Invoke-TrustCertificateAction -Renew -Wait
```

Renew a certificate and wait for it to finish, either success or failure, before returning.
This can be helpful if an Issuer takes a bit to enroll the certificate.

### EXAMPLE 5
```
Invoke-TrustCertificateAction -ID '3699b03e-ff62-4772-960d-82e53c34bf60' -Renew -Force
```

Renewals can only support 1 CN assigned to a certificate. 
To force this function to renew and automatically select the first CN, use -Force.

### EXAMPLE 6
```
Invoke-TrustCertificateAction -ID '3699b03e-ff62-4772-960d-82e53c34bf60' -Delete
```

Delete a certificate. 
As only retired certificates can be deleted, it will be retired first.

### EXAMPLE 7
```
Invoke-TrustCertificateAction -ID '3699b03e-ff62-4772-960d-82e53c34bf60' -Delete -Confirm:$false
```

Perform an action bypassing the confirmation prompt. 
Only applicable to Delete.

### EXAMPLE 8
```
Find-TrustCertificate -Status RETIRED | Invoke-TrustCertificateAction -Delete -BatchSize 100
```

Search for all retired certificates and delete them using a non default batch size of 100

### EXAMPLE 9
```
Find-TrustCertificate -Version CURRENT -Name 'mycert' | Invoke-TrustCertificateAction -CloudKeystore
```

Provision the certificate to a cloud keystore

### EXAMPLE 10
```
Invoke-TrustCertificateAction -Provision -MachineIdentity '3f4d8db9-6f83-4c9b-9a53-6f8e2a9d6d2b'
```

Provision the certificate associated with a specific machine identity

## PARAMETERS

### -ID
ID of the certificate

```yaml
Type: Guid
Parameter Sets: (All)
Aliases: certificateId

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Retire
Retire a certificate

```yaml
Type: SwitchParameter
Parameter Sets: Retire
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Recover
Recover a retired certificate

```yaml
Type: SwitchParameter
Parameter Sets: Recover
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Renew
Requests immediate renewal for an existing certificate.
Use \`-AdditionalParameters\` to provide additional parameters to the renewal request, see https://developer.venafi.com/tlsprotectcloud/reference/certificaterequests_create.

```yaml
Type: SwitchParameter
Parameter Sets: Renew
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Validate
Initiates SSL/TLS network validation

```yaml
Type: SwitchParameter
Parameter Sets: Validate
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Revoke
Revoke a certificate.
Requires a reason and optionally you can provide a comment.

```yaml
Type: SwitchParameter
Parameter Sets: Revoke
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Reason
Provide a revocation reason; defaults to UNSPECIFIED.
Allowed values are 'UNSPECIFIED', 'KEY_COMPROMISE', 'AFFILIATION_CHANGED', 'SUPERSEDED', 'CESSATION_OF_OPERATION'.

```yaml
Type: String
Parameter Sets: Revoke
Aliases:

Required: False
Position: Named
Default value: UNSPECIFIED
Accept pipeline input: False
Accept wildcard characters: False
```

### -Comment
Provide a revocation comment; defaults to 'revoked by VenafiPS'

```yaml
Type: String
Parameter Sets: Revoke
Aliases:

Required: False
Position: Named
Default value: Revoked by VenafiPS
Accept pipeline input: False
Accept wildcard characters: False
```

### -Delete
Delete a certificate.
As only retired certificates can be deleted, this will be performed first, if needed.

```yaml
Type: SwitchParameter
Parameter Sets: Delete
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Provision
By default, provision a certificate to all associated machine identities.
When used with -MachineIdentity, provision to that machine identity instead of all associated machine identities.
When used with -CloudKeystore, provision there instead.
When used with -Renew, it will wait for the renewal to complete and then provision the renewed certificate, assuming the renewal was successful.

```yaml
Type: SwitchParameter
Parameter Sets: Provision
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: SwitchParameter
Parameter Sets: Renew
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -MachineIdentity
Name or ID of a machine identity to provision to.
When used with -Provision, provision to this machine identity instead of all associated machine identities.

```yaml
Type: String
Parameter Sets: Provision
Aliases: machineIdentityId

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -CloudKeystore
Name or ID of a cloud keystore to provision to

```yaml
Type: String
Parameter Sets: Provision
Aliases: cloudKeystoreId

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Application
Optional name or ID of an application.
Only needed in circumstances where the application can't be determined automatically.

If not provided for renewal, get the application from the original certificate request.
If not available, check for associated applications with the certificate. 
If more than 1, throw an error as we don't know which to use, otherwise use that one application.

Associate a recovered certificate with an application.

```yaml
Type: String
Parameter Sets: Recover, Renew
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IssuingTemplate
Optional name or ID of an issuing template.
Only needed in circumstances where the issuing template can't be determined automatically.

If not provided, get the issuing template from the original certificate request. 
It might be this is available, but no longer valid for the application. 
In this case, check how many templates the application has. 
If only 1, use it, otherwise we can't continue.
If not available from the original certificate request, perform the same 1 template check against the application to find a suitable template.

Renew only.

```yaml
Type: String
Parameter Sets: Renew
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -BatchSize
How many certificates to retire per retirement API call.
Useful to prevent API call timeouts.
Defaults to 1000.
Not applicable to Renew or Provision.

```yaml
Type: Int32
Parameter Sets: Retire, Recover, Validate, Delete
Aliases:

Required: False
Position: Named
Default value: 1000
Accept pipeline input: False
Accept wildcard characters: False
```

### -Wait
Wait for a long running operation to complete before returning
- During a renewal, wait for enrollment to either succeed or fail

```yaml
Type: SwitchParameter
Parameter Sets: Renew
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Force the operation under certain circumstances.
- During a renewal, force choosing the first CN in the case of multiple CNs as only 1 is supported via the API.

```yaml
Type: SwitchParameter
Parameter Sets: Renew
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -AdditionalParameters
Additional items specific to the action being taken, if needed.
See the api documentation for appropriate items, many are in the links in this help.

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

### ID
## OUTPUTS

### For most, but not all actions, PSCustomObject with the following properties:
###     certificateID - Certificate uuid
###     success - A value of true indicates that the action was successful
###     error - error message if we failed
### Renewals will also have oldCertificateId and renew properties
## NOTES
If performing a renewal and subjectCN has more than 1 value, only the first will be submitted with the renewal.

## RELATED LINKS

[https://developer.venafi.com/tlsprotectcloud/reference/certificateretirement_recovercertificates](https://developer.venafi.com/tlsprotectcloud/reference/certificateretirement_recovercertificates)

[https://developer.venafi.com/tlsprotectcloud/reference/certificateretirement_retirecertificates](https://developer.venafi.com/tlsprotectcloud/reference/certificateretirement_retirecertificates)

[https://developer.venafi.com/tlsprotectcloud/reference/certificateretirement_deletecertificates](https://developer.venafi.com/tlsprotectcloud/reference/certificateretirement_deletecertificates)

[https://developer.venafi.com/tlsprotectcloud/reference/certificaterequests_create](https://developer.venafi.com/tlsprotectcloud/reference/certificaterequests_create)

[https://developer.venafi.com/tlsprotectcloud/reference/certificates_validation](https://developer.venafi.com/tlsprotectcloud/reference/certificates_validation)

