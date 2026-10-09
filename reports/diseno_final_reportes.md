# Especificación Técnica y Diseño Final de Reportes (Entrega 2)

**Asignatura:** Ingeniería de Datos y Big Data  
**Plataforma Analítica:** Microsoft SQL Server 2022 (Data Warehouse `AdventureWorksDW`) & Power BI Desktop  
**Caso de Negocio:** *Adventure Works Cycles*  

---

## 1. Introducción y Marco de Reportabilidad

**Ventas actualizadas:** V1-V5 están definidas en el mismo PBIP, con estética verde.
La ficha vigente `powerbi/piloto/ventas-finales.md` prevalece sobre los bocetos
históricos siguientes: V2 usa top 10 por venta neta, V3 territorio de la operación,
V4 desempeño sin cuotas y V5 descuento realmente aplicado con conciliación de redondeos.
Las nuevas importaciones y visuales deben revisarse tras reabrir y actualizar Desktop.

**Producción actualizada:** P1-P5 tienen definiciones de página en el proyecto Power BI.
La ficha vigente está en `powerbi/piloto/produccion-finales.md` y prevalece sobre
los bocetos históricos de producción que figuran más abajo. P5 se enfoca en catálogo,
sin repetir ventas/inventario; P1 usa fecha de inicio y P3 no tiene histórico temporal.
SQL y estructura comprobados; falta verificar apertura, actualización y DAX en Desktop.

**Implementación de Clientes actualizada:** C1-C5 ya tienen definiciones de página en el proyecto Power BI. La ficha vigente de C2-C5, sus diferencias funcionales y las pruebas de referencia están en `powerbi/piloto/clientes-finales.md`; prevalece sobre los bocetos históricos de estas páginas que figuran más abajo. Su apertura y ejecución DAX deben comprobarse en Desktop.

El presente documento establece el **diseño final y definitivo de los 15 reportes analíticos** requeridos para la plataforma de Business Intelligence de *Adventure Works Cycles*.

Habiendo validado los mockups conceptuales e interactivos en la Entrega 1 (`Taller1/mocks/index.html`), este diseño formaliza:
1. **La trazabilidad directa** entre cada indicador visual y las entidades del Data Warehouse (`AdventureWorksDW`).
2. **Las fórmulas y reglas de cálculo** (expresiones DAX y SQL).
3. **Las dimensiones de análisis, granularidad y filtros**.
4. **La estructura jerárquica de *Drill Down*** para maximizar el análisis interactivo (proyectado a la Entrega 3).

---

## 2. Matriz Global de Trazabilidad (DW a Reportes)

| Cód | Perspectiva | Reporte | Tabla de Hechos | Dimensiones Clave | Nivel de Granularidad |
|:---|:---|:---|:---|:---|:---|
| **C1** | Clientes | Panorama General de Cartera | `FactSales` | `DimCustomer`, `DimDate` | Cliente / Tipo de Cliente |
| **C2** | Clientes | Valor y Ranking de Clientes (Pareto) | `FactSales` | `DimCustomer`, `DimDate` | Cliente individual o tienda |
| **C3** | Clientes | Frecuencia y Recencia (sin puntuación RFM) | `FactSales` | `DimCustomer`, `DimDate` | Cliente consolidado |
| **C4** | Clientes | Distribución Geográfica de Clientes | `FactSales` | `DimCustomer`, `DimTerritory` | País / Estado / Ciudad |
| **C5** | Clientes | Canal de Compra (Online vs Asistido) | `FactSales` | `DimCustomer`, `DimDate` | Canal y tipo de cliente |
| **P1** | Producción | Resumen General de Manufactura | `FactWorkOrder` | `DimProduct`, `DimDate` | Orden de trabajo |
| **P2** | Producción | Calidad y Desperdicio (*Scrap*) | `FactWorkOrder` | `DimProduct`, `DimScrapReason`, `DimDate` | Motivo de scrap / Producto |
| **P3** | Producción | Control de Inventario y Stock | `FactInventorySnapshot` | `DimProduct`, `DimLocation` | Producto / Ubicación de almacén |
| **P4** | Producción | Rendimiento Operacional por Centro | `FactWorkOrderRouting`| `DimProduct`, `DimLocation`, `DimDate` | Operación / Centro de trabajo |
| **P5** | Producción | Portafolio y Catálogo de Productos | `FactSales`, `FactInventorySnapshot` | `DimProduct` | Producto / Categoría / Subcategoría |
| **V1** | Ventas | Resumen Ejecutivo de Ventas | `FactSales` | `DimDate`, `DimTerritory` | Mensual / Territorial |
| **V2** | Ventas | Rendimiento por Producto y Categoría| `FactSales` | `DimProduct`, `DimDate` | Categoría / Subcategoría / Producto |
| **V3** | Ventas | Desempeño Territorial y Regional | `FactSales` | `DimTerritory`, `DimDate` | Grupo / País / Región |
| **V4** | Ventas | Desempeño de Vendedores (sin cuotas) | `FactSales` | `DimSalesPerson`, `DimTerritory`, `DimDate`| Ejecutivo de ventas |
| **V5** | Ventas | Descuentos, Ofertas y Venta Neta | `FactSales` | `DimSpecialOffer`, `DimProduct`, `DimDate` | Tipo de promoción |

