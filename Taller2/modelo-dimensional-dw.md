# Modelo Dimensional del Data Warehouse (AdventureWorksDW)

## 1. Arquitectura Dimensional (Esquema en Estrella / Constelación)

Para dar soporte a los 15 reportes analíticos de la plataforma de reportabilidad de **Adventure Works Cycles**, se diseñó e implementó un modelo dimensional basado en la metodología **Kimball**, conformado por **8 tablas de dimensiones** y **4 tablas de hechos**.

```text
               +-------------------+
               |      DimDate      |
               +-------------------+
                  |        |
                  |        |
+-------------------+      |      +---------------------+
|    DimCustomer    |      |      |   DimSalesPerson    |
+-------------------+      |      +---------------------+
        \                  |                 /
         \                 |                /
          +--------------------------------+
          |           FactSales            |
          +--------------------------------+
         /                 |                \
        /                  |                 \
+-------------------+      |      +---------------------+
|    DimProduct     |------+      |   DimSpecialOffer   |
+-------------------+      |      +---------------------+
     |       |             |
     |       |     +-------------------+
     |       |     |   DimTerritory    |
     |       |     +-------------------+
     |       |
     |       +-----------------------------+
     |                                     |
+----------------------+        +----------------------+
|    FactWorkOrder     |        | FactInventorySnapshot|
+----------------------+        +----------------------+
     |        |                            |
     |        +--------------+             |
     |                       |             |
+-------------------+        +-------------+
|   DimScrapReason  |        |
+-------------------+        |
                             |
                   +-----------------------+
                   |  FactWorkOrderRouting |
                   +-----------------------+
                             |
                   +-------------------+
                   |    DimLocation    |
                   +-------------------+
```

---

## 2. Dimensiones Conformadas

### 2.1 `DimDate` (Dimensión Calendario)
- **Clave Primaria:** `DateKey` (Entero en formato `YYYYMMDD`, e.g., `20130514`). Clave especial `-1` para fechas no aplicables.
- **Rango Temporal:** 01/01/2010 al 31/12/2015 (2.192 registros).
- **Atributos:** `FullDate`, `Year`, `Quarter`, `QuarterName`, `Month`, `MonthName`, `MonthYear`, `DayOfMonth`, `DayOfWeekNumber`, `DayOfWeekName`, `IsWeekend`.

### 2.2 `DimCustomer` (Clientes B2C y B2B)
- **Clave Subrogada:** `CustomerKey` (IDENTITY).
- **Clave Natural:** `CustomerID`.
- **Volumetría:** 19.820 registros.
- **Atributos:** `CustomerType` ('Individual' o 'Store'), `CustomerName`, `StoreName`, `City`, `StateProvinceName`, `CountryRegionName`, `TerritoryID`.

### 2.3 `DimProduct` (Catálogo y Manufactura)
- **Clave Subrogada:** `ProductKey` (IDENTITY).
- **Clave Natural:** `ProductID`.
- **Volumetría:** 504 registros.
- **Atributos:** `ProductName`, `ProductNumber`, `MakeFlag`, `FinishedGoodsFlag`, `Color`, `SafetyStockLevel`, `ReorderPoint`, `StandardCost`, `ListPrice`, `SubcategoryName`, `CategoryName`.

### 2.4 `DimTerritory` (Territorios Comerciales)
- **Clave Subrogada:** `TerritoryKey` (IDENTITY).
- **Clave Natural:** `TerritoryID`.
- **Volumetría:** 10 registros.
- **Atributos:** `TerritoryName`, `CountryRegionCode`, `Group` (`North America`, `Europe`, `Pacific`).

### 2.5 `DimSalesPerson` (Fuerza Comercial Presencial y Digital)
- **Clave:** `SalesPersonKey` (Entero). Clave especial `0` para "Venta Online / Sin Vendedor".
- **Volumetría:** 18 registros (17 ejecutivos presenciales + 1 canal digital).
- **Atributos:** `FullName`, `JobTitle`, `SalesQuota`, `Bonus`, `CommissionPct`, `TerritoryID`.

### 2.6 `DimSpecialOffer` (Promociones y Descuentos)
- **Clave Subrogada:** `SpecialOfferKey` (IDENTITY).
- **Clave Natural:** `SpecialOfferID`.
- **Volumetría:** 16 registros.
- **Atributos:** `Description`, `DiscountPct`, `Type`, `Category`.

### 2.7 `DimLocation` (Centros de Trabajo)
- **Clave Subrogada:** `LocationKey` (IDENTITY).
- **Clave Natural:** `LocationID`.
- **Volumetría:** 14 registros.
- **Atributos:** `LocationName`, `CostRate`, `Availability`.

### 2.8 `DimScrapReason` (Motivos de Descarte)
- **Clave:** `ScrapReasonKey` (Entero). Clave especial `0` para "Sin Desperdicio / Conforme".
- **Volumetría:** 17 registros (16 motivos registrados + 1 conforme).
- **Atributos:** `ScrapReasonName`.

---

## 3. Tablas de Hechos (Fact Tables)

### 3.1 `FactSales`
- **Granularidad:** Una fila por línea de detalle de pedido de venta (`SalesOrderDetail`).
- **Volumetría:** 121.317 filas asociadas a 31.465 órdenes.
- **Métricas:** `OrderQty`, `UnitPrice`, `UnitPriceDiscount`, `DiscountAmount`, `LineTotal`, `ProductStandardCost`, `TotalProductCost`, `GrossMargin`.
- **Claves Foráneas:** `OrderDateKey`, `DueDateKey`, `ShipDateKey`, `CustomerKey`, `ProductKey`, `TerritoryKey`, `SalesPersonKey`, `SpecialOfferKey`.

### 3.2 `FactWorkOrder`
- **Granularidad:** Una fila por orden de trabajo de manufactura (`WorkOrder`).
- **Volumetría:** 72.591 filas.
- **Métricas:** `OrderQty`, `StockedQty`, `ScrappedQty`, `ScrapCost`.
- **Claves Foráneas:** `ProductKey`, `ScrapReasonKey`, `StartDateKey`, `EndDateKey`, `DueDateKey`.

### 3.3 `FactWorkOrderRouting`
- **Granularidad:** Una fila por operación ejecutada en un centro de trabajo (`WorkOrderRouting`).
- **Volumetría:** 67.131 filas.
- **Métricas:** `ActualResourceHrs`, `PlannedCost`, `ActualCost`, `CostVariance`.
- **Claves Foráneas:** `ProductKey`, `LocationKey`, `ScheduledStartDateKey`, `ScheduledEndDateKey`, `ActualStartDateKey`, `ActualEndDateKey`.

### 3.4 `FactInventorySnapshot`
- **Granularidad:** Una fila por existencia física de producto en ubicación de almacén (`ProductInventory`).
- **Volumetría:** 1.069 filas.
- **Métricas:** `Quantity`, `InventoryValue` (`Quantity * StandardCost`).
- **Claves Foráneas:** `ProductKey`, `LocationKey`.
