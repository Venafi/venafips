# Get-VdcCertificate

## SYNOPSIS
Get certificate information

## SYNTAX

### Id (Default)
```
Get-VdcCertificate [-ID] <String> [-ThrottleLimit <Int32>] [-VenafiSession <PSObject>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### IdWithPrevious
```
Get-VdcCertificate [-ID] <String> [-IncludePreviousVersions] [-ExcludeExpired] [-ExcludeRevoked]
 [-ThrottleLimit <Int32>] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### AllWithPrevious
```
Get-VdcCertificate [-All] [-IncludePreviousVersions] [-ExcludeExpired] [-ExcludeRevoked]
 [-ThrottleLimit <Int32>] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### All
```
Get-VdcCertificate [-All] [-ThrottleLimit <Int32>] [-VenafiSession <PSObject>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Get certificate information, either all available to the api key provided or by id or zone.

## EXAMPLES

### EXAMPLE 1
```
Get-VdcCertificate -ID '\ved\policy\mycert.com'
```

Get certificate info for a specific cert

### EXAMPLE 2
```
Get-VdcCertificate -All
```

Get certificate info for all certs

### EXAMPLE 3
```
Get-VdcCertificate -ID '\ved\policy\mycert.com' -IncludePreviousVersions
```

Get certificate info for a specific cert, including historical versions of the certificate.

### EXAMPLE 4
```
Get-VdcCertificate -ID '\ved\policy\mycert.com' -IncludeTppPreviousVersions -ExcludeRevoked -ExcludeExpired
```

Get certificate info for a specific cert, including historical versions of the certificate that are not revoked or expired.

## PARAMETERS

### -ID
Certificate identifier by either path or guid.
\ved\policy will be automatically applied if a full path isn't provided.

```yaml
Type: String
Parameter Sets: Id, IdWithPrevious
Aliases: Guid, Path

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -All
Retrieve all certificates

```yaml
Type: SwitchParameter
Parameter Sets: AllWithPrevious, All
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludePreviousVersions
Returns details about previous (historical) versions of a certificate.
This option will add a property named PreviousVersions to the returned object.

```yaml
Type: SwitchParameter
Parameter Sets: IdWithPrevious, AllWithPrevious
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExcludeExpired
Omits expired versions of the previous (historical) versions of a certificate.
Can only be used with the IncludePreviousVersions parameter.

```yaml
Type: SwitchParameter
Parameter Sets: IdWithPrevious, AllWithPrevious
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExcludeRevoked
Omits revoked versions of the previous (historical) versions of a certificate.
Can only be used with the IncludePreviousVersions parameter.

```yaml
Type: SwitchParameter
Parameter Sets: IdWithPrevious, AllWithPrevious
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

### ID
## OUTPUTS

### PSCustomObject
## NOTES

## RELATED LINKS

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-GET-Certificates-guid.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-GET-Certificates-guid.php)

