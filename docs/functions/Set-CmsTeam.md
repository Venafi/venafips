# Set-CmsTeam

## SYNOPSIS
Update an existing team

## SYNTAX

### NoOverwrite (Default)
```
Set-CmsTeam -Team <String> [-Name <String>] [-Role <String>] [-UserMatchingRule <Hashtable[]>] [-PassThru]
 [-TrustClient <TrustClient>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Overwrite
```
Set-CmsTeam -Team <String> [-Name <String>] [-Role <String>] -UserMatchingRule <Hashtable[]> [-NoOverwrite]
 [-PassThru] [-TrustClient <TrustClient>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Update name, role, and/or user matching rules for existing teams.

## EXAMPLES

### EXAMPLE 1
```
Set-CmsTeam -ID 'MyTeam' -Name 'ThisTeamIsBetter'
```

Rename an existing team

### EXAMPLE 2
```
Set-CmsTeam -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2' -Role 'PKI Admin'
```

Change the role for an existing team

### EXAMPLE 3
```
Set-CmsTeam -ID 'MyTeam' -UserMatchingRule @{'ClaimName'='MyClaim';'Operator'='equals';'ClaimValue'='matchme'}
```

Replace a teams user matching rules

### EXAMPLE 4
```
Set-CmsTeam -ID 'MyTeam' -UserMatchingRule @{'ClaimName'='MyClaim';'Operator'='equals';'ClaimValue'='matchme'} -NoOverwrite
```

Update a teams user matching rules, appending instead of overwriting

### EXAMPLE 5
```
Set-CmsTeam -ID 'MyTeam' -Name 'ThisTeamIsBetter' -PassThru
```

Rename an existing team and return the updated team object

### EXAMPLE 6
```
Get-CmsTeam -All | Where-Object {$_.name -like '*shouldnt be sysadmin*'} | Set-CmsTeam -NewRole 'PKI Admin'
```

Update many teams

## PARAMETERS

### -Team
Team ID or name

```yaml
Type: String
Parameter Sets: (All)
Aliases: teamId

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Name
Provide a new name for the team if you wish to change it.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Role
Provide a new role for the team if you wish to change it.
Accepted values are 'System Admin', 'PKI Admin', 'Resource Owner', or 'Guest'

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UserMatchingRule
Rule(s) for user membership which matches SSO claim data.
Each rule has 3 parts, ClaimName, Operator, and ClaimValue, in the form of a hashtable.
A list/array of hashtables is supported.
For a singlepart claim, the operator can be 'equals', 'does not equal', 'starts with', or 'ends with'.
For a multivalue claim where ClaimValue will be an array, the operator can be 'contains' or 'does not contain'.
ClaimName and ClaimValue are case sensitive.
When providing user AD groups or other groups they are most commonly provided as multivalue claims.
This parameter will overwrite existing rules by default. 
To append use -NoOverwrite.

```yaml
Type: Hashtable[]
Parameter Sets: NoOverwrite
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: Hashtable[]
Parameter Sets: Overwrite
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoOverwrite
Append to existing user matching rules as opposed to overwriting

```yaml
Type: SwitchParameter
Parameter Sets: Overwrite
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
Return the newly updated team object

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

### ID
## OUTPUTS

### PSCustomObject
## NOTES

## RELATED LINKS
