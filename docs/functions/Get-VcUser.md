# Get-VcUser

## SYNOPSIS
Get user details

## SYNTAX

### Id (Default)
```
Get-VcUser -User <String> [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Me
```
Get-VcUser [-Me] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### All
```
Get-VcUser [-All] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Returns user information for Certificate Manager, SaaS.

## EXAMPLES

### EXAMPLE 1
```
Get-VcUser -ID 9e9db8d6-234a-409c-8299-e3b81ce2f916
```

Get user details from an id

### EXAMPLE 2
```
Get-VcUser -ID 'greg.brownstein@venafi.com'
```

Get user details from a username

### EXAMPLE 3
```
Get-VcUser -Me
```

Get user details for authenticated/current user

### EXAMPLE 4
```
Get-VcUser -All
```

Get all users

## PARAMETERS

### -User
Either be the user id (guid) or username which is the email address.

```yaml
Type: String
Parameter Sets: Id
Aliases: userId, owningUser, owningUsers, owningUserId, ID

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Me
Returns details of the authenticated/current user

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

### PSCustomObject
###     username
###     userId
###     companyId
###     firstname
###     lastname
###     emailAddress
###     userType
###     userAccountType
###     userStatus
###     systemRoles
###     productRoles
###     localLoginDisabled
###     hasPassword
###     firstLoginDate
###     creationDate
###     ownedTeams
###     memberedTeams
## NOTES

## RELATED LINKS

[https://api.venafi.cloud/webjars/swagger-ui/index.html?urls.primaryName=account-service#/Users/users_getByUsername](https://api.venafi.cloud/webjars/swagger-ui/index.html?urls.primaryName=account-service#/Users/users_getByUsername)

