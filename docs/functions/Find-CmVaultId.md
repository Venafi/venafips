# Find-CmVaultId

## SYNOPSIS
Find vault IDs in the secret store

## SYNTAX

```
Find-CmVaultId [-Path] <String> [[-TrustClient] <TrustClient>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Find vault IDs in the secret store associated to an existing object.

## EXAMPLES

### EXAMPLE 1
```
Find-CmVaultId -Path '\ved\policy\awesomeobject.cyberark.com'
```

Find the vault IDs associated with an object.
For certificates with historical references, the vault IDs will

## PARAMETERS

### -Path
Path of the object

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
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

### String
## NOTES

## RELATED LINKS

[https://venafi.github.io/VenafiPS/functions/Find-CmVaultId/](https://venafi.github.io/VenafiPS/functions/Find-CmVaultId/)

[https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Find-CmVaultId.ps1](https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Find-CmVaultId.ps1)

