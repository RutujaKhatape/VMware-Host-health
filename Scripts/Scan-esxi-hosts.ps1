# ESXi Health Check Script
#version1.0
$ErrorActionPreference = 'Stop'

Import-Module VMware.PowerCLI
Set-PowerCLIConfiguration -Scope Session -InvalidCertificateAction Ignore -Confirm:$false | Out-Null
Set-PowerCLIConfiguration -Scope Session -DisplayDeprecationWarnings:$false -Confirm:$false | Out-Null

$server = 'hdc2-vctr02-za.qdev.net'

# Secure credential prompt with masked password input.
$cred = Get-Credential -Message "Enter read-only credentials for $server"

$vi = Connect-VIServer -Server $server -Credential $cred

$hosts = Get-VMHost | Sort-Object Name
$alarmCache = @{}

$rows = foreach ($h in $hosts) {
    $view = Get-View -Id $h.Id -Property Name,Runtime.ConnectionState,Runtime.PowerState,Summary.OverallStatus,TriggeredAlarmState

    if (-not $view.TriggeredAlarmState -or $view.TriggeredAlarmState.Count -eq 0) {
        [pscustomobject]@{
            HostName        = $view.Name
            ConnectionState = [string]$view.Runtime.ConnectionState
            PowerState      = [string]$view.Runtime.PowerState
            OverallStatus   = [string]$view.Summary.OverallStatus
            AlarmStatus     = 'green'
            AlarmName       = '(none)'
            AlarmSeverity   = 'info'
            Acknowledged    = ''
            Time            = ''
        }
        continue
    }

    foreach ($a in $view.TriggeredAlarmState) {
        $alarmId = [string]$a.Alarm
        if (-not $alarmCache.ContainsKey($alarmId)) {
            $alarmCache[$alarmId] = (Get-View -Id $a.Alarm -Property Info.Name).Info.Name
        }

        $severity = [string]$a.OverallStatus
        if ([string]::IsNullOrWhiteSpace($severity)) {
            $severity = 'unknown'
        }

        [pscustomobject]@{
            HostName        = $view.Name
            ConnectionState = [string]$view.Runtime.ConnectionState
            PowerState      = [string]$view.Runtime.PowerState
            OverallStatus   = [string]$view.Summary.OverallStatus
            AlarmStatus     = [string]$a.OverallStatus
            AlarmName       = $alarmCache[$alarmId]
            AlarmSeverity   = if ($severity -eq 'red') { 'error' } elseif ($severity -eq 'yellow') { 'warning' } else { $severity }
            Acknowledged    = [string]$a.Acknowledged
            Time            = if ($a.Time) { Get-Date $a.Time -Format 'yyyy-MM-dd HH:mm:ss' } else { '' }
        }
    }
}

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$outFile = "esxi_host_alarm_scan_$timestamp.csv"
$rows | Export-Csv -Path $outFile -NoTypeInformation

$summary = $rows | Group-Object AlarmSeverity | Sort-Object Name | Select-Object Name,Count

Write-Host "Connected to: $($vi.Name)"
Write-Host "Hosts scanned: $($hosts.Count)"
Write-Host "Report file: $outFile"
Write-Host "Severity summary:"
$summary | Format-Table -AutoSize | Out-String | Write-Host
$rows | Sort-Object HostName,AlarmSeverity | Format-Table -AutoSize | Out-String -Width 220 | Write-Host

Disconnect-VIServer -Server $vi -Confirm:$false | Out-Null
