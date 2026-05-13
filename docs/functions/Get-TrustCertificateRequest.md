# Get-TrustCertificateRequest

## SYNOPSIS
Get certificate request details

## SYNTAX

### ID (Default)
```
Get-TrustCertificateRequest [-CertificateRequest] <String> [-TrustClient <TrustClient>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### All
```
Get-TrustCertificateRequest [-All] [-TrustClient <TrustClient>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Get certificate request details including status, csr, creation date, etc

## EXAMPLES

### EXAMPLE 1
```
Get-TrustCertificateRequest -CertificateRequest '9719975f-6e06-4d4b-82b9-bd829e5528f0'
```

Get single certificate request

### EXAMPLE 2
```
Find-TrustCertificateRequest -Status ISSUED | Get-TrustCertificateRequest
```

Get certificate request details from a search

### EXAMPLE 3
```
Get-TrustCertificateRequest -All
```

Get all certificate requests

## PARAMETERS

### -CertificateRequest
Certificate Request ID

```yaml
Type: String
Parameter Sets: ID
Aliases: certificateRequestId

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -All
Get all certificate requests

```yaml
Type: SwitchParameter
Parameter Sets: All
Aliases:

Required: True
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

### CertificateRequest
## OUTPUTS

## NOTES

## RELATED LINKS
