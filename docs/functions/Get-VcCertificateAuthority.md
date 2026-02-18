# Get-VcCertificateAuthority

## SYNOPSIS
Get certificate authority info

## SYNTAX

### ID (Default)
```
Get-VcCertificateAuthority [-CertificateAuthority] <String> [-VenafiSession <PSObject>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### All
```
Get-VcCertificateAuthority [-All] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Get info on certificate authorities.
Retrieve info on 1 or all.

## EXAMPLES

### EXAMPLE 1
```
Get-VcCertificateAuthority -CertificateAuthority 'MyCA'
```

Get info for a certificate authority by name

### EXAMPLE 2
```
Get-VcCertificateAuthority -CertificateAuthority 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2'
```

Get info for a certificate authority by id

### EXAMPLE 3
```
Get-VcCertificateAuthority -All
```

Get info for all certificate authorities

## PARAMETERS

### -CertificateAuthority
Certificate authority name or guid.

```yaml
Type: String
Parameter Sets: ID
Aliases: certificateAuthorityId, ID, ca

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

### -VenafiSession
Authentication for the function.
The value defaults to the script session object $VenafiSession created by New-VenafiSession.
A Certificate Manager, SaaS key can also provided.

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases: Key, AccessToken

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
