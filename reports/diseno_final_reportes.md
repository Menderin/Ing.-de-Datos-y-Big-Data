# Especificación Técnica y Diseño Final de Reportes (Entrega 2)

**Asignatura:** Ingeniería de Datos y Big Data  
**Plataforma Analítica:** Microsoft SQL Server 2022 (Data Warehouse `AdventureWorksDW`) & Power BI Desktop  
**Caso de Negocio:** *Adventure Works Cycles*  

---

## 1. Introducción y Marco de Reportabilidad

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
| **C1** | Clientes | Panorama General de Cartera | `FactSales` | `DimCustomer`, `DimTerritory`, `DimDate` | Cliente / Tipo de Cliente |
| **C2** | Clientes | Valor y Ranking de Clientes (Pareto) | `FactSales` | `DimCustomer`, `DimDate` | Cliente individual o tienda |
| **C3** | Clientes | Frecuencia y Recencia (RFM) | `FactSales` | `DimCustomer`, `DimDate` | Cliente consolidado |
| **C4** | Clientes | Distribución Geográfica de Clientes | `FactSales` | `DimCustomer`, `DimTerritory` | País / Estado / Ciudad |
| **C5** | Clientes | Canal de Compra (B2C vs B2B) | `FactSales` | `DimCustomer`, `DimSalesPerson`, `DimDate` | Canal de venta (Online / Asistido) |
| **P1** | Producción | Resumen General de Manufactura | `FactWorkOrder` | `DimProduct`, `DimDate` | Orden de trabajo |
| **P2** | Producción | Calidad y Desperdicio (*Scrap*) | `FactWorkOrder` | `DimProduct`, `DimScrapReason`, `DimDate` | Motivo de scrap / Producto |
| **P3** | Producción | Control de Inventario y Stock | `FactInventorySnapshot` | `DimProduct`, `DimLocation` | Producto / Ubicación de almacén |
| **P4** | Producción | Rendimiento Operacional por Centro | `FactWorkOrderRouting`| `DimProduct`, `DimLocation`, `DimDate` | Operación / Centro de trabajo |
| **P5** | Producción | Portafolio y Catálogo de Productos | `FactSales`, `FactInventorySnapshot` | `DimProduct` | Producto / Categoría / Subcategoría |
| **V1** | Ventas | Resumen Ejecutivo de Ventas | `FactSales` | `DimDate`, `DimTerritory` | Mensual / Territorial |
| **V2** | Ventas | Rendimiento por Producto y Categoría| `FactSales` | `DimProduct`, `DimDate` | Categoría / Subcategoría / Producto |
| **V3** | Ventas | Desempeño Territorial y Regional | `FactSales` | `DimTerritory`, `DimDate` | Grupo / País / Región |
| **V4** | Ventas | Desempeño y Cuotas de Vendedores | `FactSales` | `DimSalesPerson`, `DimTerritory`, `DimDate`| Ejecutivo de ventas |
| **V5** | Ventas | Descuentos, Ofertas y Venta Neta | `FactSales` | `DimSpecialOffer`, `DimProduct`, `DimDate` | Tipo de promoción |

---

## 3. Especificación Detallada por Perspectiva

### 3.1 Perspectiva 1: Clientes

#### Reporte C1: Panorama General de Cartera
- **Objetivo de Negocio:** Evaluar el crecimiento de la base de clientes, discriminando entre consumidores finales (personas B2C) y tiendas asociadas (distribuidores B2B).
- **Tarjetas KPI:**
  - *Clientes Registrados:* `DISTINCTCOUNT(DimCustomer[CustomerID])` (19.820)
  - *Clientes Compradores:* `CALCULATE(DISTINCTCOUNT(FactSales[CustomerKey]))` (19.119)
  - *Clientes Individuales:* `CALCULATE(COUNTROWS(DimCustomer), DimCustomer[CustomerType] = "Individual")` (18.484; 93,3%)
  - *Tiendas Asociadas:* `CALCULATE(COUNTROWS(DimCustomer), DimCustomer[CustomerType] = "Store")` (1.336; 6,7%)
- **Visualizaciones Principales:**
  - Gráfico de barras apiladas: Composición de clientes compradores vs no compradores por territorio.
  - Gráfico de donas: Proporción de clientes Individuales vs Tiendas.
  - Tabla de detalle: Lista de clientes con territorio, tipo y fecha de primera compra.
- **Jerarquía Drill Down:** `DimTerritory[Group]` → `DimTerritory[CountryRegionCode]` → `DimCustomer[StateProvinceName]` → `DimCustomer[CustomerName]`.

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
  - *Territorios Activos:* `DISTINCTCOUNT(DimTerritory[TerritoryKey])` (10)
  - *Países con Clientes:* `DISTINCTCOUNT(DimCustomer[CountryRegionName])` (6)
  - *Región Líder:* Región con mayor concentración de clientes (Southwest: 4.696 clientes).
  - *Venta Promedio por Territorio:* `AVERAGEX(VALUES(DimTerritory[TerritoryName]), [Total Ventas])`.