---

## 3. Especificación Detallada por Perspectiva

### 3.1 Perspectiva 1: Clientes

#### Reporte C1: Panorama General de Cartera
- **Objetivo de Negocio:** Describir la cartera actual y sus clientes compradores, distinguiendo personas y tiendas. El DW no contiene fecha de alta del cliente: la primera compra no demuestra crecimiento de registros.
- **Tarjetas KPI:**
  - *Clientes Registrados:* `COALESCE(COUNTROWS(DimCustomer), 0)` (19.820).
  - *Clientes Compradores:* `COALESCE(DISTINCTCOUNT(FactSales[CustomerKey]), 0)` (19.119 sin filtros).
  - *Clientes Sin Compra:* registrados menos compradores del periodo (701 sin filtros).
  - *Porcentaje de Compradores:* compradores / registrados mediante `DIVIDE` (96,46% sin filtros).
- **Visualizaciones Principales:**
  - Gráfico de barras apiladas: Composición de clientes compradores vs no compradores por territorio (`DimCustomer[TerritoryName]`).
  - Gráfico de donas: Proporción de clientes Individuales vs Tiendas.
  - Tabla de detalle: ID, nombre, territorio, tipo, órdenes y fecha de primera compra del periodo seleccionado. No es fecha de alta del cliente.
- **Filtros y alcance:** año y mes filtran compras, no la cartera registrada; tipo y territorio del cliente filtran ambos. La composición de cartera sigue siendo 18.484 personas y 1.336 tiendas sin filtros. No ocultar clientes o periodos sin ventas en este reporte: son parte del análisis de cartera.
- **Implementación:** página `C1 - Panorama de clientes` en el mismo proyecto de Power BI que V1. Definición y SQL comprobados; la apertura y las consultas DAX de C1 deben verificarse en Desktop. Ver `powerbi/piloto/C1-panorama-clientes.md`.
- **Jerarquía Drill Down:** `DimCustomer[TerritoryGroup]` → `DimCustomer[CountryRegionName]` → `DimCustomer[StateProvinceName]` → `DimCustomer[CustomerName]` (todas en `DimCustomer`: Power BI solo permite jerarquías dentro de una misma tabla).

#### Reporte C2: Valor y Ranking de Clientes (Análisis de Pareto)
- **Objetivo de Negocio:** Identificar el 20% de clientes que generan el 80% de los ingresos de la compañía para estrategias de fidelización y cuentas clave.
- **Tarjetas KPI:**
  - *Ventas Totales Cartera:* `SUM(FactSales[LineTotal])` ($109,85M neto)
  - *Ticket Promedio por Cliente:* `[Total Ventas] / DISTINCTCOUNT(FactSales[CustomerKey])` ($5.745)
  - *Órdenes por Cliente:* `DISTINCTCOUNT(FactSales[SalesOrderID]) / DISTINCTCOUNT(FactSales[CustomerKey])` (1,65)
  - *Top 10 Ventas:* Venta acumulada del top 10 de distribuidores.
