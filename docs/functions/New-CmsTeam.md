# New-CmsTeam

## SYNOPSIS
Create a new team

## SYNTAX

```
New-CmsTeam [-Name] <String> [-Owner] <String[]> [-Member] <String[]> [-Role] <String>
 [[-UserMatchingRule] <System.Collections.Generic.List`1[System.Array]>] [-PassThru]
 [[-TrustClient] <TrustClient>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Create a new Certificate Manager, SaaS team

## EXAMPLES

### EXAMPLE 1
```
New-VenafiTeam -Name 'My New Team' -Member 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2' -Owner @('ca7ff555-88d2-4bfc-9efa-2630ac44c1f3', 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f4') -Role 'System Admin'
```

Create a new team

### EXAMPLE 2
```
New-VenafiTeam -Name 'My New Team' -Member 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2' -Owner @('ca7ff555-88d2-4bfc-9efa-2630ac44c1f3', 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f4') -Role 'System Admin' -UserMatchingRule @('MyClaim', 'CONTAINS', 'Group')
```

Create a new team with user matching rule

### EXAMPLE 3
```
New-VenafiTeam -Name 'My New Team' -Member 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2' -Owner @('ca7ff555-88d2-4bfc-9efa-2630ac44c1f3', 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f4') -Role 'System Admin' -PassThru
```

id                : a7d60730-a967-11ec-8832-4d051bf6d0b4
name              : My New Team
systemRoles       : {SYSTEM_ADMIN}
productRoles      :
role              : SYSTEM_ADMIN
members           : {443de910-a6cc-11ec-ad22-018e33741844}
owners            : {0a2adae0-b22b-11ea-91f3-ebd6dea5452e}
companyId         : 0bc771e1-7abe-4339-9fcd-93fffe9cba7f
userMatchingRules : {}
modificationDate  : 3/21/2022 6:38:40 PM

Create a new team returning the new team

## PARAMETERS

### -Name
Team name

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Owner
1 or more owners for the team.
Provide the unique guid obtained from Get-CmsUser.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Member
1 or more members for the team.
Provide the unique guid obtained from Get-CmsUser.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Role
Team role, either 'System Admin', 'PKI Admin', 'Resource Owner' or 'Guest'

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UserMatchingRule
If SSO is enabled, build your team membership rules to organize your users into teams automatically.
If more than 1 rule is configured, they must all be met for a user to meet the criteria.
Each rule should be of the format @('claim name', 'operator', 'value')
where operator can be equals, not_equals, contains, not_contains, starts_with, or ends_with.

```yaml
Type: System.Collections.Generic.List`1[System.Array]
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
Send back details on the newly created team

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
Position: 6
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

## NOTES

## RELATED LINKS

[https://api.venafi.cloud/webjars/swagger-ui/index.html#/Teams/create_1](https://api.venafi.cloud/webjars/swagger-ui/index.html#/Teams/create_1)

[https://docs.venafi.cloud/vcs-platform/creating-new-teams/](https://docs.venafi.cloud/vcs-platform/creating-new-teams/)