- **Visualizaciones Principales:**
  - Mapa coroplético / de burbujas: Densidad de clientes y volumen de facturación por país/estado.
  - Gráfico de barras horizontales: Clientes por territorio ordenados descendentemente.

#### Reporte C5: Canal de Compra (Digital B2C vs Asistido B2B)
- **Objetivo de Negocio:** Comparar la dinámica entre el canal de autoservicio web (`OnlineOrderFlag = 1`) y el canal tradicional atendido por ejecutivos comerciales (`OnlineOrderFlag = 0`).
- **Tarjetas KPI:**
  - *Órdenes Online:* `CALCULATE(DISTINCTCOUNT(FactSales[SalesOrderID]), FactSales[OnlineOrderFlag] = 1)` (27.659; 87,9%)
  - *Órdenes con Vendedor:* `CALCULATE(DISTINCTCOUNT(FactSales[SalesOrderID]), FactSales[OnlineOrderFlag] = 0)` (3.806; 12,1%)
  - *Ticket Promedio Online:* `$1.080` (ventas minoristas)
  - *Ticket Promedio Vendedor:* `$24.530` (pedidos mayoristas de tiendas)
- **Visualizaciones Principales:**
  - Gráfico de columnas agrupadas mensual: Facturación canal Online vs Facturación canal Vendedor.
  - Gráfico de cascada: Margen bruto porcentual aportado por cada canal.

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
  - Gráfico de barras por categoría de producto fabricado (Bicicletas, Componentes, Cuadros).
- **Jerarquía Drill Down:** `DimDate[Year]` → `DimDate[Quarter]` → `DimDate[MonthName]`.

#### Reporte P2: Calidad y Desperdicio (*Scrap Analysis*)
- **Objetivo de Negocio:** Diagnosticar las causas raíz de mermas y productos defectuosos para reducir costos de no calidad.
- **Tarjetas KPI:**
  - *Costo Total de Desperdicio:* `SUM(FactWorkOrder[ScrapCost])` ($184.250 est.)
  - *Tasa Global de Scrap:* `SUM(FactWorkOrder[ScrappedQty]) / SUM(FactWorkOrder[OrderQty])` (0,24%)
  - *Órdenes con Descarte:* `CALCULATE(COUNTROWS(FactWorkOrder), FactWorkOrder[ScrappedQty] > 0)` (729)
  - *Motivos de Descarte:* `DISTINCTCOUNT(DimScrapReason[ScrapReasonKey])` (16 motivos registrados)
- **Visualizaciones Principales:**
  - Gráfico de barras horizontales: Unidades y costos desechados por motivo (`DimScrapReason[ScrapReasonName]`).
  - Treemap: Productos con mayor impacto financiero por merma.

#### Reporte P3: Control de Inventario y Existencias Físicas
- **Objetivo de Negocio:** Mantener visibilidad del stock físico en cada almacén para evitar roturas de stock y optimizar capital de trabajo.
- **Tarjetas KPI:**
  - *Unidades en Stock:* `SUM(FactInventorySnapshot[Quantity])` (335.974)
  - *Valor del Inventario:* `SUM(FactInventorySnapshot[InventoryValue])`
  - *Productos con Existencia:* `DISTINCTCOUNT(FactInventorySnapshot[ProductKey])` (432)
  - *Centros de Almacenamiento:* `DISTINCTCOUNT(DimLocation[LocationKey])` (14)
- **Visualizaciones Principales:**
  - Gráfico de barras apiladas: Unidades disponibles por almacén (`DimLocation[LocationName]`).
  - Semáforo de stock: Productos por debajo del punto de reorden (`DimProduct[ReorderPoint]`).
- **Jerarquía Drill Down:** `DimLocation[LocationName]` → `DimProduct[CategoryName]` → `DimProduct[ProductName]`.

#### Reporte P4: Rendimiento Operacional por Centro de Trabajo
- **Objetivo de Negocio:** Medir la eficiencia y desviaciones en horas máquina/hombre y costos de manufactura.
- **Tarjetas KPI:**
  - *Operaciones Totales:* `COUNTROWS(FactWorkOrderRouting)` (67.131)
  - *Horas Reales de Recurso:* `SUM(FactWorkOrderRouting[ActualResourceHrs])` (228.962,20 hrs)
  - *Costo Real de Mano de Obra/Máquina:* `SUM(FactWorkOrderRouting[ActualCost])` ($3.487.969,50)
  - *Variación de Costo:* `SUM(FactWorkOrderRouting[CostVariance])` ($0,00 - cumplimiento presupuestario)
- **Visualizaciones Principales:**
  - Gráfico de columnas: Horas reales consumidas por centro de trabajo (`Subassembly`, `Frame Forming`, `Paint`, etc.).
  - Tabla de rendimiento: Secuencia de operaciones y tasas horarias (`DimLocation[CostRate]`).

