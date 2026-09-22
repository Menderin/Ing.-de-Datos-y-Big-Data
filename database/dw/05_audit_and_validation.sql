-- ==============================================================================
-- 05_audit_and_validation.sql
-- Auditoría de Integridad y Cuadratura: OLTP vs Data Warehouse (DW)
-- Proyecto: Ingeniería de Datos y Big Data - Entrega 2
-- ==============================================================================

USE [AdventureWorksDW];
GO

SET NOCOUNT ON;

PRINT '==============================================================================';
PRINT 'AUDITORIA DE CONTROL Y CUADRATURA: AdventureWorks2022 vs AdventureWorksDW';
PRINT '==============================================================================';

-- ------------------------------------------------------------------------------
-- 1. Comparación de Volumetría por Tabla
-- ------------------------------------------------------------------------------
SELECT 
    'DimCustomer' AS Tabla,
    (SELECT COUNT(*) FROM AdventureWorks2022.Sales.Customer) AS Filas_OLTP,
    (SELECT COUNT(*) FROM dbo.DimCustomer) AS Filas_DW,
    CASE 
        WHEN (SELECT COUNT(*) FROM AdventureWorks2022.Sales.Customer) = (SELECT COUNT(*) FROM dbo.DimCustomer) 
        THEN 'OK' ELSE 'ERROR' 
    END AS Estado
UNION ALL
SELECT 
    'DimProduct',
    (SELECT COUNT(*) FROM AdventureWorks2022.Production.Product),
    (SELECT COUNT(*) FROM dbo.DimProduct),
    CASE 
        WHEN (SELECT COUNT(*) FROM AdventureWorks2022.Production.Product) = (SELECT COUNT(*) FROM dbo.DimProduct) 
        THEN 'OK' ELSE 'ERROR' 
    END
UNION ALL
SELECT 
    'DimTerritory',
    (SELECT COUNT(*) FROM AdventureWorks2022.Sales.SalesTerritory),
    (SELECT COUNT(*) FROM dbo.DimTerritory),
    CASE 
        WHEN (SELECT COUNT(*) FROM AdventureWorks2022.Sales.SalesTerritory) = (SELECT COUNT(*) FROM dbo.DimTerritory) 
        THEN 'OK' ELSE 'ERROR' 
    END
UNION ALL
SELECT 
    'DimSalesPerson (incluye Canal Digital)',
    (SELECT COUNT(*) FROM AdventureWorks2022.Sales.SalesPerson) + 1,
    (SELECT COUNT(*) FROM dbo.DimSalesPerson),
    CASE 
        WHEN (SELECT COUNT(*) FROM AdventureWorks2022.Sales.SalesPerson) + 1 = (SELECT COUNT(*) FROM dbo.DimSalesPerson) 
        THEN 'OK' ELSE 'ERROR' 
    END
UNION ALL
SELECT 
    'DimSpecialOffer',
    (SELECT COUNT(*) FROM AdventureWorks2022.Sales.SpecialOffer),
    (SELECT COUNT(*) FROM dbo.DimSpecialOffer),
    CASE 
        WHEN (SELECT COUNT(*) FROM AdventureWorks2022.Sales.SpecialOffer) = (SELECT COUNT(*) FROM dbo.DimSpecialOffer) 
        THEN 'OK' ELSE 'ERROR' 
    END
UNION ALL
SELECT 
    'DimLocation',
    (SELECT COUNT(*) FROM AdventureWorks2022.Production.Location),
    (SELECT COUNT(*) FROM dbo.DimLocation),
    CASE 
        WHEN (SELECT COUNT(*) FROM AdventureWorks2022.Production.Location) = (SELECT COUNT(*) FROM dbo.DimLocation) 
        THEN 'OK' ELSE 'ERROR' 
    END
UNION ALL
SELECT 
    'DimScrapReason (incluye Conforme)',
    (SELECT COUNT(*) FROM AdventureWorks2022.Production.ScrapReason) + 1,
    (SELECT COUNT(*) FROM dbo.DimScrapReason),
    CASE 
        WHEN (SELECT COUNT(*) FROM AdventureWorks2022.Production.ScrapReason) + 1 = (SELECT COUNT(*) FROM dbo.DimScrapReason) 
        THEN 'OK' ELSE 'ERROR' 
    END
