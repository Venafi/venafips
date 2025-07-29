# Set-VdcCredential

## SYNOPSIS
Update credential values

## SYNTAX

### Password (Default)
```
Set-VdcCredential -Path <String> -Password <PSObject> [-Expiration <DateTime>] [-VenafiSession <PSObject>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### CertificatePath
```
Set-VdcCredential -Path <String> -Password <PSObject> -CertificatePath <String> [-Expiration <DateTime>]
 [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Certificate
```
Set-VdcCredential -Path <String> -Password <PSObject> -Certificate <X509Certificate2> [-Expiration <DateTime>]
 [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### UsernamePassword
```
Set-VdcCredential -Path <String> -Password <PSObject> -Username <String> [-Expiration <DateTime>]
 [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### CertificateLinkPath
```
Set-VdcCredential -Path <String> -CertificateLinkPath <String> [-Expiration <DateTime>]
 [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### OldValue
```
Set-VdcCredential -Path <String> -Value <Hashtable> [-VenafiSession <PSObject>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Update values for credential objects in TLSPDC.

## EXAMPLES

### EXAMPLE 1
```
Set-VdcCredential -Path '\VED\Policy\Password Credential' -Password 'my-new-password'
```

Set a new password for a password credential

### EXAMPLE 2
```
Set-VdcCredential -Path '\VED\Policy\UsernamePassword Credential' -Password 'my-new-password' -Username 'greg'
```

Set a new password for a username/password credential

### EXAMPLE 3
```
Set-VdcCredential -Path '\VED\Policy\Certificate Credential' -Password 'my-pk-password' -Certificate $p12
```

Set a new certificate for a certificate credential

### EXAMPLE 4
```
Set-VdcCredential -Path '\VED\Policy\Password Credential' -Password 'my-new-password' -Expiration (Get-Date).AddDays(30)
```

Set a new password for a password credential and set the expiration date to 30 days from now

### EXAMPLE 5
```
Set-VdcCredential -Path '\VED\Policy\Certificate Credential' -CertificateLinkPath '\VED\Policy\Certificates\newcert.domain.com'
```

Set an existing TLSPDC certificate object as the certificate for a certificate credential

## PARAMETERS

### -Path
The full path to the credential object

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Password
New password for a password, username/password, or certificate credential. 
Provide a string, SecureString, or PSCredential.

```yaml
Type: PSObject
Parameter Sets: Password, CertificatePath, Certificate, UsernamePassword
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Username
New username for a username/password credential.
A password is also required.

```yaml
Type: String
Parameter Sets: UsernamePassword
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Certificate
PKCS #12 certificate object for a certificate credential.
You can provide either a certificate object or CertificatePath to a .p12 or .pfx file.
A private key password is also required for -Password.

```yaml
Type: X509Certificate2
Parameter Sets: Certificate
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CertificatePath
Path to a certificate for a certificate credential.
You can provide either a local path to a .p12 or .pfx file or a certificate object with -Certificate.
A private key password is also required for -Password.

```yaml
Type: String
Parameter Sets: CertificatePath
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -CertificateLinkPath
Provide a path to an existing TLSPDC certificate object to be used as the certificate for a certificate credential.

```yaml
Type: String
Parameter Sets: CertificateLinkPath
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Expiration
Expiration date in UTC for the credential. 
Provide a DateTime object.
This can be set for username or password credentials.

```yaml
Type: DateTime
Parameter Sets: Password, CertificatePath, Certificate, UsernamePassword, CertificateLinkPath
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Value
Hashtable containing the keys/values to be updated.
This parameter will be deprecated in a future release. 
Use specific parameters for the credential type.
The values allowed to be updated are specific to the object type.
See https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Credentials-FriendlyName.php for details.

```yaml
Type: Hashtable
Parameter Sets: OldValue
Aliases:

Required: True
Position: Named
Default value: None
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

## RELATED LINKS

[https://venafi.github.io/VenafiPS/functions/Set-VdcCredential/](https://venafi.github.io/VenafiPS/functions/Set-VdcCredential/)

[https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Set-VdcCredential.ps1](https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Set-VdcCredential.ps1)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Credentials-update.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Credentials-update.php)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Credentials-FriendlyName.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Credentials-FriendlyName.php)

