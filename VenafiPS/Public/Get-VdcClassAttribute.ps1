function Get-VdcClassAttribute {
    <#
    .SYNOPSIS
    List all attributes for a specified class

    .DESCRIPTION
    List all attributes for a specified class, helpful for validation or to pass to Get-VdcAttribute

    .PARAMETER ClassName
    Class name to retrieve attributes for

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.

    .EXAMPLE
    Get-VdcClassAttribute -ClassName 'X509 Server Certificate'

    Get all attributes for the specified class

    .INPUTS
    ClassName

    .OUTPUTS
    PSCustomObject
    #>

    [CmdletBinding()]
    [Alias('Get-TppClassAttribute')]

    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string] $ClassName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession = (Get-VenafiSession)
    )

    begin {
        Test-VenafiSession $PSCmdlet.MyInvocation

        $allAttributes = [System.Collections.Generic.List[object]]::new()
    }

    process {

        Write-Verbose "Processing $ClassName"

        $params = @{
            Method        = 'Post'
            UriLeaf       = 'configschema/class'
            Body          = @{
                'Class' = $ClassName
            }
            VenafiSession = $VenafiSession
        }
        $classDetails = Invoke-VenafiRestMethod @params | Select-Object -ExpandProperty 'ClassDefinition'

        if ($ClassName -ne 'Top') {
            $recurseAttribs = $classDetails.SuperClassNames | Get-VdcClassAttribute -VenafiSession $VenafiSession
            foreach ($item in $recurseAttribs) {
                $allAttributes.Add($item)
            }
        }

        foreach ($item in ($classDetails.OptionalNames)) {
            $allAttributes.Add(
                [pscustomobject] @{
                    'Name'  = $item
                    'Class' = $classDetails.Name
                }
            )
        }
    }

    end {
        $allAttributes | Sort-Object -Property 'Name', 'Class' -Unique
    }
}


