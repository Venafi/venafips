# Get-VcCertificateRequest

## SYNOPSIS
Get certificate request details

## SYNTAX

### ID (Default)
```
Get-VcCertificateRequest [-CertificateRequest] <String> [-VenafiSession <PSObject>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### All
```
Get-VcCertificateRequest [-All] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Get certificate request details including status, csr, creation date, etc

## EXAMPLES

### EXAMPLE 1
```
Get-VcCertificateRequest -CertificateRequest '9719975f-6e06-4d4b-82b9-bd829e5528f0'
```

Get single certificate request

### EXAMPLE 2
```
Find-VcCertificateRequest -Status ISSUED | Get-VcCertificateRequest
```

Get certificate request details from a search

### EXAMPLE 3
```
Get-VcCertificateRequest -All
```

Get all certificate requests

## PARAMETERS

### -CertificateRequest
Certificate Request ID

```yaml
Type: String
Parameter Sets: ID
Aliases: certificateRequestId, ID

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

### -VenafiSession
Authentication for the function.
The value defaults to the script session object $VenafiSession created by New-VenafiSession.
A Certificate Manager, SaaS key can also provided.

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

### CertificateRequest
## OUTPUTS

## NOTES

## RELATED LINKS
