# ESXi Host Health Dashboard Script

$ErrorActionPreference = 'Stop'

Import-Module VMware.PowerCLI

Set-PowerCLIConfiguration `
    -InvalidCertificateAction Ignore `
    -DisplayDeprecationWarnings:$false `
    -Confirm:$false | Out-Null

$server = "hdc2-vctr02-za.qdev.net"

$cred = Get-Credential -Message "Enter read-only credentials for $server"

$vi = Connect-VIServer -Server $server -Credential $cred

$report = @()

foreach ($esxHost in (Get-VMHost | Sort-Object Name)) {

    # CPU %
    $cpuPercent = 0

    if ($esxHost.CpuTotalMhz -gt 0) {
        $cpuPercent =
            ($esxHost.CpuUsageMhz / $esxHost.CpuTotalMhz) * 100
    }

    # Memory %
    $memoryPercent = 0

    if ($esxHost.MemoryTotalGB -gt 0) {
        $memoryPercent =
            ($esxHost.MemoryUsageGB / $esxHost.MemoryTotalGB) * 100
    }

    # Cluster
    try {
        $clusterName = (Get-Cluster -VMHost $esxHost).Name
    }
    catch {
        $clusterName = "Standalone"
    }

    # Config Issues
    $configIssues = 0

    if ($esxHost.ExtensionData.ConfigIssue) {
        $configIssues = $esxHost.ExtensionData.ConfigIssue.Count
    }

    # Alerts
    $alerts = @()

    if ($cpuPercent -ge 90) {
        $alerts += "CPU Usage Critical (>90%)"
    }
    elseif ($cpuPercent -ge 80) {
        $alerts += "CPU Usage Warning (>80%)"
    }

    if ($memoryPercent -ge 90) {
        $alerts += "Memory Usage Critical (>90%)"
    }
    elseif ($memoryPercent -ge 80) {
        $alerts += "Memory Usage Warning (>80%)"
    }

    if ($configIssues -gt 0) {
        $alerts += "Configuration Issues Present"
    }

    if ($esxHost.ConnectionState -ne "Connected") {
        $alerts += "Host Not Connected"
    }

    if ($esxHost.ExtensionData.Runtime.InMaintenanceMode) {
        $alerts += "Host In Maintenance Mode"
    }

    $healthStatus = "Healthy"

    if ($alerts.Count -gt 0) {
        $healthStatus = "Warning"
    }

    $report += [PSCustomObject]@{
        HostName           = $esxHost.Name
        Cluster            = $clusterName
        ESXiVersion        = $esxHost.Version
        BuildNumber        = $esxHost.Build
        CPUUsagePercent    = $cpuPercent
        MemoryUsagePercent = $memoryPercent
        ConnectionState    = $esxHost.ConnectionState
        MaintenanceMode    = $esxHost.ExtensionData.Runtime.InMaintenanceMode
        ConfigIssues       = $configIssues
        HealthStatus       = $healthStatus
        AlertDefinitions   = ($alerts -join "; ")
        LastUpdated        = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}

# Display Results
$report | Format-Table -AutoSize

# Save JSON
$jsonPath = Join-Path $PSScriptRoot "..\Data\hosthealth.json"

$report |
ConvertTo-Json -Depth 5 |
Out-File $jsonPath

Write-Host ""
Write-Host "hosthealth.json created successfully" -ForegroundColor Green

Disconnect-VIServer -Server $vi -Confirm:$false | Out-Null