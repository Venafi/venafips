# Set-VcCertificateRequest

## SYNOPSIS
Update an existing application

## SYNTAX

```
Set-VcCertificateRequest -ID <String> [-Approve] [-RejectReason <String>] [-Wait] [-PassThru]
 [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Update details of existing applications.
Additional properties will be available in the future.

## EXAMPLES

### EXAMPLE 1
```
Set-VcCertificateRequest -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2' -Approve
```

Approve a request

### EXAMPLE 2
```
Set-VcCertificateRequest -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2' -Approve:$false
```

Reject a request

### EXAMPLE 3
```
Set-VcCertificateRequest -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2' -Approve:$false -RejectReason 'not needed'
```

Reject a request with a specific reason

### EXAMPLE 4
```
Set-VcCertificateRequest -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2' -Approve -Wait
```

Approve a request and wait for the certificate request to finish processing

### EXAMPLE 5
```
Set-VcCertificateRequest -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2' -Approve -Wait -PassThru
```

Approve a request and wait for the certificate request to finish processing.
Once finished, return the resulting object which contains the newly created certificate details.

### EXAMPLE 6
```
Find-VcCertificateRequest -Status PENDING_APPROVAL | Set-VcCertificateRequest -Approve
```

Get all requests pending approval and approve them all.
Use the Find filter to narrow the scope of requests found.

## PARAMETERS

### -ID
The certificate request id to process.

```yaml
Type: String
Parameter Sets: (All)
Aliases: certificateRequestId

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Approve
Provide the switch to approve a request

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -RejectReason
In the case of rejection, provide a reason.
The default will be 'reject'.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Rejection processed by VenafiPS
Accept pipeline input: False
Accept wildcard characters: False
```

### -Wait
Wait for the certificate request to either be issued or fail.
Depending on the speed of your CA, this could take some time.

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
Return the certificate request object.
If -Wait is specified, the returned object will have details on the newly created certificate.

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
Aliases: Key

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

### PSCustomObject
## NOTES

## RELATED LINKS
