param(
    [string]$FailureMode = "NONE",
    [string]$HealthUrl = "http://localhost:8085/health.txt",
    [string]$ExpectedVersion = "v1"
)

$ErrorActionPreference = "Stop"

if ($FailureMode -eq "WINDOWS_HEALTH_FAILURE") {
    $HealthUrl = "http://localhost:8085/this-path-does-not-exist"
    Write-Warning "INTENTIONAL LAB FAILURE: health URL changed to a missing path."
}

Write-Host "Checking $HealthUrl"

try {
    $r = Invoke-WebRequest -Uri $HealthUrl -UseBasicParsing -TimeoutSec 10
    Write-Host "HTTP status: $($r.StatusCode)"
    Write-Host "Body: $($r.Content.Trim())"

    if ($r.StatusCode -ne 200) {
        throw "Expected HTTP 200, got $($r.StatusCode)"
    }

    if ($r.Content -notmatch [regex]::Escape($ExpectedVersion)) {
        throw "Health response did not contain expected version $ExpectedVersion"
    }
}
catch {
    Write-Error "IIS health check failed: $($_.Exception.Message)"
    exit 51
}

Write-Host "IIS health check PASSED."
