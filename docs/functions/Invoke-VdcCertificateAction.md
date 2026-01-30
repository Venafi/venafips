# Invoke-VdcCertificateAction

## SYNOPSIS
Perform an action against a certificate

## SYNTAX

### Disable
```
Invoke-VdcCertificateAction -Path <String> [-Disable] [-AdditionalParameter <Hashtable>]
 [-ThrottleLimit <Int32>] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### Reset
```
Invoke-VdcCertificateAction -Path <String> [-Reset] [-AdditionalParameter <Hashtable>] [-ThrottleLimit <Int32>]
 [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Renew
```
Invoke-VdcCertificateAction -Path <String> [-Renew] [-AdditionalParameter <Hashtable>] [-ThrottleLimit <Int32>]
 [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Push
```
Invoke-VdcCertificateAction -Path <String> [-Push] [-AdditionalParameter <Hashtable>] [-ThrottleLimit <Int32>]
 [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Validate
```
Invoke-VdcCertificateAction -Path <String> [-Validate] [-AdditionalParameter <Hashtable>]
 [-ThrottleLimit <Int32>] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### Revoke
```
Invoke-VdcCertificateAction -Path <String> [-Revoke] [-AdditionalParameter <Hashtable>]
 [-ThrottleLimit <Int32>] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### Delete
```
Invoke-VdcCertificateAction -Path <String> [-Delete] [-AdditionalParameter <Hashtable>]
 [-ThrottleLimit <Int32>] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
One stop shop for basic certificate actions.
You can Retire, Reset, Renew, Push, Validate, Revoke, or Delete.
If using PowerShell v7+, this will be run in parallel.

## EXAMPLES

### EXAMPLE 1
```
Invoke-VdcCertificateAction -Path '\VED\Policy\My folder\app.mycompany.com' -Revoke
```

Perform an action

### EXAMPLE 2
```
Invoke-VdcCertificateAction -Path '\VED\Policy\My folder\app.mycompany.com' -Delete -Confirm:$false
```

Perform an action bypassing the confirmation prompt. 
Only applicable to revoke, disable, and delete.

### EXAMPLE 3
```
Invoke-VdcCertificateAction -Path '\VED\Policy\My folder\app.mycompany.com' -Revoke -Confirm:$false | Invoke-VdcCertificateAction -Delete -Confirm:$false
```

Chain multiple actions together

### EXAMPLE 4
```
Invoke-VdcCertificateAction -Path '\VED\Policy\My folder\app.mycompany.com' -Push -AdditionalParameter @{'PushToAll'=$false; 'ApplicationDN'=@('\VED\Policy\My folder\app.mycompany.com\app1','\VED\Policy\My folder\app.mycompany.com\app2')}
```

Perform a push to a subset of associated applications overwriting the default of pushing to all.

### EXAMPLE 5
```
Invoke-VdcCertificateAction -Path '\VED\Policy\My folder\app.mycompany.com' -Revoke -AdditionalParameter @{'Comments'='Key compromised'; 'Reason'='3'}
```

Perform a revoke sending additional parameters.

Comments: The details about why the certificate is being revoked.
Be sure the comment length does not exceed the limitation from the CA.
When accepting a revocation request, they may handle data outside their limits differently.
For Entrust CA or EntrustPKI CA, the maximum character limit is 250.

Values for Reason can be:
    0: None
    1: User key compromised
    2: CA key compromised
    3: User changed affiliation
    4: Certificate superseded
    5: Original use no longer valid

## PARAMETERS

### -Path
Full path to the certificate

```yaml
Type: String
Parameter Sets: (All)
Aliases: CertificateID, id

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Disable
Disable a certificate

```yaml
Type: SwitchParameter
Parameter Sets: Disable
Aliases: Retire

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Reset
Reset the state of a certificate and its associated applications

```yaml
Type: SwitchParameter
Parameter Sets: Reset
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Renew
Requests immediate renewal for an existing certificate

```yaml
Type: SwitchParameter
Parameter Sets: Renew
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Push
Provisions the same certificate and private key to one or more devices or servers.
The certificate must be associated with one or more Application objects.
By default, this will provision the certificate to all associated applications.
To specify a subset of applications, use the AdditionalParameter parameter as shown in the examples.

```yaml
Type: SwitchParameter
Parameter Sets: Push
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Validate
Initiates SSL/TLS network validation

```yaml
Type: SwitchParameter
Parameter Sets: Validate
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Revoke
Sends a revocation request to the certificate CA

```yaml
Type: SwitchParameter
Parameter Sets: Revoke
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Delete
Delete a certificate.

```yaml
Type: SwitchParameter
Parameter Sets: Delete
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -AdditionalParameter
Additional items specific to the action being taken, if needed.
See the examples for suggestions.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
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
Position: Named
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
Position: Named
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

### PSCustomObject with the following properties:
###     CertificateID - Certificate path
###     Success - A value of true indicates that the action was successful
###     Error - Indicates any errors that occurred. Not returned when Success is true
## NOTES

## RELATED LINKS

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Certificates-Reset.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Certificates-Reset.php)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Certificates-renew.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Certificates-renew.php)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Certificates-Push.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Certificates-Push.php)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Certificates-Validate.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Certificates-Validate.php)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Certificates-revoke.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Certificates-revoke.php)

