# Add-VdcCertificateAssociation

## SYNOPSIS
Add certificate association

## SYNTAX

```
Add-VdcCertificateAssociation [-CertificatePath] <String> [[-ApplicationPath] <String[]>] [-PushCertificate]
 [[-VenafiSession] <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Associates one or more Application objects to an existing certificate.
Optionally, you can push the certificate once the association is complete.

## EXAMPLES

### EXAMPLE 1
```
Add-VdcCertificateAssociation -CertificatePath '\ved\policy\my cert' -ApplicationPath '\ved\policy\my capi'
Add a single application object association
```

### EXAMPLE 2
```
Add-VdcCertificateAssociation -Path '\ved\policy\my cert' -ApplicationPath '\ved\policy\my capi' -PushCertificate
Add the association and push the certificate
```

## PARAMETERS

### -CertificatePath
Path to the certificate. 
Required if InputObject not provided.

```yaml
Type: String
Parameter Sets: (All)
Aliases: DN, CertificateDN, Path

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -ApplicationPath
List of application object paths to associate

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PushCertificate
Push the certificate after associating it to the Application objects.
This will only be successful if the certificate management type is Provisioning and is not disabled, in error, or a push is already in process.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: ProvisionCertificate

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -VenafiSession
Authentication for the function.
The value defaults to the script session object $VenafiSession created by New-VenafiSession.

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
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

### Path
## OUTPUTS

### None
## NOTES
You must have:
- Write permission to the Certificate object.
- Write or Associate and Delete permission to Application objects that are associated with the certificate

## RELATED LINKS

[https://venafi.github.io/VenafiPS/functions/Add-VdcCertificateAssociation/](https://venafi.github.io/VenafiPS/functions/Add-VdcCertificateAssociation/)

[https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Add-VdcCertificateAssociation.ps1](https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Add-VdcCertificateAssociation.ps1)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/API_Reference/r-SDK-POST-Certificates-Associate.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/API_Reference/r-SDK-POST-Certificates-Associate.php)

