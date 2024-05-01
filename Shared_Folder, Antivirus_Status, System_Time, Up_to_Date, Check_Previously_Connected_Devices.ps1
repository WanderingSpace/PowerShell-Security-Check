# Requires running with administrative privileges
{
    Write-Host "This script requires administrator privileges."
    exit
}

# Check for shared folders with network access
Write-Host "Checking shared folders with network access..."
try {
    $shares = Get-SmbShare -ErrorAction Stop
    $nonSpecialShares = $shares | Where-Object { -not $_.Special }
    if ($nonSpecialShares) {
        $nonSpecialShares
    } else {
        Write-Host "No non-special shared folders found."
    }
} catch {
    
}
    Write-Host "Failed to retrieve SMB shares: $_"



# Check and log antivirus status
try {
    $avStatus = Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntivirusProduct
    $avStatus | ForEach-Object {
        $onAccessScanning = "Unknown"
        switch ($_.productState) {
            262144 { $onAccessScanning = "Enabled and up to date" }
            262160 { $onAccessScanning = "Enabled and out of date" }
            393216 { $onAccessScanning = "Disabled and up to date" }
            393232 { $onAccessScanning = "Disabled and out of date" }
            default { $onAccessScanning = "Status Unknown" }
        }
        Write-Output "Antivirus Name: $($_.displayName) - OnAccess Scanning: $onAccessScanning" | Out-File -FilePath "av_log.txt" -Append
    }
} catch {
    Write-Host "Failed to retrieve antivirus status."
}

# Log system time changes (Monitor event ID 4616 in the Security log)
try {
    $timeChangeEvents = Get-EventLog -LogName Security -InstanceId 4616 -Newest 50 -ErrorAction Stop
    if ($timeChangeEvents) {
        $timeChangeEvents | ForEach-Object {
            $whoChanged = $_.ReplacementStrings[6] + " (" + $_.ReplacementStrings[1] + ")"
            $newTime = $_.ReplacementStrings[4]
            $oldTime = $_.ReplacementStrings[3]
            Write-Output "System time changed: $($_.TimeGenerated) by $whoChanged from $oldTime to $newTime" | Out-File -FilePath "time_change_log.txt" -Append
        }
    } else {
        Write-Host "No recent system time changes detected."
    }
} catch {
    Write-Host "Failed to retrieve or log system time changes: $_"
}

# Check if computer is up to date
Write-Host "Checking if the computer is up to date..."
try {
    $updates = Get-WmiObject -Query "SELECT * FROM Win32_QuickFixEngineering"
    $updates | ForEach-Object {
        Write-Host "Installed Update: $($_.HotFixID) - $($_.Description) on $($_.InstalledOn)"
    }
} catch {
    Write-Host "Failed to retrieve update information."
}

# Check previously connected devices
Write-Host "Checking previously connected devices..."
Get-WmiObject -Query "SELECT * FROM Win32_PnPEntity" | Where-Object { $_.ConfigManagerErrorCode -eq 0 } | Select-Object Name, Description, Status, DeviceID

# Write a message indicating completion
Write-Host "System check complete."
