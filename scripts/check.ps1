# =============================================================
#  AI GAUNTLET — Scoring Script (Windows PowerShell)
#  Run from your project root: .\scripts\check.ps1
# =============================================================

$ErrorActionPreference = "Continue"
$Score = 0
$Report = @()
$BackendProcess = $null

# ── Helpers ──────────────────────────────────────────────────
function ChkPass($desc, $pts) {
    $script:Score += $pts
    $script:Report += [PSCustomObject]@{Status="PASS"; Desc=$desc; Pts=$pts}
    Write-Host "  [PASS] $desc  +$pts pts" -ForegroundColor Green
}
function ChkFail($desc) {
    $script:Report += [PSCustomObject]@{Status="FAIL"; Desc=$desc; Pts=0}
    Write-Host "  [FAIL] $desc  0 pts" -ForegroundColor Red
}
function ChkWarn($desc) {
    $script:Report += [PSCustomObject]@{Status="WARN"; Desc=$desc; Pts=0}
    Write-Host "  [WARN] $desc" -ForegroundColor Yellow
}
function Section($title) {
    Write-Host ""
    Write-Host "=== $title" -ForegroundColor Cyan -NoNewline
    Write-Host ""
}

function WaitForBackend {
    for ($i = 0; $i -lt 20; $i++) {
        Start-Sleep -Seconds 1
        try {
            $r = Invoke-WebRequest -Uri "http://localhost:8000/health" -TimeoutSec 2 -ErrorAction SilentlyContinue
            if ($r.StatusCode -eq 200) { return $true }
        } catch {}
    }
    return $false
}

function HttpGet($url) {
    try {
        $r = Invoke-WebRequest -Uri $url -TimeoutSec 30 -ErrorAction Stop
        return $r.Content | ConvertFrom-Json
    } catch { return $null }
}

function HttpPost($url) {
    try {
        $r = Invoke-WebRequest -Uri $url -Method POST -TimeoutSec 15 -ErrorAction Stop
        return $r.Content | ConvertFrom-Json
    } catch { return $null }
}

# ── Banner ────────────────────────────────────────────────────
Clear-Host
Write-Host "  +======================================================+" -ForegroundColor Cyan
Write-Host "  |         AI GAUNTLET - SCORING SYSTEM                |" -ForegroundColor Cyan
Write-Host "  |          Review Intelligence Challenge               |" -ForegroundColor Cyan
Write-Host "  +======================================================+" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Running from: $(Get-Location)"
$ParticipantName = Read-Host "  Enter your name"
Write-Host ""
Write-Host "  Scoring: $ParticipantName  |  $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor White
Write-Host ""

# ═════════════════════════════════════════════════════════════
#  1. PROJECT STRUCTURE (10 pts)
# ═════════════════════════════════════════════════════════════
Section "1/7  PROJECT STRUCTURE  (10 pts)"

if (Test-Path "backend")  { ChkPass "backend/ directory exists" 2 } else { ChkFail "backend/ directory missing" }
if (Test-Path "frontend") { ChkPass "frontend/ directory exists" 2 } else { ChkFail "frontend/ directory missing" }
if ((Test-Path "docker-compose.yml") -or (Test-Path "infra\docker-compose.yml")) {
    ChkPass "docker-compose.yml found" 2
} else { ChkFail "docker-compose.yml not found" }

$TestFiles = Get-ChildItem -Path "tests" -Recurse -Include "*.py","*.test.js","*.spec.js","*.json" -ErrorAction SilentlyContinue
if ($TestFiles.Count -gt 0) { ChkPass "tests/ directory has test files" 2 } else { ChkFail "tests/ empty or missing" }
if (Test-Path ".env") { ChkPass ".env file exists" 2 } else { ChkFail ".env missing (copy .env.example)" }

# ═════════════════════════════════════════════════════════════
#  2. BACKEND HEALTH (20 pts)
# ═════════════════════════════════════════════════════════════
Section "2/7  BACKEND HEALTH  (20 pts)"

