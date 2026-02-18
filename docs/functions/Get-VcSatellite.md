# Get-VcSatellite

## SYNOPSIS
Get VSatellite info

## SYNTAX

### ID
```
Get-VcSatellite -VSatellite <String> [-IncludeWorkers] [-VenafiSession <PSObject>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### All
```
Get-VcSatellite [-All] [-IncludeWorkers] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Get 1 or more VSatellites. 
Encyption key and algorithm will be included.

## EXAMPLES

### EXAMPLE 1
```
Get-VcSatellite -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2'
```

vsatelliteId                : e2d60b61-9a8c-4a3a-985c-92498bd1fc77
encryptionKey               : o4aFaJUTtCydprvb1jN15hIa5vJqFpQ1ZiY=
encryptionKeyAlgorithm      : ED25519
companyId                   : e2d60b61-9a8c-4a3a-985c-92498bd1fc77
productEntitlements         : {ANY}
environmentId               : ea2c3f80-658b-11eb-9bbd-338917ba2e36
pairingCodeId               : e2d60b61-9a8c-4a3a-985c-92498bd1fc77
name                        : VSatellite Hub 0001
edgeType                    : HUB
edgeStatus                  : ACTIVE
clientId                    : e2d60b61-9a8c-4a3a-985c-92498bd1fc77
modificationDate            : 6/15/2023 11:48:40 AM
address                     : 1.2.3.4
deploymentDate              : 6/15/2023 11:44:14 AM
lastSeenOnDate              : 8/13/2023 8:00:06 AM
reconciliationFailed        : False
encryptionKeyId             : mwU4oTesrjyGBln0pZ8FkRfhek0UtvighIw=
encryptionKeyDeploymentDate : 6/15/2023 11:48:40 AM
kubernetesVersion           : v1.23.6+k3s1
integrationServicesCount    : 0

Get a single object by ID

### EXAMPLE 2
```
Get-VcSatellite -ID 'My Awesome App'
```

Get a single object by name. 
The name is case sensitive.

### EXAMPLE 3
```
Get-VcSatellite -All
```

Get all VSatellites

### EXAMPLE 4
```
Get-VcSatellite -All -IncludeWorkers
```

Get all VSatellites and include workers

## PARAMETERS

### -VSatellite
VSatellite ID or name

```yaml
Type: String
Parameter Sets: ID
Aliases: vsatelliteId, ID

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -All
Get all VSatellites

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

### -IncludeWorkers
Include VSatellite workers in the output

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

## NOTES

## RELATED LINKS
