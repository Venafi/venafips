# Remove-VdcCertificateAssociation

## SYNOPSIS
Remove certificate associations

## SYNTAX

### RemoveOne (Default)
```
Remove-VdcCertificateAssociation -Path <String> -ApplicationPath <String[]> [-OrphanCleanup]
 [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### RemoveAll
```
Remove-VdcCertificateAssociation -Path <String> [-OrphanCleanup] [-All] [-VenafiSession <PSObject>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Dissociates one or more Application objects from an existing certificate.
Optionally, you can remove the application objects and corresponding orphaned device objects that no longer have any applications

## EXAMPLES

### EXAMPLE 1
```
Remove-VdcCertificateAssociation -Path '\ved\policy\my cert' -ApplicationPath '\ved\policy\my capi'
Remove a single application object association
```

### EXAMPLE 2
```
Remove-VdcCertificateAssociation -Path '\ved\policy\my cert' -ApplicationPath '\ved\policy\my capi' -OrphanCleanup
Disassociate and delete the application object
```

### EXAMPLE 3
```
Remove-VdcCertificateAssociation -Path '\ved\policy\my cert' -RemoveAll
Remove all certificate associations
```

## PARAMETERS

### -Path
Path to the certificate

```yaml
Type: String
Parameter Sets: (All)
Aliases: DN, CertificateDN

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -ApplicationPath
List of application object paths to dissociate

```yaml
Type: String[]
Parameter Sets: RemoveOne
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OrphanCleanup
Delete the Application object after dissociating it.
Only delete the corresponding Device DN when it has no child objects.
Otherwise retain the Device path and its children.

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

### -All
Remove all associated application objects

```yaml
Type: SwitchParameter
Parameter Sets: RemoveAll
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
A Certificate Manager, Self-Hosted token can also provided.
If providing a Certificate Manager, Self-Hosted token, an environment variable named VDC_SERVER must also be set.

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
- Write or Associate permission to Application objects that are associated with the certificate
- Delete permission to Application and device objects when specifying -OrphanCleanup

## RELATED LINKS

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Certificates-Dissociate.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Certificates-Dissociate.php)

