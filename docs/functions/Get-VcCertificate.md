# Get-VcCertificate

## SYNOPSIS
Get certificate information

## SYNTAX

### Id (Default)
```
Get-VcCertificate [-Certificate] <String> [-OwnerDetail] [-VenafiSession <PSObject>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### All
```
Get-VcCertificate [-All] [-OwnerDetail] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Get certificate information, either all available to the api key provided or by id or zone.

## EXAMPLES

### EXAMPLE 1
```
Get-VdcCertificate -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2'
```

Get certificate info for a specific cert

### EXAMPLE 2
```
Get-VdcCertificate -All
```

Get certificate info for all certs

## PARAMETERS

### -Certificate
Certificate identifier, the ID or certificate name.

```yaml
Type: String
Parameter Sets: Id
Aliases: certificateId, certificateIds, ID

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -All
Retrieve all certificates

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

### -OwnerDetail
Retrieve extended application owner info

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: IncludeVaasOwner

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -VenafiSession
Authentication for the function.
The value defaults to the script session object $VenafiSession created by New-VenafiSession.
A Certificate Manager, SaaS key can also be provided.

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

### ID
## OUTPUTS

### PSCustomObject
## NOTES

## RELATED LINKS
