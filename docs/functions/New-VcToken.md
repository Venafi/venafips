# New-VcToken

## SYNOPSIS
Get a new access token

## SYNTAX

### ScriptSession (Default)
```
New-VcToken [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Endpoint
```
New-VcToken -Endpoint <String> -Jwt <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Session
```
New-VcToken [-Jwt <String>] -VenafiSession <PSObject> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Get a new access token from an endpoint and JWT.
You can also provide a VenafiSession, or no session to use the script scoped one, which will use the stored endpoint and jwt to refresh the access token.
This only works if the jwt has not expired.

## EXAMPLES

### EXAMPLE 1
```
New-VcToken
```

Refresh the existing access token stored in the script scoped variable VenafiSession
Only possible if the JWT has not expired.

### EXAMPLE 2
```
New-VcToken -Endpoint 'https://api.venafi.cloud/v1/oauth2/v2.0/2222c771-61f3-11ec-8a47-490a1e43c222/token' -Jwt $Jwt
```

Get a new token with OAuth

### EXAMPLE 3
```
New-VcToken -VenafiSession $sess
```

Refresh the existing access token stored in session.
Only possible if the JWT has not expired.

## PARAMETERS

### -Endpoint
Token Endpoint URL as shown on the service account details page in Certificate Manager, SaaS

```yaml
Type: String
Parameter Sets: Endpoint
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Jwt
JSON web token with access to the configured service account

```yaml
Type: String
Parameter Sets: Endpoint
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: Session
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -VenafiSession
VenafiSession object created from New-VenafiSession method.
This can be used to refresh the access token if the JWT has not expired.

```yaml
Type: PSObject
Parameter Sets: Session
Aliases:

Required: True
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

### None
## OUTPUTS

### PSCustomObject with the following properties:
###     Endpoint
###     AccessToken
###     JWT
###     Expires
## NOTES

## RELATED LINKS
