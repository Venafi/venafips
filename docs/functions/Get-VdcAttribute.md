# Get-VdcAttribute

## SYNOPSIS
Get object attributes as well as policy attributes

## SYNTAX

### Attribute (Default)
```
Get-VdcAttribute -Path <String> -Attribute <String[]> [-Class <String>] [-AsValue] [-NoLookup]
 [-ThrottleLimit <Int32>] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### All
```
Get-VdcAttribute -Path <String> [-All] [-Class <String>] [-NoLookup] [-ThrottleLimit <Int32>]
 [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Retrieves object attributes as well as policy attributes.
You can either retrieve all attributes or individual ones.
Policy folders can have attributes as well as policies which apply to the resultant objects.
For more info on policies and how they are different than attributes, see https://docs.venafi.com/Docs/current/TopNav/Content/Policies/c_policies_tpp.php.

Attribute properties are directly added to the return object for ease of access.
To retrieve attribute configuration, see the Attribute property of the return object which has properties
Name, PolicyPath, Locked, Value, Overridden (when applicable), and CustomFieldGuid (when applicable).

## EXAMPLES

### EXAMPLE 1
```
Get-VdcAttribute -Path '\VED\Policy\certificates\test.gdb.com' -Attribute 'State'
```

Name      : test.gdb.com
Path      : \VED\Policy\Certificates\test.gdb.com
TypeName  : X509 Server Certificate
Guid      : b7a7221b-e038-41d9-9d49-d7f45c1ca128
Attribute : {@{Name=State; PolicyPath=\VED\Policy\Certificates; Locked=False; Value=UT; Overridden=False}}
State     : UT

Retrieve a single attribute

### EXAMPLE 2
```
Get-VdcAttribute -Path '\VED\Policy\certificates\test.gdb.com' -Attribute 'State', 'Driver Name'
```

Name        : test.gdb.com
Path        : \VED\Policy\Certificates\test.gdb.com
TypeName    : X509 Server Certificate
Guid        : b7a7221b-e038-41d9-9d49-d7f45c1ca128
Attribute   : {@{Name=State; PolicyPath=\VED\Policy\Certificates; Locked=False; Value=UT; Overridden=False}, @{Name=Driver
            Name; PolicyPath=; Locked=False; Value=appx509certificate; Overridden=False}}
State       : UT
Driver Name : appx509certificate

Retrieve multiple attributes

### EXAMPLE 3
```
Get-VdcAttribute -Path '\VED\Policy\certificates\test.gdb.com' -Attribute 'ServiceNow Assignment Group'
```

Name                        : test.gdb.com
Path                        : \VED\Policy\Certificates\test.gdb.com
TypeName                    : X509 Server Certificate
Guid                        : b7a7221b-e038-41d9-9d49-d7f45c1ca128
Attribute                   : {@{CustomFieldGuid={7f214dec-9878-495f-a96c-57291f0d42da}; Name=ServiceNow Assignment Group;
                            PolicyPath=; Locked=False; Value=Venafi Management; Overridden=False}}
ServiceNow Assignment Group : Venafi Management

Retrieve a custom field attribute.
You can specify either the guid or custom field label name.

### EXAMPLE 4
```
Get-VdcAttribute -Path '\VED\Policy\mydevice\myapp' -Attribute 'Certificate' -NoLookup
```

Name                        : myapp
Path                        : \VED\Policy\mydevice\myapp
TypeName                    : Adaptable App
Guid                        : b7a7221b-e038-41d9-9d49-d7f45c1ca128
Attribute                   : {@{Name=Certificate; PolicyPath=; Value=\VED\Policy\mycert; Locked=False; Overridden=False}}
Certificate                 : \VED\Policy\mycert

Retrieve an attribute value without custom value lookup

### EXAMPLE 5
```
Get-VdcAttribute -Path '\VED\Policy\certificates\test.gdb.com' -All
```

Name                                  : test.gdb.com
Path                                  : \VED\Policy\Certificates\test.gdb.com
TypeName                              : X509 Server Certificate
Guid                                  : b7a7221b-e038-41d9-9d49-d7f45c1ca128
Attribute                             : {@{CustomFieldGuid={7f214dec-9878-495f-a96c-57291f0d42da}; Name=ServiceNow
                                        Assignment Group; PolicyPath=; Locked=False; Value=Venafi Management;
                                        Overridden=False}…}
ServiceNow Assignment Group           : Venafi Management
City                                  : Salt Lake City
Consumers                             : {\VED\Policy\Installations\Agentless\US Zone\mydevice\myapp}
Contact                               : local:{b1c77034-c099-4a5c-9911-9e26007817da}
Country                               : US
Created By                            : WebAdmin
Driver Name                           : appx509certificate
...

Retrieve all attributes applicable to this object

### EXAMPLE 6
```
Get-VdcAttribute -Path 'Certificates' -Class 'X509 Certificate' -Attribute 'State'
```

Name      : Certificates
Path      : \VED\Policy\Certificates
TypeName  : Policy
Guid      : a91fc152-a9fb-4b49-a7ca-7014b14d73eb
Attribute : {@{Name=State; PolicyPath=\VED\Policy\Certificates; Locked=False; Value=UT}}
ClassName : X509 Certificate
State     : UT

Retrieve a policy attribute value for the specified policy folder and class.
\ved\policy will be prepended to the path.

### EXAMPLE 7
```
Get-VdcAttribute -Path '\VED\Policy\certificates' -Class 'X509 Certificate' -All
```

Name                                  : Certificates
Path                                  : \VED\Policy\Certificates
TypeName                              : Policy
Guid                                  : a91fc152-a9fb-4b49-a7ca-7014b14d73eb
Attribute                             : {@{CustomFieldGuid={7f214dec-9878-495f-a96c-57291f0d42da}; Name=ServiceNow
                                        Assignment Group; PolicyPath=; Locked=False; Value=}…}
ClassName                             : X509 Certificate
Approver                              : local:{b1c77034-c099-4a5c-9911-9e26007817da}
Key Algorithm                         : RSA
Key Bit Strength                      : 2048
Managed By                            : Aperture
Management Type                       : Enrollment
Network Validation Disabled           : 1
Notification Disabled                 : 0
...

Retrieve all policy attributes for the specified policy folder and class

### EXAMPLE 8
```
Find-VdcCertificate | Get-VdcAttribute -Attribute Contact,'Managed By','Want Renewal' -ThrottleLimit 50
```

Name         : mycert
Path         : \VED\Policy\mycert
TypeName     : X509 Server Certificate
Guid         : 1dc31664-a9f3-407c-8bf3-1e388e90a114
Attribute    : {@{Name=Contact; PolicyPath=\VED\Policy; Value=local:{ab2a2e32-b412-4466-b5b5-484478a99bf4}; Locked=False; Overridden=False}, @{Name=Managed By; PolicyPath=\VED\Policy;
            Value=Aperture; Locked=True; Overridden=False}, @{Name=Want Renewal; PolicyPath=\VED\Policy; Value=0; Locked=True; Overridden=False}}
Contact      : local:{ab2a2e32-b412-4466-b5b5-484478a99bf4}
Managed By   : Aperture
Want Renewal : 0
...

Retrieve specific attributes for all certificates. 
Throttle the number of threads to 50, the default is 100

### EXAMPLE 9
```
Get-VdcAttribute -Path 'certs' -Attribute 'Contact' -AsValue
```

Retrieve just the value associated with an attribute as opposed to the entire object

## PARAMETERS

### -Path
Path to the object. 
If the root is excluded, \ved\policy will be prepended.
If retrieving policy attributes with -Class, this value must be a path to a Policy.

```yaml
Type: String
Parameter Sets: (All)
Aliases: DN

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Attribute
Only retrieve the value/values for these attribute(s).
For custom fields, you can provide either the Guid or Label.

```yaml
Type: String[]
Parameter Sets: Attribute
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -All
Get all object attributes or policy attributes.
This will perform 3 steps, get the object type, enumerate the attributes for the object type, and get all the values.
Note, expect this to take longer than usual given the number of api calls.
It is recommended to use this once to see what attributes are available, then use -Attribute to get specific ones in the future.

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

### -Class
Get policy attributes instead of object attributes.
Provide the class name to retrieve the value(s) for.
The Attribute property of the return object will contain the path where the policy was applied.

If unsure of the class name, add the value through the TLSPDC UI and go to Support-\>Policy Attributes to find it.

```yaml
Type: String
Parameter Sets: (All)
Aliases: ClassName, PolicyClass

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AsValue
Return only the value of the attribute requested.
Only applicable when using -Attribute with a single attribute.

```yaml
Type: SwitchParameter
Parameter Sets: Attribute
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoLookup
Default functionality is to perform lookup of attributes names to see if they are custom fields or not.
If they are, pass along the guid instead of the name, as required by the api for custom fields.
To override this behavior and use the attribute name as is, add -NoLookup.
Useful if, on the off chance, you have a custom field with the same name as a built-in attribute.
Can also be used with -All and the output will contain guids instead of looked up names.

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

### -ThrottleLimit
Limit the number of threads when running in parallel; the default is 100.
Setting the value to 1 will disable multithreading.
On PS v5 the ThreadJob module is required at module loading time. 
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
A TLSPDC token can be provided directly.
If providing a TLSPDC token, an environment variable named VDC_SERVER must also be set.

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

### Path
## OUTPUTS

### PSCustomObject
## NOTES

## RELATED LINKS

[https://docs.venafi.com/Docs/currentSDK/TopNav/Content/SDK/WebSDK/r-SDK-POST-Config-findpolicy.php](https://docs.venafi.com/Docs/currentSDK/TopNav/Content/SDK/WebSDK/r-SDK-POST-Config-findpolicy.php)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Config-readeffectivepolicy.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Config-readeffectivepolicy.php)

