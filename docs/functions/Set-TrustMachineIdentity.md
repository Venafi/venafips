# Set-TrustMachineIdentity

## SYNOPSIS
Update an existing machine identity

## SYNTAX

```
Set-TrustMachineIdentity [-MachineIdentity] <String> [[-Certificate] <String>] [[-Binding] <Hashtable>]
 [[-Keystore] <Hashtable>] [-Force] [-PassThru] [[-TrustClient] <TrustClient>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Update an existing machine identity, including associated certificate, binding details, and keystore details.

## EXAMPLES

### EXAMPLE 1
```
Set-TrustMachineIdentity -MachineIdentity 3f4d8db9-6f83-4c9b-9a53-6f8e2a9d6d2b -Certificate 'web01.example.com'
```

Update the certificate associated with a machine identity.

### EXAMPLE 2
```
Set-TrustMachineIdentity -MachineIdentity 3f4d8db9-6f83-4c9b-9a53-6f8e2a9d6d2b -Certificate 'web01.example.com' -Force
```

Update the machine identity certificate and use only the current certificate version when multiple versions exist.

### EXAMPLE 3
```
Set-TrustMachineIdentity -MachineIdentity 3f4d8db9-6f83-4c9b-9a53-6f8e2a9d6d2b -Binding @{ 'port' = 8443 } -PassThru
```

Update one binding value and return the updated machine identity object.

### EXAMPLE 4
```
Set-TrustMachineIdentity -MachineIdentity 3f4d8db9-6f83-4c9b-9a53-6f8e2a9d6d2b -Keystore @{ 'alias' = 'new-alias' }
```

Update one keystore value while keeping other existing keystore values unchanged.

### EXAMPLE 5
```
Set-TrustMachineIdentity -MachineIdentity 3f4d8db9-6f83-4c9b-9a53-6f8e2a9d6d2b -Binding @{ 'port' = 8443 } -PassThru | Invoke-TrustCertificateAction -Provision
```

Update one binding value and provision the certificate with the new binding details in one pipeline.

## PARAMETERS

### -MachineIdentity
Machine identity ID

```yaml
Type: String
Parameter Sets: (All)
Aliases: machineIdentityId

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Certificate
Set the certificate associated with the machine identity.
You can provide the certificate name or ID.
If multiple certificates are found with the same name, an error will be thrown unless you use -Force to specify you want to use the current version of the certificate.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Binding
Binding details to update.
Provide a hashtable with the same structure as the binding object returned by Get-TrustMachineIdentity.
You can provide a partial hashtable with only the values to change.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Keystore
Keystore details to update.
Provide a hashtable with the same structure as the keystore object returned by Get-TrustMachineIdentity.
You can provide a partial hashtable with only the values to change.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
When used with -Certificate, resolve the certificate using only the current version.

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

### -PassThru
Return the updated machine identity object

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
Position: 5
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

### Machine
## OUTPUTS

## NOTES

## RELATED LINKS
