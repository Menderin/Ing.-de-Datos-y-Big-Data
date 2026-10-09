param([Parameter(Mandatory)][string]$SqlFile)
$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$entry = Get-Content (Join-Path $root '.env') | Where-Object { $_ -match '^\s*MSSQL_SA_PASSWORD\s*=' } | Select-Object -First 1
$secret = ($entry -split '=', 2)[1].Trim().Trim('"').Trim("'")
$previousEncoding = $OutputEncoding
$previousPassword = $env:SQLCMDPASSWORD
try {
    $OutputEncoding = [System.Text.UTF8Encoding]::new($false)
    $env:SQLCMDPASSWORD = $secret
    Get-Content -Raw -Encoding UTF8 $SqlFile | docker exec -i -e SQLCMDPASSWORD bigdata-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -C -b -f 65001 -w 240
    if ($LASTEXITCODE -ne 0) { throw 'Consulta SQL fallida.' }
} finally {
    $OutputEncoding = $previousEncoding
    $env:SQLCMDPASSWORD = $previousPassword
}