UNION ALL
SELECT 
    'FactSales',
    (SELECT COUNT(*) FROM AdventureWorks2022.Sales.SalesOrderDetail),
    (SELECT COUNT(*) FROM dbo.FactSales),
    CASE 
        WHEN (SELECT COUNT(*) FROM AdventureWorks2022.Sales.SalesOrderDetail) = (SELECT COUNT(*) FROM dbo.FactSales) 
        THEN 'OK' ELSE 'ERROR' 
    END
UNION ALL
SELECT 
    'FactWorkOrder',
    (SELECT COUNT(*) FROM AdventureWorks2022.Production.WorkOrder),
    (SELECT COUNT(*) FROM dbo.FactWorkOrder),
    CASE 
        WHEN (SELECT COUNT(*) FROM AdventureWorks2022.Production.WorkOrder) = (SELECT COUNT(*) FROM dbo.FactWorkOrder) 
        THEN 'OK' ELSE 'ERROR' 
    END
UNION ALL
SELECT 
    'FactWorkOrderRouting',
    (SELECT COUNT(*) FROM AdventureWorks2022.Production.WorkOrderRouting),
    (SELECT COUNT(*) FROM dbo.FactWorkOrderRouting),
    CASE 
        WHEN (SELECT COUNT(*) FROM AdventureWorks2022.Production.WorkOrderRouting) = (SELECT COUNT(*) FROM dbo.FactWorkOrderRouting) 
        THEN 'OK' ELSE 'ERROR' 
    END
UNION ALL
SELECT 
    'FactInventorySnapshot',
    (SELECT COUNT(*) FROM AdventureWorks2022.Production.ProductInventory),
    (SELECT COUNT(*) FROM dbo.FactInventorySnapshot),
    CASE 
        WHEN (SELECT COUNT(*) FROM AdventureWorks2022.Production.ProductInventory) = (SELECT COUNT(*) FROM dbo.FactInventorySnapshot) 
        THEN 'OK' ELSE 'ERROR' 
    END;

-- ------------------------------------------------------------------------------
-- 2. Cuadratura Monetaria y Cuantitativa de Hechos
-- ------------------------------------------------------------------------------
SELECT 
    'Total Ventas Netas (LineTotal)' AS Metrica,
    CAST((SELECT SUM(LineTotal) FROM AdventureWorks2022.Sales.SalesOrderDetail) AS NUMERIC(18,2)) AS Valor_OLTP,
    CAST((SELECT SUM(LineTotal) FROM dbo.FactSales) AS NUMERIC(18,2)) AS Valor_DW,
    CASE 
        WHEN ABS((SELECT SUM(LineTotal) FROM AdventureWorks2022.Sales.SalesOrderDetail) - (SELECT SUM(LineTotal) FROM dbo.FactSales)) < 0.01 
        THEN 'CUADRA EXACTO' ELSE 'DESCUADRE' 
    END AS Estado
UNION ALL
SELECT 
    'Unidades Vendidas (OrderQty)',
    (SELECT SUM(OrderQty) FROM AdventureWorks2022.Sales.SalesOrderDetail),
    (SELECT SUM(OrderQty) FROM dbo.FactSales),
    CASE 
        WHEN (SELECT SUM(OrderQty) FROM AdventureWorks2022.Sales.SalesOrderDetail) = (SELECT SUM(OrderQty) FROM dbo.FactSales) 
        THEN 'CUADRA EXACTO' ELSE 'DESCUADRE' 
    END
UNION ALL
SELECT 
    'Unidades Planificadas (WorkOrder)',
    (SELECT SUM(OrderQty) FROM AdventureWorks2022.Production.WorkOrder),
    (SELECT SUM(OrderQty) FROM dbo.FactWorkOrder),
    CASE 
        WHEN (SELECT SUM(OrderQty) FROM AdventureWorks2022.Production.WorkOrder) = (SELECT SUM(OrderQty) FROM dbo.FactWorkOrder) 
        THEN 'CUADRA EXACTO' ELSE 'DESCUADRE' 
    END
