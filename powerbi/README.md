# Power BI: conexión y modelo

Ya están definidas en el [proyecto editable](piloto/PilotoVentas.pbip) las 15 páginas C1-C5, P1-P5 y V1-V5: 13 tablas (incluye una auxiliar desconectada), 14 relaciones y 102 medidas. Clientes usa azul; producción, violeta; ventas, verde. Consultar [clientes](piloto/clientes-finales.md), [producción](piloto/produccion-finales.md) y [ventas](piloto/ventas-finales.md). Para cargar las nuevas dimensiones de vendedores/ofertas y columnas de ventas, cerrar/reabrir el PBIP y pulsar **Actualizar**; no repetir el ETL si el DW sigue cargado. V4 analiza vendedores sin cuotas; V5 concilia descuentos y redondeos. Las páginas nuevas requieren revisión visual e interacción en Desktop.

Kit para conectar Power BI Desktop al Data Warehouse `AdventureWorksDW` (Entrega 3).
Power BI Desktop solo existe para Windows; el SQL Server puede estar en el mismo equipo (Docker Desktop) o en otro accesible por red.

El proyecto comenzó con un [piloto V1 de ventas](piloto/README.md), luego se amplió con clientes y producción en el mismo archivo. No hace falta construir manualmente el modelo para abrirlo.

La guía inicial de [C1 - Panorama de clientes](piloto/C1-panorama-clientes.md) describe esa página, no el tamaño actual del proyecto.

Las instrucciones siguientes corresponden al modelo completo, no al piloto. Los valores de referencia proceden de [controles SQL](../database/reports/README.md); no implican que todas las medidas DAX hayan sido ejecutadas en Power BI.

| Archivo | Contenido |
|:---|:---|
| [`consultas.m`](consultas.m) | 12 consultas de Power Query (8 dimensiones + 4 hechos) |
| [`medidas.dax`](medidas.dax) | Medidas DAX de los 15 reportes, con el valor esperado de cada una |
| Este documento | Pasos, relaciones y configuración del modelo |

## 1. Dejar el Data Warehouse listo

```powershell
docker compose up -d                 # SQL Server en localhost,1433
.\ejecutarETL.ps1                    # crea y carga AdventureWorksDW
```

La auditoría final debe mostrar todo `OK` / `CUADRA EXACTO` y `0` huérfanos.

## 2. Conectar

1. Power BI Desktop → **Obtener datos → SQL Server**.
2. Servidor: `localhost,1433`. Base de datos: `AdventureWorksDW`. Modo: **Importar**.
3. Credenciales de base de datos: usuario `sa`, contraseña de `.env`.
4. Si aparece un aviso de certificado, verificar que se trata del servidor local del proyecto. No aceptar certificados desconocidos ni desactivar globalmente el cifrado.
5. Seleccionar las 12 tablas (o usar `consultas.m` en el Editor avanzado).

## 3. Relaciones (esquema en estrella)

Todas **varios a uno**, filtro **unidireccional** (de la dimensión hacia el hecho). Crear o revisar cada relación: no depender de la detección automática.

| Hecho | Columna | Dimensión | Estado |
|:---|:---|:---|:---|
| FactSales | `OrderDateKey` | DimDate[DateKey] | Activa |
| FactSales | `DueDateKey`, `ShipDateKey` | DimDate[DateKey] | **Inactiva** (usar `USERELATIONSHIP`) |
| FactSales | `CustomerKey` | DimCustomer | Activa |
| FactSales | `ProductKey` | DimProduct | Activa |
| FactSales | `TerritoryKey` | DimTerritory | Activa |
| FactSales | `SalesPersonKey` | DimSalesPerson | Activa |
| FactSales | `SpecialOfferKey` | DimSpecialOffer | Activa |
| FactWorkOrder | `StartDateKey` | DimDate[DateKey] | Activa |
| FactWorkOrder | `EndDateKey`, `DueDateKey` | DimDate[DateKey] | **Inactiva** |
| FactWorkOrder | `ProductKey` / `ScrapReasonKey` | DimProduct / DimScrapReason | Activa |
| FactWorkOrderRouting | `ActualStartDateKey` | DimDate[DateKey] | Activa |
| FactWorkOrderRouting | `ScheduledStartDateKey`, `ScheduledEndDateKey`, `ActualEndDateKey` | DimDate[DateKey] | **Inactiva** |
| FactWorkOrderRouting | `ProductKey` / `LocationKey` | DimProduct / DimLocation | Activa |
| FactInventorySnapshot | `ProductKey` / `LocationKey` | DimProduct / DimLocation | Activa |

Power BI solo permite una relación activa entre dos tablas; por eso las fechas adicionales quedan inactivas.

No crear relación entre `DimCustomer` y `DimTerritory`: `DimCustomer` ya trae `TerritoryName` y `TerritoryGroup`, y esa relación generaría rutas ambiguas con `FactSales`.

## 4. Configuración del modelo

1. **Tabla de fechas:** `DimDate` → *Marcar como tabla de fechas* → columna `FullDate`. (`consultas.m` ya excluye la fila `DateKey = -1`.)
2. **Ordenar por columna:** `MonthName` por `Month`; `DayOfWeekName` por `DayOfWeekNumber`; `QuarterName` por `Quarter`.
3. **Jerarquías** (Drill Down, bonificación del enunciado), creadas en el panel de campos:

| Tabla | Jerarquía | Niveles |
|:---|:---|:---|
| DimDate | Calendario | `Year` → `QuarterName` → `MonthName` → `FullDate` |
| DimProduct | Producto | `CategoryName` → `SubcategoryName` → `ProductName` |
| DimTerritory | Territorio de ventas | `Group` → `CountryRegionCode` → `TerritoryName` |
| DimCustomer | Geografía de clientes | `TerritoryGroup` → `CountryRegionName` → `StateProvinceName` → `City` → `CustomerName` |
| DimLocation | Centro de trabajo | `LocationName` |

4. **Medidas:** crear la tabla `Medidas` y pegar `medidas.dax`. Ocultar las columnas de claves (`*Key`) y de importes de las tablas de hechos para que solo se usen las medidas.
5. **Formato:** `Ventas Netas`, `Costo de Ventas`, `Margen Bruto`, `Descuento Total`, `Costo de Scrap`, etc. como moneda; los `%` como porcentaje.

## 5. Cifras de control

Si el modelo está bien armado, las tarjetas deben mostrar:

| Medida | Valor |
|:---|---:|
| Ventas Netas | 109.846.381 |
| Órdenes | 31.465 |
| Unidades Vendidas | 274.914 |
| Clientes Registrados / Compradores | 19.820 / 19.119 |
| Órdenes de Trabajo | 72.591 |
| Unidades en Stock | 335.974 |
| Horas Reales | 228.962,2 |

## 6. Particularidades de los datos

- **Rango temporal:** las ventas abarcan 31-05-2011 a 30-06-2014 (2011 y 2014 son años parciales; cuidar la comparación YoY).
- **Margen bruto ~8,5 %:** es una estimación con el `StandardCost` actual del producto y el precio efectivamente cobrado, no un margen contable histórico certificado.
- **Variación de costo = 0:** en AdventureWorks el costo real de cada operación coincide con el planificado.
- **`Sin Categoría`:** 209 productos (piezas intermedias y materias primas) no tienen subcategoría; aparecen así en los reportes de producción (23.050 órdenes de trabajo).
- **Cuotas de vendedores:** `SalesQuota` es un valor único por vendedor, no por periodo.
