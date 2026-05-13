# Get-TrustCertificateAuthority

## SYNOPSIS
Get certificate authority info

## SYNTAX

### ID (Default)
```
Get-TrustCertificateAuthority [-CertificateAuthority] <String> [-TrustClient <TrustClient>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### All
```
Get-TrustCertificateAuthority [-All] [-TrustClient <TrustClient>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Get info on certificate authorities.
Retrieve info on 1 or all.

## EXAMPLES

### EXAMPLE 1
```
Get-TrustCertificateAuthority -CertificateAuthority 'MyCA'
```

Get info for a certificate authority by name

### EXAMPLE 2
```
Get-TrustCertificateAuthority -CertificateAuthority 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2'
```

Get info for a certificate authority by id

### EXAMPLE 3
```
Get-TrustCertificateAuthority -All
```

Get info for all certificate authorities

## PARAMETERS

### -CertificateAuthority
Certificate authority name or guid.

```yaml
Type: String
Parameter Sets: ID
Aliases: certificateAuthorityId

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -All
Get all certificate authorities

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

### CertificateAuthority
## OUTPUTS

### PSCustomObject
## NOTES

## RELATED LINKS
