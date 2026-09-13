[CmdletBinding()]
param(
    [string]$BackupFile = "/var/opt/mssql/backup/AdventureWorks2022.bak",
    [string]$DatabaseName = "AdventureWorks2022"
)

$ErrorActionPreference = "Stop"
$containerName = "bigdata-sqlserver"
$sqlcmdPath = "/opt/mssql-tools18/bin/sqlcmd"

if (-not (Test-Path ".env")) {
    throw "No existe .env. Ejecuta primero: Copy-Item .env.example .env"
}

$passwordLine = Get-Content ".env" | Where-Object { $_ -match '^\s*MSSQL_SA_PASSWORD\s*=' } | Select-Object -First 1
if (-not $passwordLine) {
    throw "No se encontró MSSQL_SA_PASSWORD en .env"
}
$saPassword = ($passwordLine -split "=", 2)[1].Trim().Trim('"').Trim("'")
if ([string]::IsNullOrWhiteSpace($saPassword)) {
    throw "MSSQL_SA_PASSWORD está vacío en .env"
}

$running = docker inspect --format '{{.State.Running}}' $containerName 2>$null
if ($running -ne "true") {
    throw "El contenedor $containerName no está ejecutándose. Ejecuta: docker compose up -d"
}

 $sql = @"
SET NOCOUNT ON;
IF DB_ID(N'$DatabaseName') IS NOT NULL
BEGIN
    ALTER DATABASE [$DatabaseName] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [$DatabaseName];
END;
RESTORE DATABASE [$DatabaseName]
FROM DISK = N'$BackupFile'
WITH MOVE N'AdventureWorks2022' TO N'/var/opt/mssql/data/$DatabaseName.mdf',
     MOVE N'AdventureWorks2022_log' TO N'/var/opt/mssql/data/$DatabaseName`_log.ldf',
     RECOVERY, STATS = 10;
ALTER DATABASE [$DatabaseName] SET MULTI_USER;
SELECT name, state_desc FROM sys.databases WHERE name = N'$DatabaseName';
"@

Write-Host "Restaurando $DatabaseName desde $BackupFile ..." -ForegroundColor Cyan
$result = $sql | docker exec -i -e "SQLCMDPASSWORD=$saPassword" $containerName $sqlcmdPath -S localhost -U sa -C -b 2>&1
$exitCode = $LASTEXITCODE
$result | Write-Host
if ($exitCode -ne 0) {
    throw "La restauración falló. Revisa el mensaje de sqlcmd."
}
Write-Host "Restauracion completada." -ForegroundColor Green
