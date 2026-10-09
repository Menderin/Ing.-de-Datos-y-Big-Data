<#
.SYNOPSIS
Carga tolerante: staging, rechazos y publicacion atomica del DW.
#>
[CmdletBinding()]
param(
    [string]$ContainerName = "bigdata-sqlserver",
    [string]$SourceDatabase = "AdventureWorks2022",
    [string]$TargetDatabase = "AdventureWorksDW"
)
$ErrorActionPreference = "Stop"
foreach ($name in @($SourceDatabase, $TargetDatabase)) {
    if ($name -notmatch '^[A-Za-z_][A-Za-z0-9_]{0,127}$') {
        throw "Nombre de base invalido: $name"
    }
}
if ($SourceDatabase -eq $TargetDatabase -or $TargetDatabase -in @('master','model','msdb','tempdb')) {
    throw "El destino debe ser una base analitica separada."
}
$envPath = Join-Path $PSScriptRoot '.env'
if (-not (Test-Path $envPath)) { throw 'Configura primero .env.' }
$line = Get-Content $envPath | Where-Object { $_ -match '^\s*MSSQL_SA_PASSWORD\s*=' } | Select-Object -First 1
if (-not $line) { throw 'Falta MSSQL_SA_PASSWORD en .env.' }
$secret = ($line -split '=',2)[1].Trim().Trim('"').Trim("'")
if ([string]::IsNullOrWhiteSpace($secret)) { throw 'La clave de SQL Server esta vacia.' }
$running = docker inspect --format '{{.State.Running}}' $ContainerName
if ($LASTEXITCODE -ne 0 -or $running -ne 'true') { throw 'Inicia SQL Server con docker compose up -d.' }

$files = @('00_prepare_source.sql','01_create_dw_schema.sql','02_populate_dim_date.sql',
    '03_etl_dimensions.sql','04_etl_facts.sql','05_audit_and_validation.sql')
$parts = [System.Collections.Generic.List[string]]::new()
$parts.Add("USE master;" + [Environment]::NewLine + "GO")
$parts.Add("IF DB_ID(N'$SourceDatabase') IS NULL THROW 51007, 'No existe la base fuente.', 1;")
$parts.Add("IF DB_ID(N'$TargetDatabase') IS NULL EXEC(N'CREATE DATABASE [$TargetDatabase]');")
$parts.Add("GO")
foreach ($file in $files) {
    $parts.Add("PRINT 'Etapa: $file';" + [Environment]::NewLine + "GO")
    $parts.Add((Get-Content -Raw -Encoding UTF8 (Join-Path $PSScriptRoot "database/dw/$file")))
    $parts.Add("GO")
}
$sql = ($parts -join [Environment]::NewLine).Replace('$(SourceDatabase)', $SourceDatabase).Replace('$(TargetDatabase)', $TargetDatabase)
$clock = [System.Diagnostics.Stopwatch]::StartNew()
Write-Host ''
Write-Host ('=' * 78)
Write-Host 'PIPELINE ETL - ADVENTUREWORKS'
Write-Host "Origen: $SourceDatabase"
Write-Host "Destino: $TargetDatabase"
Write-Host ('=' * 78)
$previousEncoding = $OutputEncoding
$previousConsoleEncoding = [Console]::OutputEncoding
$previousPassword = $env:SQLCMDPASSWORD
try {
    $OutputEncoding = [System.Text.UTF8Encoding]::new($false)
    [Console]::OutputEncoding = $OutputEncoding
    $env:SQLCMDPASSWORD = $secret
    $sql | docker exec -i -e SQLCMDPASSWORD $ContainerName /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -C -b -f 65001 -w 240 | ForEach-Object {
        if ($_ -notmatch "^Changed database context to '.*'\.$") { Write-Host $_ }
    }
    if ($LASTEXITCODE -ne 0) {
        throw 'Fallo tecnico. Se revierte la carga no publicada; revise el error SQL.'
    }
    Write-Host ("ETL terminado en {0:N2} s. Consulte dbo.EtlRun para conocer la calidad." -f $clock.Elapsed.TotalSeconds)
} finally {
    $OutputEncoding = $previousEncoding
    [Console]::OutputEncoding = $previousConsoleEncoding
    $env:SQLCMDPASSWORD = $previousPassword
}
