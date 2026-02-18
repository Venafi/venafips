# Invoke-VenafiRestMethod

## SYNOPSIS
Ability to execute REST API calls which don't exist in a dedicated function yet

## SYNTAX

### Session (Default)
```
Invoke-VenafiRestMethod [-VenafiSession <PSObject>] [-Method <String>] [-UriRoot <String>] [-UriLeaf <String>]
 [-VcRegion <String>] [-Platform <String>] [-Header <Hashtable>] [-Body <Hashtable>] [-FullResponse]
 [-TimeoutSec <Int32>] [-SkipCertificateCheck] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### URL
```
Invoke-VenafiRestMethod -Server <String> [-UseDefaultCredential] [-Certificate <X509Certificate>]
 [-Method <String>] [-UriRoot <String>] [-UriLeaf <String>] [-VcRegion <String>] [-Platform <String>]
 [-Header <Hashtable>] [-Body <Hashtable>] [-FullResponse] [-TimeoutSec <Int32>] [-SkipCertificateCheck]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Ability to execute REST API calls which don't exist in a dedicated function yet

## EXAMPLES

### EXAMPLE 1
```
Invoke-VenafiRestMethod -Method Delete -UriLeaf 'Discovery/{1345311e-83c5-4945-9b4b-1da0a17c45c6}'
Api call
```

### EXAMPLE 2
```
Invoke-VenafiRestMethod -Method Post -UriLeaf 'Certificates/Revoke' -Body @{'CertificateDN'='\ved\policy\mycert.com'}
Api call with optional payload
```

## PARAMETERS

### -VenafiSession
VenafiSession object from New-VenafiSession.
For typical calls to New-VenafiSession, the object will be stored as a session object named $VenafiSession.
Otherwise, if -PassThru was used, provide the resulting object.

```yaml
Type: PSObject
Parameter Sets: Session
Aliases: Key, AccessToken

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Server
Server or url to access vedsdk, venafi.company.com or https://venafi.company.com.

```yaml
Type: String
Parameter Sets: URL
Aliases: ServerUrl

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseDefaultCredential
Use Windows Integrated authentication

```yaml
Type: SwitchParameter
Parameter Sets: URL
Aliases: UseDefaultCredentials

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Certificate
Certificate for Certificate Manager, Self-Hosted token-based authentication

```yaml
Type: X509Certificate
Parameter Sets: URL
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Method
API method, either get, post, patch, put or delete.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Get
Accept pipeline input: False
Accept wildcard characters: False
```

### -UriRoot
Path between the server and endpoint.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Vedsdk
Accept pipeline input: False
Accept wildcard characters: False
```

### -UriLeaf
Path to the api endpoint excluding the base url and site, eg.
certificates/import

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -VcRegion
Certificate Manager, SaaS region to target. 
Only supported if VenafiSession is an api key otherwise the comes from VenafiSession directly.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Us
Accept pipeline input: False
Accept wildcard characters: False
```

### -Platform
Venafi Platform to target, either VC or VDC.
If not provided, the platform will be determined based on the VenafiSession or the calling function name.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Header
Optional additional headers. 
The authorization header will be included automatically.

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

### -Body
Optional body to pass to the endpoint

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

### -FullResponse
Provide the full response including headers as opposed to just the response content

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

### -TimeoutSec
Connection timeout. 
Default to 0, no timeout.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -SkipCertificateCheck
Skip certificate checking, eg.
self signed certificate on server

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

### None
## OUTPUTS

### PSCustomObject
## NOTES

## RELATED LINKS
