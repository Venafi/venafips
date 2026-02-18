# Get-VcWebhook

## SYNOPSIS
Get webhook info

## SYNTAX

### ID (Default)
```
Get-VcWebhook [-ID] <String> [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### All
```
Get-VcWebhook [-All] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Get 1 or all webhooks

## EXAMPLES

### EXAMPLE 1
```
Get-VcWebhook -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2' | ConvertTo-Json
```

{
    "webhookId": "a7ddd210-0a39-11ee-8763-134b935c90aa",
    "name": "ServiceNow-expiry,
    "properties": {
        "connectorKind": "WEBHOOK",
        "filter": {
            "filterType": "EXPIRATION",
            "applicationIds": \[\]
        },
        "target": {
            "type": "generic",
            "connection": {
                "secret": "MySecret",
                "url": "https://instance.service-now.com/api/company/endpoint"
            }
        }
    }
}

Get a single object by ID

### EXAMPLE 2
```
Get-VcWebhook -ID 'My Webhook'
```

Get a single object by name. 
The name is case sensitive.

### EXAMPLE 3
```
Get-VcWebhook -All
```

Get all webhooks

## PARAMETERS

### -ID
Webhook ID or name

```yaml
Type: String
Parameter Sets: ID
Aliases: webhookId

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -All
Get all webhooks

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

### ID
## OUTPUTS

## NOTES

## RELATED LINKS
