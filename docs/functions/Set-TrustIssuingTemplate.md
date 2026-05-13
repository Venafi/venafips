# Set-TrustIssuingTemplate

## SYNOPSIS
Update an existing issuing template

## SYNTAX

### Base (Default)
```
Set-TrustIssuingTemplate -IssuingTemplate <String> [-Name <String>] [-Description <String>] [-PassThru]
 [-TrustClient <TrustClient>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### CA
```
Set-TrustIssuingTemplate -IssuingTemplate <String> [-Name <String>] [-Description <String>]
 -CertificateAuthority <String> -ProductOption <String> [-PassThru] [-TrustClient <TrustClient>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Update details of existing issuing templates.
Additional properties will be available in the future.

## EXAMPLES

### EXAMPLE 1
```
Set-TrustIssuingTemplate -IssuingTemplate 'DigiCert' -Name 'ThisNameIsBetter'
```

Rename an existing issuing template

### EXAMPLE 2
```
Set-TrustIssuingTemplate -IssuingTemplate 'MyTemplate' -CertificateAuthority 'GreatCA' -ProductOption 'BestOption'
```

Change the certificate authority and product option associated with this template. 
This will update all certificate requests using this template to use the new CA and product option as well.

### EXAMPLE 3
```
Set-TrustIssuingTemplate -IssuingTemplate 'MyTemplate' -Description 'Updated description'
```

Update the description for this template

### EXAMPLE 4
```
Get-TrustIssuingTemplate -All -CA 'OldCA' | Set-TrustIssuingTemplate -CertificateAuthority 'newCA' -ProductOption 'NewOption'
```

Update all templates using a specific CA to use a new CA and product option

## PARAMETERS

### -IssuingTemplate
The issuing template to update. 
Specify either ID or name.

```yaml
Type: String
Parameter Sets: (All)
Aliases: issuingTemplateId

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Name
Provide a new name for the issuing template if you wish to change it.

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

### -Description
Provide a new description for the issuing template if you wish to change it.

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

### -CertificateAuthority
Update the certificate authority associated with this template. 
Specify by name or ID.

```yaml
Type: String
Parameter Sets: CA
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProductOption
When updating the certificate authority, specify the product option to use as well. 
Specify by name or ID.

```yaml
Type: String
Parameter Sets: CA
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
Return the newly updated object

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
Default value: (Get-TrustClient)
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

### PSCustomObject
## NOTES

## RELATED LINKS
