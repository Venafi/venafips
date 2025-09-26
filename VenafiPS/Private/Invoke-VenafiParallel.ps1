function Invoke-VenafiParallel {

    <#
    .SYNOPSIS
    Helper function to execute a scriptblock in parallel

    .DESCRIPTION
    Execute a scriptblock in parallel.
    For PS v5, the ThreadJob module is required.

    .PARAMETER InputObject
    List of items to iterate over

    .PARAMETER ScriptBlock
    Scriptblock to execute against the list of items

    .PARAMETER ThrottleLimit
    Limit the number of threads when running in parallel; the default is 100.
    Setting the value to 1 will disable multithreading.
    On PS v5 the ThreadJob module is required.  If not found, multithreading will be disabled.

    .PARAMETER ProgressTitle
    Message displayed on the progress bar

    .PARAMETER VenafiSession
    Authentication for the function.

    .EXAMPLE
    Invoke-VenafiParallel -InputObject $myObjects -ScriptBlock { Do-Something $PSItem }

    Execute in parallel.  Reference each item in the scriptblock as $PSItem or $_.

    .EXAMPLE
    Invoke-VenafiParallel -InputObject $myObjects -ScriptBlock { Do-Something $PSItem } -ThrottleLimit 5

    Only run 5 threads at a time instead of the default of 100.

    .EXAMPLE
    $ProgressPreference = 'SilentlyContinue'
    Invoke-VenafiParallel -InputObject $myObjects -ScriptBlock { Do-Something $PSItem }

    Execute in parallel with no progress bar.

    .NOTES
    In your ScriptBlock:
    - Use either $PSItem or $_ to reference the current input object
    - Remember, hashtables are reference types so be sure to clone if 'using' from parent

    #>


    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [AllowNull()]
        [psobject] $InputObject,

        [Parameter(Mandatory)]
        [scriptblock] $ScriptBlock,

        [Parameter()]
        [int32] $ThrottleLimit = 100,

        [Parameter()]
        [string] $ProgressTitle = 'Performing action',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession

    )

    if (-not $InputObject) { return }

    # if ThreadJob module is not available, throttle to 1 so multithreading isn't used
    if ( $PSVersionTable.PSVersion.Major -eq 5 ) {
        if ( -not $script:ThreadJobAvailable ) {
            $ThrottleLimit = 1
        }
    }

    # no need for parallel processing overhead if just processing 1 item
    if ( $InputObject.Count -eq 1 ) {
        $ThrottleLimit = 1
    }

    # throttle to 1 = no parallel
    if ( $ThrottleLimit -le 1 ) {
        # remove $using: from vars, not threaded and not supported
        $InputObject | ForEach-Object -Process ([ScriptBlock]::Create(($ScriptBlock.ToString() -ireplace [regex]::Escape('$using:'), '$')))
        return
    }

    # parallel processing from here down

    $VenafiSession = Get-VenafiSession

    $starterSb = {

        # need to import module until https://github.com/PowerShell/PowerShell/issues/12240 is complete
        # import via path instead of just module name to support non-standard paths, eg. development work

        # ParallelImportPath is set during module import
        Import-Module $using:script:ParallelImportPath -Force

        # bring in the venafi session from the calling ps session
        $script:VenafiSession = $using:VenafiSession

        # bring in verbose preference from calling ps session
        $VerbosePreference = $using:VerbosePreference

        # bring in debug preference from calling ps session
        $DebugPreference = $using:DebugPreference
    }


    if ( $PSVersionTable.PSVersion.Major -eq 5 ) {
        # Start-ThreadJob does not have any child jobs for some reason so there will be no progress
        $sb = ([ScriptBlock]::Create($starterSb.ToString() + '$using:InputObject | % { ' + $ScriptBlock.ToString() + '}'))
        return Start-ThreadJob -ScriptBlock $sb -ThrottleLimit $ThrottleLimit | Receive-Job -Wait -AutoRemoveJob
    }
    else {
        # PS7
        $sb = ([ScriptBlock]::Create($starterSb.ToString() + $ScriptBlock.ToString()))

        if ( $ProgressPreference -ne 'Continue' ) {
            # no progress, arguably faster
            return $InputObject | Foreach-Object -AsJob -ThrottleLimit $ThrottleLimit -Parallel $sb | Receive-Job -Wait -AutoRemoveJob
        }
        else {

            Write-Progress -Activity $ProgressTitle -Status "Initializing..."

            $job = $InputObject | Foreach-Object -AsJob -ThrottleLimit $ThrottleLimit -Parallel $sb

            if ( -not $job.ChildJobs ) {
                return
            }

            $childJobs = $job.ChildJobs
            $childJobsCount = $childJobs.Count

            # Calculate progress update threshold for better performance
            $progressThreshold = [Math]::Max(1, [Math]::Floor($childJobsCount / 100))  # Update every 1% or minimum every job
            if ($childJobsCount -lt 20) { $progressThreshold = 1 }  # Always show progress for small sets

            $lastReportedCount = 0

            do {
                Start-Sleep -Milliseconds 100

                $completedJobs = $childJobs | Where-Object State -in 'Completed', 'Failed', 'Stopped'

                # get latest job info
                $job | Receive-Job

                $completedCount = $completedJobs.Count

                # Only update progress when we've crossed the threshold or reached the end
                if (($completedCount - $lastReportedCount) -ge $progressThreshold -or $completedCount -eq $childJobsCount) {
                    [int] $percent = ($completedCount / $childJobsCount) * 100
                    Write-Progress -Activity $ProgressTitle -Status ('{0}% complete ({1}/{2})' -f $percent, $completedCount, $childJobsCount) -PercentComplete $percent
                    $lastReportedCount = $completedCount
                }

            } while ($completedJobs.Count -lt $childJobsCount)

            Write-Progress -Completed -Activity 'done'
        }
    }

}

