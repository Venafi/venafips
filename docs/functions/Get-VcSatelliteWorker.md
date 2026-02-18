# Get-VcSatelliteWorker

## SYNOPSIS
Get VSatellite worker info

## SYNTAX

### ID
```
Get-VcSatelliteWorker -ID <Guid> [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### All
```
Get-VcSatelliteWorker [-All] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### VSatellite
```
Get-VcSatelliteWorker -VSatellite <String> [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Get 1 or more VSatellite workers, the bridge between a vsatellite and ADCS

## EXAMPLES

### EXAMPLE 1
```
Get-VcSatelliteWorker -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2'
```

vsatelliteWorkerId : 5df78790-a155-11ef-a5a8-8f3513444123
companyId          : 09b24f81-b22b-11ea-91f3-123456789098
host               : 1.2.3.4
port               : 555
pairingCode        : a138fe58-ecb6-45a4-a9af-01dd4d5c74d1
pairingPublicKey   : FDww6Nml8IUFQZ56j9LRweEWoCQ1732wi/ZfZaQj+s0=
status             : DRAFT

Get a single worker by ID

### EXAMPLE 2
```
Get-VcSatelliteWorker -All
```

Get all VSatellite workers

### EXAMPLE 3
```
Get-VcSatelliteWorker -VSatellite 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f3'
```

Get all workers associated with a specific VSatellite

## PARAMETERS

### -ID
VSatellite worker ID

```yaml
Type: Guid
Parameter Sets: ID
Aliases: vsatelliteWorkerId

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -All
Get all VSatellite workers

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

### -VSatellite
Get workers associated with a specific VSatellite, specify either VSatellite ID or name

```yaml
Type: String
Parameter Sets: VSatellite
Aliases: vsatelliteId

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
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

### ID, VSatelliteID
## OUTPUTS

## NOTES

## RELATED LINKS