$BackendStarted = $false

if (Test-Path "backend\main.py") {
    Write-Host "  Detected: Python/FastAPI backend - starting..." -ForegroundColor DarkGray
    $BackendProcess = Start-Process -FilePath "python" -ArgumentList "-m","uvicorn","main:app","--port","8000","--log-level","error" `
        -WorkingDirectory "backend" -PassThru -WindowStyle Hidden
} elseif (Test-Path "backend\package.json") {
    Write-Host "  Detected: Node backend - starting..." -ForegroundColor DarkGray
    $BackendProcess = Start-Process -FilePath "npm" -ArgumentList "start" `
        -WorkingDirectory "backend" -PassThru -WindowStyle Hidden
} else {
    ChkWarn "Cannot detect backend entry point - skipping backend tests"
}

if ($BackendProcess) {
    if (WaitForBackend) {
        $BackendStarted = $true
        ChkPass "Backend starts successfully" 3

        # Health check
        try {
            $health = Invoke-WebRequest -Uri "http://localhost:8000/health" -TimeoutSec 5
            $healthJson = $health.Content | ConvertFrom-Json
            if ($healthJson.status -eq "ok") {
                ChkPass '/health returns {"status": "ok"}' 3
            } else { ChkFail '/health body incorrect' }
        } catch { ChkFail '/health endpoint error' }

        # Upload CSV
        try {
            $boundary = "gauntletboundary"
            $csvContent = [System.IO.File]::ReadAllBytes("data\sample-reviews.csv")
            $bodyLines = @(
                "--$boundary",
                'Content-Disposition: form-data; name="file"; filename="sample-reviews.csv"',
                "Content-Type: text/csv",
                "",
                [System.Text.Encoding]::UTF8.GetString($csvContent),
                "--$boundary--"
            )
            $body = $bodyLines -join "`r`n"
            $uploadResp = Invoke-WebRequest -Uri "http://localhost:8000/upload" -Method POST `
                -ContentType "multipart/form-data; boundary=$boundary" `
                -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) -TimeoutSec 15
            $uploadJson = $uploadResp.Content | ConvertFrom-Json
            $uploadId = $uploadJson.upload_id

            if ($uploadId) {
                ChkPass "POST /upload accepts CSV" 4

                # Trigger analysis
                try { HttpPost "http://localhost:8000/analyze/$uploadId" | Out-Null } catch {}

                # Wait for results
                Write-Host "  Waiting for AI analysis (up to 60s)..." -ForegroundColor DarkGray
                $results = $null
                for ($i = 0; $i -lt 30; $i++) {
                    Start-Sleep -Seconds 2
                    $r = HttpGet "http://localhost:8000/results/$uploadId"
                    if ($r -and $r.Count -gt 0 -and $r[0].theme) {
                        $results = $r
                        break
                    }
                }

                if ($results) {
                    ChkPass "GET /results returns structured review data" 5
                    $uploadId | Out-File -FilePath "$env:TEMP\gauntlet_upload_id.txt" -Encoding UTF8
                } else {
                    ChkFail "GET /results empty after 60s"
                }

                # Analytics
                $analytics = HttpGet "http://localhost:8000/analytics/$uploadId"
                if ($analytics -and ($analytics.theme_distribution -or $analytics.themes)) {
                    ChkPass "GET /analytics returns aggregates" 5
                } else {
                    ChkWarn "GET /analytics response shape unexpected"
                }
            } else { ChkFail "upload_id not returned from /upload" }
        } catch {
            ChkFail "POST /upload failed: $_"
            ChkFail "GET /results (upload failed)"
        }
    } else {
        ChkFail "Backend did not start within 20s"
        ChkFail "POST /upload (backend not running)"
        ChkFail "GET /results (backend not running)"
    }
}

# ═════════════════════════════════════════════════════════════
#  3. FRONTEND BUILD (15 pts)
# ═════════════════════════════════════════════════════════════
Section "3/7  FRONTEND BUILD  (15 pts)"

