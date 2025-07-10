function New-VdcObject {
    <#
    .SYNOPSIS
    Create a new object

    .DESCRIPTION
    Generic use function to create a new object if a specific function hasn't been created yet for the class.
    This can also be used to duplicate an existing object.

    .PARAMETER Path
    Full path, including name, for the object to be created.
    If the root path is excluded, \ved\policy will be prepended.

    .PARAMETER Class
    Class name of the new object.
    See https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/SchemaReference/r-SDK-CNattributesWhere.php for more info.

    .PARAMETER Attribute
    Hashtable with initial values for the new object.
    These will be specific to the object class being created.

    .PARAMETER SourcePath
    Provide this path when you want to duplicate an existing object.
    This will be the path of the source object and Path will be the destination.
    All attributes which have been set on this object will be copied to the new one.
    Retrieving all existing attributes will take some time.

    Not recommended for duplicating certificates.

    .PARAMETER PushCertificate
    If creating an application object, you can optionally push the certificate once the creation is complete.
    Only available if a 'Certificate' key containing the certificate path is provided for Attribute.

    .PARAMETER Force
    Force the creation of missing parent policy folders when the class is either Policy or Device.

    .PARAMETER PassThru
    Return a TppObject representing the newly created object.

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.

    .EXAMPLE
    New-VdcObject -Path '\VED\Policy\Test Device' -Class 'Device' -Attribute @{'Description'='new device testing'}

    Create a new object

    .EXAMPLE
    New-VdcObject -Path 'missing\folder\again' -Class 'Policy' -Force

    Create a new object as well as any missing policy folders in the path

    .EXAMPLE
    New-VdcObject -Path '\VED\Policy\Test Device' -Class 'Device' -Attribute @{'Description'='new device testing'} -PassThru

    Create a new object and return the resultant object

    .EXAMPLE
    New-VdcObject -Path '\VED\Policy\Test Device\App' -Class 'Basic' -Attribute @{'Driver Name'='appbasic';'Certificate'='\Ved\Policy\mycert.com'}

    Create a new Basic application and associate it to a device and certificate

    .EXAMPLE
    New-VdcObject -Path 'certificates\duplicate.company.com' -SourcePath 'certificates\original.company.com'

    Create a duplicate object with all attributes from the original being copied over

    .INPUTS
    none

    .OUTPUTS
    TppObject, if PassThru provided

    .LINK
    https://venafi.github.io/VenafiPS/functions/New-VdcObject/

    .LINK
    https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/New-VdcObject.ps1

    .LINK
    https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Add-VdcCertificateAssociation.ps1

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Config-create.php

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/SchemaReference/r-SDK-CNattributesWhere.php

    #>

    [CmdletBinding(DefaultParameterSetName = 'NonDup', SupportsShouldProcess)]
    [Alias('New-TppObject')]

    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Path,

        [Parameter(Mandatory, ParameterSetName = 'NonDup')]
        [String] $Class,

        [Parameter(ParameterSetName = 'NonDup')]
        [ValidateNotNullOrEmpty()]
        [Hashtable] $Attribute,

        [Parameter(ParameterSetName = 'Dup')]
        [string] $SourcePath,

        [Parameter()]
        [Alias('ProvisionCertificate')]
        [switch] $PushCertificate,

        [Parameter()]
        [switch] $Force,

        [Parameter()]
        [switch] $PassThru,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    Test-VenafiSession $PSCmdlet.MyInvocation

    if ( $PushCertificate -and (-not $Attribute.Certificate) ) {
        Write-Warning 'A ''Certificate'' key containing the certificate path must be provided for Attribute when using PushCertificate, eg. -Attribute @{''Certificate''=''\Ved\Policy\mycert.com''}.  Certificate provisioning will not take place.'
    }

    $newPath = $Path | ConvertTo-VdcFullPath

    $params = @{
        Method  = 'Post'
        UriLeaf = 'config/create'
        Body    = @{
            ObjectDN = $newPath
        }
    }

    if ( $SourcePath ) {
        $fullSourcePath = $SourcePath | ConvertTo-VdcFullPath

        $o = Get-VdcObject -Path $fullSourcePath
        $oa = $o | Get-VdcAttribute -All

        $attribs = foreach ($a in $oa.Attribute) {
            if (![string]::IsNullOrEmpty($a.Value)) {
                @{'Name' = $a.name; 'Value' = $a.value }
            }
        }

        $params.Body.Class = $o.TypeName
        $params.Body.NameAttributeList = @($attribs)
    }
    else {
        $params.Body.Class = $Class
    }

    if ( $PSBoundParameters.ContainsKey('Attribute') ) {
        # api requires a list of hashtables for nameattributelist
        # with 2 items per hashtable, with key names 'name' and 'value'
        # this is cumbersome for the user so allow them to pass a standard hashtable and convert it for them
        $updatedAttribute = @($Attribute.GetEnumerator() | ForEach-Object { @{'Name' = $_.name; 'Value' = $_.value } })
        $params.Body.Add('NameAttributeList', $updatedAttribute)
    }

    if ( $PSCmdlet.ShouldProcess($newPath, ('Create {0} Object' -f $params.Body.Class)) ) {

        $retryCount = 0
        do {
            $retryCreate = $false

            $response = Invoke-VenafiRestMethod @params

            switch ($response.Result) {

                1 {
                    Write-Verbose "Successfully created $Class at $newPath"
                    $returnObject = ConvertTo-VdcObject -Path $response.Object.DN -Guid $response.Object.Guid -TypeName $response.Object.TypeName
                }

                400 {
                    # occurs when a parent object, anywhere in the path, is missing

                    # with these classes we know the parent is a policy so we can create them
                    if ( $Class -in 'Policy', 'Device' ) {
                        if ( -not $Force ) {
                            throw "Part of the path $newPath does not exist.  Use -Force to create the missing policy folders."
                        }
                        else {

                            $pathSplit = $newPath.Split('\')

                            # create the parent policy folders
                            # don't try and create \ved or \ved\policy levels
                            for ($i = 3; $i -lt ($pathSplit.Count - 1); $i++) {
                                if ( -not (Find-VdcObject -Path ($pathSplit[0..($i - 1)] -join '\') -Pattern $pathSplit[$i])) {
                                    Write-Verbose ('Creating missing policy folder {0}' -f ($pathSplit[0..$i] -join '\'))
                                    New-VdcPolicy -Path ($pathSplit[0..$i] -join '\')
                                }
                            }

                            $retryCreate = $true
                        }
                    }
                    else {
                        throw "Part of path $newPath does not exist."
                    }
                }

                401 {
                    throw "$newPath already exists"
                }

                Default {
                    throw ('Error creating object: {0}, {1}' -f $response.Result, $_)
                }
            }

            $retryCount++

        } until (
            -not $retryCreate -or $retryCount -gt 2
        )

        if ( $Attribute.Certificate ) {
            $associateParams = @{
                CertificatePath = $Attribute.Certificate
                ApplicationPath = $response.Object.DN
            }
            if ( $PushCertificate.IsPresent ) {
                $associateParams.Add('PushCertificate', $true)
            }

            Add-VdcCertificateAssociation @associateParams
        }

        if ( $PassThru ) {
            $returnObject
        }
    }
}


