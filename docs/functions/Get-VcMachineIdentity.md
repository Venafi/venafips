# Get-VcMachineIdentity

## SYNOPSIS
Get machine identities

## SYNTAX

### ID (Default)
```
Get-VcMachineIdentity [-ID] <String> [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### All
```
Get-VcMachineIdentity [-All] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Get 1 or all machine identities

## EXAMPLES

### EXAMPLE 1
```
Get-VcMachineIdentity -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2'
```

machineIdentityId : cc57e830-1a90-11ee-abe7-bda0c823b1ad
companyId         : cc57e830-1a90-11ee-abe7-bda0c823b1ad
machineId         : 5995ecf0-19ca-11ee-9386-3ba941243b67
certificateId     : cc535450-1a90-11ee-8774-3d248c9b48c5
status            : DISCOVERED
creationDate      : 7/4/2023 1:32:50 PM
lastSeenOn        : 7/4/2023 1:32:50 PM
modificationDate  : 7/4/2023 1:32:50 PM
keystore          : @{friendlyName=1.test.net; keystoreCapiStore=my; privateKeyIsExportable=False}
binding           : @{createBinding=False; port=40112; siteName=domain.io}

Get a single machine identity by ID

### EXAMPLE 2
```
Get-VcMachineIdentity -All
```

Get all machine identities

## PARAMETERS

### -ID
Machine identity ID

```yaml
Type: String
Parameter Sets: ID
Aliases: machineIdentityId

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -All
Get all machine identities

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
A TLSPC key can also provided.

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: (Get-VenafiSession)
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

## NOTES

## RELATED LINKS