- **Visualizaciones Principales:**
  - Gráfico de Pareto: Venta acumulada por cliente y porcentaje acumulado respecto al total.
  - Tabla clasificada: Top 50 clientes con mayor volumen de facturación, cantidad de órdenes y margen generado.
- **Filtros:** Periodo fiscal, Territorio, Tipo de Cliente.

#### Reporte C3: Frecuencia y Recencia de Compra (RFM)
- **Objetivo de Negocio:** Segmentar la base de clientes según su patrón temporal de recompra e inactividad.
- **Tarjetas KPI:**
  - *Clientes Frecuentes (> 3 órdenes):* Conteo de clientes con más de 3 compras en el periodo.
  - *Clientes Recurrentes (2 a 3 órdenes):* Conteo de clientes en fase de consolidación.
  - *Clientes de Compra Única (1 orden):* Conteo de clientes que no han vuelto a recomprar.
  - *Recencia Media:* Promedio de días transcurridos desde el último pedido registrado.
- **Visualizaciones Principales:**
  - Gráfico de dispersión (Scatter Plot): Frecuencia (eje Y) vs Total Comprado (eje X), agrupado por categoría de cliente.
  - Matriz de segmentación por cuartiles de recencia.

#### Reporte C4: Distribución Geográfica de Clientes
- **Objetivo de Negocio:** Analizar la cobertura espacial y la penetración de mercado global de *Adventure Works*.
- **Tarjetas KPI:**
  - *Territorios Activos:* `DISTINCTCOUNT(DimCustomer[TerritoryName])` (10)
  - *Países con Clientes:* `DISTINCTCOUNT(DimCustomer[CountryRegionName])` (6)
  - *Región Líder:* Región con mayor concentración de clientes (Southwest: 4.696 clientes).
  - *Venta Promedio por Territorio:* `AVERAGEX(VALUES(DimTerritory[TerritoryName]), [Total Ventas])`.
- **Visualizaciones Principales:**
  - Mapa coroplético / de burbujas: Densidad de clientes y volumen de facturación por país/estado.
  - Gráfico de barras horizontales: Clientes por territorio ordenados descendentemente.

#### Reporte C5: Canal de Compra (Online vs Asistido)
- **Objetivo de Negocio:** Comparar la dinámica entre el canal de autoservicio web (`OnlineOrderFlag = 1`) y el canal tradicional atendido por ejecutivos comerciales (`OnlineOrderFlag = 0`).
- **Tarjetas KPI:**
  - *Órdenes Online:* `CALCULATE(DISTINCTCOUNT(FactSales[SalesOrderID]), FactSales[OnlineOrderFlag] = 1)` (27.659; 87,9%)
  - *Órdenes con Vendedor:* `CALCULATE(DISTINCTCOUNT(FactSales[SalesOrderID]), FactSales[OnlineOrderFlag] = 0)` (3.806; 12,1%)
  - *Ticket Promedio Online:* `$1.061` (ventas minoristas)
  - *Ticket Promedio Vendedor:* `$21.148` (pedidos mayoristas de tiendas)
- **Visualizaciones Principales:**
  - Gráfico de columnas agrupadas mensual: Facturación canal Online vs Facturación canal Vendedor.
  - Gráfico de cascada: Margen bruto aportado por cada canal (`GrossMargin`).

---

### 3.2 Perspectiva 2: Procesos y Producción

#### Reporte P1: Resumen General de Manufactura
- **Objetivo de Negocio:** Supervisar la ejecución del plan maestro de producción física en plantas industriales.
- **Tarjetas KPI:**
  - *Órdenes de Trabajo:* `COUNTROWS(FactWorkOrder)` (72.591)
  - *Unidades Planificadas:* `SUM(FactWorkOrder[OrderQty])` (4.507.721)
  - *Unidades Almacenadas (Conformes):* `SUM(FactWorkOrder[StockedQty])` (4.497.070; 99,76%)
  - *Unidades Desechadas:* `SUM(FactWorkOrder[ScrappedQty])` (10.651; 0,24%)
