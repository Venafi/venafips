# Invoke-VcCertificateAction

## SYNOPSIS
Perform an action against one or more certificates

## SYNTAX

### Retire
```
Invoke-VcCertificateAction -ID <Guid> [-Retire] [-BatchSize <Int32>] [-AdditionalParameters <Hashtable>]
 [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Recover
```
Invoke-VcCertificateAction -ID <Guid> [-Recover] [-BatchSize <Int32>] [-AdditionalParameters <Hashtable>]
 [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Renew
```
Invoke-VcCertificateAction -ID <Guid> [-Renew] [-Provision] [-Wait] [-Force]
 [-AdditionalParameters <Hashtable>] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### Validate
```
Invoke-VcCertificateAction -ID <Guid> [-Validate] [-BatchSize <Int32>] [-AdditionalParameters <Hashtable>]
 [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Revoke
```
Invoke-VcCertificateAction -ID <Guid> [-Revoke] [-Reason <String>] [-Comment <String>]
 [-AdditionalParameters <Hashtable>] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### Delete
```
Invoke-VcCertificateAction -ID <Guid> [-Delete] [-BatchSize <Int32>] [-AdditionalParameters <Hashtable>]
 [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Provision
```
Invoke-VcCertificateAction -ID <Guid> [-Provision] [-AdditionalParameters <Hashtable>]
 [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
One stop shop for certificate actions.
You can Retire, Recover, Renew, Validate, Provision, or Delete.

## EXAMPLES

### EXAMPLE 1
```
Invoke-VcCertificateAction -ID '3699b03e-ff62-4772-960d-82e53c34bf60' -Retire
```

Perform an action against 1 certificate

### EXAMPLE 2
```
Invoke-VcCertificateAction -ID '3699b03e-ff62-4772-960d-82e53c34bf60' -Renew -AdditionalParameters @{'Application'='10f71a12-daf3-4737-b589-6a9dd1cc5a97'}
```

Perform an action against 1 certificate with additional parameters.
In this case we are renewing a certificate, but the certificate has multiple applications associated with it.
Only one certificate and application combination can be renewed at a time so provide the specific application to be renewed.

### EXAMPLE 3
```
Find-VcCertificate -Version CURRENT -Issuer i1 | Invoke-VcCertificateAction -Renew -AdditionalParameters @{'certificateIssuingTemplateId'='10f71a12-daf3-4737-b589-6a9dd1cc5a97'}
```

Find all current certificates issued by i1 and renew them with a different issuer.

### EXAMPLE 4
```
Find-VcCertificate -Version Current -Name 'mycert' | Invoke-VcCertificateAction -Renew -Wait
```

Renew a certificate and wait for it to pass the Requested state (and hopefully Issued).
This can be helpful if an Issuer takes a bit to enroll the certificate.

### EXAMPLE 5
```
Invoke-VcCertificateAction -ID '3699b03e-ff62-4772-960d-82e53c34bf60' -Renew -Force
```

Renewals can only support 1 CN assigned to a certificate. 
To force this function to renew and automatically select the first CN, use -Force.

### EXAMPLE 6
```
Invoke-VcCertificateAction -ID '3699b03e-ff62-4772-960d-82e53c34bf60' -Delete
```

Delete a certificate. 
As only retired certificates can be deleted, it will be retired first.

### EXAMPLE 7
```
Invoke-VcCertificateAction -ID '3699b03e-ff62-4772-960d-82e53c34bf60' -Delete -Confirm:$false
```

Perform an action bypassing the confirmation prompt. 
Only applicable to Delete.

### EXAMPLE 8
```
Find-VcCertificate -Status RETIRED | Invoke-VcCertificateAction -Delete -BatchSize 100
```

Search for all retired certificates and delete them using a non default batch size of 100

## PARAMETERS

### -ID
ID of the certificate

```yaml
Type: Guid
Parameter Sets: (All)
Aliases: certificateID

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
If more than 1 application is associated with the certificate, provide -AdditionalParameters @{'Application'='application id'} to specify the id.
Use -AdditionalParameters to provide additional parameters to the renewal request, see https://developer.venafi.com/tlsprotectcloud/reference/certificaterequests_create.

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
As only retired certificates can be deleted, this will be performed first.

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
Provision a certificate to all associated machine identities.

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
- During a renewal, wait for the certificate to pass the Requested state

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
- During a renewal, force choosing the first CN in the case of multiple CNs as only 1 is supported.

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

### When using retire and recover, PSCustomObject with the following properties:
###     CertificateID - Certificate uuid
###     Success - A value of true indicates that the action was successful
## NOTES
If performing a renewal and subjectCN has more than 1 value, only the first will be submitted with the renewal.

## RELATED LINKS

[https://api.venafi.cloud/webjars/swagger-ui/index.html?configUrl=%2Fv3%2Fapi-docs%2Fswagger-config&urls.primaryName=outagedetection-service](https://api.venafi.cloud/webjars/swagger-ui/index.html?configUrl=%2Fv3%2Fapi-docs%2Fswagger-config&urls.primaryName=outagedetection-service)

[https://api.venafi.cloud/webjars/swagger-ui/index.html?urls.primaryName=outagedetection-service#/Certificates/certificateretirement_deleteCertificates](https://api.venafi.cloud/webjars/swagger-ui/index.html?urls.primaryName=outagedetection-service#/Certificates/certificateretirement_deleteCertificates)

