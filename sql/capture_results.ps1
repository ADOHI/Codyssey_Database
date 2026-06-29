$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$resultsDir = Join-Path $root "results"
New-Item -ItemType Directory -Force -Path $resultsDir | Out-Null

$utf8Bom = New-Object System.Text.UTF8Encoding $true

docker exec codyssey-mysql rm -rf /tmp/codyssey-sql
docker cp (Join-Path $root "sql") codyssey-mysql:/tmp/codyssey-sql | Out-Null

docker exec codyssey-mysql mysql -uroot -prootpassword --default-character-set=utf8mb4 -e "source /tmp/codyssey-sql/01_schema.sql" | Out-Null
docker exec codyssey-mysql mysql -uroot -prootpassword --default-character-set=utf8mb4 -e "source /tmp/codyssey-sql/02_insert_sample_data.sql" | Out-Null

function Save-SqlResult {
    param(
        [string]$ContainerSql,
        [string]$ContainerOut,
        [string]$Header,
        [string]$OutPath
    )
    docker exec codyssey-mysql sh -c "mysql -uroot -prootpassword --default-character-set=utf8mb4 -t codyssey < '$ContainerSql' > '$ContainerOut' 2>&1"
    $localTmp = Join-Path $env:TEMP ([System.IO.Path]::GetFileName($ContainerOut))
    docker cp "codyssey-mysql:${ContainerOut}" $localTmp | Out-Null
    $body = [System.IO.File]::ReadAllText($localTmp, [System.Text.Encoding]::UTF8)
    [System.IO.File]::WriteAllText($OutPath, $Header + $body, $utf8Bom)
}

# Bonus metrics (sample data full state, before UPDATE/DELETE queries)
$metricsDescFile = Join-Path $PSScriptRoot "bonus_metrics_descriptions.txt"
$metricsDescriptions = @{}
Get-Content $metricsDescFile -Encoding UTF8 | ForEach-Object {
    $parts = $_ -split '\|', 2
    if ($parts.Count -eq 2) { $metricsDescriptions[$parts[0]] = $parts[1] }
}

$combinedMetrics = [System.IO.File]::ReadAllText((Join-Path $PSScriptRoot "bonus_metrics_header.txt"), [System.Text.Encoding]::UTF8)

$metricsDir = Join-Path $PSScriptRoot "bonus_metrics"
Get-ChildItem $metricsDir -Filter "*.sql" | Sort-Object Name | ForEach-Object {
    $num = $_.BaseName.Substring(0, 2)
    $containerSql = "/tmp/codyssey-sql/bonus_metrics/$($_.Name)"
    $containerOut = "/tmp/bonus_metrics_$num.txt"
    $desc = $metricsDescriptions[$num]
    if (-not $desc) { $desc = $_.Name }

    $header = @"
============================================================
bonus_metrics_$num.txt
$desc
============================================================

"@
    $outPath = Join-Path $resultsDir "bonus_metrics_$num.txt"
    Save-SqlResult -ContainerSql $containerSql -ContainerOut $containerOut -Header $header -OutPath $outPath
    Write-Host "Saved bonus_metrics_$num.txt"
    $combinedMetrics += [System.IO.File]::ReadAllText($outPath, [System.Text.Encoding]::UTF8) + "`r`n"
}

[System.IO.File]::WriteAllText((Join-Path $resultsDir "bonus_metrics.txt"), $combinedMetrics, $utf8Bom)
Write-Host "Saved bonus_metrics.txt"

$descFile = Join-Path $PSScriptRoot "query_descriptions.txt"
$descriptions = @{}
Get-Content $descFile -Encoding UTF8 | ForEach-Object {
    $parts = $_ -split '\|', 2
    if ($parts.Count -eq 2) { $descriptions[$parts[0]] = $parts[1] }
}

$queryDir = Join-Path $PSScriptRoot "queries"
Get-ChildItem $queryDir -Filter "*.sql" | Sort-Object Name | ForEach-Object {
    $num = $_.BaseName.Substring(0, 2)
    $containerSql = "/tmp/codyssey-sql/queries/$($_.Name)"
    $containerOut = "/tmp/query_out_$num.txt"
    $desc = $descriptions[$num]
    if (-not $desc) { $desc = $_.Name }

    $header = @"
============================================================
query_$num.txt
$desc
============================================================

"@
    $outName = if ($num -eq "16") { "query_16_index.txt" } else { "query_$num.txt" }
    Save-SqlResult -ContainerSql $containerSql -ContainerOut $containerOut -Header $header -OutPath (Join-Path $resultsDir $outName)
    Write-Host "Saved $outName"
}

# Bonus: FK error capture
docker exec codyssey-mysql sh -c "mysql -uroot -prootpassword --default-character-set=utf8mb4 codyssey < /tmp/codyssey-sql/bonus_fk_single.sql > /tmp/fk_error.txt 2>&1"
docker cp codyssey-mysql:/tmp/fk_error.txt (Join-Path $env:TEMP "codyssey_fk_error.txt") | Out-Null
$fkHeader = [System.IO.File]::ReadAllText((Join-Path $PSScriptRoot "bonus_fk_header.txt"), [System.Text.Encoding]::UTF8)
$fkBody = [System.IO.File]::ReadAllText((Join-Path $env:TEMP "codyssey_fk_error.txt"), [System.Text.Encoding]::UTF8)
[System.IO.File]::WriteAllText((Join-Path $resultsDir "bonus_fk_error.txt"), $fkHeader + $fkBody, $utf8Bom)
Write-Host "Saved bonus_fk_error.txt"

Write-Host "Done: $resultsDir"