#### Reporte P5: Portafolio y Catálogo de Productos
- **Objetivo de Negocio:** Analizar la cartera de artículos producidos internamente versus componentes adquiridos a terceros.
- **Tarjetas KPI:**
  - *Artículos en Catálogo:* `COUNTROWS(DimProduct)` (504)
  - *Productos Terminados para Venta:* `CALCULATE(COUNTROWS(DimProduct), DimProduct[FinishedGoodsFlag] = 1)` (295)
  - *Productos Fabricados Internamente:* `CALCULATE(COUNTROWS(DimProduct), DimProduct[MakeFlag] = 1)` (238)
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
  - *Margen Bruto Porcentual:* `[Margen Bruto] / [Ventas Netas]` (~42%)
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
  - *Categoría Líder en Facturación:* `Bikes` (> 85% de la facturación)
  - *Precio Promedio de Venta:* `AVERAGE(FactSales[UnitPrice])`
- **Visualizaciones Principales:**
  - Gráfico de barras jerárquico: Ventas y Margen por Categoría y Subcategoría.
  - Tabla Top 20 productos más vendidos (volumen monetario y unidades).
- **Jerarquía Drill Down:** `DimProduct[CategoryName]` → `DimProduct[SubcategoryName]` → `DimProduct[ProductName]`.

#### Reporte V3: Desempeño Territorial y Regional
- **Objetivo de Negocio:** Comparar el volumen de negocio y ticket medio entre mercados nacionales e internacionales.
- **Tarjetas KPI:**
  - *Territorios Comerciales:* 10
  - *Venta Nacional (Norteamérica):* Participación porcentual de US y Canadá (~55%).
  - *Venta Internacional:* Participación de Europa y Pacífico (~45%).
  - *Territorio con Mayor Venta:* Southwest / Northwest.
- **Visualizaciones Principales:**
  - Gráfico de columnas apiladas al 100%: Participación mensual de cada grupo territorial (`North America`, `Europe`, `Pacific`).
  - Mapa de calor con métricas de ventas y cantidad de clientes compradores.
- **Jerarquía Drill Down:** `DimTerritory[Group]` → `DimTerritory[CountryRegionCode]` → `DimTerritory[TerritoryName]`.

#### Reporte V4: Desempeño y Cuotas de Vendedores
- **Objetivo de Negocio:** Evaluar la productividad de la fuerza comercial presencial y el cumplimiento de cuotas individuales.
- **Tarjetas KPI:**
  - *Ejecutivos Comerciales:* 17 vendedores registrados
  - *Ventas Asistidas:* Facturación generada por vendedores presenciales
  - *Cumplimiento Global de Cuota:* `SUM(FactSales[LineTotal]) / SUM(DimSalesPerson[SalesQuota])`
  - *Comisión Total Estimada:* `SUMX(FactSales, FactSales[LineTotal] * RELATED(DimSalesPerson[CommissionPct]))`
- **Visualizaciones Principales:**
  - Gráfico de barras comparativo: Ventas reales vs Cuota asignada por vendedor.
  - Tabla de ranking comercial con bonus acumulado y territorio asignado.

#### Reporte V5: Descuentos, Ofertas y Venta Neta
- **Objetivo de Negocio:** Evaluar el impacto de las campañas promocionales y descuentos por volumen en el margen financiero.
- **Tarjetas KPI:**
  - *Venta Bruta (sin descuento):* `SUMX(FactSales, FactSales[OrderQty] * FactSales[UnitPrice])`
  - *Descuento Total Otorgado:* `SUM(FactSales[DiscountAmount])` ($3,18M)
  - *Venta Neta Efectiva:* `SUM(FactSales[LineTotal])`
  - *Tasa Promedio de Descuento:* `[Descuento Total] / [Venta Bruta]` (2,52%)
- **Visualizaciones Principales:**
  - Gráfico de cascada (Waterfall): De Venta Bruta a Venta Neta discriminando por tipo de oferta especial.
  - Gráfico de torta/anillo: Porcentaje de ventas con precio regular vs ventas bajo promoción.

---

## 4. Requisitos para la Implementación en Power BI (Entrega 3)

1. **Modo de Almacenamiento:** Conexión mediante modo **Importación** (VertiPaq) apuntando a la base `AdventureWorksDW` en `localhost,1433`.
2. **Modelo de Relaciones:** Esquema en estrella puro con dirección de filtro unidireccional (1 a varios desde las dimensiones hacia las tablas de hechos).
3. **Optimización de Medidas:** Todas las métricas dinámicas deben ser implementadas mediante medidas DAX explícitas (no columnas calculadas), asegurando máximo rendimiento en memoria.
4. **Bonificación de Drill Down:** Se implementaron las jerarquías requeridas en Tiempo, Geografía, Producto y Centro de Costo para habilitar la navegación interactiva solicitada en la pauta oficial.