- **Visualizaciones Principales:**
  - Gráfico de líneas mensual: Evolución temporal de unidades ordenadas vs producidas.
  - Gráfico de barras por categoría de producto fabricado (solo se fabrican `Bikes` 12.518 órdenes, `Components` 37.023 y `Sin Categoría` 23.050; esta última agrupa piezas intermedias sin subcategoría).
- **Jerarquía Drill Down:** `DimDate[Year]` → `DimDate[Quarter]` → `DimDate[MonthName]`.

#### Reporte P2: Calidad y Desperdicio (*Scrap Analysis*)
- **Objetivo de Negocio:** Diagnosticar las causas raíz de mermas y productos defectuosos para reducir costos de no calidad.
- **Tarjetas KPI:**
  - *Costo Total de Desperdicio:* `SUM(FactWorkOrder[ScrapCost])` ($359.947)
  - *Tasa Global de Scrap:* `SUM(FactWorkOrder[ScrappedQty]) / SUM(FactWorkOrder[OrderQty])` (0,24%)
  - *Órdenes con Descarte:* `CALCULATE(COUNTROWS(FactWorkOrder), FactWorkOrder[ScrappedQty] > 0)` (729)
  - *Motivos de Descarte:* `CALCULATE(DISTINCTCOUNT(DimScrapReason[ScrapReasonKey]), DimScrapReason[ScrapReasonKey] <> 0)` (16 motivos reales; no contar el miembro «Sin Desperdicio»).
- **Visualizaciones Principales:**
  - Gráfico de barras horizontales: Unidades y costos desechados por motivo (`DimScrapReason[ScrapReasonName]`).
  - Treemap: Productos con mayor impacto financiero por merma.

#### Reporte P3: Control de Inventario y Existencias Físicas
- **Objetivo de Negocio:** Mantener visibilidad del stock físico en cada almacén para evitar roturas de stock y optimizar capital de trabajo.
- **Tarjetas KPI:**
  - *Unidades en Stock:* `SUM(FactInventorySnapshot[Quantity])` (335.974)
  - *Valor del Inventario:* `SUM(FactInventorySnapshot[InventoryValue])`
  - *Productos con Registro de Stock:* `DISTINCTCOUNT(FactInventorySnapshot[ProductKey])` (432; incluye productos con cantidad cero).
  - *Productos con Existencia:* `CALCULATE(DISTINCTCOUNT(FactInventorySnapshot[ProductKey]), FactInventorySnapshot[Quantity] > 0)` (428 con stock positivo).
  - *Centros de Almacenamiento:* `DISTINCTCOUNT(DimLocation[LocationKey])` (14)
- **Visualizaciones Principales:**
  - Gráfico de barras apiladas: Unidades disponibles por almacén (`DimLocation[LocationName]`).
  - Semáforo de stock: Productos por debajo del punto de reorden (`DimProduct[ReorderPoint]`).
- **Navegación:** Ubicación, categoría y producto pueden añadirse como niveles de un visual. No constituyen una jerarquía nativa entre tablas distintas. El inventario es una foto actual: el filtro de fecha no debe sugerir stock histórico.

#### Reporte P4: Rendimiento Operacional por Centro de Trabajo
- **Objetivo de Negocio:** Medir la eficiencia y desviaciones en horas máquina/hombre y costos de manufactura.
- **Tarjetas KPI:**
  - *Operaciones Totales:* `COUNTROWS(FactWorkOrderRouting)` (67.131)
  - *Horas Reales de Recurso:* `SUM(FactWorkOrderRouting[ActualResourceHrs])` (228.962,20 hrs)
  - *Costo Real de Mano de Obra/Máquina:* `SUM(FactWorkOrderRouting[ActualCost])` ($3.487.969,50)
  - *Variación de Costo:* `SUM(FactWorkOrderRouting[CostVariance])` ($0,00; en AdventureWorks el costo real de cada operación coincide con el planificado, por lo que la variación es nula en toda la fuente)
- **Visualizaciones Principales:**
  - Gráfico de columnas: Horas reales consumidas por centro de trabajo (`Subassembly`, `Frame Forming`, `Paint`, etc.).
  - Tabla de rendimiento: Secuencia de operaciones y tasas horarias (`DimLocation[CostRate]`).

