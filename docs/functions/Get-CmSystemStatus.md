# Get-CmSystemStatus

## SYNOPSIS
Get the Certificate Manager, Self-Hosted system status

## SYNTAX

```
Get-CmSystemStatus [[-TrustClient] <TrustClient>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Returns service module statuses for Trust Protection Platform, Log Server, and Trust Protection Platform services that run on Microsoft Internet Information Services (IIS)

## EXAMPLES

### EXAMPLE 1
```
Get-CmSystemStatus
Get the status
```

## PARAMETERS

### -TrustClient
Authentication for the function.
The value defaults to the script session object $TrustClient created by New-TrustClient.

```yaml
Type: TrustClient
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
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

### none
## OUTPUTS

### PSCustomObject
## NOTES

## RELATED LINKS

[https://venafi.github.io/VenafiPS/functions/Get-CmSystemStatus/](https://venafi.github.io/VenafiPS/functions/Get-CmSystemStatus/)

[https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Get-CmSystemStatus.ps1](https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Get-CmSystemStatus.ps1)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-GET-SystemStatus.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-GET-SystemStatus.php)

