param (
    [System.Boolean]$mst = $false
)
$cmm = "$PSScriptRoot\ControlMyMonitor.exe"
$monitor = "Secondary"  # Select secondary monitor(s)
$vcpCode = "D6"         # VCP Code for Power Mode
$offCode = "4"          # Off
$onCode = "1"           # On
$interval = 250         # Time keeping script alive

$global:kernelEventDetected = $false
$global:dellEventDetected = $false
$eventWindow = 3

# Cycle monitors if both events are triggered
function global:Update-Toggle {
    if (-not $mst) {
        $tz = "Mountain Standard Time" 
    }
    if ($global:kernelEventDetected -eq $true -and $global:dellEventDetected -eq $true -and $tz -like "*Mountain Standard Time*") {
        Update-Monitor
        $global:kernelEventDetected = $false
        $global:dellEventDetected = $false
    }
}

# Power cycle the monitor(s) 
function global:Update-Monitor {
    Write-Host "$(Get-Date -Format T): Cycling monitor..." -ForegroundColor Cyan
    & $cmm /SetValue $monitor $vcpCode $offCode
    Start-Sleep -Milliseconds 500
    & $cmm /SetValue $monitor $vcpCode $onCode
}

# In case we already registered these events
Get-EventSubscriber | Where-Object SourceIdentifier -in 'PowerSourceEvent','DellHubEvent' | Unregister-Event

# Create watchers
$sysLog = New-Object System.Diagnostics.EventLog("System")
$sysLog.EnableRaisingEvents = $true
$appLog = New-Object System.Diagnostics.EventLog("Application")
$appLog.EnableRaisingEvents = $true

# Register an action when a new entry is written
Register-ObjectEvent `
-InputObject $sysLog `
-EventName EntryWritten `
-SourceIdentifier PowerSourceEvent `
-Action {
    try {
        $e = $Event.SourceEventArgs.Entry
        if ($e.Source -eq "Microsoft-Windows-Kernel-Power" -and $e.InstanceId -eq 105) { 
            $global:kernelEventDetected = $true
            Update-Toggle
            Start-Sleep -Seconds $eventWindow
            $global:kernelEventDetected = $false
            $global:dellEventDetected = $false
        }
    }
    catch {
        Write-Error "Kernel Event Handler Failed: $_"
    }
}

Register-ObjectEvent `
-InputObject $appLog `
-EventName EntryWritten `
-SourceIdentifier DellHubEvent `
-Action {
    try {
        $e = $Event.SourceEventArgs.Entry
        if ($e.Source -eq "DellTechHub" -and $e.Message -like "*PowerEvent handled successfully*") {
            $global:dellEventDetected = $true
            Update-Toggle
            Start-Sleep -Seconds $eventWindow
            $global:kernelEventDetected = $false
            $global:dellEventDetected = $false
        }
    }
    catch {
        Write-Error "Dell Event Handler Failed: $_"
    }
}

# Script kept alive so that local variables can be accessed
while ($true) { 
    $tz = Get-Timezone | Select-Object -Property Id
    Start-Sleep -Milliseconds $interval
}