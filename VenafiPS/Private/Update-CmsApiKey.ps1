function Update-CmsApiKey {
    <#
    .SYNOPSIS
    Rotate an API key

    .DESCRIPTION
    Rotate the active API key for a service account.
    If the key has never been rotated, a rotation request is made; otherwise a replacement is made.
    The new active key is returned along with its expiration date.

    .PARAMETER TrustClient
    TrustClient object containing the endpoint and authentication details for the service account.

    .PARAMETER RemoveInactiveKey
    Delete any inactive (previously rotated) API key after generating the new one.

    .EXAMPLE
    Update-CmsApiKey -TrustClient $client

    Rotate the API key and return the new active key.

    .EXAMPLE
    Update-CmsApiKey -TrustClient $client -RemoveInactiveKey

    Rotate the API key and delete the old inactive key from the previous rotation.

    .INPUTS
    None

    .OUTPUTS
    Hashtable with ApiKey (PSCredential) and Expires (datetime)
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'Converting to a secure string, its already plaintext')]
    param (
        [Parameter()]
        [switch] $KeepInactiveKey,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [TrustClient] $TrustClient
    )

    # there will be 2 keys at most.  1 always active.
    $existingKeys = Invoke-TrustRestMethod -TrustClient $TrustClient -Method Get -UriLeaf 'apikeys' | Select-Object -ExpandProperty apiKeys
    $existingActiveKey = $existingKeys | Where-Object apiKeyStatus -eq 'ACTIVE'
    $existingInactiveKey = $existingKeys | Where-Object apiKeyStatus -ne 'ACTIVE'

    # delete inactive key if exists
    if ( -not $KeepInactiveKey ) {
        if ( $existingInactiveKey ) {
            try {
                $deleteParams = @{
                    key = $existingInactiveKey.key
                }
                $null = Invoke-TrustRestMethod -TrustClient $TrustClient -Method Put -UriLeaf 'apikeys/rotation' -Body $deleteParams
                Write-Verbose "Deleted inactive API key"
            }
            catch {
                Write-Error "Failed to delete inactive API key, manual cleanup may be required"
            }
        }
        else {
            Write-Warning 'There are no inactive API keys to delete'
        }
    }

    $endpoint = if ( $KeepInactiveKey ) {
        'replacement'
    }
    else {
        'rotationrequest'
    }

    # determine validity end date for new key based on provided validity days or existing key validity window, if available
    if ( $existingActiveKey.validityEndDate ) {
        $validityEndDate = [datetime]::Parse($existingActiveKey.validityEndDate)
        $validityStartDate = if ( $existingActiveKey.validityStartDate ) { [datetime]::Parse($existingActiveKey.validityStartDate) } else { [datetime]::MinValue }
        $validityDays = [math]::Max([int][math]::Ceiling(($validityEndDate - $validityStartDate).TotalDays), 0)
    }
    else {
        $validityDays = 0
    }

    # regen the existing active key
    $regenParams = @{
        apiVersion   = 'ALL'
        key          = $existingActiveKey.key
        validityDays = $validityDays
    }
    $regenResponse = Invoke-TrustRestMethod -TrustClient $TrustClient -Method Post -UriLeaf "apikeys/$endpoint" -Body $regenParams

    if ( $regenResponse.apiKeys ) {
        Write-Debug "API key rotation response: $($regenResponse | ConvertTo-Json -Depth 5)"
        $newKey = $regenResponse.apiKeys | Where-Object apiKeyStatus -eq 'ACTIVE'
        Write-Verbose 'New API key generated'
    }
    else {
        throw 'Unexpected response from API key rotation endpoint, no apiKeys property found.'
    }

    $response = @{
        'ApiKey' = New-Object System.Management.Automation.PSCredential('ApiKey', ($newKey.key | ConvertTo-SecureString -AsPlainText -Force))
        Expires  = [datetime]::MaxValue
    }

    if ( $newKey.validityEndDate ) {
        $response.Expires = [datetime]::Parse($newKey.validityEndDate)
    }

    $response
}