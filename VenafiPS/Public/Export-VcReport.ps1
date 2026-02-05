function Export-VcReport {
    <#
    .SYNOPSIS
    Get custom report data

    .DESCRIPTION
    Get custom report data and either save to a file or get as a powershell object

    .PARAMETER Report
    Report name as specified on Insights -> Custom Reports

    .PARAMETER OutPath
    Optional path to write the output to.
    This is just the directory; the file name will be the Report name, eg. MyReport.csv.

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A TLSPC key can also provided.

    .INPUTS
    Report

    .EXAMPLE
    $reportData = Export-VcReport -Report 'Custom expiration report'

    Get report data for further processing

    .EXAMPLE
    Export-VcReport -Report 'Custom expiration report' -OutPath '~/reports'

    Save report data to a csv file.  The directory must already exist.
    #>

    [CmdletBinding()]
    param (

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('reportId')]
        [string] $Report,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                if (Test-Path $_ -PathType Container) {
                    $true
                }
                else {
                    Throw "Output path '$_' does not exist"
                }
            })]
        [String] $OutPath,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    process {

        $reportId = if ( Test-IsGuid($Report) ) {
            $Report
        }
        else {
            $query = 'query SearchCustomReports($filter: ReportDefinitionFilterInput) {
                        searchReportDefinition(filter: $filter) {
                            nodes {
                            __typename
                            name
                            id
                            isDownloadable
                            query
                            description
                            }
                            __typename
                            }
                        }
                    '

            $variables = @{
                'filter' = @{
                    'and' = @(
                        @{
                            'or' = @(
                                @{
                                    'name' = @{
                                        'eq' = $Report
                                    }
                                }
                            )
                        }
                    )
                }
            }

            $response = Invoke-VcGraphQL -Query $query -Variables $variables

            if ( -not $response.searchReportDefinition.nodes ) {
                throw "Report '$Report' was not found"
            }

            if ( -not $response.searchReportDefinition.nodes.isDownloadable ) {
                throw "Report '$Report' is not downloadable.  Login to Certificate Manager SaaS, run the report, and try again."
            }

            $response.searchReportDefinition.nodes.id
        }

        $getReportQuery = 'query GetReportDownloadDetails($id: UUID!) {
                        reportDownloadDetails(id: $id) {
                            url
                            __typename
                        }
                        }'

        $getReportVars = @{'id' = $reportId }
        $getReportResponse = Invoke-VcGraphQL -Query $getReportQuery -Variables $getReportVars

        if ( $getReportResponse ) {
            if ( $OutPath ) {
                $reportPath = Join-Path -Path (Resolve-Path -Path $OutPath) -ChildPath ('{0}.csv' -f $Report)
                Invoke-WebRequest -Uri $getReportResponse.reportDownloadDetails.url -OutFile $reportPath
                Write-Verbose "Saved report to $reportPath"
            }
            else {
                $tempFile = New-TemporaryFile
                try {
                    Invoke-WebRequest -Uri $getReportResponse.reportDownloadDetails.url -OutFile $tempFile.FullName
                    Import-Csv -Path $tempFile.FullName
                }
                finally {
                    Remove-Item -Path $tempFile.FullName -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }
}

