# Find-CmClient

## SYNOPSIS
Get information about registered Server Agents or Agentless clients

## SYNTAX

```
Find-CmClient [[-ClientType] <String>] [[-TrustClient] <TrustClient>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Get information about registered Server Agent or Agentless clients.

## EXAMPLES

### EXAMPLE 1
```
Find-CmClient
Find all clients
```

### EXAMPLE 2
```
Find-CmClient -ClientType Portal
Find clients with the specific type
```

## PARAMETERS

### -ClientType
The client type.
Allowed values include VenafiAgent, AgentJuniorMachine, AgentJuniorUser, Portal, Agentless, PreEnrollment, iOS, Android

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
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
Position: 2
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

### None
## OUTPUTS

### PSCustomObject
## NOTES

## RELATED LINKS

[https://venafi.github.io/VenafiPS/functions/Find-CmClient/](https://venafi.github.io/VenafiPS/functions/Find-CmClient/)

[https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Find-CmClient.ps1](https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Find-CmClient.ps1)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-GET-ClientDetails.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-GET-ClientDetails.php)

