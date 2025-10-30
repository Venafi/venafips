# New-VcWebhook

## SYNOPSIS
Create a new webhook

## SYNTAX

### EventName (Default)
```
New-VcWebhook -Name <String> [-Type <String>] -Url <String> -EventName <String[]> [-Secret <String>]
 [-CriticalOnly] [-PassThru] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### EventType
```
New-VcWebhook -Name <String> [-Type <String>] -Url <String> -EventType <String[]> [-Secret <String>]
 [-CriticalOnly] [-PassThru] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Create a new webhook to forward logged events to another service such as Slack, Teams, or a SIEM

## EXAMPLES

### EXAMPLE 1
```
New-VcWebhook -Name 'MyWebhook' -Url 'https://my.com/endpoint' -EventType 'Authentication'
```

Create a new webhook for one event type

### EXAMPLE 2
```
New-VcWebhook -Name 'MyWebhook' -Url 'https://my.com/endpoint' -EventType 'Authentication' -Type slack
```

Create a new webhook to send events to Slack

### EXAMPLE 3
```
New-VcWebhook -Name 'MyWebhook' -Url 'https://my.com/endpoint' -EventType 'Authentication', 'Certificates', 'Applications'
```

Create a new webhook with multiple event types

### EXAMPLE 4
```
New-VcWebhook -Name 'MyWebhook' -Url 'https://my.com/endpoint' -EventName 'Certificate Validation Started'
```

Create a new webhook with event names as opposed to event types.
This will result in fewer messages received as opposed to subscribing at the event type level.

### EXAMPLE 5
```
New-VcWebhook -Name 'MyWebhook' -Url 'https://my.com/endpoint' -EventType 'Certificates' -CriticalOnly
```

Subscribe to critical messages only for a specific event type

### EXAMPLE 6
```
New-VcWebhook -Name 'MyWebhook' -Url 'https://my.com/endpoint' -EventType 'Authentication' -Secret 'MySecret'
```

Create a new webhook with optional secret

### EXAMPLE 7
```
New-VcWebhook -Name 'MyWebhook' -Url 'https://my.com/endpoint' -EventType 'Authentication' -PassThru
```

Create a new webhook returning the newly created object

## PARAMETERS

### -Name
Webhook name

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Type
slack, teams, or generic (for SIEM, ServiceNow, etc).
The default is generic.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Generic
Accept pipeline input: False
Accept wildcard characters: False
```

### -Url
Endpoint to be called when the event type/name is triggered.
This should be the full url and will be validated during webhook creation.
See https://developer.venafi.com/tlsprotectcloud/docs/control-plane-forwarding-logged-events for more details.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -EventType
One or more event types to trigger on.
This property has tab completion to provide you with a list of values

```yaml
Type: String[]
Parameter Sets: EventType
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -EventName
One or more event names to trigger on.
This property has tab completion to provide you with a list of values

```yaml
Type: String[]
Parameter Sets: EventName
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Secret
Secret value used to calculate signature which will be sent to the endpoint in the header

```yaml
Type: String
Parameter Sets: (All)
Aliases: token

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CriticalOnly
Only subscribe to log messages deemed as critical

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

### -PassThru
Return newly created webhook object

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

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

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

## OUTPUTS

### PSCustomObject, if PassThru provided
## NOTES

## RELATED LINKS

[https://api.venafi.cloud/webjars/swagger-ui/index.html?urls.primaryName=connectors-service#/Connectors/connectors_create](https://api.venafi.cloud/webjars/swagger-ui/index.html?urls.primaryName=connectors-service#/Connectors/connectors_create)

[https://developer.venafi.com/tlsprotectcloud/docs/control-plane-forwarding-logged-events](https://developer.venafi.com/tlsprotectcloud/docs/control-plane-forwarding-logged-events)

