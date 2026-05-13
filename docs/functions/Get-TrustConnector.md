# Get-TrustConnector

## SYNOPSIS
Get connector info

## SYNTAX

### ID (Default)
```
Get-TrustConnector [-Connector] <String> [-TrustClient <TrustClient>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### All
```
Get-TrustConnector [-All] [-TrustClient <TrustClient>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Get details on 1 or all connectors associated with your tenant

## EXAMPLES

### EXAMPLE 1
```
Get-TrustConnector -Connector 'My Connector'
```

Get a single object by name. 
The name is case sensitive.

### EXAMPLE 2
```
Get-TrustConnector -All
```

Get all connectors

## PARAMETERS

### -Connector
Connector ID or name

```yaml
Type: String
Parameter Sets: ID
Aliases: connectorId

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -All
Get all connectors

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

### Connector
## OUTPUTS

## NOTES

## RELATED LINKS
