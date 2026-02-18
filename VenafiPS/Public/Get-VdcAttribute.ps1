function Get-VdcAttribute {
    <#
    .SYNOPSIS
    Get object attributes as well as policy attributes

    .DESCRIPTION
    Retrieves object attributes as well as policy attributes.
    You can either retrieve all attributes or individual ones.
    Policy folders can have attributes as well as policies which apply to the resultant objects.
    For more info on policies and how they are different than attributes, see https://docs.venafi.com/Docs/current/TopNav/Content/Policies/c_policies_tpp.php.

    Attribute properties are directly added to the return object for ease of access.
    To retrieve attribute configuration, see the Attribute property of the return object which has properties
    Name, PolicyPath, Locked, Value, Overridden (when applicable), and CustomFieldGuid (when applicable).

    .PARAMETER Path
    Path to the object.  If the root is excluded, \ved\policy will be prepended.
    If retrieving policy attributes with -Class, this value must be a path to a Policy.

    .PARAMETER Attribute
    Only retrieve the value/values for these attribute(s).
    For custom fields, you can provide either the Guid or Label.

    .PARAMETER All
    Get all object attributes or policy attributes.
    This will perform 3 steps, get the object type, enumerate the attributes for the object type, and get all the values.
    Note, expect this to take longer than usual given the number of api calls.
    It is recommended to use this once to see what attributes are available, then use -Attribute to get specific ones in the future.

    .PARAMETER Class
    Get policy attributes instead of object attributes.
    Provide the class name to retrieve the value(s) for.
    The Attribute property of the return object will contain the path where the policy was applied.

    If unsure of the class name, add the value through the Certificate Manager, Self-Hosted UI and go to Support->Policy Attributes to find it.

    .PARAMETER AsValue
    Return only the value of the attribute requested.
    Only applicable when using -Attribute with a single attribute.

    .PARAMETER NoLookup
    Default functionality is to perform lookup of attributes names to see if they are custom fields or not.
    If they are, pass along the guid instead of the name, as required by the api for custom fields.
    To override this behavior and use the attribute name as is, add -NoLookup.
    Useful if, on the off chance, you have a custom field with the same name as a built-in attribute.
    Can also be used with -All and the output will contain guids instead of looked up names.

    .PARAMETER ThrottleLimit
    Limit the number of threads when running in parallel; the default is 100.
    Setting the value to 1 will disable multithreading.
    On PS v5 the ThreadJob module is required at module loading time.  If not found, multithreading will be disabled.

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A Certificate Manager, Self-Hosted token can be provided directly.
    If providing a Certificate Manager, Self-Hosted token, an environment variable named VDC_SERVER must also be set.

    .INPUTS
    Path

    .OUTPUTS
    PSCustomObject

    .EXAMPLE
    Get-VdcAttribute -Path '\VED\Policy\certificates\test.gdb.com' -Attribute 'State'

    Name      : test.gdb.com
    Path      : \VED\Policy\Certificates\test.gdb.com
    TypeName  : X509 Server Certificate
    Guid      : b7a7221b-e038-41d9-9d49-d7f45c1ca128
    Attribute : {@{Name=State; PolicyPath=\VED\Policy\Certificates; Locked=False; Value=UT; Overridden=False}}
    State     : UT

    Retrieve a single attribute

    .EXAMPLE
    Get-VdcAttribute -Path '\VED\Policy\certificates\test.gdb.com' -Attribute 'State', 'Driver Name'

    Name        : test.gdb.com
    Path        : \VED\Policy\Certificates\test.gdb.com
    TypeName    : X509 Server Certificate
    Guid        : b7a7221b-e038-41d9-9d49-d7f45c1ca128
    Attribute   : {@{Name=State; PolicyPath=\VED\Policy\Certificates; Locked=False; Value=UT; Overridden=False}, @{Name=Driver
                Name; PolicyPath=; Locked=False; Value=appx509certificate; Overridden=False}}
    State       : UT
    Driver Name : appx509certificate

    Retrieve multiple attributes

    .EXAMPLE
    Get-VdcAttribute -Path '\VED\Policy\certificates\test.gdb.com' -Attribute 'ServiceNow Assignment Group'

    Name                        : test.gdb.com
    Path                        : \VED\Policy\Certificates\test.gdb.com
    TypeName                    : X509 Server Certificate
    Guid                        : b7a7221b-e038-41d9-9d49-d7f45c1ca128
    Attribute                   : {@{CustomFieldGuid={7f214dec-9878-495f-a96c-57291f0d42da}; Name=ServiceNow Assignment Group;
                                PolicyPath=; Locked=False; Value=Venafi Management; Overridden=False}}
    ServiceNow Assignment Group : Venafi Management

    Retrieve a custom field attribute.
    You can specify either the guid or custom field label name.

    .EXAMPLE
    Get-VdcAttribute -Path '\VED\Policy\mydevice\myapp' -Attribute 'Certificate' -NoLookup

    Name                        : myapp
    Path                        : \VED\Policy\mydevice\myapp
    TypeName                    : Adaptable App
    Guid                        : b7a7221b-e038-41d9-9d49-d7f45c1ca128
    Attribute                   : {@{Name=Certificate; PolicyPath=; Value=\VED\Policy\mycert; Locked=False; Overridden=False}}
    Certificate                 : \VED\Policy\mycert

    Retrieve an attribute value without custom value lookup

    .EXAMPLE
    Get-VdcAttribute -Path '\VED\Policy\certificates\test.gdb.com' -All

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

    .EXAMPLE
    Get-VdcAttribute -Path 'Certificates' -Class 'X509 Certificate' -Attribute 'State'

    Name      : Certificates
    Path      : \VED\Policy\Certificates
    TypeName  : Policy
    Guid      : a91fc152-a9fb-4b49-a7ca-7014b14d73eb
    Attribute : {@{Name=State; PolicyPath=\VED\Policy\Certificates; Locked=False; Value=UT}}
    ClassName : X509 Certificate
    State     : UT

    Retrieve a policy attribute value for the specified policy folder and class.
    \ved\policy will be prepended to the path.

    .EXAMPLE
    Get-VdcAttribute -Path '\VED\Policy\certificates' -Class 'X509 Certificate' -All

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

    .EXAMPLE
    Find-VdcCertificate | Get-VdcAttribute -Attribute Contact,'Managed By','Want Renewal' -ThrottleLimit 50

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

    Retrieve specific attributes for all certificates.  Throttle the number of threads to 50, the default is 100

    .EXAMPLE
    Get-VdcAttribute -Path 'certs' -Attribute 'Contact' -AsValue

    Retrieve just the value associated with an attribute as opposed to the entire object

    .LINK
    https://docs.venafi.com/Docs/currentSDK/TopNav/Content/SDK/WebSDK/r-SDK-POST-Config-findpolicy.php

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Config-readeffectivepolicy.php

    #>
    [CmdletBinding(DefaultParameterSetName = 'Attribute')]

    param (

        [Parameter(Mandatory, ParameterSetName = 'Attribute', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Parameter(Mandatory, ParameterSetName = 'All', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('DN')]
        [String] $Path,

        [Parameter(Mandatory, ParameterSetName = 'Attribute')]
        [ValidateNotNullOrEmpty()]
        [String[]] $Attribute,

        [Parameter(Mandatory, ParameterSetName = 'All')]
        [switch] $All,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Alias('ClassName', 'PolicyClass')]
        [string] $Class,

        [Parameter(ParameterSetName = 'Attribute')]
        [switch] $AsValue,

        [Parameter()]
        [switch] $NoLookup,

        [Parameter()]
        [int32] $ThrottleLimit = 100,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession = (Get-VenafiSession)
    )

    begin {

        $allItems = [System.Collections.Generic.List[hashtable]]::new()
        $classAttributes = @{}

        if ( $Class -and $All ) {
            Write-Verbose ('getting attributes for {0}' -f $Class)
            $classAttributes.$Class = Get-VdcClassAttribute -ClassName $Class -VenafiSession $VenafiSession | Select-Object -ExpandProperty Name -Unique
        }
    }

    process {

        $attrib = if ( $All ) {
            if ( $Class ) {
                # policy attributes, already retrieved in begin block
                $classAttributes.$Class
            }
            else {

                # object attributes, get attributes for this specific type

                $thisObject = Get-VdcObject -Path $Path -VenafiSession $VenafiSession

                $thisType = $thisObject.TypeName

                if ( -not $classAttributes.$thisType ) {
                    Write-Verbose ('getting attributes for {0}' -f $thisType)
                    $classAttributes.$thisType = Get-VdcClassAttribute -ClassName $thisObject.TypeName -VenafiSession $VenafiSession | Select-Object -ExpandProperty Name -Unique
                }

                $classAttributes.$thisType
            }
        }
        else {
            $Attribute
        }

        $allItems.AddRange(
            [hashtable[]](
                $attrib | ForEach-Object {
                    @{
                        Path      = $Path
                        Attribute = $_
                    }
                }
            )
        )
    }

    end {

        # each item in $allItems with have 1 path and 1 attribute
        # $attribValues = $allItems | foreach {
        $parallelParams = @{
            InputObject   = $allItems
            ThrottleLimit = $ThrottleLimit
            ProgressTitle = 'Getting attributes'
            VenafiSession = $VenafiSession
            ScriptBlock   = {
                $Class = $using:Class
                $NoLookup = $using:NoLookup

                $attribute = $PSItem.Attribute

                $params = @{
                    Method        = 'Post'
                    Body          = @{
                        ObjectDN      = $PSItem.Path
                        AttributeName = $attribute
                    }
                    UriLeaf       = 'config/ReadEffectivePolicy'
                    VenafiSession = $using:VenafiSession
                }
                if ( $Class ) {
                    $params.Body.Class = $Class
                    $params.UriLeaf = 'config/FindPolicy'
                }

                $customField = $null

                if ( -not $NoLookup ) {

                    # parallel lookup
                    $customField = ($using:VenafiSession).CustomField | Where-Object { $_.Label -eq $attribute -or $_.Guid -eq $attribute }

                    if ( $customField ) {
                        $params.Body.AttributeName = $customField.Guid
                    }
                }

                # disabled is a special kind of attribute which cannot be read with readeffectivepolicy
                if ( $params.Body.AttributeName -eq 'Disabled' ) {
                    $oldUri = $params.UriLeaf
                    $params.UriLeaf = 'Config/Read'
                    $response = Invoke-VenafiRestMethod @params
                    $params.UriLeaf = $oldUri
                }
                else {
                    $response = Invoke-VenafiRestMethod @params
                }

                if ( $response.Error ) {
                    if ( $response.Result -in 601, 112) {
                        Write-Error "'$attribute' is not a valid attribute for $($PSItem.Path).  Are you looking for a policy attribute?  If so, add -Class."
                        continue
                    }
                    elseif ( $response.Result -eq 102) {
                        # attribute is valid, but value not set
                        # we're ok with this one
                    }
                    else {
                        Write-Error $response.Error
                        continue
                    }
                }

                $valueOut = if ( $response.Values ) {
                    switch ($response.Values.GetType().Name) {
                        'Object[]' {
                            switch ($response.Values.Count) {
                                1 {
                                    $response.Values[0]
                                }

                                Default {
                                    $response.Values
                                }
                            }
                        }
                        Default {
                            $response.Values
                        }
                    }
                }
                else {
                    $null
                }

                $return = @{
                    Path       = $PSItem.Path
                    Name       = $attribute
                    Value      = $valueOut
                    PolicyPath = $response.PolicyDN
                    Locked     = $response.Locked
                }

                if ( $CustomField ) {
                    $return.Name = $customField.Label
                    $return.CustomFieldGuid = $customField.Guid
                }

                # overridden not available at policy level
                if ( -not $Class ) {
                    $return.Overridden = $response.Overridden
                }

                [PSCustomObject]$return
            }
        }

        $attribValues = Invoke-VenafiParallel @parallelParams

        # caller just wants this one value
        if ( $AsValue -and $attribValues.count -eq 1 ) {
            return $attribValues[0].Value
        }

        $attribValues | Group-Object -Property Path | ForEach-Object {
            $result = @{
                Path      = $_.Name
                Attribute = $_.Group | Select-Object -Property * -ExcludeProperty Path
            }

            if ( $Class ) {
                $result.ClassName = $Class
            }

            # Add each attribute as a direct property
            foreach ($attr in $_.Group) {
                if ($attr.Value -and $attr.Name) {
                    $result[$attr.Name] = $attr.Value
                }
            }

            [PSCustomObject]$result
        }
    }
}
