﻿# Requires running with administrative privileges
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
    

    Write-Host "Failed to retrieve SMB shares: $_"
}


# Check and log antivirus status
try {
    $avStatus = Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntivirusProduct
    if ($avStatus) {
        foreach ($av in $avStatus) {
            Write-Host "Antivirus Name: $($av.displayName)"
            Write-Output "Antivirus Name: $($av.displayName)" | Out-File -FilePath "av_log.txt" -Append
        }
    } else {
        Write-Host "No antivirus product active or detected."
        Write-Output "No antivirus product active or detected." | Out-File -FilePath "av_log.txt" -Append
    }
} catch {
    Write-Host "Failed to retrieve antivirus status. Error: $_"
    Write-Output "Failed to retrieve antivirus status. Error: $_" | Out-File -FilePath "av_log.txt" -Append
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

# Check last write times of critical configuration files
$criticalFiles = @("C:\Windows\System32\drivers\etc\hosts", "C:\Windows\System32\config\SYSTEM")
foreach ($file in $criticalFiles) {
    $info = Get-Item $file
    Write-Host "$($info.Name) was last written on $($info.LastWriteTime)"
}

# Write a message indicating completion
Write-Host "System check complete."