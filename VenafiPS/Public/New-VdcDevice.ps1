function New-VdcDevice {
    <#
    .SYNOPSIS
    Add a new device

    .DESCRIPTION
    Add a new device with optional attributes

    .PARAMETER Path
    Full path to the new device.
    Alternatively, you can provide just the policy path, but then DeviceName must be provided.

    .PARAMETER DeviceName
    Name of 1 or more devices to create.  Path must be of type Policy to use this.

    .PARAMETER Description
    Device description

    .PARAMETER CredentialPath
    Path to the credential which has permissions to update the device

    .PARAMETER Hostname
    Hostname or IP Address of the device

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
    $newPolicy = New-VdcDevice -Path '\VED\Policy\MyFolder\device' -PassThru
    Create device with full path to device and returning the object created

    .EXAMPLE
    $policyPath | New-VdcDevice -DeviceName 'myDevice' -Hostname 1.2.3.4
    Pipe policy path and provide device details

    .LINK
    https://venafi.github.io/VenafiPS/functions/New-VdcDevice/

    .LINK
    https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/New-VdcDevice.ps1

    .LINK
    https://venafi.github.io/VenafiPS/functions/New-VdcObject/

    .LINK
    https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/New-VdcObject.ps1

    #>

    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '')]

    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                if ( $_ | Test-TppDnPath ) {
                    $true
                }
                else {
                    throw "'$_' is not a valid DN path"
                }
            })]
        [string] $Path,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String[]] $DeviceName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String] $Description,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                if ( $_ | Test-TppDnPath ) {
                    $true
                }
                else {
                    throw "'$_' is not a valid DN path"
                }
            })]
        [string] $CredentialPath,

        [Parameter()]
        [Alias('IpAddress')]
        [string] $Hostname,

        [Parameter()]
        [switch] $PassThru,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {

        # leave .Validate() out as New-VdcObject will do it for us later

        $params = @{
            Path       = ''
            Class      = 'Device'
            PassThru   = $true

            Attribute  = @{ }
        }

        if ( $PSBoundParameters.ContainsKey('Description') ) {
            $params.Attribute['Description'] = $Description
        }

        if ( $PSBoundParameters.ContainsKey('CredentialPath') ) {
            $params.Attribute['Credential'] = $CredentialPath
        }

        if ( $PSBoundParameters.ContainsKey('Hostname') ) {
            $params.Attribute['Host'] = $Hostname
        }

        # if no attributes were provided, we need to pull out the attribute key
        # otherwise the request will fail
        if ( $params.Attribute.Count -eq 0 ) {
            $params.Remove('Attribute')
        }
    }

    process {

        if ( $PSBoundParameters.ContainsKey('DeviceName') ) {
            $devicePaths = $DeviceName | ForEach-Object {
                $Path + "\$_"
            }
        }
        else {
            $devicePaths = @($Path)
        }

        foreach ($thisPath in $devicePaths) {

            $params.Path = $thisPath

            if ( $PSCmdlet.ShouldProcess($thisPath, 'Create Device Object') ) {

                $response = New-VdcObject @params

                if ( $PassThru ) {
                    $response
                }
            }
        }
    }
}


