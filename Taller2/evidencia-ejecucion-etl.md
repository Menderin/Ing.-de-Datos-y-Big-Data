# Evidencia de Ejecución y Validación del Pipeline ETL

La bitácora de las secciones 1 y 2 corresponde a la implementación inicial. La versión tolerante incorpora una etapa adicional y su duración no corresponde a esos tiempos históricos. La evidencia de regresión actual se añade en la sección 3.

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
✓ Paso completado en 0.33 segundos.

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
✓ Paso completado en 3.76 segundos.

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
Control                                    Huerfanos  
------------------------------------------ -----------
FactSales (vendedor/oferta/fechas entrega)           0
FactWorkOrder                                        0
FactWorkOrderRouting                                 0
DimCustomer sin direccion (esperado 0)               0
DimCustomer sin territorio (esperado 0)              0
✓ Paso completado en 1.25 segundos.

=================================================================
 PIPELINE ETL FINALIZADO EXITOSAMENTE
 Tiempo total: 5.57 segundos
 Base analítica operativa: AdventureWorksDW
=================================================================
```

---

## 2. Certificación de Cuadratura e Integridad

1. **Cero Pérdida de Datos:** Las 121.317 líneas de venta, 72.591 órdenes de trabajo, 67.131 operaciones de ruta y 1.069 existencias de inventario fueron migradas con 100% de paridad.
2. **Cuadratura Financiera Exacta:** La suma de `$109.846.381,40` en ventas netas coincide al centavo entre la base transaccional y la tabla `FactSales`.
3. **Integridad Referencial Absoluta:** Se constatan **0 registros huérfanos** en las dimensiones vinculadas a `FactSales`, `FactWorkOrder` y `FactWorkOrderRouting` (sección 4 de la auditoría).
4. **Calidad de `DimCustomer`:** 0 clientes sin dirección y 0 sin territorio. Una versión previa del ETL dejaba 635 clientes tipo tienda con ciudad y país `No Informado`, porque se buscaba la dirección del contacto (`PersonID`) en lugar de la de la tienda (`StoreID`); fue corregido en `03_etl_dimensions.sql`.

## 3. Regresión de la carga tolerante — 7 de octubre de 2026

Se compararon los valores del DW anterior a las nuevas validaciones con la recarga tolerante de la misma fuente. No se modificó `AdventureWorks2022`.

| Control | Antes | Después |
| --- | ---: | ---: |
| Filas FactSales | 121317 | 121317 |
| Filas FactWorkOrder | 72591 | 72591 |
| Filas FactWorkOrderRouting | 67131 | 67131 |
| Filas FactInventorySnapshot | 1069 | 1069 |
| Ventas netas | 109846381.399888 | 109846381.399888 |
| Unidades vendidas | 274914 | 274914 |
| Unidades planificadas | 4507721 | 4507721 |
| Unidades desechadas | 10651 | 10651 |
| Horas reales | 228962.2000 | 228962.2000 |
| Costo real | 3487969.5000 | 3487969.5000 |
| Stock físico | 335974 | 335974 |

Las dimensiones conservan 2192 fechas, 19820 clientes, 504 productos, 10 territorios, 18 vendedores (incluido miembro especial), 16 ofertas, 14 ubicaciones y 17 motivos de descarte (incluido miembro especial).

La última carga verificada tuvo RunID `AC6B7C4F-551A-4533-BCA7-CB92B928CD75`, estado `COMPLETED` y duración de 51,52 segundos en este equipo. Las 22 tablas fuente registraron cero rechazos. Se registraron cuatro normalizaciones de espacios; no hubo incidencias `WARNING` ni `REJECT`. La auditoría de cuadratura y las restricciones del DW pasaron.

La batería de pruebas en bases sintéticas separadas terminó así:

```text
Ran 12 tests in 86.323s
OK
```

Incluye conversiones inválidas, nulos obligatorios y permitidos, negativos, desbordamientos, textos vacíos/largos, nombres compuestos, duplicados, referencias rotas, combinación oferta/producto, fechas/totales incoherentes y tablas vacías. Un fallo técnico inducido después de reconstruir/cargar tablas revirtió la transacción y mantuvo la carga publicada anterior; una columna requerida ausente también conservó el DW.

Las bases temporales de pruebas se eliminaron al finalizar. Los tiempos son observaciones de esta ejecución, no garantías de rendimiento. Véase [calidad-datos-etl.md](calidad-datos-etl.md) para las reglas y limitaciones.
