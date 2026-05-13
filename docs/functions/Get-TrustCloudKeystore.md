# Get-TrustCloudKeystore

## SYNOPSIS
Get cloud keystore info

## SYNTAX

### CK
```
Get-TrustCloudKeystore -CloudKeystore <String> [-CloudProvider <String>] [-TrustClient <TrustClient>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### CP
```
Get-TrustCloudKeystore -CloudProvider <String> [-TrustClient <TrustClient>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### All
```
Get-TrustCloudKeystore [-All] [-TrustClient <TrustClient>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Get 1 or more cloud keystores

## EXAMPLES

### EXAMPLE 1
```
Get-TrustCloudKeystore -CloudProvider 'MyGCP'
```

Get all keystores for a specific provider

### EXAMPLE 2
```
Get-TrustCloudKeystore -CloudProvider 'MyGCP' -CloudKeystore 'CK'
```

Get a specific keystore

### EXAMPLE 3
```
Get-TrustCloudKeystore -All
```

Get all cloud keystores across all providers

## PARAMETERS

### -CloudKeystore
Cloud keystore ID or name, tab completion supported

```yaml
Type: String
Parameter Sets: CK
Aliases: cloudKeystoreId

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
Aliases: cloudProviderId

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: CP
Aliases: cloudProviderId

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

### CloudProvider, CloudKeystore
## OUTPUTS

## NOTES

## RELATED LINKS