#### Reporte P5: Portafolio y Catálogo de Productos
- **Objetivo de Negocio:** Analizar la cartera de artículos producidos internamente versus componentes adquiridos a terceros.
- **Tarjetas KPI:**
  - *Artículos en Catálogo:* `COUNTROWS(DimProduct)` (504)
  - *Productos Terminados para Venta:* `CALCULATE(COUNTROWS(DimProduct), DimProduct[FinishedGoodsFlag] = 1)` (295)
  - *Productos Fabricados Internamente:* `CALCULATE(COUNTROWS(DimProduct), DimProduct[MakeFlag] = 1)` (239)
  - *Categorías de Producto:* 4 (`Bikes`, `Components`, `Clothing`, `Accessories`)
- **Visualizaciones Principales:**
  - Matriz de dispersión: Margen unitario (`ListPrice - StandardCost`) vs Precio de lista.
  - Donut chart: Distribución de referencias por subcategoría.

---

### 3.3 Perspectiva 3: Ventas

#### Reporte V1: Resumen Ejecutivo Comercial
- **Objetivo de Negocio:** Tablero de mando principal para la dirección general con las métricas consolidadas de facturación y margen.
- **Tarjetas KPI:**
  - *Ventas Netas Totales:* `SUM(FactSales[LineTotal])` ($109,85M)
  - *Costo Total de Mercaderías (COGS):* `SUM(FactSales[TotalProductCost])`
  - *Margen Bruto:* `SUM(FactSales[GrossMargin])`
  - *Margen Bruto Porcentual:* `[Margen Bruto] / [Ventas Netas]` (~8,5%; margen bruto $9,37M sobre COGS $100,47M, calculado con `StandardCost` vigente del producto)
  - *Órdenes Totales:* `DISTINCTCOUNT(FactSales[SalesOrderID])` (31.465)
  - *Ticket Promedio:* `[Ventas Netas] / [Órdenes Totales]` ($3.491)
- **Visualizaciones Principales:**
  - Gráfico de áreas / líneas con tendencia mensual: Ventas Netas, Costo y Margen mes a mes.
  - Indicador de velocímetro / KPI card con variación respecto al año anterior (YoY).
- **Jerarquía Drill Down:** `DimDate[Year]` → `DimDate[Quarter]` → `DimDate[MonthName]`.

#### Reporte V2: Rendimiento por Producto y Categoría
- **Objetivo de Negocio:** Identificar las líneas de producto más rentables y los artículos con mayor rotación comercial.
- **Tarjetas KPI:**
  - *Unidades Vendidas:* `SUM(FactSales[OrderQty])` (274.914)
  - *Productos con Venta Activa:* `DISTINCTCOUNT(FactSales[ProductKey])` (266)
  - *Categoría Líder en Facturación:* `Bikes` (86,2% de la facturación)
  - *Precio Promedio por Línea:* `AVERAGE(FactSales[UnitPrice])` (media no ponderada, antes del descuento).
  - *Precio Neto por Unidad:* `[Ventas Netas] / [Unidades Vendidas]` (ponderado por cantidades e incluye descuentos).
- **Visualizaciones Principales:**
  - Gráfico de barras jerárquico: Ventas y Margen por Categoría y Subcategoría.
  - Tabla Top 20 productos más vendidos (volumen monetario y unidades).
- **Jerarquía Drill Down:** `DimProduct[CategoryName]` → `DimProduct[SubcategoryName]` → `DimProduct[ProductName]`.

#### Reporte V3: Desempeño Territorial y Regional
- **Objetivo de Negocio:** Comparar el volumen de negocio y ticket medio entre mercados nacionales e internacionales.
- **Tarjetas KPI:**
  - *Territorios Comerciales:* 10
  - *Ventas Norteamérica:* Participación porcentual de US y Canadá (72,2%).
  - *Ventas Europa y Pacífico:* Participación de esos grupos (27,8%). No se presupone un país base para etiquetar venta nacional/internacional.
  - *Territorio con Mayor Venta:* Southwest ($24,18M), seguido de Canada ($16,36M) y Northwest ($16,08M).
