# test-canary.ps1
Write-Host "Canary Release Test"
Write-Host "================================"
Write-Host ""

# Check connection
Write-Host "Checking connection to http://localhost ..."
try {
    $response = Invoke-WebRequest -Uri "http://localhost" -UseBasicParsing -ErrorAction Stop
    $httpCode = $response.StatusCode
} catch {
    $httpCode = 0
}

if ($httpCode -ne 200) {
    Write-Host "ERROR: Cannot connect to http://localhost"
    Write-Host "HTTP Code: $httpCode"
    Write-Host ""
    Write-Host "Please check:"
    Write-Host "  1. Run: docker compose ps"
    Write-Host "  2. Run: docker compose logs"
    Write-Host "  3. Make sure port 80 is not in use"
    exit 1
}

Write-Host "Connection OK!"
Write-Host ""

# Show sample
Write-Host "Sample response content:"
Write-Host "---"
$sampleResponse = (Invoke-WebRequest -Uri "http://localhost" -UseBasicParsing).Content
$sampleResponse -split "`r?`n" | Select-String -Pattern "(STABLE|CANARY|status)" | Select-Object -First 3
Write-Host "---"
Write-Host ""

$stable = 0
$canary = 0
$total = 100

Write-Host "Sending $total requests..."
Write-Host ""

for ($i = 1; $i -le $total; $i++) {
    $responseBody = (Invoke-WebRequest -Uri "http://localhost" -UseBasicParsing).Content

    if ($responseBody -match "STABLE") {
        $stable++
    } elseif ($responseBody -match "CANARY") {
        $canary++
    }

    Write-Host -NoNewline "`rProgress: $i/$total"
}

Write-Host ""
Write-Host ""
Write-Host "================================"
Write-Host "Results"
Write-Host "================================"
Write-Host ""
Write-Host ("  STABLE (v1.0.0): {0} hits ({1}%)" -f $stable, [math]::Floor($stable * 100 / $total))
Write-Host ("  CANARY (v2.0.0): {0} hits ({1}%)" -f $canary, [math]::Floor($canary * 100 / $total))
Write-Host ""
Write-Host "================================"
Write-Host ""

if ($stable -eq 0 -and $canary -eq 0) {
    Write-Host "WARNING: No hits detected!"
    Write-Host "The response may not contain 'STABLE' or 'CANARY' text."
    Write-Host "Run: Invoke-WebRequest -Uri http://localhost -UseBasicParsing"
    Write-Host "to inspect the actual response."
} elseif ($canary -ge 5 -and $canary -le 20) {
    Write-Host "Canary release is working correctly!"
    Write-Host "(Distribution is within expected range for 10% config)"
} else {
    Write-Host "Note: Distribution is outside expected range"
    Write-Host "(May need more samples or check configuration)"
}
