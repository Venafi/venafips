# Get-CmsUser

## SYNOPSIS
Get user details

## SYNTAX

### Id (Default)
```
Get-CmsUser -User <String> [-TrustClient <TrustClient>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### Me
```
Get-CmsUser [-Me] [-TrustClient <TrustClient>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### All
```
Get-CmsUser [-All] [-TrustClient <TrustClient>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Returns user information for Certificate Manager, SaaS.

## EXAMPLES

### EXAMPLE 1
```
Get-CmsUser -ID 9e9db8d6-234a-409c-8299-e3b81ce2f916
```

Get user details from an id

### EXAMPLE 2
```
Get-CmsUser -ID 'greg.brownstein@venafi.com'
```

Get user details from a username

### EXAMPLE 3
```
Get-CmsUser -Me
```

Get user details for authenticated/current user

### EXAMPLE 4
```
Get-CmsUser -All
```

Get all users

## PARAMETERS

### -User
Either be the user id (guid) or username which is the email address.

```yaml
Type: String
Parameter Sets: Id
Aliases: userId

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

