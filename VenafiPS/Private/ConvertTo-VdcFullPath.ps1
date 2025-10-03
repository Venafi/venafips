function ConvertTo-VdcFullPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string] $Path
    )

    begin {

    }

    process {
        $newPath = $Path.TrimEnd('\')
        if ( $Path.ToLower() -notlike '\ved*') {
            "\VED\Policy\$newPath"
        }
        else {
            $newPath
        }
    }

    end {

    }
}
