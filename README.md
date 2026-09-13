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
├── evidencia/            Capturas utilizadas en el informe
├── Taller1/              Documentación y entregables
│   └── mocks/            Mockups navegables de los 15 reportes
├── docker-compose.yml    SQL Server 2022 en Docker
└── recuperarBD.ps1       Restauración automática del backup
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

### 4. Restaurar AdventureWorks2022

Ejecutar desde PowerShell:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\recuperarBD.ps1
```

El script restaura `Data/AdventureWorks2022.bak` y deja la base `AdventureWorks2022` disponible en SQL Server.

> Si la base ya existe, el script la elimina y la restaura nuevamente desde el backup.

### 5. Conectarse desde SSMS

Utilizar los siguientes parámetros:

```text
Servidor: localhost,1433
Autenticación: Autenticación de SQL Server
Usuario: sa
Contraseña: valor definido en .env
Cifrado: obligatorio
Certificado de servidor de confianza: activado
```

Después de conectarse, actualizar la carpeta **Bases de datos**. La base `AdventureWorks2022` debería aparecer en estado operativo.

## Abrir los mockups

Abrir directamente en Chrome o Edge:

```text
Taller1/mocks/index.html
```

Los mockups no requieren instalación ni servidor. Contienen 15 vistas navegables:

- cinco reportes de clientes;
- cinco reportes de procesos y producción;
- cinco reportes de ventas.

Los filtros son funcionales, pero los valores se presentan como datos de muestra para representar el comportamiento esperado de los futuros reportes en Power BI.

## Detener el entorno

```powershell
docker compose stop
```

Para iniciarlo nuevamente:

```powershell
docker compose start
```

Los datos restaurados permanecen en el volumen Docker `bigdata-sqlserver-data`.
