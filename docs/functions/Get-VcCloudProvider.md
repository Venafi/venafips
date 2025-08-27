# Get-VcCloudProvider

## SYNOPSIS
Get cloud provider info

## SYNTAX

### ID (Default)
```
Get-VcCloudProvider [-CloudProvider] <String> [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### All
```
Get-VcCloudProvider [-All] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Get 1 or more cloud providers

## EXAMPLES

### EXAMPLE 1
```
Get-VcCloudProvider -CloudProvider 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2'
```

cloudProviderId : ca7ff555-88d2-4bfc-9efa-2630ac44c1f2
name            : MyGCP
type            : GCP
status          : VALIDATED
statusDetails   :
team            : @{teamId=ca7ff555-88d2-4bfc-9efa-2630ac44c1f2; name=Cloud Admin Team}
authorizedTeam  : {@{teamId=ca7ff555-88d2-4bfc-9efa-2630ac44c1f2; name=Cloud App Team}}
keystoresCount  : 1
configuration   : @{accountId=077141312; externalId=ca7ff555-88d2-4bfc-9efa-2630ac44c1f2; role=ACMIntegrationRole; organizationId=}

Get a single object by ID

### EXAMPLE 2
```
Get-VcCloudProvider -CloudProvider 'GCP'
```

Get a single object by name. 
The name is case sensitive.

### EXAMPLE 3
```
Get-VcCloudProvider -All
```

Get all cloud providers

## PARAMETERS

### -CloudProvider
Cloud provider ID or name, tab completion supported

```yaml
Type: String
Parameter Sets: ID
Aliases: cloudProviderId, ID, cp

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -All
Get all cloud providers

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

### CloudProvider
## OUTPUTS

## NOTES

## RELATED LINKS
