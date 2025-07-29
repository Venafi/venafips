# Get-VdcVersion

## SYNOPSIS
Get the TLSPDC version

## SYNTAX

```
Get-VdcVersion [[-VenafiSession] <PSObject>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Returns the TLSPDC version

## EXAMPLES

### EXAMPLE 1
```
Get-VdcVersion
Get the version
```

## PARAMETERS

### -VenafiSession
Authentication for the function.
The value defaults to the script session object $VenafiSession created by New-VenafiSession.

```yaml
Type: PSObject
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

### Version
## NOTES

## RELATED LINKS

[https://venafi.github.io/VenafiPS/functions/Get-VdcVersion/](https://venafi.github.io/VenafiPS/functions/Get-VdcVersion/)

[https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Get-VdcVersion.ps1](https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Get-VdcVersion.ps1)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-GET-SystemStatusVersion.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-GET-SystemStatusVersion.php)

