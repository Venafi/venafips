function Test-VenafiSession {
    <#
    .SYNOPSIS
    Validate authentication session/key/token

    .DESCRIPTION
    Validate authentication session from New-VenafiSession, a Certificate Manager, SaaS key, or Certificate Manager, Self-Hosted token.

    .PARAMETER InvocationInfo
    InvocationInfo from calling function

    .EXAMPLE
    Test-VenafiSession $PSCmdlet.MyInvocation

    #>

    [CmdletBinding()]

    param (
        [Parameter(Mandatory, Position = 0)]
        [System.Management.Automation.InvocationInfo] $InvocationInfo
    )

    process {

        # moving the functionality into Get-VenafiSession which will be called by
        # the Invoke functions
        return

        if ( (Get-PSCallStack).Count -gt 3 -and -not $InvocationInfo.BoundParameters['VenafiSession'] ) {
            # nested function, no need to continue testing session since it was already done
            return
        }

        $Platform = if ( $InvocationInfo.MyCommand -match '-Vc' ) {
            'VC'
        }
        elseif ($InvocationInfo.MyCommand -match '-Vdc') {
            'VDC'
        }
        else {
            throw 'Venafi Platform, VC or VDC, could not be determined'
        }

        if ( $InvocationInfo.BoundParameters['VenafiSession'] ) {
            $VenafiSession = $InvocationInfo.BoundParameters['VenafiSession']
        }
        else {
            if ( $env:VDC_TOKEN ) {
                $VenafiSession = $env:VDC_TOKEN
            }
            elseif ( $env:VC_KEY ) {
                $VenafiSession = $env:VC_KEY
            }
            elseif ( $script:VenafiSession ) {
                $VenafiSession = $script:VenafiSession
            }
            else {
                throw 'Please run New-VenafiSession or provide a Certificate Manager, SaaS key or Certificate Manager, Self-Hosted token.'
            }
        }

        switch ($VenafiSession.GetType().Name) {
            'PSCustomObject' {

                if ( -not $VenafiSession.Key -and -not $VenafiSession.Token ) {
                    throw "You must first connect to either Certificate Manager, SaaS or a Certificate Manager, Self-Hosted server with New-VenafiSession"
                }

                # make sure the auth type and url we have match
                # this keeps folks from calling a vaas function with a token and vice versa
                if ( $Platform -and $Platform -ne $VenafiSession.Platform ) {
                    throw ('{0} is only accessible for {1}' -f $InvocationInfo.InvocationName, $Platform)
                }

                if ( $Platform -eq 'VDC' ) {
                    if ( $VenafiSession.Token.Expires -and $VenafiSession.Token.Expires -lt (Get-Date).ToUniversalTime() ) {
                        throw 'Certificate Manager, Self-Hosted token has expired.  Execute New-VenafiSession and rerun your command.'
                    }
                }

                # don't perform .Validate as we do above since this
                # isn't the class, it's a converted pscustomobject
                # for Invoke-VenafiParallel usage
                break
            }

            'String' {

                # key or token provided directly, not via New-VenafiSession

                break
            }

            Default {
                throw "Unknown session '$VenafiSession'.  Please run New-VenafiSession or provide a Certificate Manager, SaaS key or Certificate Manager, Self-Hosted access token."
            }
        }

        # $script:VenafiSessionNested = $VenafiSession
        # $script:PlatformNested = $Platform
    }
}
