# Proceso ETL Implementado y Operativo

## 1. Arquitectura del Flujo ETL

El proceso de Extracción, Transformación y Carga (ETL) aprovecha que la fuente transaccional (`AdventureWorks2022`) y el repositorio analítico (`AdventureWorksDW`) residen en la misma instancia de SQL Server 2022 en Docker. La versión actual agrega preparación tolerante, registro de rechazos y publicación transaccional. Las reglas están detalladas en [calidad-datos-etl.md](calidad-datos-etl.md).

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
- **Rendimiento:** La validación y trazabilidad agregan trabajo respecto de la carga inicial. La duración depende del equipo y de las incidencias; no se garantiza el tiempo de la versión inicial sin estas validaciones.

### 2.2 Tratamiento de Fechas y Clave Especial `-1`
- Para fechas nulas o no aplicables (como `ShipDate` en órdenes no despachadas o `ActualEndDate` en operaciones en curso), se asigna la clave `DateKey = -1` ('1900-01-01', 'No Aplica').
- Esto garantiza que ninguna clave foránea quede huérfana o rompa la integridad referencial en Power BI.

### 2.3 Tratamiento de Clientes (B2C y B2B)
- En `AdventureWorks2022`, los clientes están divididos entre `PersonID` (personas naturales) y `StoreID` (tiendas).
- El proceso ETL unifica ambas entidades en `DimCustomer`, asignando un `CustomerType` transparente ('Individual' o 'Store'), resolviendo la dirección principal mediante búsqueda en `BusinessEntityAddress` y estandarizando el nombre legal.

### 2.4 Tratamiento de Vendedores y Canal Digital
- Las ventas en línea (`OnlineOrderFlag = 1`) no poseen un ejecutivo comercial asignado (`SalesPersonID IS NULL`).
- El ETL inserta el registro especial `SalesPersonKey = 0` ('Venta Online / Sin Vendedor', 'Canal Digital') en `DimSalesPerson`. Las órdenes online sin vendedor usan esa clave; una venta asistida sin vendedor válido se rechaza.

### 2.5 Tratamiento de Desperdicio en Manufactura
- En `Production.WorkOrder`, las órdenes sin merma poseen `ScrapReasonID IS NULL`.
- El ETL inserta el registro especial `ScrapReasonKey = 0` ('Sin Desperdicio / Conforme') en `DimScrapReason`.

---

## 3. Secuencia de Ejecución del Pipeline

| Paso | Script | Propósito |
| --- | --- | --- |
| 0 | `database/dw/00_prepare_source.sql` | Abre la transacción, prepara staging, valida, normaliza, registra incidencias y propaga rechazos. |
| 1 | `database/dw/01_create_dw_schema.sql` | Reconstruye tablas dimensionales, hechos, índices y restricciones dentro de la transacción. |
| 2 | `database/dw/02_populate_dim_date.sql` | Genera el calendario continuo con rango mínimo 2010–2015 y ampliación según las fechas aceptadas. |
| 3 | `database/dw/03_etl_dimensions.sql` | Carga las siete dimensiones maestras desde staging aceptado. |
| 4 | `database/dw/04_etl_facts.sql` | Resuelve claves y carga los cuatro hechos desde staging aceptado. |
| 5 | `database/dw/05_audit_and_validation.sql` | Verifica cuadratura, contabilidad de rechazos e integridad, y confirma la transacción. |

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

Ambos orquestadores leen la contraseña de `sa` desde `.env`, ejecutan las seis etapas en una sola sesión SQL y muestran el resumen de calidad. Los scripts SQL no deben ejecutarse por separado. Un fallo técnico anterior a la publicación revierte la carga y conserva el DW previo; las filas incorrectas se registran y excluyen sin impedir cargar las válidas.
