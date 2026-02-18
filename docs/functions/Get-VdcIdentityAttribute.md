# Get-VdcIdentityAttribute

## SYNOPSIS
Get attribute values for Certificate Manager, Self-Hosted identity objects

## SYNTAX

```
Get-VdcIdentityAttribute [-ID] <String[]> [[-Attribute] <String[]>] [[-VenafiSession] <PSObject>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Get attribute values for Certificate Manager, Self-Hosted identity objects.

## EXAMPLES

### EXAMPLE 1
```
Get-VdcIdentityAttribute -IdentityId 'AD+blah:{1234567890olikujyhtgrfedwsqa}'
```

Get basic attributes

### EXAMPLE 2
```
Get-VdcIdentityAttribute -IdentityId 'AD+blah:{1234567890olikujyhtgrfedwsqa}' -Attribute 'Surname'
```

Get specific attribute for user

## PARAMETERS

### -ID
The id that represents the user or group. 
Use Find-VdcIdentity to get the id.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: PrefixedUniversalId, Contact, IdentityId

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Attribute
Retrieve identity attribute values for the users and groups.
Common user attributes include Group Membership, Name, Internet Email Address, Given Name, and Surname.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
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
Position: 3
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

### PSCustomObject with the properties Identity and Attribute
## NOTES

## RELATED LINKS

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Identity-Validate.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Identity-Validate.php)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Identity-Readattribute.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Identity-Readattribute.php)

