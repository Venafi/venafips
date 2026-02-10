function Get-VcTag {
    <#
    .SYNOPSIS
    Get tag names and values

    .DESCRIPTION
    Get 1 or all tags.
    Tag values will be provided.

    .PARAMETER Tag
    Tag name or name:value pair to get.
    If a value is provided, the tag must have that value to be returned.

    .PARAMETER All
    Get all tags

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A Certificate Manager, SaaS key can also provided.key can also provided.

    .INPUTS
    Name

    .EXAMPLE
    Get-VcTag -Tag 'MyTag'

    Get a single tag

    .EXAMPLE
    Get-VcTag -Tag 'MyTag:MyValue'

    Get a single tag only if it has the specified value

    .EXAMPLE
    Get-VcTag -All

    Get all tags

    #>

    [CmdletBinding()]

    param (

        [Parameter(Mandatory, ParameterSetName = 'ID', ValueFromPipelineByPropertyName, Position = 0)]
        [Alias('Name')]
        [string] $Tag,

        [Parameter(Mandatory, ParameterSetName = 'All')]
        [switch] $All,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {
        Test-VenafiSession $PSCmdlet.MyInvocation
    }

    process {

        if ( $PSCmdlet.ParameterSetName -eq 'All' ) {
            $allTags = Invoke-VenafiRestMethod -UriLeaf 'tags' | Select-Object -ExpandProperty tags
            $allValues = Invoke-VenafiRestMethod -UriLeaf 'tags/values' | Select-Object -ExpandProperty values

            $allTags | Select-Object @{'n' = 'tagId'; 'e' = { $_.key } },
            @{
                'n' = 'value'
                'e' = {
                    $thisId = $_.id
                    $thisTagValues = $allValues | Where-Object tagId -eq $thisId
                    if ( $thisTagValues ) {
                        @($thisTagValues.value)
                    }
                    else {
                        $null
                    }
                }
            }
        }
        else {
            if ($Tag.Contains(':')) {
                $requestName, $requestValue = $Tag.Split(':', 2)
            }
            else {
                $requestName = $Tag
            }

            $thisTag = Invoke-VenafiRestMethod -UriLeaf "tags/$requestName"
            $thisTagValues = Invoke-VenafiRestMethod -UriLeaf "tags/$requestName/values" | Select-Object -ExpandProperty values

            if ( $thisTag ) {

                if ( $requestValue ) {
                    if ( $thisTagValues ) {
                        if ( -not ( $requestValue -in $thisTagValues.value ) ) {
                            Write-Verbose "The tag '$requestName' exists but does not have a value of '$requestValue'"
                            return
                        }
                    }
                    else {
                        Write-Verbose "The tag '$requestName' was found but does not have any values"
                        return
                    }
                }

                return @{
                    $thisTag.key = $thisTagValues.value
                }
            }
        }
    }
}


