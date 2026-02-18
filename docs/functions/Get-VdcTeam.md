# Get-VdcTeam

## SYNOPSIS
Get team info

## SYNTAX

### ID (Default)
```
Get-VdcTeam [-ID] <String> [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### All
```
Get-VdcTeam [-All] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Get info for a team including members and owners.

## EXAMPLES

### EXAMPLE 1
```
Get-VdcTeam -ID 'local:{803f332e-7576-4696-a5a2-8ac6be6b14e6}'
```

Get info for a Certificate Manager, Self-Hosted team

### EXAMPLE 2
```
Find-VdcIdentity -Name MyTeamName | Get-VdcTeam
```

Search for a team and then get details

### EXAMPLE 3
```
Get-VdcTeam -All
```

Get info for all teams

## PARAMETERS

### -ID
Team ID in local prefixed universal format. 
You can find the team/group ID with Find-VdcIdentity.

```yaml
Type: String
Parameter Sets: ID
Aliases: PrefixedUniversal, Guid, PrefixedName

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -All
Provide this switch to get all teams

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

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-GET-Teams-prefix-universal.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-GET-Teams-prefix-universal.php)