if (Test-Path "frontend\package.json") {
    $compCount = 0
    foreach ($kw in @("Upload","Dashboard","Chart","Detail","Review")) {
        $found = Get-ChildItem "frontend\src" -Recurse -Include "*.jsx","*.tsx" -ErrorAction SilentlyContinue `
            | Select-String $kw -Quiet
        if ($found) { $compCount++ }
    }
    if ($compCount -ge 3) { ChkPass "Key React components present ($compCount of 5)" 5 }
    else { ChkFail "Missing components (found $compCount, need 3+)" }

    $rechartsUsed = Get-ChildItem "frontend\src" -Recurse -Include "*.jsx","*.tsx","*.js" -ErrorAction SilentlyContinue `
        | Select-String "recharts" -Quiet
    if ($rechartsUsed) { ChkPass "Recharts used for charts" 3 } else { ChkFail "Recharts not found" }

    Write-Host "  Building frontend (npm run build)..." -ForegroundColor DarkGray
    $buildResult = & cmd /c "cd frontend && npm run build 2>&1"
    if ($LASTEXITCODE -eq 0) { ChkPass "npm run build succeeds" 5 } else { ChkFail "npm run build failed" }

    try {
        Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 3 -ErrorAction Stop | Out-Null
        ChkPass "Frontend live at localhost:3000" 2
    } catch { ChkWarn "Frontend not running at localhost:3000" }
} else { ChkFail "frontend\package.json not found" }

# ═════════════════════════════════════════════════════════════
#  4. AI INTEGRATION (20 pts)
# ═════════════════════════════════════════════════════════════
Section "4/7  AI INTEGRATION  (20 pts)"

$anthropicUsed = Get-ChildItem "backend" -Recurse -Include "*.py","*.js","*.ts" -ErrorAction SilentlyContinue `
    | Select-String "anthropic|Anthropic" -Quiet
if ($anthropicUsed) { ChkPass "Anthropic SDK used in backend" 5 } else { ChkFail "Anthropic SDK not found" }

$structuredOut = Get-ChildItem "backend" -Recurse -Include "*.py","*.js","*.ts" -ErrorAction SilentlyContinue `
    | Select-String "key_phrases|response_format|json_object" -Quiet
if ($structuredOut) { ChkPass "Structured JSON output enforced" 5 } else { ChkFail "Structured output not enforced" }

# AI eval (10 pts)
Write-Host ""
Write-Host "  Running AI eval on 5 labelled reviews..." -ForegroundColor DarkGray

if ($BackendStarted -and (Test-Path "data\eval-reviews-labeled.csv")) {
    $evalRows = Import-Csv "data\eval-reviews-labeled.csv"
    $csvLines = @("review_id,product,review_text,date")
    $i = 1
    foreach ($row in $evalRows) {
        $text = $row.review_text -replace '"', '""'
        $csvLines += "$i,EvalProduct,`"$text`",2024-01-01"
        $i++
    }
    $evalCsv = $csvLines -join "`n"

    try {
        $boundary = "gauntletevalbnd"
        $body = "--$boundary`r`nContent-Disposition: form-data; name=`"file`"; filename=`"eval.csv`"`r`nContent-Type: text/csv`r`n`r`n$evalCsv`r`n--$boundary--"
        $uploadResp = Invoke-WebRequest -Uri "http://localhost:8000/upload" -Method POST `
            -ContentType "multipart/form-data; boundary=$boundary" `
            -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) -TimeoutSec 15
        $evalUploadId = ($uploadResp.Content | ConvertFrom-Json).upload_id

        try { HttpPost "http://localhost:8000/analyze/$evalUploadId" | Out-Null } catch {}

        $evalResults = $null
        for ($j = 0; $j -lt 30; $j++) {
            Start-Sleep -Seconds 2
            $r = HttpGet "http://localhost:8000/results/$evalUploadId"
            if ($r -and $r.Count -gt 0 -and $r[0].theme) { $evalResults = $r; break }
        }

        $correct = 0
        if ($evalResults) {
            for ($k = 0; $k -lt $evalRows.Count -and $k -lt $evalResults.Count; $k++) {
                $exp = $evalRows[$k]
                $act = $evalResults[$k]
                $themeOk = $act.theme.Trim().ToLower() -eq $exp.expected_theme.Trim().ToLower()
                $sentOk  = $act.sentiment.Trim().ToLower() -eq $exp.expected_sentiment.Trim().ToLower()
                if ($themeOk -and $sentOk) {
                    Write-Host "    [PASS] Review $($k+1): $($act.theme) / $($act.sentiment)" -ForegroundColor Green
                    $correct++
                } else {
                    Write-Host "    [FAIL] Review $($k+1): got $($act.theme)/$($act.sentiment) expected $($exp.expected_theme)/$($exp.expected_sentiment)" -ForegroundColor Red
                }
            }
        }
        $evalPts = $correct * 2
        $script:Score += $evalPts
        $script:Report += [PSCustomObject]@{Status="PASS"; Desc="AI eval accuracy: $correct/5 reviews correct"; Pts=$evalPts}
        Write-Host "  [PASS] AI eval accuracy: $correct/5 reviews correct  +$evalPts pts" -ForegroundColor Green
    } catch {
        ChkFail "AI eval failed: $_"
    }
} else {
    ChkWarn "Skipping AI eval (backend not running or eval file missing)"
}

# ═════════════════════════════════════════════════════════════
#  5. TESTING COMPLETENESS (20 pts)
# ═════════════════════════════════════════════════════════════
Section "5/7  TESTING COMPLETENESS  (20 pts)"

$testFiles = Get-ChildItem "tests" -Recurse -Include "test_*.py","*.test.js","*.spec.js" -ErrorAction SilentlyContinue
if ($testFiles.Count -gt 0) { ChkPass "Integration test files exist" 5 } else { ChkFail "No test files in tests/" }

if (Test-Path "tests\test_api.py") {
    Write-Host "  Running pytest..." -ForegroundColor DarkGray
    $pytestOut = & python -m pytest tests\test_api.py -v --tb=line 2>&1 | Out-String
    $passed = ([regex]::Matches($pytestOut, "PASSED")).Count
    $failed = ([regex]::Matches($pytestOut, "FAILED")).Count
    if ($failed -eq 0 -and $passed -gt 0) { ChkPass "All $passed pytest tests pass" 8 }
    elseif ($passed -ge 3) { ChkPass "$passed tests pass (partial)" 4; ChkFail "$failed test(s) still failing" }
    else { ChkFail "Tests failing: $passed passed, $failed failed" }
}

if (Test-Path "tests\postman-collection.json") { ChkPass "Postman collection present" 4 } else { ChkFail "tests\postman-collection.json not found" }
if (Test-Path "qa-checklist.md") { ChkPass "qa-checklist.md present" 3 } else { ChkFail "qa-checklist.md not found" }

# ═════════════════════════════════════════════════════════════
#  6. DOCKER (10 pts)
# ═════════════════════════════════════════════════════════════
Section "6/7  DOCKER & INFRASTRUCTURE  (10 pts)"

$composeFile = if (Test-Path "docker-compose.yml") { "docker-compose.yml" }
               elseif (Test-Path "infra\docker-compose.yml") { "infra\docker-compose.yml" }
               else { $null }

if ($composeFile) {
    ChkPass "docker-compose.yml found ($composeFile)" 2
    $configResult = & docker compose -f $composeFile config 2>&1
    if ($LASTEXITCODE -eq 0) { ChkPass "docker-compose config validates" 4 } else { ChkFail "docker-compose config has errors" }
    $services = & docker compose -f $composeFile config --services 2>/dev/null | Out-String
    if ($services -match "backend|api") { ChkPass "Backend service in compose" 2 } else { ChkFail "Backend service not found" }
    if ($services -match "frontend|web|nginx") { ChkPass "Frontend service in compose" 2 } else { ChkFail "Frontend service not found" }
} else { ChkFail "docker-compose.yml not found" }

# ═════════════════════════════════════════════════════════════
#  7. GIT HYGIENE (5 pts)
# ═════════════════════════════════════════════════════════════
Section "7/7  GIT HYGIENE  (5 pts)"

$gitLog = git log --oneline 2>&1
if ($LASTEXITCODE -eq 0) {
    $commitCount = ($gitLog | Measure-Object -Line).Lines
    if ($commitCount -ge 4) { ChkPass "Strong commit history ($commitCount commits)" 2 }
    elseif ($commitCount -ge 2) { ChkPass "Commit history present ($commitCount commits)" 1 }
    else { ChkFail "Too few commits ($commitCount)" }

    $generic = ($gitLog | Where-Object { $_ -match "initial commit|^update|^fix$|^wip$" }).Count
    if ($generic -le 1) { ChkPass "Meaningful commit messages" 2 } else { ChkWarn "$generic generic commit messages" }

    $prList = gh pr list --state all 2>&1
    if ($prList -and $prList.Count -ge 1 -and $prList -notmatch "no pull requests") {
        ChkPass "GitHub PR exists" 1
    } else { ChkFail "No PR found (run: gh pr create)" }
} else { ChkFail "Not a git repository" }

# ═════════════════════════════════════════════════════════════
#  FINAL SCORE
# ═════════════════════════════════════════════════════════════
Write-Host ""
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""

$badge = switch ($true) {
    ($Score -ge 90) { "ELITE - You're at Stage 7" }
    ($Score -ge 75) { "STAGE 6 - Fleet commander" }
    ($Score -ge 55) { "STAGE 5 - On your way" }
    ($Score -ge 35) { "STAGE 4 - Getting there" }
    default         { "STAGE 3 - Keep pushing" }
}
$colour = if ($Score -ge 75) { "Green" } elseif ($Score -ge 40) { "Yellow" } else { "Red" }

Write-Host "  Participant: $ParticipantName"
Write-Host "  Timestamp:   $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
Write-Host ""
Write-Host "  +------------------------------------------+" -ForegroundColor $colour
Write-Host "  |   FINAL SCORE:   $Score / 100                  |" -ForegroundColor $colour
Write-Host "  |   $badge" -ForegroundColor $colour
Write-Host "  +------------------------------------------+" -ForegroundColor $colour
Write-Host ""
Write-Host "  Breakdown:" -ForegroundColor White
foreach ($entry in $Report) {
    $c = if ($entry.Status -eq "PASS") { "Green" } elseif ($entry.Status -eq "FAIL") { "Red" } else { "Yellow" }
    $prefix = if ($entry.Status -eq "PASS") { "[+$($entry.Pts)]" } elseif ($entry.Status -eq "FAIL") { "[0]  " } else { "[--] " }
    Write-Host "  $prefix $($entry.Desc)" -ForegroundColor $c
}

# Save report
$reportContent = @"
# AI Gauntlet - Score Report

**Participant:** $ParticipantName
**Date:** $(Get-Date -Format 'yyyy-MM-dd HH:mm')
**Score:** $Score / 100
**Badge:** $badge

## Breakdown

| Check | Result | Points |
|-------|--------|--------|
"@
foreach ($entry in $Report) {
    $icon = if ($entry.Status -eq "PASS") { "✅" } elseif ($entry.Status -eq "FAIL") { "❌" } else { "⚠️" }
    $reportContent += "`n| $($entry.Desc) | $icon | $($entry.Pts) |"
}
$reportContent | Out-File -FilePath "SCORE_REPORT.md" -Encoding UTF8

Write-Host ""
Write-Host "  Report saved to: SCORE_REPORT.md" -ForegroundColor White
Write-Host ""
Write-Host "  Screenshot this terminal and share in the group chat!" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""

# Cleanup
if ($BackendProcess -and !$BackendProcess.HasExited) {
    Stop-Process -Id $BackendProcess.Id -Force -ErrorAction SilentlyContinue
}