UNION ALL
SELECT 
    'Unidades Desechadas (Scrap)',
    (SELECT SUM(ScrappedQty) FROM AdventureWorks2022.Production.WorkOrder),
    (SELECT SUM(ScrappedQty) FROM dbo.FactWorkOrder),
    CASE 
        WHEN (SELECT SUM(ScrappedQty) FROM AdventureWorks2022.Production.WorkOrder) = (SELECT SUM(ScrappedQty) FROM dbo.FactWorkOrder) 
        THEN 'CUADRA EXACTO' ELSE 'DESCUADRE' 
    END
UNION ALL
SELECT 
    'Horas Reales Operaciones',
    CAST((SELECT SUM(ActualResourceHrs) FROM AdventureWorks2022.Production.WorkOrderRouting) AS NUMERIC(18,2)),
    CAST((SELECT SUM(ActualResourceHrs) FROM dbo.FactWorkOrderRouting) AS NUMERIC(18,2)),
    CASE 
        WHEN ABS((SELECT SUM(ActualResourceHrs) FROM AdventureWorks2022.Production.WorkOrderRouting) - (SELECT SUM(ActualResourceHrs) FROM dbo.FactWorkOrderRouting)) < 0.01 
        THEN 'CUADRA EXACTO' ELSE 'DESCUADRE' 
    END
UNION ALL
SELECT 
    'Costo Real de Operaciones',
    CAST((SELECT SUM(ActualCost) FROM AdventureWorks2022.Production.WorkOrderRouting) AS NUMERIC(18,2)),
    CAST((SELECT SUM(ActualCost) FROM dbo.FactWorkOrderRouting) AS NUMERIC(18,2)),
    CASE 
        WHEN ABS((SELECT SUM(ActualCost) FROM AdventureWorks2022.Production.WorkOrderRouting) - (SELECT SUM(ActualCost) FROM dbo.FactWorkOrderRouting)) < 0.01 
        THEN 'CUADRA EXACTO' ELSE 'DESCUADRE' 
    END
UNION ALL
SELECT 
    'Stock Físico en Almacén',
    (SELECT SUM(Quantity) FROM AdventureWorks2022.Production.ProductInventory),
    (SELECT SUM(Quantity) FROM dbo.FactInventorySnapshot),
    CASE 
        WHEN (SELECT SUM(Quantity) FROM AdventureWorks2022.Production.ProductInventory) = (SELECT SUM(Quantity) FROM dbo.FactInventorySnapshot) 
        THEN 'CUADRA EXACTO' ELSE 'DESCUADRE' 
    END;

-- ------------------------------------------------------------------------------
-- 3. Verificación de Cero Huérfanos / Integridad Referencial
-- ------------------------------------------------------------------------------
SELECT 
    'FactSales' AS Tabla_Hecho,
    SUM(CASE WHEN dc.CustomerKey IS NULL THEN 1 ELSE 0 END) AS Clientes_Huerfanos,
    SUM(CASE WHEN dp.ProductKey IS NULL THEN 1 ELSE 0 END) AS Productos_Huerfanos,
    SUM(CASE WHEN dt.TerritoryKey IS NULL THEN 1 ELSE 0 END) AS Territorios_Huerfanos,
    SUM(CASE WHEN dd.DateKey IS NULL THEN 1 ELSE 0 END) AS Fechas_Huerfanas
FROM dbo.FactSales f
LEFT JOIN dbo.DimCustomer dc ON f.CustomerKey = dc.CustomerKey
LEFT JOIN dbo.DimProduct dp ON f.ProductKey = dp.ProductKey
LEFT JOIN dbo.DimTerritory dt ON f.TerritoryKey = dt.TerritoryKey
LEFT JOIN dbo.DimDate dd ON f.OrderDateKey = dd.DateKey;
GO
