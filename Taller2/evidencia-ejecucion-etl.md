# Evidencia de Ejecución y Validación del Pipeline ETL

## 1. Bitácora de Ejecución del Orquestador

A continuación se presenta la traza completa de la ejecución de `run_etl.py` sobre el contenedor `bigdata-sqlserver`:

```text
=================================================================
 INICIANDO PIPELINE ETL - ENTREGA 2 (DATA WAREHOUSE)
 Contenedor: bigdata-sqlserver
 Directorio raíz: /home/daniel/Ing.-de-Datos-y-Big-Data
=================================================================

>>> Paso 1/5: 1. Esquema DDL (database/dw/01_create_dw_schema.sql) ...
Changed database context to 'master'.
Changed database context to 'AdventureWorksDW'.
Creando tablas dimensionales...
Creando tablas de hechos...
Esquema de AdventureWorksDW creado exitosamente.
✓ Paso completado en 0.13 segundos.

>>> Paso 2/5: 2. DimDate (Calendario) (database/dw/02_populate_dim_date.sql) ...
Changed database context to 'AdventureWorksDW'.
Poblando dimension DimDate...
DimDate poblada con exito: 2192 registros.
✓ Paso completado en 0.10 segundos.

>>> Paso 3/5: 3. Dimensiones Maestras (database/dw/03_etl_dimensions.sql) ...
Changed database context to 'AdventureWorksDW'.
==============================================================================
INICIANDO CARGA ETL DE DIMENSIONES
==============================================================================
Cargando DimTerritory...
DimTerritory cargada: 10 registros.
Cargando DimSalesPerson...
DimSalesPerson cargada: 18 registros (incluye canal online).
Cargando DimCustomer...
DimCustomer cargada: 19820 registros.
Cargando DimProduct...
DimProduct cargada: 504 registros.
Cargando DimSpecialOffer...
DimSpecialOffer cargada: 16 registros.
Cargando DimLocation...
DimLocation cargada: 14 registros.
Cargando DimScrapReason...
DimScrapReason cargada: 17 registros.
==============================================================================
CARGA DE TODAS LAS DIMENSIONES COMPLETADA
==============================================================================
✓ Paso completado en 0.32 segundos.

>>> Paso 4/5: 4. Tablas de Hechos (database/dw/04_etl_facts.sql) ...
Changed database context to 'AdventureWorksDW'.
==============================================================================
INICIANDO CARGA ETL DE TABLAS DE HECHOS
==============================================================================
Cargando FactSales...
FactSales cargada: 121317 registros.
Cargando FactWorkOrder...
FactWorkOrder cargada: 72591 registros.
Cargando FactWorkOrderRouting...
FactWorkOrderRouting cargada: 67131 registros.
Cargando FactInventorySnapshot...
FactInventorySnapshot cargada: 1069 registros.
==============================================================================
CARGA DE TODAS LAS TABLAS DE HECHOS COMPLETADA
==============================================================================
✓ Paso completado en 3.84 segundos.

>>> Paso 5/5: 5. Auditoria de Cuadratura (database/dw/05_audit_and_validation.sql) ...
Changed database context to 'AdventureWorksDW'.
==============================================================================
AUDITORIA DE CONTROL Y CUADRATURA: AdventureWorks2022 vs AdventureWorksDW
==============================================================================
Tabla                                  Filas_OLTP  Filas_DW    Estado
-------------------------------------- ----------- ----------- ------
DimCustomer                                  19820       19820 OK    
DimProduct                                     504         504 OK    
DimTerritory                                    10          10 OK    
DimSalesPerson (incluye Canal Digital)          18          18 OK    
DimSpecialOffer                                 16          16 OK    
DimLocation                                     14          14 OK    
DimScrapReason (incluye Conforme)               17          17 OK    
FactSales                                   121317      121317 OK    
FactWorkOrder                                72591       72591 OK    
FactWorkOrderRouting                         67131       67131 OK    
FactInventorySnapshot                         1069        1069 OK    

Metrica                           Valor_OLTP           Valor_DW             Estado       
--------------------------------- -------------------- -------------------- -------------
Total Ventas Netas (LineTotal)            109846381.40         109846381.40 CUADRA EXACTO
Unidades Vendidas (OrderQty)                 274914.00            274914.00 CUADRA EXACTO
Unidades Planificadas (WorkOrder)           4507721.00           4507721.00 CUADRA EXACTO
Unidades Desechadas (Scrap)                   10651.00             10651.00 CUADRA EXACTO
Horas Reales Operaciones                     228962.20            228962.20 CUADRA EXACTO
Costo Real de Operaciones                   3487969.50           3487969.50 CUADRA EXACTO
Stock Físico en Almacén                      335974.00            335974.00 CUADRA EXACTO

Tabla_Hecho Clientes_Huerfanos Productos_Huerfanos Territorios_Huerfanos Fechas_Huerfanas
----------- ------------------ ------------------- --------------------- ----------------
FactSales                    0                   0                     0                0
✓ Paso completado en 0.61 segundos.

=================================================================
 PIPELINE ETL FINALIZADO EXITOSAMENTE
 Tiempo total: 5.00 segundos
 Base analítica operativa: AdventureWorksDW
=================================================================
```

---

## 2. Certificación de Cuadratura e Integridad

1. **Cero Pérdida de Datos:** Las 121.317 líneas de venta, 72.591 órdenes de trabajo, 67.131 operaciones de ruta y 1.069 existencias de inventario fueron migradas con 100% de paridad.
2. **Cuadratura Financiera Exacta:** La suma de `$109.846.381,40` en ventas netas coincide al centavo entre la base transaccional y la tabla `FactSales`.
3. **Integridad Referencial Absoluta:** Se constatan **0 registros huérfanos** en todas las dimensiones vinculadas a `FactSales`.
