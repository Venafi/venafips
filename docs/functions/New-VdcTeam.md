# New-VdcTeam

## SYNOPSIS
Create a new team

## SYNTAX

```
New-VdcTeam [-Name] <String> [-Owner] <String[]> [-Member] <String[]> [[-Policy] <String[]>]
 [-Product] <String[]> [[-Description] <String>] [-PassThru] [[-VenafiSession] <PSObject>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Create a new Certificate Manager, Self-Hosted team

## EXAMPLES

### EXAMPLE 1
```
New-VdcTeam -Name 'My New Team' -Member 'local:{803f332e-7576-4696-a5a2-8ac6be6b14e6}' -Owner 'local:{803f332e-7576-4696-a5a2-8ac6be6b14e7}' -Product 'TLS'
```

Create a new team

### EXAMPLE 2
```
New-VdcTeam -Name 'My New Team' -Member 'local:{803f332e-7576-4696-a5a2-8ac6be6b14e6}' -Owner 'local:{803f332e-7576-4696-a5a2-8ac6be6b14e7}' -Product 'TLS' -Policy '\ved\policy\myfolder'
```

Create a new team and assign it to a policy

### EXAMPLE 3
```
New-VdcTeam -Name 'My New Team' -Member 'local:{803f332e-7576-4696-a5a2-8ac6be6b14e6}' -Owner 'local:{803f332e-7576-4696-a5a2-8ac6be6b14e7}' -Product 'TLS' -Description 'One amazing team'
```

Create a new team with optional description

### EXAMPLE 4
```
New-VdcTeam -Name 'My New Team' -Member 'local:{803f332e-7576-4696-a5a2-8ac6be6b14e6}' -Owner 'local:{803f332e-7576-4696-a5a2-8ac6be6b14e7}' -Product 'TLS' -PassThru
```

Name     : My New Team
ID       : local:{a6053090-e309-49d9-98a7-28cbe7896c27}
Path     : \VED\Identity\My New Team
FullName : local:My New Team
IsGroup  : True
Members  : @{Name=sample-user; ID=local:{6baad36c-7cac-48c8-8e54-000cc22ad88f};
           Path=\VED\Identity\sample-user; FullName=local:sample-user; IsGroup=False}
Owners   : @{Name=sample-owner; ID=local:{d1a76bc7-d3a6-431b-9bea-d2d8780ecd86};
           Path=\VED\Identity\sample-owner; FullName=local:sample-owner; IsGroup=False}

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
1 or more owners for the team
Provide the identity ID property from Find-VdcIdentity or Get-VdcIdentity.

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
1 or more members for the team
Provide the identity ID property from Find-VdcIdentity or Get-VdcIdentity.

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

### -Policy
1 or more policy folder paths this team manages.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Product
1 or more product names, 'TLS', 'SSH', and/or 'Code Signing'.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Description
Team description or purpose.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
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

### -VenafiSession
Authentication for the function.
The value defaults to the script session object $VenafiSession created by New-VenafiSession.
A Certificate Manager, Self-Hosted token key can also provided.
If providing a Certificate Manager, Self-Hosted token, an environment variable named VDC_SERVER must also be set.

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
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

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Teams.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Teams.php)

