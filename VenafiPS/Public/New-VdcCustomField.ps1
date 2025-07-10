
function New-VdcCustomField {
    <#
    .SYNOPSIS
    Create new custom field in Venafi of the specified class and type.

    .DESCRIPTION
    Creates a new custom field in Venafi. Required parameters are name, label, class and type.
    See Venafi docs for information about other metadata items.

    .PARAMETER Name
    Name of new custom field

    .PARAMETER Label
    Label of new custom field

    .PARAMETER Class
    Class of new custom field, either 'Device' or 'X509 Certificate'

    .PARAMETER Type
    Type of new custom field, one of 'String', 'List', 'DateTime', 'Identity'

    .PARAMETER AllowedValue
    An array of allowable values for the Custom Field.

    .PARAMETER Single
    Controls the number of input selections. If not used the user can select
    multiple values for the Custom Field. Otherwise the user can select only
    one value

    .PARAMETER Help
    The tool tip to show to the user how to populate the Custom Field.

    .PARAMETER ErrorMessage
    The error message that you define for this Custom Field.

    .PARAMETER Mandatory
    Determines if a value is required in the custom field. If not used a value is
    optional, otherwise the user must enter a value.

    .PARAMETER Policyable
    Determines if the custom field can be used in a policy setting to apply to
    all objects in the policy. If not used the custom field cannot apply to a policy.

    .PARAMETER RegEx
    The regular expression to control user input.

    .PARAMETER RenderHidden
    Controls the visibility of the custom field in the UI. By default custom fields
    are visible in the class they are created for. This switch hides them.

    .PARAMETER RenderReadOnly
    Controls if the custom field is read only. By default a user can change the custom
    field value. This switch makes it the custom field value cannot be changed.

    .PARAMETER DateOnly
    Controls if the custom field requires a calendar date. By default a date is not required.

    .PARAMETER TimeOnly
    Controls if the custom field requires a time of day. By default a time is not required.

    .PARAMETER PassThru
    Return a PSCustomObject with the following properties:
        AllowedValues
        Class
        DateOnly
        DN
        ErrorMessage
        Guid
        Help
        Label
        Mandatory
        Name
        Policyable
        RegularExpression
        RenderHidden
        RenderReadOnly
        Single
        TimeOnly
        Type

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.

    .INPUTS
    None

    .OUTPUTS
    PSCustomObject, if PassThru provided

    .EXAMPLE
    New-VdcCustomField -Name "Last Date" -Label "Last Date" -Class "X509 Certificate" -Type "String" -RenderReadOnly -Help "Last Date of certificate import"
    Create new custom field for certificates

    .LINK
    https://venafi.github.io/VenafiPS/functions/New-VdcCustomField/

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Metadata-DefineItem.php

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Metadata-Item.php

    #>

    [CmdletBinding(SupportsShouldProcess)]
    [Alias('New-TppCustomField')]

    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Label,

        [Parameter(Mandatory)]
        [ValidateSet('Device', 'X509 Certificate')]
        [ValidateNotNullOrEmpty()]
        [string[]]$Class,

        [Parameter(Mandatory)]
        [ValidateSet('String', 'List', 'DateTime', 'Identity')]
        [ValidateNotNullOrEmpty()]
        [string]$Type,

        [Parameter()]
        [string[]]$AllowedValue,

        [Parameter()]
        [switch]$Single,

        [Parameter()]
        [string]$Help,

        [Parameter()]
        [string]$ErrorMessage,

        [Parameter()]
        [switch]$Mandatory,

        [Parameter()]
        [switch]$Policyable,

        [Parameter()]
        [string]$RegEx,

        [Parameter()]
        [switch]$RenderHidden,

        [Parameter()]
        [switch]$RenderReadOnly,

        [Parameter()]
        [switch]$DateOnly,

        [Parameter()]
        [switch]$TimeOnly,

        [Parameter()]
        [switch] $PassThru,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {
        Test-VenafiSession $PSCmdlet.MyInvocation

        $resultObj = @()

        if ( $Type -eq 'String' ) {
            $ItemType = '1'
        }
        elseif ( $Type -eq 'List' ) {
            $ItemType = '2'
        }
        elseif ( $Type -eq 'DateTime' ) {
            $ItemType = '4'
        }
        elseif ( $Type -eq 'Identity' ) {
            $ItemType = '5'
        }

        $params = @{

            Method        = 'Post'
            UriLeaf       = 'Metadata/DefineItem'
            Body          = @{
                "Item" = @{
                    "Name"           = $Name
                    "Classes"        = @($Class)
                    "Label"          = $Label
                    "Type"           = $ItemType
                    "Single"         = $Single.ToString().ToLower()
                    "Mandatory"      = $Mandatory.ToString().ToLower()
                    "Policyable"     = $Policyable.ToString().ToLower()
                    "RenderHidden"   = $RenderHidden.ToString().ToLower()
                    "RenderReadOnly" = $RenderReadOnly.ToString().ToLower()
                    "DateOnly"       = $DateOnly.ToString().ToLower()
                    "TimeOnly"       = $TimeOnly.ToString().ToLower()
                }
            }
        }
        if ( $PSBoundParameters.ContainsKey('Help') ) {
            $params.Body.Item['Help'] = $Help
        }
        if ( $PSBoundParameters.ContainsKey('AllowedValue') ) {
            $params.Body.Item['AllowedValues'] = @($AllowedValue)
        }
        if ( $PSBoundParameters.ContainsKey('ErrorMessage') ) {
            $params.Body.Item['ErrorMessage'] = $ErrorMessage
        }
        if ( $PSBoundParameters.ContainsKey('RegEx') ) {
            $params.Body.Item['RegularExpression'] = $RegEx
        }
    }

    end {
        if ( $PSCmdlet.ShouldProcess($Label) ) {

            $response = Invoke-VenafiRestMethod @params

            if ( $response.Result -eq [TppMetadataResult]::Success ) {
                if (( $PassThru )) {
                    $resultObj = [PSCustomObject] @{
                        "Path"  = $response.Item.DN
                        "Label" = $response.Item.Label
                        "Name"  = $response.Item.Name
                        "Guid"  = [guid]$response.Item.Guid
                        "Type"  = $response.Item.Type
                        "Class" = $response.Item.Classes
                    }
                    if ($response.Item.Mandatory) {
                        $resultObj | Add-Member -MemberType NoteProperty -Name "Mandatory" -Value $response.Item.Mandatory
                    }
                    if ($response.Item.Policyable) {
                        $resultObj | Add-Member -MemberType NoteProperty -Name "Policyable" -Value $response.Item.Policyable
                    }
                    if ($response.Item.RenderHidden) {
                        $resultObj | Add-Member -MemberType NoteProperty -Name "RenderHidden" -Value $response.Item.RenderHidden
                    }
                    if ($response.Item.RenderReadOnly) {
                        $resultObj | Add-Member -MemberType NoteProperty -Name "RenderReadOnly" -Value $response.Item.RenderReadOnly
                    }
                    if ($response.Item.DateOnly) {
                        $resultObj | Add-Member -MemberType NoteProperty -Name "DateOnly" -Value $response.Item.DateOnly
                    }
                    if ($response.Item.TimeOnly) {
                        $resultObj | Add-Member -MemberType NoteProperty -Name "TimeOnly" -Value $response.Item.TimeOnly
                    }
                    if ($response.Item.Help) {
                        $resultObj | Add-Member -MemberType NoteProperty -Name "Help" -Value $response.Item.Help
                    }
                    if ($response.Item.AllowedValues) {
                        $resultObj | Add-Member -MemberType NoteProperty -Name "AllowedValues" -Value $response.Item.AllowedValues
                    }
                    if ($response.Item.Single) {
                        $resultObj | Add-Member -MemberType NoteProperty -Name "Single" -Value $response.Item.Single
                    }
                    if ($response.Item.ErrorMessage) {
                        $resultObj | Add-Member -MemberType NoteProperty -Name "ErrorMessage" -Value $response.Item.ErrorMessage
                    }
                    if ($response.Item.RegularExpression) {
                        $resultObj | Add-Member -MemberType NoteProperty -Name "RegularExpression" -Value $response.Item.RegularExpression
                    }
                    return $resultObj
                }
            }
            else {
                throw $response.Error
            }
        }
    }
}


