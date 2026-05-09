function Get-TrustClient {

    process {
        # find out if a session was passed in as a parameter from the calling function in the stack.
        # this should only come from the first function which was initiated by the user

        # this provides 2 benefits:
        # - nested functions do not need TrustClient provided
        # - we can pipe between functions which use different sessions, eg. export from server1 -> import to server2.
        #   this is only possible when core function processing occurs in the end block as the call stack during the process
        #   block including the calling and current function and their parameters.  there shouldn't be too many functions
        #   where we need to go between environments anyway, mainly export and import.  perhaps revisit this in the future if needed.

        # if a session isn't explicitly provided, fallback to the script scope session variable created with New-TrustClient

        $stack = Get-PSCallStack
        $trustClientNested = $stack.InvocationInfo.BoundParameters.TrustClient | Select-Object -First 1

        $sess = if ($trustClientNested) {
            $trustClientNested
            Write-Debug 'Using nested session from call stack'
        }
        elseif ( $script:TrustClient ) {
            $script:TrustClient
            Write-Debug 'Using script session'
        }
        # elseif ( $env:CM_TOKEN ) {
        #     $env:CM_TOKEN
        #     Write-Debug 'Using Certificate Manager, Self-Hosted token environment variable'
        # }
        # elseif ( $env:VC_KEY ) {
        #     $env:VC_KEY
        #     Write-Debug 'Using Certificate Manager, SaaS key environment variable'
        # }
        else {
            throw [System.ArgumentException]::new('Please run New-TrustClient or provide a valid auth value to -TrustClient.')
        }

        # find out the platform from the calling function
        $platform = switch ($stack[1].Command) {
            { $_ -match '-Ngts' } {
                'NGTS'
            }
            { $_ -match '-Vc' } {
                'VC'
            }
            { $_ -match '-Cm' } {
                'CM'
            }
            Default {
            # we don't know the platform, eg. -Venafi functions.  this won't happen often
                $null
            }
        }

        # make sure the auth type and url we have match
        # this keeps folks from calling a vaas function with a token and vice versa
        # if we don't know the platform, do not fail and allow it to fail later, most likely in Invoke-TrustRestMethod
        if ( $Platform -and $Platform -ne $sess.Platform ) {
            throw "You are attemping to call a $Platform function with an invalid session"
        }

            # Check token expiration and auto-refresh if possible
            if ($sess.Expires -and $sess.Expires -gt [datetime]::MinValue) {
                $secondsRemaining = [math]::Round((($sess.Expires.ToUniversalTime()) - [DateTime]::UtcNow).TotalSeconds, 0)
                Write-Verbose ("Access token expires in {0} seconds" -f $secondsRemaining)
            }

            if ($sess.IsExpired()) {
                Write-Verbose 'Access token is expired or nearing expiration'
                if ($sess.CanRefresh()) {
                    Write-Verbose 'Automatically refreshing access token'
                    try {
                        Invoke-SessionRefresh -Session $sess
                    }
                    catch {
                        throw "Failed to auto-refresh token: $($_.Exception.Message)"
                    }
                }
                else {
                    throw 'Access token has expired and cannot be automatically refreshed. Please authenticate again with New-TrustClient.'
                }
            }

        $sess
    }
}
