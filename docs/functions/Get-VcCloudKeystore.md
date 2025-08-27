# Get-VcCloudKeystore

## SYNOPSIS
Get cloud keystore info

## SYNTAX

### CK
```
Get-VcCloudKeystore -CloudKeystore <String> [-CloudProvider <String>] [-VenafiSession <PSObject>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### CP
```
Get-VcCloudKeystore -CloudProvider <String> [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### All
```
Get-VcCloudKeystore [-All] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Get 1 or more cloud keystores

## EXAMPLES

### EXAMPLE 1
```
Get-VcCloudKeystore -CloudProvider 'MyGCP'
```

Get all keystores for a specific provider

### EXAMPLE 2
```
Get-VcCloudKeystore -CloudProvider 'MyGCP' -CloudKeystore 'CK'
```

Get a specific keystore

### EXAMPLE 3
```
Get-VcCloudKeystore -All
```

Get all cloud keystores across all providers

## PARAMETERS

### -CloudKeystore
Cloud keystore ID or name, tab completion supported

```yaml
Type: String
Parameter Sets: CK
Aliases: cloudKeystoreId, ck

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -CloudProvider
Limit keystores to specific providers.
Cloud provider ID or name, tab completion supported

```yaml
Type: String
Parameter Sets: CK
Aliases: cloudProviderId, cp

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: CP
Aliases: cloudProviderId, cp

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -All
Get all cloud keystores

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

### CloudProvider, CloudKeystore
## OUTPUTS

## NOTES

## RELATED LINKS
