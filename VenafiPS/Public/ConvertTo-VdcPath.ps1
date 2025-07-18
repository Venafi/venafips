function ConvertTo-VdcPath {
    <#
    .SYNOPSIS
    Convert GUID to Path

    .DESCRIPTION
    Convert GUID to Path

    .PARAMETER Guid
    Guid type, [guid] 'xyxyxyxy-xyxy-xyxy-xyxy-xyxyxyxyxyxy'

    .PARAMETER IncludeType
    Include the object type in the response

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.

    .INPUTS
    Guid

    .OUTPUTS
    String representing the Path

    .EXAMPLE
    ConvertTo-VdcPath -Guid [guid]'xyxyxyxy-xyxy-xyxy-xyxy-xyxyxyxyxyxy'

    #>

    [CmdletBinding()]
    [Alias('ConvertTo-TppPath')]

    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Guid] $Guid,

        [Parameter()]
        [switch] $IncludeType,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {
        Write-Warning 'ConvertTo-VdcPath to be deprecated.  Use Get-VdcObject instead.'

        Test-VenafiSession $PSCmdlet.MyInvocation

        $params = @{

            Method     = 'Post'
            UriLeaf    = 'config/GuidToDN'
            Body       = @{
                ObjectGUID = ''
            }
        }
    }

    process {

        $params.Body.ObjectGUID = "{$Guid}"

        $response = Invoke-VenafiRestMethod @params

        if ( $response.Result -eq 1 ) {
            if ( $PSBoundParameters.ContainsKey('IncludeType') ) {
                [PSCustomObject] @{
                    Path     = $response.ObjectDN
                    TypeName = $response.ClassName
                }
            } else {
                $response.ObjectDN
            }
        } else {
            throw $response.Error
        }
    }
}

