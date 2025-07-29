# Get-VdcCredential

## SYNOPSIS
Get credential details

## SYNTAX

```
Get-VdcCredential [-Path] <String> [-IncludeDetail] [[-VenafiSession] <PSObject>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Get credential details.
Object returned will depend on the credential type.

## EXAMPLES

### EXAMPLE 1
```
Get-VdcCredential -Path '\VED\Policy\MySecureCred'
Get a credential
```

## PARAMETERS

### -Path
The full path to the credential object

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -IncludeDetail
Include metadata associated with the credential in addition to the credential itself

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

### -VenafiSession
Authentication for the function.
The value defaults to the script session object $VenafiSession created by New-VenafiSession.

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
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

### Password/UsernamePassword Credential - PSCredential
### Certificate Credential - X509Certificate2
### with IncludeDetail - PSCustomObject
## NOTES

## RELATED LINKS

[https://venafi.github.io/VenafiPS/functions/Get-VdcCredential/](https://venafi.github.io/VenafiPS/functions/Get-VdcCredential/)

[https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Get-VdcCredential.ps1](https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Get-VdcCredential.ps1)

