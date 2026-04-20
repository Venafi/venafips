function Select-TrustBatch {
    <#
    .SYNOPSIS
    Batches pipeline input.

    .DESCRIPTION
    Batches up pipeline input into consistently sized List[T]s of objects. Used to ensure that processing occurs in specific sized batches.
    Useful for not recieving API timouts due to sending more objects than can be processed in the connection timeout period.

    .PARAMETER InputObject
    The pipeline input objects binds to this parameter one by one.
    Do not use it directly.

    .PARAMETER BatchSize
    The size of the batches to separate the pipeline input into.

    .PARAMETER BatchType
    Type of object to group things into. Defaults to a Powershell custom object

    Valid Values: "pscustomobject", "string", "int", "guid"

    .PARAMETER TotalCount
    The total number of items in the pipeline. Used to calculate progress.
    If you do not provide this value or ProgressPreference is set to 'SilentlyContinue', no progress will be displayed.

    .OUTPUTS
    System.Collections.Generic.List[T]

    .EXAMPLE
    1..6000 | Select-TrustBatch -batchsize 1000 -BatchType string

    #>

    [CmdletBinding(PositionalBinding = $false)]
    param (
        [Parameter(ValueFromPipeline)]
        $InputObject,

        [Parameter(Mandatory)]
        [int] $BatchSize,

        [Parameter(Mandatory, Position = 0)]
        [ValidateSet("pscustomobject", "string", "int", "guid")]
        [string] $BatchType = "pscustomobject",

        [Parameter()]
        [int] $TotalCount,

        [Parameter()]
        [string] $Activity = 'Processing batches'

    )

    Begin {
        switch ($BatchType) {
            'string' {
                $Batch = [System.Collections.Generic.Queue[string]]::new($BatchSize)
            }
            'int' {
                $Batch = [System.Collections.Generic.Queue[int]]::new($BatchSize)
            }
            'guid' {
                $Batch = [System.Collections.Generic.Queue[guid]]::new($BatchSize)
            }
            'pscustomobject' {
                $Batch = [System.Collections.Generic.Queue[pscustomobject]]::new($BatchSize)
            }
        }

        $count = 0
        If ($TotalCount) {
            $progressParams = @{
                Activity        = $Activity
                Status          = 'Initializing'
                PercentComplete = -1
            }
            Write-Progress @progressParams
        }
    }

    Process {

        $count++

        $Batch.Enqueue($_)

        if ($Batch.Count -eq $BatchSize) {

            If ($TotalCount) {
                $progressParams.Status = 'Batch {0}, items {1}-{2}' -f ($count / $BatchSize), ($count - $BatchSize + 1), $count
                [int] $percent = ($count / $TotalCount) * 100
                $progressParams.PercentComplete = $percent
                Write-Progress @progressParams
            }
            'Processing batch {0}, items {1}-{2}' -f ($count / $BatchSize), ($count - $BatchSize + 1), $count | Write-Verbose

            , ($Batch)
            $Batch.Clear() # start next batch
        }
    }

    end {
        # process any remaining items, eg. we didn't have a full batch
        if ( $Batch.Count ) {
            $batchNum = [math]::Ceiling($count / $BatchSize)

            If ($TotalCount) {
                $progressParams.Status = 'Batch {0}, items {1}-{2}' -f $batchNum, ((($batchNum - 1) * $BatchSize) + 1), $count
                [int] $percent = ($count / $TotalCount) * 100
                $progressParams.PercentComplete = $percent
                Write-Progress @progressParams
            }
            'Processing batch {0}, items {1}-{2}' -f $batchNum, ((($batchNum - 1) * $BatchSize) + 1), $count | Write-Verbose

            , ($Batch)
            $Batch.Clear()
            Remove-Variable Batch

            If ($TotalCount) {
                Write-Progress -Activity 'Completed' -Completed
            }
        }
    }
}
