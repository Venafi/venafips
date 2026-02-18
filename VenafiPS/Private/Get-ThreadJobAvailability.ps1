function Get-ThreadJobAvailability {
    if ($null -eq $script:ThreadJobAvailable) {
        $script:ThreadJobAvailable = ($null -ne (Get-Module -Name Microsoft.PowerShell.ThreadJob -ListAvailable))
    }
    return $script:ThreadJobAvailable
}