param(
    [string]$SiteName = "HarnessTroubleshootingLab",
    [string]$AppPoolName = "HarnessTroubleshootingLabPool",
    [string]$PhysicalPath = "C:\\inetpub\\HarnessTroubleshootingLab"
)

$ErrorActionPreference = "Stop"
Import-Module WebAdministration

$backupPath = Join-Path "C:\\HarnessLabBackup" $SiteName
Write-Host "=== Rolling back IIS lab ==="

if (Test-Path "IIS:\\Sites\\$SiteName") {
    Stop-Website -Name $SiteName -ErrorAction SilentlyContinue
}

if (Test-Path $backupPath) {
    Write-Host "Restoring backup from $backupPath"
    if (Test-Path $PhysicalPath) { Remove-Item -Recurse -Force $PhysicalPath }
    Copy-Item -Recurse -Force $backupPath $PhysicalPath

    if (Test-Path "IIS:\\AppPools\\$AppPoolName") {
        Start-WebAppPool -Name $AppPoolName
    }
    if (Test-Path "IIS:\\Sites\\$SiteName") {
        Start-Website -Name $SiteName
    }
} else {
    Write-Warning "No previous backup exists. Removing lab website instead."
    if (Test-Path "IIS:\\Sites\\$SiteName") { Remove-Website -Name $SiteName }
}

Write-Host "Rollback completed."
