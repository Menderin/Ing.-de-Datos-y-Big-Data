# SQL Server transaccional con Docker

## Propósito

Esta configuración levanta SQL Server 2022 Developer como motor de la base transaccional AdventureWorks.

## Componentes

- **Imagen:** `mcr.microsoft.com/mssql/server:2022-latest`.
- **Contenedor:** `bigdata-sqlserver`.
- **Puerto:** `1433` del equipo Windows hacia `1433` del contenedor.
- **Persistencia:** volumen Docker `bigdata-sqlserver-data` montado en `/var/opt/mssql`.
- **Backup:** carpeta local `Data/` montada como `/var/opt/mssql/backup` en modo solo lectura.
- **Credenciales:** se leen desde el archivo local `.env`, que no debe subirse al repositorio.

## Puesta en marcha

Desde la raíz del repositorio:

```powershell
Copy-Item .env.example .env
docker compose up -d
docker compose ps
docker compose logs -f sqlserver
```

El contenedor estará listo cuando los logs indiquen que SQL Server está preparado para aceptar conexiones.

## Conexión desde SSMS

Usar estos valores:

- **Tipo de servidor:** Motor de base de datos.
- **Servidor:** `localhost,1433`.
- **Autenticación:** SQL Server Authentication.
- **Login:** `sa`.
- **Contraseña:** valor definido en `.env`.

La base `AdventureWorks2022` todavía debe restaurarse desde el archivo `.bak` después de levantar el contenedor.

## Detener y reiniciar

```powershell
docker compose stop
docker compose start
```

El volumen mantiene los datos aunque el contenedor se detenga o se recree.
