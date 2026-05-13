function Get-CmClassAttribute {
    <#
    .SYNOPSIS
    List all attributes for a specified class

    .DESCRIPTION
    List all attributes for a specified class, helpful for validation or to pass to Get-CmAttribute

    .PARAMETER ClassName
    Class name to retrieve attributes for

    .PARAMETER TrustClient
    Authentication for the function.
    The value defaults to the script session object $TrustClient created by New-TrustClient.

    .EXAMPLE
    Get-CmClassAttribute -ClassName 'X509 Server Certificate'

    Get all attributes for the specified class

    .INPUTS
    ClassName

    .OUTPUTS
    PSCustomObject
    #>

    [Alias('Get-VdcClassAttribute')]
    [CmdletBinding()]

    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string] $ClassName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [TrustClient] $TrustClient = (Get-TrustClient)
    )

    begin {

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
            TrustClient = $TrustClient
        }
        $classDetails = Invoke-TrustRestMethod @params | Select-Object -ExpandProperty 'ClassDefinition'

        if ($ClassName -ne 'Top') {
            $recurseAttribs = $classDetails.SuperClassNames | Get-CmClassAttribute -TrustClient $TrustClient
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


