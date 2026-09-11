param(
    [string]$FailureMode = "NONE",
    [string]$ReleaseVersion = "v1",
    [string]$SiteName = "HarnessTroubleshootingLab",
    [string]$AppPoolName = "HarnessTroubleshootingLabPool",
    [string]$PhysicalPath = "C:\\inetpub\\HarnessTroubleshootingLab",
    [int]$Port = 8085
)

$ErrorActionPreference = "Stop"

Write-Host "=== Windows/IIS deployment ==="
Write-Host "Computer: $env:COMPUTERNAME"
Write-Host "User: $env:USERNAME"
Write-Host "FailureMode: $FailureMode"
Write-Host "ReleaseVersion: $ReleaseVersion"

if ($FailureMode -eq "WINDOWS_SCRIPT_FAILURE") {
    Write-Error "INTENTIONAL LAB FAILURE: deployment script exited before IIS configuration."
    exit 42
}

Import-Module WebAdministration

$backupRoot = "C:\\HarnessLabBackup"
$backupPath = Join-Path $backupRoot $SiteName
New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null

if (Test-Path $PhysicalPath) {
    if (Test-Path $backupPath) { Remove-Item -Recurse -Force $backupPath }
    Copy-Item -Recurse -Force $PhysicalPath $backupPath
}

New-Item -ItemType Directory -Force -Path $PhysicalPath | Out-Null

@"
<!doctype html>
<html>
<head><title>Harness Windows Lab</title></head>
<body>
<h1>Harness Windows IIS Troubleshooting Lab</h1>
<p>Release: $ReleaseVersion</p>
<p>Host: $env:COMPUTERNAME</p>
<p>Deployed: $(Get-Date -Format o)</p>
</body>
</html>
"@ | Set-Content -Encoding UTF8 (Join-Path $PhysicalPath "index.html")

"OK - Windows IIS - $ReleaseVersion" | Set-Content -Encoding ASCII (Join-Path $PhysicalPath "health.txt")

if (-not (Test-Path "IIS:\\AppPools\\$AppPoolName")) {
    New-WebAppPool -Name $AppPoolName | Out-Null
}
Set-ItemProperty "IIS:\\AppPools\\$AppPoolName" -Name managedRuntimeVersion -Value ""

if (Test-Path "IIS:\\Sites\\$SiteName") {
    Remove-Website -Name $SiteName
}
New-Website -Name $SiteName -PhysicalPath $PhysicalPath -Port $Port -ApplicationPool $AppPoolName | Out-Null
Start-WebAppPool -Name $AppPoolName
Start-Website -Name $SiteName

if ($FailureMode -eq "WINDOWS_STOP_APPPOOL") {
    Write-Warning "INTENTIONAL LAB FAILURE: stopping application pool after deployment."
    Stop-WebAppPool -Name $AppPoolName
}

Write-Host "IIS deployment complete."
Get-Website -Name $SiteName | Format-List Name,State,PhysicalPath,Bindings
