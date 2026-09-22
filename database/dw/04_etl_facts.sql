-- ==============================================================================
-- 04_etl_facts.sql
-- Extracción, Transformación y Carga (ETL) de Tablas de Hechos (Fact Tables)
-- Fuente: AdventureWorks2022 -> Destino: AdventureWorksDW
-- Proyecto: Ingeniería de Datos y Big Data - Entrega 2
-- ==============================================================================

USE [AdventureWorksDW];
GO

SET NOCOUNT ON;

PRINT '==============================================================================';
PRINT 'INICIANDO CARGA ETL DE TABLAS DE HECHOS';
PRINT '==============================================================================';

-- ------------------------------------------------------------------------------
-- 1. Cargar FactSales
-- ------------------------------------------------------------------------------
PRINT 'Cargando FactSales...';
TRUNCATE TABLE dbo.FactSales;

INSERT INTO dbo.FactSales (
    SalesOrderID,
    SalesOrderDetailID,
    OrderDateKey,
    DueDateKey,
    ShipDateKey,
    CustomerKey,
    ProductKey,
    TerritoryKey,
    SalesPersonKey,
    SpecialOfferKey,
    OnlineOrderFlag,
    OrderQty,
    UnitPrice,
    UnitPriceDiscount,
    DiscountAmount,
    LineTotal,
    ProductStandardCost,
    TotalProductCost,
    GrossMargin
)
SELECT 
    soh.SalesOrderID,
    sod.SalesOrderDetailID,
    YEAR(soh.OrderDate) * 10000 + MONTH(soh.OrderDate) * 100 + DAY(soh.OrderDate) AS OrderDateKey,
    YEAR(soh.DueDate) * 10000 + MONTH(soh.DueDate) * 100 + DAY(soh.DueDate) AS DueDateKey,
    COALESCE(YEAR(soh.ShipDate) * 10000 + MONTH(soh.ShipDate) * 100 + DAY(soh.ShipDate), -1) AS ShipDateKey,
    dc.CustomerKey,
    dp.ProductKey,
    dt.TerritoryKey,
    COALESCE(soh.SalesPersonID, 0) AS SalesPersonKey,
    dso.SpecialOfferKey,
    soh.OnlineOrderFlag,
    sod.OrderQty,
    sod.UnitPrice,
    sod.UnitPriceDiscount,
    CAST(sod.OrderQty * sod.UnitPrice * sod.UnitPriceDiscount AS MONEY) AS DiscountAmount,
    sod.LineTotal,
    dp.StandardCost AS ProductStandardCost,
    CAST(sod.OrderQty * dp.StandardCost AS MONEY) AS TotalProductCost,
    CAST(sod.LineTotal - (sod.OrderQty * dp.StandardCost) AS NUMERIC(38,6)) AS GrossMargin
FROM AdventureWorks2022.Sales.SalesOrderDetail sod
INNER JOIN AdventureWorks2022.Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
INNER JOIN dbo.DimCustomer dc ON soh.CustomerID = dc.CustomerID
INNER JOIN dbo.DimProduct dp ON sod.ProductID = dp.ProductID
INNER JOIN dbo.DimTerritory dt ON soh.TerritoryID = dt.TerritoryID
INNER JOIN dbo.DimSpecialOffer dso ON sod.SpecialOfferID = dso.SpecialOfferID;

PRINT 'FactSales cargada: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' registros.';

-- ------------------------------------------------------------------------------
-- 2. Cargar FactWorkOrder
-- ------------------------------------------------------------------------------
PRINT 'Cargando FactWorkOrder...';
TRUNCATE TABLE dbo.FactWorkOrder;

