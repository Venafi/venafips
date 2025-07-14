function Set-VdcAttribute {
    <#
    .SYNOPSIS
    Sets a value on an objects attribute or policies (policy attributes)

    .DESCRIPTION
    Set the value on an objects attribute.  The attribute can either be built-in or custom.
    You can also set policies (policy attributes).

    .PARAMETER Path
    Path to the object to modify

    .PARAMETER Attribute
    Hashtable with names and values to be set.
    If setting a custom field, you can use either the name or guid as the key.
    If using a custom field name, you must have created a session with New-VenafiSession and not just a TLSPDC token.
    To clear a value overwriting policy, set the value to $null.

    .PARAMETER Class
    Required when setting policy attributes.  Provide the class name to set the value for.
    If unsure of the class name, add the value through the TLSPDC UI and go to Support->Policy Attributes to find it.

    .PARAMETER Lock
    Lock the value on the policy.  Only applicable to setting policies.

    .PARAMETER BypassValidation
    Bypass data validation.  Only applicable to custom fields.

    .PARAMETER NoOverwrite
    Add to any existing value, if there is one, as opposed to overwriting.
    Unlike overwriting, adding can only be a single value, not an array.
    Not applicable to custom fields.

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.

    .INPUTS
    Path

    .OUTPUTS
    None

    .EXAMPLE
    Set-VdcAttribute -Path '\VED\Policy\My Folder\app.company.com' -Attribute @{'Consumers'='\VED\Policy\myappobject.company.com'}

    Set the value on an object

    .EXAMPLE
    Set-VdcAttribute -Path '\VED\Policy\My Folder\app.company.com' -Attribute @{'Management Type'=$null}

    Clear the value on an object, reverting to policy if applicable

    .EXAMPLE
    Set-VdcAttribute -Path '\VED\Policy\My Folder\app.company.com' -Attribute @{'My custom field Label'='new custom value'}

    Set the value on a custom field

    .EXAMPLE
    Set-VdcAttribute -Path '\VED\Policy\My Folder\app.company.com' -Attribute @{'My custom field Label'='new custom value'} -BypassValidation

    Set the value on a custom field bypassing field validation

    .EXAMPLE
    Set-VdcAttribute -Path '\VED\Policy\My Folder' -Class 'X509 Certificate' -Attribute @{'Notification Disabled'='0'}

    Set a policy attribute

    .EXAMPLE
    Set-VdcAttribute -Path '\VED\Policy\My Folder' -Class 'X509 Certificate' -Attribute @{'Notification Disabled'='0'} -Lock

    Set a policy attribute and lock the value

    .EXAMPLE
    Set-VdcAttribute -Path '\VED\Policy\app.company.com' -Attribute @{'X509 SubjectAltName IPAddress'='1.2.3.4'; 'X509 SubjectAltName DNS'='me.x.com'}

    Update SAN field(s).  The SAN key names are:
    - X509 SubjectAltName DNS
    - X509 SubjectAltName IPAddress
    - X509 SubjectAltName OtherName UPN
    - X509 SubjectAltName RFC822
    - X509 SubjectAltName URI

    .LINK
    https://venafi.github.io/VenafiPS/functions/Set-VdcAttribute/

    .LINK
    https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Set-VdcAttribute.ps1

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Metadata-Set.php

    .LINK
    https://docs.venafi.com/Docs/currentSDK/TopNav/Content/SDK/WebSDK/r-SDK-POST-Metadata-SetPolicy.php

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Config-addvalue.php

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Config-addpolicyvalue.php

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Config-write.php

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Config-writepolicy.php
    #>

    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'NotPolicy')]
    [Alias('Set-TppAttribute')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Being flagged incorrectly')]

    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                if ( $_ | Test-TppDnPath ) {
                    $true
                }
                else {
                    throw "'$_' is not a valid DN path"
                }
            })]
        [Alias('DN')]
        [String] $Path,

        [Parameter(Mandatory)]
        [hashtable] $Attribute,

        [Parameter(Mandatory, ParameterSetName = 'Policy')]
        [Alias('ClassName', 'PolicyClass')]
        [string] $Class,

        [Parameter(ParameterSetName = 'Policy')]
        [switch] $Lock,

        [Parameter()]
        [switch] $BypassValidation,

        [Parameter()]
        [switch] $NoOverwrite,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {
        $sess = Get-VenafiSession

        $params = @{
            Method = 'Post'
        }

        $baseFields = @()
        $customFields = @()

        $Attribute.GetEnumerator() | ForEach-Object {

            $thisKey = $_.Key

            if ($null -ne $_.Value) {
                if ( $_.Value.GetType().BaseType.Name -eq 'Array' ) {
                    $thisValue = @($_.Value)
                }
                else {
                    $thisValue = ($_.Value).ToString()
                }
            }
            else {
                # cannot add 'null', only overwrite to blank out the value
                $NoOverwrite = $false
                $thisValue = $_.Value
                $BypassValidation = $true
            }
            $customFieldError = $null

            $customField = $sess.CustomField | Where-Object { $_.Label -eq $thisKey -or $_.Guid -eq $thisKey }
            if ( $customField ) {
                Write-Verbose ('found custom field {0} - {1}' -f $customField.DN, $customField | ConvertTo-Json)
                if ( -not $BypassValidation ) {
                    switch ( $customField.Type.ToString() ) {
                        '1' {
                            # string
                            if ( $customField.RegularExpression -and $thisValue -notmatch $customField.RegularExpression ) {
                                $customFieldError = 'regular expression ''{0}'' validation failed' -f $customField.RegularExpression
                            }
                        }

                        '2' {
                            # list
                            if ( $thisValue -notin $customField.AllowedValues ) {
                                $customFieldError = 'value is not in the list of allowed values ''{0}''' -f $customField.AllowedValues
                            }
                        }

                        '5' {
                            # identity
                            if ( -not ($thisValue | Test-VdcIdentity -ExistOnly) ) {
                                $customFieldError = 'value is not a valid identity'
                            }
                        }

                        '4' {
                            # date/time
                            try {
                                [datetime] $thisValue
                            }
                            catch {
                                $customFieldError = 'value is not a valid date'
                            }
                        }

                        Default {
                            $customFieldError = 'unknown custom field type'
                        }
                    }
                }

                if ( $customFieldError ) {
                    Write-Error ('The value ''{0}'' for field ''{1}'' encountered an error, {2}' -f $thisValue, $thisKey, $customFieldError)
                }
                else {
                    $customFields += @{
                        ItemGuid = $customField.Guid
                        List     = if ($null -eq $thisValue) { , @() } else { , @($thisValue) }
                    }
                }
            }
            else {
                $baseFields += @{
                    Name  = $thisKey
                    Value = if ($null -eq $thisValue) { '' } else { $thisValue }
                    # Value = if ($null -eq $thisValue) { , @() } else { , @($thisValue) }
                }
            }
        }
    }

    process {

        if ( -not $PSCmdlet.ShouldProcess($Path) ) {
            continue
        }

        # built-in fields and custom fields have different APIs and payloads
        # as do attributes and policy attributes...

        if ( $baseFields.Count -gt 0 ) {

            if ( $PSBoundParameters.ContainsKey('Class') ) {
                # config/WritePolicy and AddPolicyValue only allows 1 key/value per call
                foreach ($field in $baseFields) {

                    $params.Body = @{
                        ObjectDN      = $Path
                        Class         = $Class
                        AttributeName = $field.Name
                        Locked        = [int]$Lock.ToBool()
                    }

                    if ( $NoOverwrite ) {
                        $params.UriLeaf = 'config/AddPolicyValue'
                        $params.Body.Value = $field.Value
                    }
                    else {
                        $params.UriLeaf = 'config/WritePolicy'
                        $params.Body.Values = @($field.Value)
                    }

                    $response = Invoke-VenafiRestMethod @params

                    if ( $response.Result -ne 1 ) {
                        Write-Error $response.Error
                    }
                }
            }
            else {

                if ( $NoOverwrite ) {

                    $params.UriLeaf = 'config/AddValue'
                    foreach ( $field in $baseFields ) {
                        $params.Body = @{
                            ObjectDN      = $Path
                            AttributeName = $field.Name
                            Value         = $field.Value
                        }

                        $response = Invoke-VenafiRestMethod @params

                        if ( $response.Result -ne 1 ) {
                            Write-Error $response.Error
                        }

                    }
                }
                else {
                    $params.UriLeaf = 'config/Write'
                    $params.Body = @{
                        ObjectDN      = $Path
                        AttributeData = @($baseFields)
                    }

                    $response = Invoke-VenafiRestMethod @params

                    if ( $response.Result -ne 1 ) {
                        Write-Error $response.Error
                    }
                }
            }
        }

        if ( $customFields.Count -gt 0 ) {

            if ( $PSBoundParameters.ContainsKey('Class') ) {
                $params.UriLeaf = 'Metadata/SetPolicy'
                $params.Body = @{
                    DN          = $Path
                    ConfigClass = $Class
                    GuidData    = $customFields
                    Locked      = [int]$Lock.ToBool()
                }
            }
            else {

                $params.UriLeaf = 'Metadata/Set'
                $params.Body = @{
                    DN           = $Path
                    GuidData     = $customFields
                    KeepExisting = $true
                }
            }

            $response = Invoke-VenafiRestMethod @params

            if ( $response.Result -ne [TppMetadataResult]::Success ) {
                Write-Error $response.Error
            }
        }
    }
}

