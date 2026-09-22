# Ingeniería de Datos y Big Data

Repositorio del proyecto de reportabilidad basado en la base de datos de ejemplo **AdventureWorks2022**.

La solución propuesta considera el siguiente flujo:

```text
AdventureWorks / SQL Server
          ↓
         ETL
          ↓
      Data Warehouse
          ↓
        Power BI
```

El trabajo actual corresponde a la **Entrega 1** e incluye el diseño de la arquitectura, el diseño conceptual de los reportes y la implementación de la base transaccional como fuente de datos.

## Requisitos

- Windows.
- Docker Desktop.
- PowerShell.
- SQL Server Management Studio (SSMS), recomendado para explorar la base.
- Archivo `AdventureWorks2022.bak` proporcionado por el profesor.

## Estructura principal

```text
.
├── Data/                 Backup local de AdventureWorks
├── Docs/                 Material oficial del taller
├── database/
│   ├── dw/               Scripts DDL, carga y auditoría del Data Warehouse
│   └── etl/              Orquestador en Python (run_etl.py)
├── evidencia/            Capturas utilizadas en el informe
├── reports/              Diseño técnico final de los 15 reportes
├── Taller1/              Entregables y mockups interactivos (Entrega 1)
├── Taller2/              Documentación de modelo dimensional y ETL (Entrega 2)
├── docker-compose.yml    SQL Server 2022 en Docker
├── recuperarBD.ps1       Restauración automática del backup transaccional
└── ejecutarETL.ps1       Ejecución automatizada del ETL y creación del DW
```

## Levantar el proyecto

### 1. Preparar el backup

Copiar el archivo entregado por el profesor en:

```text
Data/AdventureWorks2022.bak
```

El archivo `.bak` no se incluye en Git debido a su tamaño.

### 2. Configurar la contraseña

Desde la raíz del repositorio, crear el archivo local `.env`:

```powershell
Copy-Item .env.example .env
notepad .env
```

Reemplazar la contraseña de ejemplo por una contraseña segura. El archivo `.env` está excluido de Git.

### 3. Levantar SQL Server

Iniciar Docker Desktop y ejecutar:

```powershell
docker compose up -d
docker compose ps
```

Para revisar el proceso de inicio:

```powershell
docker compose logs -f sqlserver
```

SQL Server estará disponible en `localhost,1433`.

### 4. Restaurar la base transaccional (AdventureWorks2022)

Ejecutar desde PowerShell:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\recuperarBD.ps1
```

El script restaura `Data/AdventureWorks2022.bak` y deja la base `AdventureWorks2022` disponible y en línea en SQL Server.

### 5. Ejecutar el Pipeline ETL y Crear el Data Warehouse (AdventureWorksDW)

Para crear el esquema dimensional en estrella, cargar las dimensiones conformadas, poblar las tablas de hechos y validar la cuadratura de datos, ejecutar:

**En Windows (PowerShell):**
```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\ejecutarETL.ps1
```

**Alternativa multiplataforma (Python):**
```bash
python3 database/etl/run_etl.py
```

El pipeline se ejecuta en ~5 segundos y deja operativa la base analítica **`AdventureWorksDW`** con 121.317 registros en `FactSales`, 72.591 en `FactWorkOrder`, 67.131 en `FactWorkOrderRouting`, 1.069 en `FactInventorySnapshot` y cero registros huérfanos.

### 6. Conectarse desde SSMS

Utilizar los siguientes parámetros:

```text
Servidor: localhost,1433
Autenticación: Autenticación de SQL Server
Usuario: sa
Contraseña: valor definido en .env
Cifrado: obligatorio
Certificado de servidor de confianza: activado
```

Después de conectarse, ambas bases de datos (`AdventureWorks2022` y `AdventureWorksDW`) estarán disponibles y operativas.

## Diseño de Reportes y Mockups

- **Especificación Técnica Final:** Consultar [reports/diseno_final_reportes.md](reports/diseno_final_reportes.md) para la ficha técnica completa de los 15 reportes (KPIs, fórmulas DAX, tablas del DW y jerarquías de Drill Down).
- **Mockups Interactivos:** Abrir directamente en Chrome o Edge:
  ```text
  Taller1/mocks/index.html
  ```

## Detener el entorno

```powershell
docker compose stop
```

Para iniciarlo nuevamente:

```powershell
docker compose start
```

Los datos permanecen en el volumen Docker `bigdata-sqlserver-data`.