INSERT INTO dbo.FactWorkOrder (
    WorkOrderID,
    ProductKey,
    ScrapReasonKey,
    StartDateKey,
    EndDateKey,
    DueDateKey,
    OrderQty,
    StockedQty,
    ScrappedQty,
    ScrapCost
)
SELECT 
    wo.WorkOrderID,
    dp.ProductKey,
    COALESCE(wo.ScrapReasonID, 0) AS ScrapReasonKey,
    YEAR(wo.StartDate) * 10000 + MONTH(wo.StartDate) * 100 + DAY(wo.StartDate) AS StartDateKey,
    COALESCE(YEAR(wo.EndDate) * 10000 + MONTH(wo.EndDate) * 100 + DAY(wo.EndDate), -1) AS EndDateKey,
    YEAR(wo.DueDate) * 10000 + MONTH(wo.DueDate) * 100 + DAY(wo.DueDate) AS DueDateKey,
    wo.OrderQty,
    wo.StockedQty,
    wo.ScrappedQty,
    CAST(wo.ScrappedQty * dp.StandardCost AS MONEY) AS ScrapCost
FROM AdventureWorks2022.Production.WorkOrder wo
INNER JOIN dbo.DimProduct dp ON wo.ProductID = dp.ProductID;

PRINT 'FactWorkOrder cargada: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' registros.';

-- ------------------------------------------------------------------------------
-- 3. Cargar FactWorkOrderRouting
-- ------------------------------------------------------------------------------
PRINT 'Cargando FactWorkOrderRouting...';
TRUNCATE TABLE dbo.FactWorkOrderRouting;

INSERT INTO dbo.FactWorkOrderRouting (
    WorkOrderID,
    ProductKey,
    LocationKey,
    OperationSequence,
    ScheduledStartDateKey,
    ScheduledEndDateKey,
    ActualStartDateKey,
    ActualEndDateKey,
    ActualResourceHrs,
    PlannedCost,
    ActualCost,
    CostVariance
)
SELECT 
    wor.WorkOrderID,
    dp.ProductKey,
    dl.LocationKey,
    wor.OperationSequence,
    YEAR(wor.ScheduledStartDate) * 10000 + MONTH(wor.ScheduledStartDate) * 100 + DAY(wor.ScheduledStartDate) AS ScheduledStartDateKey,
    YEAR(wor.ScheduledEndDate) * 10000 + MONTH(wor.ScheduledEndDate) * 100 + DAY(wor.ScheduledEndDate) AS ScheduledEndDateKey,
    COALESCE(YEAR(wor.ActualStartDate) * 10000 + MONTH(wor.ActualStartDate) * 100 + DAY(wor.ActualStartDate), -1) AS ActualStartDateKey,
    COALESCE(YEAR(wor.ActualEndDate) * 10000 + MONTH(wor.ActualEndDate) * 100 + DAY(wor.ActualEndDate), -1) AS ActualEndDateKey,
    wor.ActualResourceHrs,
    wor.PlannedCost,
    wor.ActualCost,
    CAST(wor.ActualCost - wor.PlannedCost AS MONEY) AS CostVariance
FROM AdventureWorks2022.Production.WorkOrderRouting wor
INNER JOIN dbo.DimProduct dp ON wor.ProductID = dp.ProductID
INNER JOIN dbo.DimLocation dl ON wor.LocationID = dl.LocationID;

PRINT 'FactWorkOrderRouting cargada: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' registros.';

-- ------------------------------------------------------------------------------
-- 4. Cargar FactInventorySnapshot
-- ------------------------------------------------------------------------------
PRINT 'Cargando FactInventorySnapshot...';
TRUNCATE TABLE dbo.FactInventorySnapshot;

INSERT INTO dbo.FactInventorySnapshot (
    ProductKey,
    LocationKey,
    Shelf,
    Bin,
    Quantity,
    InventoryValue
)
SELECT 
    dp.ProductKey,
    dl.LocationKey,
    pi.Shelf,
    pi.Bin,
    pi.Quantity,
    CAST(pi.Quantity * dp.StandardCost AS MONEY) AS InventoryValue
FROM AdventureWorks2022.Production.ProductInventory pi
INNER JOIN dbo.DimProduct dp ON pi.ProductID = dp.ProductID
INNER JOIN dbo.DimLocation dl ON pi.LocationID = dl.LocationID;

PRINT 'FactInventorySnapshot cargada: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' registros.';

PRINT '==============================================================================';
PRINT 'CARGA DE TODAS LAS TABLAS DE HECHOS COMPLETADA';
PRINT '==============================================================================';
GO
