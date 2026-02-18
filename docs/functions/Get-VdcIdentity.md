# Get-VdcIdentity

## SYNOPSIS
Get user and group details

## SYNTAX

### Id (Default)
```
Get-VdcIdentity -ID <String> [-IncludeAssociated] [-IncludeMembers] [-VenafiSession <PSObject>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Me
```
Get-VdcIdentity [-Me] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### All
```
Get-VdcIdentity [-All] [-IncludeAssociated] [-IncludeMembers] [-VenafiSession <PSObject>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Returns user/group information for Certificate Manager, Self-Hosted
This returns individual identity, group identity, or distribution groups from a local or non-local provider such as Active Directory.

## EXAMPLES

### EXAMPLE 1
```
Get-VdcIdentity -ID 'AD+myprov:asdfgadsf9g87df98g7d9f8g7'
```

Get identity details from an id

### EXAMPLE 2
```
Get-VdcIdentity -ID 'AD+myprov:asdfgadsf9g87df98g7d9f8g7' -IncludeMembers
```

Get identity details including members if the identity is a group

### EXAMPLE 3
```
Get-VdcIdentity -ID 'AD+myprov:asdfgadsf9g87df98g7d9f8g7' -IncludeAssociated
```

Get identity details including associated groups/folders

### EXAMPLE 4
```
Get-VdcIdentity -Me
```

Get identity details for authenticated/current user

### EXAMPLE 5
```
Get-VdcIdentity -All
```

Get all user and group info

## PARAMETERS

### -ID
Provide the guid or prefixed universal id. 
To search, use Find-VdcIdentity.

```yaml
Type: String
Parameter Sets: Id
Aliases: Guid, FullName

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Me
Returns the identity of the authenticated/current user

```yaml
Type: SwitchParameter
Parameter Sets: Me
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -All
Return a complete list of local users.

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

### -IncludeAssociated
Include all associated identity groups and folders.

```yaml
Type: SwitchParameter
Parameter Sets: Id, All
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeMembers
Include all individual members if the ID is a group.

```yaml
Type: SwitchParameter
Parameter Sets: Id, All
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
###     Name
###     ID
###     Path
###     FullName
###     Associated (if -IncludeAssociated provided)
###     Members (if -IncludeMembers provided)
## NOTES

## RELATED LINKS

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Identity-Validate.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Identity-Validate.php)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-GET-Identity-Self.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-GET-Identity-Self.php)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Identity-GetAssociatedEntries.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Identity-GetAssociatedEntries.php)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Identity-GetMembers.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Identity-GetMembers.php)

