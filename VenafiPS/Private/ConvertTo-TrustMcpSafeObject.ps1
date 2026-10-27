function ConvertTo-TrustMcpSafeObject {
    <#
    .SYNOPSIS
    Prepare an object to be returned from an MCP tool

    .DESCRIPTION
    Recursively convert an object into plain hashtables/arrays which serialize consistently on PS 5.1 and 7.
    Secrets are redacted, dates are converted to ISO 8601, enums to strings, and long strings and arrays are truncated
    so responses stay a reasonable size for a language model.

    .PARAMETER InputObject
    Object to convert

    .PARAMETER MaxDepth
    Maximum depth to traverse.  Anything deeper is converted to a string.

    .PARAMETER MaxStringLength
    Strings longer than this are truncated

    .PARAMETER MaxArrayCount
    Arrays longer than this are truncated
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowNull()]
        [object] $InputObject,

        [Parameter()]
        [int] $MaxDepth = 8,

        [Parameter()]
        [int] $MaxStringLength = 2000,

        [Parameter()]
        [int] $MaxArrayCount = 200,

        [Parameter(DontShow)]
        [int] $Depth = 0
    )

    begin {
        $redactPattern = '(?i)(password|passphrase|secret|privatekey|private_key|apikey|api_key|token|pkcs12|pfx|credential|connectionDetails|pairingcode|pairing_code)'
        # names which only describe a secret, eg. OAuth Token Scope or apiKeyId, are not secrets themselves.
        # the last word must be separated by a space, _, :, -, or camel case.  anything with 'secret' is always redacted, eg. a secret id can be the secret
        $describesPattern = '(?i)(?:[\s_:\-]|(?-i:(?<=[a-z])(?=[A-Z])))(id|ids|scope|scopes|type|algorithm|complexity|expires|expiration|expiry|hint|url|uri|endpoint)$'
        $isSecretName = {
            param([string] $Name)
            ($Name -match $redactPattern) -and (($Name -match '(?i)secret') -or ($Name -notmatch $describesPattern))
        }
        $childParams = @{
            MaxDepth        = $MaxDepth
            MaxStringLength = $MaxStringLength
            MaxArrayCount   = $MaxArrayCount
            Depth           = $Depth + 1
        }
    }

    process {
        $obj = $InputObject

        if ( $null -eq $obj ) { return $null }

        if ( $obj -is [System.Security.SecureString] -or $obj -is [pscredential] ) { return '[redacted]' }

        if ( $obj -is [string] ) {
            if ( $obj.Length -gt $MaxStringLength ) {
                return ('{0}...[truncated {1} chars]' -f $obj.Substring(0, $MaxStringLength), ($obj.Length - $MaxStringLength))
            }
            return $obj
        }

        if ( $obj -is [datetime] ) { return $obj.ToUniversalTime().ToString('o') }
        if ( $obj -is [datetimeoffset] ) { return $obj.UtcDateTime.ToString('o') }
        if ( $obj -is [enum] -or $obj -is [guid] -or $obj -is [version] -or $obj -is [timespan] ) { return $obj.ToString() }
        if ( $obj -is [bool] -or $obj -is [char] -or $obj.GetType().IsPrimitive -or $obj -is [decimal] ) { return $obj }

        if ( $Depth -ge $MaxDepth ) { return $obj.ToString() }

        if ( $obj -is [System.Collections.IDictionary] ) {
            $out = [ordered]@{}
            foreach ( $key in $obj.Keys ) {
                if ( & $isSecretName "$key" ) {
                    $out["$key"] = '[redacted]'
                }
                else {
                    $out["$key"] = ConvertTo-TrustMcpSafeObject -InputObject $obj[$key] @childParams
                }
            }
            return $out
        }

        if ( $obj -is [System.Collections.IEnumerable] ) {
            $items = @($obj)
            $out = [System.Collections.Generic.List[object]]::new()
            foreach ( $item in ($items | Select-Object -First $MaxArrayCount) ) {
                $out.Add((ConvertTo-TrustMcpSafeObject -InputObject $item @childParams))
            }
            if ( $items.Count -gt $MaxArrayCount ) {
                $out.Add(('...[truncated {0} items]' -f ($items.Count - $MaxArrayCount)))
            }
            # prevent the pipeline from unrolling the array
            return , $out.ToArray()
        }

        # PSCustomObject and class instances, eg. CmObject
        $out = [ordered]@{}
        foreach ( $prop in $obj.PSObject.Properties ) {
            if ( $prop.MemberType -notin 'NoteProperty', 'Property', 'AliasProperty' ) { continue }
            if ( & $isSecretName $prop.Name ) {
                $out[$prop.Name] = '[redacted]'
                continue
            }
            try {
                $out[$prop.Name] = ConvertTo-TrustMcpSafeObject -InputObject $prop.Value @childParams
            }
            catch {
                # some class properties throw on access
                $out[$prop.Name] = $null
            }
        }
        $out
    }
}
