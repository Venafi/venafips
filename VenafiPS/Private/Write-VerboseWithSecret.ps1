<#
.SYNOPSIS
Remove sensitive information when writing verbose info

.DESCRIPTION
Remove sensitive information when writing verbose info

.PARAMETER InputObject
JSON string or other object

.PARAMETER SecretName
Name of secret(s) to hide their values.  Default value is 'Password', 'AccessToken', 'RefreshToken', 'access_token', 'refresh_token', 'Authorization', 'KeystorePassword', 'tppl-api-key', 'CertficateData'

.INPUTS
InputObject

.OUTPUTS
None

.EXAMPLE
@{'password'='foobar'} | Write-VerboseWithSecret
Hide password value from hashtable

.EXAMPLE
$jsonString | Write-VerboseWithSecret
Hide value(s) from JSON string

#>
function Write-VerboseWithSecret {

    [CmdletBinding()]

    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowNull()]
        [AllowEmptyString()]
        [psobject] $InputObject,

        [Parameter()]
        [string[]] $PropertyName = @('AccessToken', 'Password', 'RefreshToken', 'access_token', 'refresh_token', 'Authorization', 'KeystorePassword', 'tppl-api-key', 'CertificateData', 'certificate', 'dekEncryptedPassword', 'PrivateKeyData')
    )

    begin {
    }

    process {

        if ( -not $InputObject -or [System.Management.Automation.ActionPreference]::SilentlyContinue -eq $VerbosePreference ) {
            return
        }

        Write-Debug ('Write-VerboseWithSecret input type: {0}' -f $InputObject.GetType().FullName)

        # default to json string
        $processMe = $InputObject
        if ($InputObject.GetType().FullName -ne 'System.String') {
            # if hashtable or other object, convert to json first
            $processMe = $InputObject | ConvertTo-Json -Depth 10 -Compress
        }

        foreach ($prop in $PropertyName) {

            # look for values in json string, eg. "Body": "{"Password":"MyPass"}" or {\"Password\":\"MyPass\"}
            if ( $processMe -match "\\?""$prop\\?"":\\?""(.*?)\\?""" ) {
                $processMe = $processMe.replace($matches[1], '***hidden***')
            }
        }

        Write-Verbose $processMe

    }
}
