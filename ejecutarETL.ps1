<#
.SYNOPSIS
    Orquestador del proceso ETL para la Entrega 2.
.DESCRIPTION
    Ejecuta la creación del Data Warehouse (AdventureWorksDW), carga de dimensiones,
    carga de tablas de hechos y auditoría de integridad en el contenedor SQL Server de Docker.
#>

[CmdletBinding()]
param(
    [string]$ContainerName = "bigdata-sqlserver"
)

$ErrorActionPreference = "Stop"
$sqlcmdPath = "/opt/mssql-tools18/bin/sqlcmd"

# 1. Validar existencia del archivo .env
if (-not (Test-Path ".env")) {
    throw "No existe el archivo .env. Copia primero .env.example a .env y define MSSQL_SA_PASSWORD."
}

# 2. Obtener contraseña de sa desde .env
$passwordLine = Get-Content ".env" | Where-Object { $_ -match '^\s*MSSQL_SA_PASSWORD\s*=' } | Select-Object -First 1
if (-not $passwordLine) {
    throw "No se encontro MSSQL_SA_PASSWORD en .env"
}
$saPassword = ($passwordLine -split "=", 2)[1].Trim().Trim('"').Trim("'")
if ([string]::IsNullOrWhiteSpace($saPassword)) {
    throw "MSSQL_SA_PASSWORD esta vacio en .env"
}

# 3. Validar estado del contenedor Docker
$running = docker inspect --format '{{.State.Running}}' $ContainerName 2>$null
if ($running -ne "true") {
    throw "El contenedor $ContainerName no esta ejecutandose. Inicialo con: docker compose up -d"
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " INICIANDO PIPELINE ETL - ENTREGA 2 (DATA WAREHOUSE)        " -ForegroundColor Cyan
Write-Host " Contenedor: $ContainerName                                 " -ForegroundColor Cyan
Write-Host " Fecha/Hora: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')      " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$scriptSequence = @(
    @{ Name = "1. Esquema DDL"; File = "database/dw/01_create_dw_schema.sql" },
    @{ Name = "2. DimDate (Calendario)"; File = "database/dw/02_populate_dim_date.sql" },
    @{ Name = "3. Dimensiones Maestras"; File = "database/dw/03_etl_dimensions.sql" },
    @{ Name = "4. Tablas de Hechos"; File = "database/dw/04_etl_facts.sql" },
    @{ Name = "5. Auditoria de Cuadratura"; File = "database/dw/05_audit_and_validation.sql" }
)

$stopwatchTotal = [System.Diagnostics.Stopwatch]::StartNew()

foreach ($step in $scriptSequence) {
    if (-not (Test-Path $step.File)) {
        throw "No se encontro el archivo $($step.File)"
    }

    Write-Host "`n>>> Ejecutando: $($step.Name) ($($step.File)) ..." -ForegroundColor Yellow
    $stopwatchStep = [System.Diagnostics.Stopwatch]::StartNew()

    $content = Get-Content -Path $step.File -Raw -Encoding UTF8
    $result = $content | docker exec -i -e "SQLCMDPASSWORD=$saPassword" $ContainerName $sqlcmdPath -S localhost -U sa -C -b 2>&1
    $exitCode = $LASTEXITCODE

    $stopwatchStep.Stop()
    $result | Write-Host

    if ($exitCode -ne 0) {
        throw "Fallo en la ejecucion de $($step.File). Revisa los mensajes de sqlcmd."
    }

    Write-Host "Paso completado en $([math]::Round($stopwatchStep.Elapsed.TotalSeconds, 2)) segundos." -ForegroundColor Green
}

$stopwatchTotal.Stop()

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host " PIPELINE ETL FINALIZADO EXITOSAMENTE                        " -ForegroundColor Green
Write-Host " Tiempo total: $([math]::Round($stopwatchTotal.Elapsed.TotalSeconds, 2)) segundos            " -ForegroundColor Green
Write-Host " Base analitica operativa: AdventureWorksDW                 " -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
