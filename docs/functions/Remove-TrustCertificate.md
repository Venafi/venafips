# Remove-TrustCertificate

## SYNOPSIS
Remove a certificate

## SYNTAX

```
Remove-TrustCertificate [-ID] <String> [[-TrustClient] <TrustClient>] [-ProgressAction <ActionPreference>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Remove a certificate

## EXAMPLES

### EXAMPLE 1
```
Remove-TrustCertificate -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2'
```

Remove a certificate

### EXAMPLE 2
```
Find-TrustCertificate | Remove-TrustCertificate
```

Remove multiple certificates based on a search

### EXAMPLE 3
```
Remove-TrustCertificate -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2' -Confirm:$false
```

Remove a certificate bypassing the confirmation prompt

## PARAMETERS

### -ID
Certificate ID of a certificate that has been retired

```yaml
Type: String
Parameter Sets: (All)
Aliases: certificateId

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
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
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

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

## NOTES

## RELATED LINKS
