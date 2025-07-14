function Find-VdcObject {
    <#
    .SYNOPSIS
    Find objects by path, class, or pattern

    .DESCRIPTION
    Find objects by path, class, or pattern.

    .PARAMETER Path
    The path to start our search.  The default is \ved\policy.

    .PARAMETER Class
    1 or more classes/types to search for

    .PARAMETER Pattern
    By default, object filter to apply to Path.
    If the Attribute parameter is provided, this will filter against an object's attribute/custom field values instead of the path.

    Follow the below rules:
    - To list DNs that include an asterisk or question mark, prepend the character with two backslashes.
    - To list DNs with a wildcard character, append a question mark (?). For example, "test_?.mycompany.net" counts test_1.MyCompany.net and test_2.MyCompany.net but not test12.MyCompany.net.
    - To list DNs with similar names, prepend an asterisk. For example, *est.MyCompany.net, counts Test.MyCompany.net and West.MyCompany.net.
    You can also use both literals and wildcards in a pattern.

    .PARAMETER Attribute
    A list of attribute names to limit the search against.  Only valid when searching by pattern.
    A custom field name can also be provided.

    .PARAMETER Recursive
    Searches the subordinates of the object specified in Path.

    .PARAMETER NoLookup
    Default functionality when finding by Attribute is to perform a lookup to see if they are custom fields or not.
    If they are, pass along the guid instead of name required by the api for custom fields.
    To override this behavior and use the attribute name as is, add -NoLookup.
    Useful if on the off chance you have a custom field with the same name as a built-in attribute.

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.

    .INPUTS
    Path

    .OUTPUTS
    pscustomobject

    .EXAMPLE
    Find-VdcObject
    Get all objects recursively starting from \ved\policy

    .EXAMPLE
    Find-VdcObject -Path '\VED\Policy\certificates'

    Get all objects in the root of a specific folder

    .EXAMPLE
    Find-VdcObject -Path '\VED\Policy\My Folder' -Recursive

    Get all objects in a folder and subfolders

    .EXAMPLE
    Find-VdcObject -Path '\VED\Policy' -Pattern '*test*'

    Get items in a specific folder filtering the path

    .EXAMPLE
    Find-VdcObject -Class 'capi' -Path '\ved\policy\installations' -Recursive

    Get objects of a specific type

    .EXAMPLE
    Find-VdcObject -Class 'capi' -Pattern '*test*' -Path '\ved\policy\installations' -Recursive

    Get all objects of a specific type where the path is of a specific pattern

    .EXAMPLE
    Find-VdcObject -Class 'capi', 'iis6' -Pattern '*test*' -Path '\ved\policy\installations' -Recursive

    Get objects for multiple types

    .EXAMPLE
    Find-VdcObject -Pattern '*f5*'

    Find objects with the specific name.  All objects under \ved\policy (the default) will be searched.

    .EXAMPLE
    Find-VdcObject -Attribute 'Description' -Pattern 'awesome'

    Find objects where the specific attribute matches the pattern

    .EXAMPLE
    Find-VdcObject -Attribute 'Environment' -Pattern 'Development'

    Find objects where a custom field value matches the pattern.
    By default, the attribute will be checked against the current list of custom fields.

    .EXAMPLE
    Find-VdcObject -Attribute 'Description' -Pattern 'venafips' -Class 'X509 Server Certificate'

    Find objects of a specific type where the specific attribute matches the pattern

    .EXAMPLE
    Find-VdcObject -Attribute 'Description' -Pattern 'duplicate' -NoLookup

    Bypass custom field lookup and force Attribute to be treated as a built-in attribute.
    Useful if there are conflicting custom field and built-in attribute names and you want to force the lookup against built-in.

    .LINK
    https://venafi.github.io/VenafiPS/functions/Find-VdcObject/

    .LINK
    https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Find-VdcObject.ps1

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Config-find.php

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Config-findobjectsofclass.php

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Config-enumerate.php

    #>

    [CmdletBinding(DefaultParameterSetName = 'FindByPath')]
    [Alias('fto', 'Find-TppObject')]

    param (
        [Parameter(ParameterSetName = 'FindByPath', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'FindByClass', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'FindByPattern', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('DN')]
        [String] $Path = '\ved\policy',

        [Parameter(Mandatory, ParameterSetName = 'FindByPattern')]
        [Parameter(ParameterSetName = 'FindByClass')]
        [Parameter(Mandatory, ParameterSetName = 'FindByAttribute')]
        [ValidateNotNull()]
        [AllowEmptyString()]
        [String] $Pattern,

        [Parameter(Mandatory, ParameterSetName = 'FindByClass')]
        [Parameter(ParameterSetName = 'FindByAttribute')]
        [ValidateNotNullOrEmpty()]
        [Alias('TypeName')]
        [String[]] $Class,

        [Parameter(Mandatory, ParameterSetName = 'FindByAttribute')]
        [ValidateNotNullOrEmpty()]
        [Alias('AttributeName')]
        [String[]] $Attribute,

        [Parameter(ParameterSetName = 'FindByPath')]
        [Parameter(ParameterSetName = 'FindByClass')]
        [Parameter(ParameterSetName = 'FindByPattern')]
        [Alias('r')]
        [switch] $Recursive,

        [Parameter(ParameterSetName = 'FindByAttribute')]
        [switch] $NoLookup,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {
        # needed for access to the custom fields
        $sess = Get-VenafiSession
    }

    process {

        $params = @{
            Method = 'Post'
            Body   = @{
                'ObjectDN' = $Path | ConvertTo-VdcFullPath
            }
        }

        Switch ($PsCmdlet.ParameterSetName) {

            'FindByAttribute' {

                $customField = $sess.CustomField | Where-Object { $_.Label -eq $Attribute[0] -or $_.Guid -eq $Attribute[0] }

                # if attribute isn't a custom field or user doesn't want to perform a cf lookup for a conflicting attrib/cf name, perform standard find object
                if ( $NoLookup -or (-not $customField) ) {

                    $params.UriLeaf = 'config/find'
                    $params.Body = @{
                        AttributeNames = $Attribute
                    }
                }
                else {
                    # cf found
                    $params.UriLeaf = 'Metadata/Find'
                    $params.Body = @{
                        ItemGuid = $customField.Guid
                        Value    = $Pattern
                    }
                }
                break
            }

            { $_ -in 'FindByPath', 'FindByPattern' } {
                $params.UriLeaf = 'config/enumerate'
                # if a path wasn't provided, default to recursive enumeration of \ved\policy
                if ( -not $PSBoundParameters.ContainsKey('Path') ) {
                    $params.Body.Recursive = 'true'
                }
                break
            }

            'FindByClass' {
                $params.UriLeaf = 'config/FindObjectsOfClass'
                # if a path wasn't provided, default to recursive enumeration of \ved\policy
                if ( -not $PSBoundParameters.ContainsKey('Path') ) {
                    $params.Body.Recursive = 'true'
                }
                break
            }
        }

        # pattern is not used by custom field lookup
        if ( $PSBoundParameters.ContainsKey('Pattern') -and ($params.UriLeaf -ne 'Metadata/Find') ) {
            $params.Body.Pattern = $Pattern
        }

        if ( $PSBoundParameters.ContainsKey('Recursive') ) {
            $params.Body.Recursive = 'true'
        }

        if ( $PSCmdlet.ParameterSetName -eq 'FindByClass' ) {
            # the rest api doesn't have the ability to search for multiple classes and path at the same time
            # loop through classes to get around this
            $params.Body.Class = ''
            $objects = $Class.ForEach{
                $thisClass = $_
                $params.Body.Class = $thisClass

                $response = Invoke-VenafiRestMethod @params

                if ( $response.Result -eq 1 ) {
                    $response.Objects
                }
                else {
                    Write-Error ('Retrieval of class {0} failed with error {1}' -f $thisClass, $response.Error)
                    Continue
                }
            }
        }
        else {
            $response = Invoke-VenafiRestMethod @params

            # success for cf lookup is 0, all others are config calls and success is 1
            if ( $response.Result -in 0, 1 ) {
                $objects = $response.Objects
            }
            else {
                Write-Error $response.Error
            }

            # there are no apis to search for a specific type and attribute at the same time
            # filter here before sending back the results
            if ( $PSCmdlet.ParameterSetName -eq 'FindByAttribute' -and $Class ) {
                $objects = $objects | Where-Object TypeName -In $Class
            }
        }

        foreach ($object in $objects) {
            ConvertTo-VdcObject -Path $object.DN -Guid $object.Guid -TypeName $object.TypeName
        }
    }
}

