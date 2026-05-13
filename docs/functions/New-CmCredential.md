# New-CmCredential

## SYNOPSIS
Create a new credential

## SYNTAX

### UsernamePassword (Default)
```
New-CmCredential -Path <String> -Secret <PSObject> [-PassThru] [-TrustClient <TrustClient>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Certificate
```
New-CmCredential -Path <String> -Secret <PSObject> -CertificatePath <String> [-PassThru]
 [-TrustClient <TrustClient>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Create a new credential of type Password, Username Password, or Certificate.

## EXAMPLES

### EXAMPLE 1
```
New-CmCredential -Path '\VED\Policy\cred' -Secret $myCred
```

Create a new Username Credential with the username and password from $myCred

### EXAMPLE 2
```
New-CmCredential -Path '\VED\Policy\cred' -Secret $myPassword
```

Create a new Password Credential with the value of $myPassword.
$myPassword can be a string or a securestring.

### EXAMPLE 3
```
New-CmCredential -Path '\VED\Policy\certcred' -Secret $certPassword -CertificatePath 'C:\mycert.pfx'
```

Create a new Certificate Credential with the certificate at 'C:\mycert.pfx' and the password $certPassword.

### EXAMPLE 4
```
New-CmCredential -Path '\VED\Policy\certcred' -Secret $certPassword -CertificatePath 'C:\mycert.pfx' -PassThru
```

Create a new Certificate Credential and return the object.

## PARAMETERS

### -Path
Full path, including name, for the object to be created.
If the root path is excluded, \ved\policy will be prepended.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Secret
The secret value for the credential. 
The type of credential created will depend on the type of this parameter.
If a String or SecureString is provided, a Password Credential will be created.
If a PSCredential is provided, a Username Password Credential will be created with the username and password from the PSCredential.

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CertificatePath
If provided, a Certificate Credential will be created.
The certificate must be in a PFX/PKCS12 format and Secret must contain the private key password for the certificate to be imported correctly.

```yaml
Type: String
Parameter Sets: Certificate
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
Return the newly created object properties.

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

### none
## OUTPUTS

### pscustomobject, if PassThru provided
## NOTES

## RELATED LINKS
