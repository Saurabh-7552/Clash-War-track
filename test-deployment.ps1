# Test Clash War Tracker Deployment
param(
    [string]$ElasticIP = "13.48.112.177"
)

Write-Host "🧪 Testing Clash War Tracker Deployment..." -ForegroundColor Green
Write-Host "Target: $ElasticIP" -ForegroundColor Cyan
Write-Host ""

# Test backend health
Write-Host "🔍 Testing Backend Health..." -ForegroundColor Blue
try {
    $healthResponse = Invoke-WebRequest -Uri "http://${ElasticIP}:8080/api/health" -TimeoutSec 10 -UseBasicParsing
    if ($healthResponse.StatusCode -eq 200) {
        Write-Host "✅ Backend Health: OK" -ForegroundColor Green
        Write-Host "   Response: $($healthResponse.Content)" -ForegroundColor Gray
    }
}
catch {
    Write-Host "❌ Backend Health: FAILED" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Gray
}

Write-Host ""

# Test Clash API
Write-Host "🎮 Testing Clash of Clans API..." -ForegroundColor Blue
try {
    $apiResponse = Invoke-WebRequest -Uri "http://${ElasticIP}:8080/api/fetch-currentwar?clanTag=%232GC8P2L88" -TimeoutSec 15 -UseBasicParsing
    $content = $apiResponse.Content
    
    if ($apiResponse.StatusCode -eq 200) {
        if ($content -eq "[]") {
            Write-Host "⚠️  Clash API: Empty Response (clan might not be in war)" -ForegroundColor Yellow
        }
        elseif ($content.Contains("NO_WAR")) {
            Write-Host "ℹ️  Clash API: Clan not in war" -ForegroundColor Cyan
        }
        elseif ($content.Contains("ERROR")) {
            Write-Host "❌ Clash API: Error in response" -ForegroundColor Red
            Write-Host "   Response: $content" -ForegroundColor Gray
        }
        else {
            Write-Host "✅ Clash API: Working" -ForegroundColor Green
            # Parse JSON to show player count
            try {
                $jsonData = $content | ConvertFrom-Json
                Write-Host "   Players found: $($jsonData.Count)" -ForegroundColor Gray
            }
            catch {
                Write-Host "   Response length: $($content.Length) chars" -ForegroundColor Gray
            }
        }
    }
}
catch {
    Write-Host "❌ Clash API: FAILED" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Gray
}

Write-Host ""

# Test frontend
Write-Host "🌐 Testing Frontend..." -ForegroundColor Blue
try {
    $frontendResponse = Invoke-WebRequest -Uri "http://${ElasticIP}" -TimeoutSec 10 -UseBasicParsing
    if ($frontendResponse.StatusCode -eq 200) {
        Write-Host "✅ Frontend: OK" -ForegroundColor Green
        if ($frontendResponse.Content.Contains("Clash War Tracker")) {
            Write-Host "   Content: Clash War Tracker app detected" -ForegroundColor Gray
        }
        else {
            Write-Host "   Content: HTML page loaded ($($frontendResponse.Content.Length) chars)" -ForegroundColor Gray
        }
    }
}
catch {
    Write-Host "❌ Frontend: FAILED" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Gray
}

Write-Host ""

# Test leaderboard endpoint
Write-Host "🏆 Testing Leaderboard..." -ForegroundColor Blue
try {
    $leaderboardResponse = Invoke-WebRequest -Uri "http://${ElasticIP}:8080/api/leaderboard" -TimeoutSec 10 -UseBasicParsing
    if ($leaderboardResponse.StatusCode -eq 200) {
        $content = $leaderboardResponse.Content
        if ($content -eq "[]") {
            Write-Host "ℹ️  Leaderboard: Empty (no data yet)" -ForegroundColor Cyan
        }
        else {
            Write-Host "✅ Leaderboard: Has data" -ForegroundColor Green
            try {
                $jsonData = $content | ConvertFrom-Json
                Write-Host "   Entries: $($jsonData.Count)" -ForegroundColor Gray
            }
            catch {
                Write-Host "   Response length: $($content.Length) chars" -ForegroundColor Gray
            }
        }
    }
}
catch {
    Write-Host "❌ Leaderboard: FAILED" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "🎯 Test Summary:" -ForegroundColor Yellow
Write-Host "   Frontend URL: http://$ElasticIP" -ForegroundColor White
Write-Host "   Backend URL:  http://${ElasticIP}:8080" -ForegroundColor White
Write-Host "   API Health:   http://${ElasticIP}:8080/api/health" -ForegroundColor White
Write-Host ""
Write-Host "📝 Next Steps:" -ForegroundColor Yellow
Write-Host "   1. If tests pass: Point domain clashtrack.ai to $ElasticIP" -ForegroundColor White
Write-Host "   2. Setup SSL certificate for HTTPS" -ForegroundColor White
Write-Host "   3. Test the full application workflow" -ForegroundColor White
