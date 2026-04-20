function Test-VdcDnPath {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string] $Path,

        [Parameter()]
        [bool] $AllowRoot = $true
    )

    process {
        if ( $AllowRoot ) {
            $Path -imatch '^[\\|\\\\]+ved([\\|\\\\]+.+)*$'
        } else {
            $Path -imatch '^[\\|\\\\]+ved([\\|\\\\]+.+)+$'
        }
    }
}
