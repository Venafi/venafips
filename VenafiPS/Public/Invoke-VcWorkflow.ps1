function Invoke-VcWorkflow {
    <#
    .SYNOPSIS
    Start a machine or machine identity workflow

    .DESCRIPTION
    Start a workflow to either test machine credentials or provision or discover machine identities

    .PARAMETER ID
    Machine or machine identity id for the workflow to trigger.
    Workflows 'Test' and 'GetConfig' require the machine ID.
    Workflows 'Provision' and 'Discover' require the machine identity ID.

    .PARAMETER Workflow
    The name of the workflow to trigger.
    Valid values are 'Test', 'GetConfig', 'Provision', or 'Discover'.

    .PARAMETER ThrottleLimit
    Limit the number of threads when running in parallel; the default is 100.
    Setting the value to 1 will disable multithreading.
    On PS v5 the ThreadJob module is required.  If not found, multithreading will be disabled.


    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A Certificate Manager, SaaS key can also provided.

    .EXAMPLE
    Invoke-VcWorkflow -ID '1345baf1-fc56-49b7-aa03-78e35bfe0a1a' -Workflow 'Provision'

    ID                                   Success WorkflowName WorkflowID
    --                                   ------- ------------ ----------
    1345baf1-fc56-49b7-aa03-78e35bfe0a1a    True Provision    345b9d33-8c8a-4d4b-9fea-124f3a72f957

    Trigger provisioning

    .EXAMPLE
    Invoke-VcWorkflow -ID '1345baf1-fc56-49b7-aa03-78e35bfe0a1a' -Workflow 'Test'

    ID               : 1345baf1-fc56-49b7-aa03-78e35bfe0a1a
    Success          : False
    WorkflowName     : Test
    WorkflowID       : 345b9d33-8c8a-4d4b-9fea-124f3a72f957
    Error            : failed to connect to Citrix ADC: [ERROR] nitro-go: Failed to create resource of type login, name=login, err=failed: 401 Unauthorized ({ "errorcode": 354,
                       "message": "Invalid username or password", "severity": "ERROR" })

    Trigger test connection, but it failed

    .EXAMPLE
    Find-VcMachineIdentity -Filter @('and', @('certificateValidityEnd', 'lt', (get-date).AddDays(30)), @('certificateValidityEnd', 'gt', (get-date))) | ForEach-Object {
        $renewResult = $_ | Invoke-VenafiCertificateAction -Renew
        # optionally add renew validation
        $_ | Invoke-VcWorkflow -Workflow 'Provision'
    }

    ID                                   Success WorkflowName WorkflowID
    --                                   ------- ------------ ----------
    1345baf1-fc56-49b7-aa03-78e35bfe0a1a    True Provision    345b9d33-8c8a-4d4b-9fea-124f3a72f957
    89fa4370-2026-11ee-8a18-ff9579bb988e    True Provision    7598917c-7027-4927-be73-e592bcc4c567

    Renew and provision all machine identities with certificates expiring within 30 days

    .INPUTS
    ID

    .OUTPUTS
    pscustomobject

    .NOTES
    Currently no eu or au region support when providing an api key directly
    Use a session from New-VenafiSession
    #>


    [CmdletBinding()]
    [Alias('Invoke-VaasWorkflow')]

    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('machineID', 'machineIdentityID')]
        [string] $ID,

        [Parameter()]
        [ValidateSet('Test', 'GetConfig', 'Provision', 'Discover')]
        [string] $Workflow = 'Test',

        [Parameter()]
        [int32] $ThrottleLimit = 100,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {
        Test-VenafiSession $PSCmdlet.MyInvocation
        $allIDs = [System.Collections.Generic.List[string]]::new()
    }

    process {
        $allIDs.Add($ID)
    }

    end {

        Invoke-VenafiParallel -InputObject $allIDs -ScriptBlock {
            $workflow = $using:Workflow
            # $allIDs | ForEach-Object {
            $thisID = $PSItem
            $thisWebSocketID = (New-Guid).Guid

            try {

                $WS = New-Object System.Net.WebSockets.ClientWebSocket
                $CT = New-Object System.Threading.CancellationToken

                if ( $script:VenafiSession -is [PSCustomObject] ) {
                    $server = $script:VenafiSession.Server.Replace('https://', '')
                    $WS.Options.SetRequestHeader("tppl-api-key", $script:VenafiSession.Key.GetNetworkCredential().password)
                }
                else {
                    # TODO: defaults to US, add other region support
                    # for other regions, create a session first
                    $server = ($script:VcRegions).'us'
                    $server = $server.Replace('https://', '')
                    $WS.Options.SetRequestHeader("tppl-api-key", $script:VenafiSession)
                }
                $URL = 'wss://{0}/ws/notificationclients/{1}' -f $server, $thisWebSocketID

                #Get connected
                $Conn = $WS.ConnectAsync($URL, $CT)

                While ( !$Conn.IsCompleted ) {
                    Start-Sleep -Milliseconds 100
                }

                Write-Verbose "Connecting to $($URL)..."
                $Size = 8192
                $Array = [byte[]] @(, 0) * $Size

                #Send Starting Request
                $Command = [System.Text.Encoding]::UTF8.GetBytes("ACTION=Command")
                $Send = New-Object System.ArraySegment[byte] -ArgumentList @(, $Command)
                $Conn = $WS.SendAsync($Send, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $CT)

                While (!$Conn.IsCompleted) {
                    Start-Sleep -Milliseconds 100
                }

                #Start reading the received items
                $Recv = New-Object System.ArraySegment[byte] -ArgumentList @(, $Array)
                $Conn = $WS.ReceiveAsync($Recv, $CT)

                Write-Verbose 'Triggering workflow'

                $triggerParams = @{
                    UriLeaf = "machines/$thisID/workflows"
                    Method  = 'Post'
                    Body    = @{
                        'workflowInput' = @{
                            'wsClientId' = $thisWebSocketID
                        }
                        'workflowName'  = 'testConnection'
                    }

                }

                switch ($Workflow) {
                    'GetConfig' {
                        $triggerParams.Body.workflowName = 'getTargetConfiguration'
                    }

                    'Provision' {
                        $triggerParams.Body.workflowName = 'provisionCertificate'
                        $triggerParams.UriLeaf = "machineidentities/$thisID/workflows"
                    }

                    'Discover' {
                        $triggerParams.Body.workflowName = 'discoverCertificates'
                        $triggerParams.UriLeaf = "machines/$thisID/workflows"
                    }
                }

                $null = Invoke-VenafiRestMethod @triggerParams

                While (!$Conn.IsCompleted) {
                    Start-Sleep -Milliseconds 100
                }

                $response = ''
                $Recv.Array[0..($Conn.Result.Count - 1)] | ForEach-Object { $response += [char]$_ }

                Write-Verbose $response

                $responseObj = $response | ConvertFrom-Json

                $out = [pscustomobject]@{
                    ID           = $thisID
                    Success      = $true
                    WorkflowName = $Workflow
                    WorkflowID   = $thisWebSocketID
                }

                if ( $responseObj.data.result -ne $true ) {
                    $out.Success = $false
                    try {
                        $out | Add-Member @{'Error' = $responseObj.data.result.message | ConvertFrom-Json }
                    }
                    catch {
                        $out | Add-Member @{'Error' = $responseObj.data.result.message }
                    }
                }

                $out

            }
            finally {
                if ( $WS ) {
                    $WS.Dispose()
                }
            }
        } -ThrottleLimit $ThrottleLimit -ProgressTitle 'Invoking workflow'
    }
}