- **Visualizaciones Principales:**
  - Gráfico de columnas apiladas al 100%: Participación mensual de cada grupo territorial (`North America`, `Europe`, `Pacific`).
  - Mapa de calor con métricas de ventas y cantidad de clientes compradores.
- **Jerarquía Drill Down:** `DimTerritory[Group]` → `DimTerritory[CountryRegionCode]` → `DimTerritory[TerritoryName]`.

#### Reporte V4: Desempeño de Vendedores
- **Objetivo de Negocio:** Comparar el aporte comercial de vendedores identificados, sin inferir cumplimiento de metas.
- **Tarjetas KPI:**
  - *Venta con Vendedor:* Venta neta con `SalesPersonKey <> 0`.
  - *Vendedores con Ventas:* Distintos vendedores presentes en los hechos del período seleccionado.
  - *Órdenes con Vendedor:* Órdenes distintas de esas operaciones.
  - *Ticket Promedio:* Venta con vendedor / órdenes con vendedor.
- **Visualizaciones Principales:**
  - Ranking de venta neta por vendedor y tendencia mensual.
  - Detalle de compradores, órdenes, ticket y margen estimado.
- **Límite:** No se muestran cuota, bonus ni comisión actuales como indicadores históricos. Territorio corresponde a la venta, no a la asignación actual del vendedor. Las ventas sin vendedor permanecen en otros reportes.

#### Reporte V5: Descuentos, Ofertas y Venta Neta
- **Objetivo de Negocio:** Evaluar el impacto de las campañas promocionales y descuentos por volumen en el margen financiero.
- **Tarjetas KPI:**
  - *Venta Bruta (sin descuento):* `SUMX(FactSales, FactSales[OrderQty] * FactSales[UnitPrice])`
  - *Descuento Total Otorgado:* `SUM(FactSales[DiscountAmount])` ($527.508)
  - *Venta Neta Efectiva:* `SUM(FactSales[LineTotal])`
  - *Tasa Promedio de Descuento:* `[Descuento Total] / [Venta Bruta]` (0,48%; sobre venta bruta de $110,37M)
- **Visualizaciones Principales:**
  - Gráfico de cascada (Waterfall): De Venta Bruta a Venta Neta discriminando por tipo de oferta especial (`DimSpecialOffer[Type]`).
  - Gráfico de torta/anillo: Porcentaje de ventas con precio regular vs ventas bajo promoción.

---

## 4. Requisitos para la Implementación en Power BI (Entrega 3)

1. **Modo de Almacenamiento:** Conexión mediante modo **Importación** (VertiPaq) apuntando a la base `AdventureWorksDW` en `localhost,1433`. La guía paso a paso, las consultas de Power Query, las relaciones y las medidas DAX listas para pegar están en la carpeta [`powerbi/`](../powerbi/README.md).
2. **Modelo de Relaciones:** Esquema en estrella puro con dirección de filtro unidireccional (1 a varios desde las dimensiones hacia las tablas de hechos).
3. **Optimización de Medidas:** Todas las métricas dinámicas deben ser implementadas mediante medidas DAX explícitas (no columnas calculadas), asegurando máximo rendimiento en memoria.
4. **Bonificación de Drill Down:** Las jerarquías están diseñadas; su implementación y funcionamiento deben comprobarse en Power BI Desktop. No se consideran implementadas por existir este documento.

## 5. Validación SQL previa a Power BI

Los scripts de [database/reports/](../database/reports/) obtienen indicadores, detalles de los 15 reportes y ocho escenarios del piloto V1. Ejecutar `python database/reports/validar_reportes.py` antes de comparar el modelo de Power BI. Las cifras dependen de la carga aceptada actual: no son constantes obligatorias para una nueva fuente.

Esta validación comprueba consultas y coherencia del DW, no ejecuta DAX ni verifica interacciones visuales. Para C1/C4, los conteos de cartera no se reducen por fecha de venta con filtros unidireccionales; los compradores y ventas sí. C3 usa como referencia la última fecha de venta global de la carga, no la fecha de hoy. En C2 deben definirse explícitamente los filtros del universo del Pareto y cómo tratar empates; el control SQL incluye toda la cartera compradora, no solo el top 50 mostrado.
