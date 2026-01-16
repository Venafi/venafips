# Find-VcCertificate

## SYNOPSIS
Find certificates in TLSPC

## SYNTAX

### SimpleFilter (Default)
```
Find-VcCertificate [-Name <String>] [-KeyLength <Int32>] [-Serial <String>] [-Fingerprint <String>]
 [-IsSelfSigned] [-IsExpired] [-Status <String[]>] [-ExpireBefore <DateTime>] [-ExpireAfter <DateTime>]
 [-VersionType <String>] [-SanDns <String>] [-Application <String[]>] [-Tag <String[]>] [-CN <String>]
 [-Issuer <String>] [-IncludeAny] [-Order <PSObject[]>] [-ApplicationDetail] [-OwnerDetail] [-First <Int32>]
 [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### AdvancedFilter
```
Find-VcCertificate -Filter <System.Collections.Generic.List`1[System.Object]> [-Order <PSObject[]>]
 [-ApplicationDetail] [-OwnerDetail] [-First <Int32>] [-VenafiSession <PSObject>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### SavedSearch
```
Find-VcCertificate [-Order <PSObject[]>] -SavedSearchName <String> [-ApplicationDetail] [-OwnerDetail]
 [-First <Int32>] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Find certificates based on various attributes.

## EXAMPLES

### EXAMPLE 1
```
Find-VcCertificate
```

Find all certificates

### EXAMPLE 2
```
Find-VcCertificate -First 500
```

Find the first 500 certificates

### EXAMPLE 3
```
Find-VcCertificate -Name 'mycert.company.com'
```

Find certificates matching all of part of the name

### EXAMPLE 4
```
Find-VcCertificate -Fingerprint '075C43428E70BCF941039F54B8ED78DE4FACA87F'
```

Find certificates matching a single value

### EXAMPLE 5
```
Find-VcCertificate -ExpireAfter (get-date) -ExpireBefore (get-date).AddDays(30)
```

Find certificates matching multiple values. 
In this case, find all certificates expiring in the next 30 days.

### EXAMPLE 6
```
Find-VcCertificate -ExpireAfter (get-date) -ExpireBefore (get-date).AddDays(30)| Invoke-VcCertificateAction -Renew
```

Find all certificates expiring in the next 30 days and renew them

### EXAMPLE 7
```
Find-VcCertificate -Filter @('subjectDN', 'FIND', 'www.barron.com')
```

Find via a filter instead of using built-in function properties

### EXAMPLE 8
```
Find-VcCertificate -ApplicatonDetail
```

Include application details, not just the ID.
This will make additional api calls and will increase the response time.

### EXAMPLE 9
```
Find-VcCertificate -OwnerDetail
```

Include user/team owner details, not just the ID.
This will make additional api calls and will increase the response time.

## PARAMETERS

### -Name
Search for certificates with the name matching part or all of the value

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

### -KeyLength
Search by certificate key length

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

### -Serial
Search by serial number

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

### -Fingerprint
Search by fingerprint

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

### -IsSelfSigned
Search for only self signed certificates

```yaml
Type: SwitchParameter
Parameter Sets: SimpleFilter
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -IsExpired
Search for only expired certificates.
This will search for only certificates that are expired including active, retired, current, old, etc.
Use -IsExpired:$false for certificates that are NOT expired.

```yaml
Type: SwitchParameter
Parameter Sets: SimpleFilter
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Status
Search by one or more certificate statuses. 
Valid values include ACTIVE, RETIRED, and DELETED.

```yaml
Type: String[]
Parameter Sets: SimpleFilter
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExpireBefore
Search for certificates expiring before a certain date.
Use with -ExpireAfter for a defined start and end.

```yaml
Type: DateTime
Parameter Sets: SimpleFilter
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExpireAfter
Search for certificates expiring after a certain date.
Use with -ExpireBefore for a defined start and end.

```yaml
Type: DateTime
Parameter Sets: SimpleFilter
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -VersionType
Search by version type. 
Valid values include CURRENT and OLD.

```yaml
Type: String
Parameter Sets: SimpleFilter
Aliases: Version

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SanDns
Search for certificates with SAN DNS matching part or all of the value

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

### -Application
Application ID or name that this certificate is associated with.
Use Tab Completion to see available applications.

```yaml
Type: String[]
Parameter Sets: SimpleFilter
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Tag
One or more tags associated with the certificate.
You can specify either just a tag name or name:value.

```yaml
Type: String[]
Parameter Sets: SimpleFilter
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CN
Search for certificates where the subject CN matches all of part of the value

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

### -Issuer
Search by issuer name

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

### -IncludeAny
When using multiple filter parameters, combine them with OR logic instead of AND logic

```yaml
Type: SwitchParameter
Parameter Sets: SimpleFilter
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Filter
Array or multidimensional array of fields and values to filter on.
Each array should be of the format @(field, comparison operator, value).
To combine filters, use the format @('operator', @(field, comparison operator, value), @(field2, comparison operator2, value2)).
Nested filters are supported.
Field names and values are case sensitive, but VenafiPS will try and convert to the proper case if able.

Available operators are:

Operator    |	Name                    |	Description and Usage
-----------------------------------------------------------------------------------
EQ              Equal operator              The search result is equal to the specified value.
Valid for numeric or Boolean fields.
FIND            Find operator               The search result is based on the value of all or part of one or more strings.
You can also use Regular Expressions (regex).
GT              Greater than                The search result has a higher numeric value than the specified value.
GTE             Greater than or equal to    The search result is equal or has a higher numeric value than the specified value.
IN              In clause                   The search result matches one of the values in an array.
LT              Less Than                   The search result has a lower value than the specified value.
LTE             Less than or equal to       The search result is equal or less than the specified value.
MATCH           Match operator              The search result includes a string value from the supplied list.
You can also use regex for your search.

For more info comparison operators, see https://docs.venafi.cloud/api/about-api-search-operators/.

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
1 or more fields to order on.
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

### -SavedSearchName
Find certificates based on a saved search, see https://docs.venafi.cloud/vaas/certificates/saving-certificate-filters

```yaml
Type: String
Parameter Sets: SavedSearch
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ApplicationDetail
Retrieve detailed application info.
This will cause additional api calls to be made and take longer.

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

### -OwnerDetail
Retrieve detailed user/team owner info.
This will cause additional api calls to be made and take longer.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: IncludeVaasOwner

Required: False
Position: Named
Default value: False
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

### -VenafiSession
Authentication for the function.
The value defaults to the script session object $VenafiSession created by New-VenafiSession.
A TLSPC key can also provided.

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
