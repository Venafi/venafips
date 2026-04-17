function Get-VenafiSession {

    process {
        # find out if a session was passed in as a parameter from the calling function in the stack.
        # this should only come from the first function which was initiated by the user

        # this provides 2 benefits:
        # - nested functions do not need VenafiSession provided
        # - we can pipe between functions which use different sessions, eg. export from server1 -> import to server2.
        #   this is only possible when core function processing occurs in the end block as the call stack during the process
        #   block including the calling and current function and their parameters.  there shouldn't be too many functions
        #   where we need to go between environments anyway, mainly export and import.  perhaps revisit this in the future if needed.

        # if a session isn't explicitly provided, fallback to the script scope session variable created with New-VenafiSession

        $stack = Get-PSCallStack
        $venafiSessionNested = $stack.InvocationInfo.BoundParameters.VenafiSession | Select-Object -First 1

        $sess = if ($venafiSessionNested) {
            $venafiSessionNested
            Write-Debug 'Using nested session from call stack'
        }
        elseif ( $script:VenafiSession ) {
            $script:VenafiSession
            Write-Debug 'Using script session'
        }
        # elseif ( $env:VDC_TOKEN ) {
        #     $env:VDC_TOKEN
        #     Write-Debug 'Using Certificate Manager, Self-Hosted token environment variable'
        # }
        # elseif ( $env:VC_KEY ) {
        #     $env:VC_KEY
        #     Write-Debug 'Using Certificate Manager, SaaS key environment variable'
        # }
        else {
            throw [System.ArgumentException]::new('Please run New-VenafiSession or provide a valid auth value to -VenafiSession.')
        }

        # find out the platform from the calling function
        $platform = switch ($stack[1].Command) {
            { $_ -match '-Ngts' } {
                'NGTS'
            }
            { $_ -match '-Vc' } {
                'VC'
            }
            { $_ -match '-Vdc' } {
                'VDC'
            }
            Default {
            # we don't know the platform, eg. -Venafi functions.  this won't happen often
                $null
            }
        }

        # make sure the auth type and url we have match
        # this keeps folks from calling a vaas function with a token and vice versa
        # if we don't know the platform, do not fail and allow it to fail later, most likely in Invoke-VenafiRestMethod
        if ( $Platform -and $Platform -ne $sess.Platform ) {
            throw "You are attemping to call a $Platform function with an invalid session"
        }

            # Check token expiration and auto-refresh if possible
            if ($sess -is [VenafiSession]) {
                if ($sess.Auth -and $sess.Auth.Expires -and $sess.Auth.Expires -gt [datetime]::MinValue) {
                    $secondsRemaining = [math]::Round((($sess.Auth.Expires.ToUniversalTime()) - [DateTime]::UtcNow).TotalSeconds, 0)
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
                        throw 'Access token has expired and cannot be automatically refreshed. Please authenticate again with New-VenafiSession.'
                    }
                }
            }

        $sess
    }
}
