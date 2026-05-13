# Find-TrustCertificateInstance

## SYNOPSIS
Find certificate requests

## SYNTAX

### SimpleFilter (Default)
```
Find-TrustCertificateInstance [-HostName <String>] [-IpAddress <IPAddress>] [-Port <Int32>] [-Status <String>]
 [-Order <PSObject[]>] [-First <Int32>] [-TrustClient <TrustClient>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### AdvancedFilter
```
Find-TrustCertificateInstance -Filter <System.Collections.Generic.List`1[System.Object]> [-Order <PSObject[]>]
 [-First <Int32>] [-TrustClient <TrustClient>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Find certificate requests

## EXAMPLES

### EXAMPLE 1
```
Find-TrustCertificateInstance
```

Get all instancese

## PARAMETERS

### -HostName
Hostname to find via regex match

```yaml
Type: String
Parameter Sets: SimpleFilter
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IpAddress
Machine IP Address

```yaml
Type: IPAddress
Parameter Sets: SimpleFilter
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Port
Machine port

```yaml
Type: Int32
Parameter Sets: SimpleFilter
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Status
Instance status, either IN_USE or SUPERSEDED

```yaml
Type: String
Parameter Sets: SimpleFilter
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Filter
Array or multidimensional array of fields and values to filter on.
Each array should be of the format @('operator', @(field, comparison operator, value), @(field2, comparison operator2, value2)).
Nested filters are supported.
For a complete list of comparison operators, see https://docs.venafi.cloud/api/about-api-search-operators/.
To see which fields you can search on, execute Find-TrustCertificateInstance -First 1.

```yaml
Type: System.Collections.Generic.List`1[System.Object]
Parameter Sets: AdvancedFilter
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Order
Array of fields to order on.
For each item in the array, you can provide a field name by itself; this will default to ascending.
You can also provide a hashtable with the field name as the key and either asc or desc as the value.

```yaml
Type: PSObject[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -First
Only retrieve this many records

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

## OUTPUTS

## NOTES

## RELATED LINKS
