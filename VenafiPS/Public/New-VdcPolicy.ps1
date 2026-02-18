function New-VdcPolicy {
    <#
    .SYNOPSIS
    Add a new policy folder

    .DESCRIPTION
    Add a new policy folder(s).  Add object attributes or policy attributes at the same time.

    .PARAMETER Path
    Full path to the new policy folder.
    If the root path is excluded, \ved\policy will be prepended.
    If used with -Name, this will be the root path and subfolders will be created.

    .PARAMETER Name
    One of more policy folders to create under -Path.

    .PARAMETER Attribute
    Hashtable with names and values to be set on the policy itself.
    If used with -Class, this will set policy attributes.
    If setting a custom field, you can use either the name or guid as the key.
    To clear a value overwriting policy, set the value to $null.

    .PARAMETER Class
    Use with -Attribute to set policy attributes at policy creation time.
    If unsure of the class name, add the value through the Certificate Manager, Self-Hosted UI and go to Support->Policy Attributes to find it.

    .PARAMETER Lock
    Use with -PolicyAttribute and -Class to lock the policy attribute

    .PARAMETER Description
    Deprecated.  Use -Attribute @{''Description''=''my description''} instead.

    .PARAMETER Force
    Force the creation of missing parent policy folders

    .PARAMETER PassThru
    Return a TppObject representing the newly created policy.

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.

    .INPUTS
    Path

    .OUTPUTS
    TppObject, if PassThru provided

    .EXAMPLE
    $newPolicy = New-VdcPolicy -Path 'new'

    Create a new policy folder

    .EXAMPLE
    $newPolicy = New-VdcPolicy -Path 'existing' -Name 'new1', 'new2', 'new3'

    Create multiple policy folders

    .EXAMPLE
    $newPolicy = New-VdcPolicy -Path 'new1\new2\new3' -Force

    Create a new policy folder named new3 and create new1 and new2 if they do not exist

    .EXAMPLE
    $newPolicy = New-VdcPolicy -Path 'new' -Attribute {'Description'='my new policy folder'}

    Create a new policy folder setting attributes on the object at creation time

    .EXAMPLE
    $newPolicy = New-VdcPolicy -Path 'new' -Class 'X509 Certificate' -Attribute {'State'='UT'}

    Create a new policy folder setting policy attributes (not object attributes)

    .EXAMPLE
    $newPolicy = New-VdcPolicy -Path 'new' -Class 'X509 Certificate' -Attribute {'State'='UT'} -Lock

    Create a new policy folder setting policy attributes (not object attributes) and locking them

    .EXAMPLE
    $newPolicy = New-VdcPolicy -Path 'new' -PassThru

    Create a new policy folder returning the policy object created

    .LINK
    https://venafi.github.io/VenafiPS/functions/New-VdcPolicy/

    .LINK
    https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/New-VdcPolicy.ps1

    .LINK
    https://venafi.github.io/VenafiPS/functions/New-VdcObject/

    .LINK
    https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/New-VdcObject.ps1

    #>

    [CmdletBinding(SupportsShouldProcess)]
    [Alias('New-TppPolicy')]

    param (
        [Parameter(Mandatory, ParameterSetName = 'Path', ValueFromPipelineByPropertyName)]
        [Parameter(Mandatory, ParameterSetName = 'Name', ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'PathWithPolicyAttribute', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'NameWithPolicyAttribute', Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $Path,

        [Parameter(ParameterSetName = 'Name', Mandatory)]
        [Parameter(ParameterSetName = 'NameWithPolicyAttribute', Mandatory)]
        [string[]] $Name,

        [Parameter(ParameterSetName = 'Path')]
        [Parameter(ParameterSetName = 'Name')]
        [String] $Description,

        [Parameter(ParameterSetName = 'Path')]
        [Parameter(ParameterSetName = 'Name')]
        [Parameter(ParameterSetName = 'PathWithPolicyAttribute', Mandatory)]
        [Parameter(ParameterSetName = 'NameWithPolicyAttribute', Mandatory)]
        [hashtable] $Attribute,

        [Parameter(ParameterSetName = 'PathWithPolicyAttribute', Mandatory)]
        [Parameter(ParameterSetName = 'NameWithPolicyAttribute', Mandatory)]
        [string] $Class,

        [Parameter(ParameterSetName = 'PathWithPolicyAttribute')]
        [Parameter(ParameterSetName = 'NameWithPolicyAttribute')]
        [switch] $Lock,

        [Parameter()]
        [switch] $Force,

        [Parameter()]
        [switch] $PassThru,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {

        $params = @{
            Class         = 'Policy'
            PassThru      = $true
            Force         = $Force
        }

        if ( ($PSBoundParameters.ContainsKey('Description') -or $PSBoundParameters.ContainsKey('Attribute')) -and $PSCmdlet.ParameterSetName -in 'Path', 'Name' ) {
            $params.Attribute = @{}

            if ( $PSBoundParameters.ContainsKey('Description') ) {
                $params.Attribute += @{'Description' = $Description }
            }

            if ( $PSBoundParameters.ContainsKey('Attribute') ) {
                $params.Attribute += $Attribute
            }
        }
    }

    process {

        $newPath = $Path | ConvertTo-VdcFullPath

        if ( $PSCmdlet.ParameterSetName -in 'Path', 'PathWithPolicyAttribute' ) {

            $params.Path = $newPath

            if ( $PSCmdlet.ShouldProcess($newPath, 'Create Policy') ) {

                $response = New-VdcObject @params

                if ( $PSBoundParameters.ContainsKey('Class') ) {
                    $response | Set-VdcAttribute -Attribute $Attribute -Class $Class -Lock:$Lock
                }

                if ( $PassThru ) {
                    $response
                }
            }
        } else {
            foreach ($thisName in $Name) {
                $PSBoundParameters['Path'] = "$newPath\$thisName"
                $null = $PSBoundParameters.Remove('Name')

                New-VdcPolicy @PSBoundParameters
            }
        }

    }
}


