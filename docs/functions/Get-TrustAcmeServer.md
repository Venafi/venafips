# Get-TrustAcmeServer

## SYNOPSIS
Get ACME server info

## SYNTAX

### ID (Default)
```
Get-TrustAcmeServer [-AcmeServer] <String> [-Deactivated <Boolean>] [-TrustClient <TrustClient>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### All
```
Get-TrustAcmeServer [-All] [-Deactivated <Boolean>] [-TrustClient <TrustClient>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Get 1 or more ACMEv2 servers, which ACME clients connect to for certificates.
These are the servers in Configurations \> ACME Servers, not certificate authorities of type ACME, see Get-TrustCertificateAuthority for those.
Supported on Certificate Manager SaaS and NGTS.

## EXAMPLES

### EXAMPLE 1
```
Get-TrustAcmeServer -AcmeServer 'My ACME server'
```

acmeServerId            : ca7ff555-88d2-4bfc-9efa-2630ac44c1f2
name                    : My ACME server
deactivated             : False
directoryUrl            : https://api.venafi.cloud/v1/acme/ca7ff555-88d2-4bfc-9efa-2630ac44c1f2/directory
application             : @{id=ca7ff555-88d2-4bfc-9efa-2630ac44c1f2; name=My app}
issuingTemplate         : @{id=ca7ff555-88d2-4bfc-9efa-2630ac44c1f2; name=My template}
certificateTags         : {}
totalAccounts           : 4
totalOrders             : 20
totalCertificatesIssued : 0
createdOn               : 10/20/2026 1:02:03 PM
lastModifiedOn          : 10/20/2026 1:02:03 PM
workspaceId             :
eabKID                  : 1a2b3c

Get a single ACME server by name

### EXAMPLE 2
```
Get-TrustAcmeServer -All
```

Get all ACME servers

### EXAMPLE 3
```
Get-TrustAcmeServer -All -Deactivated $true
```

Get all deactivated ACME servers

## PARAMETERS

### -AcmeServer
ACME server ID or name. 
The name is not case sensitive.

```yaml
Type: String
Parameter Sets: ID
Aliases: acmeServerId

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -All
Get all ACME servers

```yaml
Type: SwitchParameter
Parameter Sets: All
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Deactivated
Only get servers which are deactivated, $true, or active, $false.
Both are returned if not provided.

```yaml
Type: Boolean
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

### AcmeServer
## OUTPUTS

## NOTES

## RELATED LINKS

[https://venafi.github.io/VenafiPS/functions/Get-TrustAcmeServer/](https://venafi.github.io/VenafiPS/functions/Get-TrustAcmeServer/)

[https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Get-TrustAcmeServer.ps1](https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Get-TrustAcmeServer.ps1)

