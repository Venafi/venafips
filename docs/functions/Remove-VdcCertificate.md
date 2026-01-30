# Remove-VdcCertificate

## SYNOPSIS
Remove a certificate

## SYNTAX

```
Remove-VdcCertificate [-Path] <String> [-KeepAssociatedApps] [[-ThrottleLimit] <Int32>]
 [[-VenafiSession] <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Removes a Certificate object, all associated objects including pending workflow tickets, and the corresponding Secret Store vault information.
You must either be a Master Admin or have Delete permission to the objects and have certificate:delete token scope.
Run this in parallel with PowerShell v7+ when you have a large number to process.

## EXAMPLES

### EXAMPLE 1
```
$cert | Remove-VdcCertificate
Remove a certificate via pipeline
```

### EXAMPLE 2
```
Remove-VdcCertificate -Path '\ved\policy\my cert'
Remove a certificate and any associated app
```

### EXAMPLE 3
```
Remove-VdcCertificate -Path '\ved\policy\my cert' -KeepAssociatedApps
Remove a certificate and first remove all associations, keeping the apps
```

## PARAMETERS

### -Path
Path to the certificate to remove

```yaml
Type: String
Parameter Sets: (All)
Aliases: DN, CertificateDN

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -KeepAssociatedApps
Provide this switch to remove associations prior to certificate removal

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

### -ThrottleLimit
Limit the number of threads when running in parallel; the default is 100.
Setting the value to 1 will disable multithreading.
On PS v5 the ThreadJob module is required. 
If not found, multithreading will be disabled.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 100
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
Default value: (Get-VenafiSession)
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

## RELATED LINKS

[https://venafi.github.io/VenafiPS/functions/Remove-VdcCertificate/](https://venafi.github.io/VenafiPS/functions/Remove-VdcCertificate/)

[https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Remove-VdcCertificate.ps1](https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Remove-VdcCertificate.ps1)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-DELETE-Certificates-Guid.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-DELETE-Certificates-Guid.php)

