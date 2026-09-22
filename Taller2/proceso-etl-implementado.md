# Proceso ETL Implementado y Operativo

## 1. Arquitectura del Flujo ETL

El proceso de Extracción, Transformación y Carga (ETL) fue diseñado bajo el principio de **máxima eficiencia computacional**, aprovechando que tanto la fuente transaccional (`AdventureWorks2022`) como el repositorio analítico (`AdventureWorksDW`) residen en la misma instancia de Microsoft SQL Server 2022 en Docker.

```text
+------------------------+
|   AdventureWorks2022   |  (Fuente Transaccional OLTP)
+------------------------+
            |
            |  1. Extracción relacional
            |  2. Limpieza de valores nulos y normalización
            |  3. Generación de claves subrogadas y lookup
            |  4. Inserción basada en conjuntos (Set-Based ELT)
            v
+------------------------+
|    AdventureWorksDW    |  (Data Warehouse Analítico OLAP)
+------------------------+
```

---

## 2. Decisiones Técnicas y Reglas de Negocio

### 2.1 Enfoque Set-Based en Motor Relacional
- En lugar de extraer fila por fila a través de la red (lo que implicaría serializar más de 300.000 registros y generar cuellos de botella por latencia de socket), el pipeline ejecuta transformaciones basadas en conjuntos directamente en el motor SQL Server.
- **Rendimiento:** Carga completa en **menos de 5 segundos**.

### 2.2 Tratamiento de Fechas y Clave Especial `-1`
- Para fechas nulas o no aplicables (como `ShipDate` en órdenes no despachadas o `ActualEndDate` en operaciones en curso), se asigna la clave `DateKey = -1` ('1900-01-01', 'No Aplica').
- Esto garantiza que ninguna clave foránea quede huérfana o rompa la integridad referencial en Power BI.

### 2.3 Tratamiento de Clientes (B2C y B2B)
- En `AdventureWorks2022`, los clientes están divididos entre `PersonID` (personas naturales) y `StoreID` (tiendas).
- El proceso ETL unifica ambas entidades en `DimCustomer`, asignando un `CustomerType` transparente ('Individual' o 'Store'), resolviendo la dirección principal mediante búsqueda en `BusinessEntityAddress` y estandarizando el nombre legal.

### 2.4 Tratamiento de Vendedores y Canal Digital
- Las ventas en línea (`OnlineOrderFlag = 1`) no poseen un ejecutivo comercial asignado (`SalesPersonID IS NULL`).
- El ETL inserta el registro especial `SalesPersonKey = 0` ('Venta Online / Sin Vendedor', 'Canal Digital') en `DimSalesPerson`. Toda orden web se asocia a esta clave, permitiendo filtrar ventas con vendedor vs ventas web sin pérdida de datos.

### 2.5 Tratamiento de Desperdicio en Manufactura
- En `Production.WorkOrder`, las órdenes sin merma poseen `ScrapReasonID IS NULL`.
- El ETL inserta el registro especial `ScrapReasonKey = 0` ('Sin Desperdicio / Conforme') en `DimScrapReason`.

---

## 3. Secuencia de Ejecución del Pipeline

| Paso | Script | Propósito | Tiempo Promedio |
|:---|:---|:---|:---|
| **1** | `database/dw/01_create_dw_schema.sql` | Crea la base de datos `AdventureWorksDW`, tablas dimensionales, hechos, índices y claves foráneas. | ~0,15 s |
| **2** | `database/dw/02_populate_dim_date.sql` | Genera el calendario continuo 2010–2015 con atributos de año, mes, trimestre y fin de semana. | ~0,10 s |
| **3** | `database/dw/03_etl_dimensions.sql` | Extrae, transforma y carga las 7 dimensiones maestras (`DimTerritory`, `DimSalesPerson`, `DimCustomer`, `DimProduct`, `DimSpecialOffer`, `DimLocation`, `DimScrapReason`). | ~0,35 s |
| **4** | `database/dw/04_etl_facts.sql` | Resuelve claves foráneas contra las dimensiones y carga las 4 tablas de hechos (`FactSales`, `FactWorkOrder`, `FactWorkOrderRouting`, `FactInventorySnapshot`). | ~3,80 s |
| **5** | `database/dw/05_audit_and_validation.sql` | Ejecuta validación cruzada de volumetría, cuadratura monetaria y verificación de cero huérfanos. | ~0,60 s |

---

## 4. Instrucciones de Ejecución

### Opción A: Mediante PowerShell en Windows (Recomendada)
Desde la raíz del repositorio:
```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\ejecutarETL.ps1
```

### Opción B: Mediante Python Multiplataforma
```bash
python3 database/etl/run_etl.py
```

Ambos orquestadores leen la contraseña de `sa` desde el archivo `.env`, validan que el contenedor `bigdata-sqlserver` esté activo, ejecutan la secuencia de 5 etapas y emiten un informe de estado con los tiempos de procesamiento.
