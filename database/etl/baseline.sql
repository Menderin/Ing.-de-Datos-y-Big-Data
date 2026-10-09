USE AdventureWorksDW;
SELECT 'FactSales' AS Tabla, COUNT_BIG(*) AS Filas, SUM(LineTotal) AS Total,
 SUM(CAST(OrderQty AS BIGINT)) AS Unidades FROM dbo.FactSales;
SELECT 'FactWorkOrder' AS Tabla, COUNT_BIG(*) AS Filas, SUM(CAST(OrderQty AS BIGINT)) AS Unidades,
 SUM(CAST(ScrappedQty AS BIGINT)) AS Descartadas FROM dbo.FactWorkOrder;
SELECT 'FactWorkOrderRouting' AS Tabla, COUNT_BIG(*) AS Filas,
 SUM(ActualResourceHrs) AS Horas, SUM(ActualCost) AS Costo FROM dbo.FactWorkOrderRouting;
SELECT 'FactInventorySnapshot' AS Tabla, COUNT_BIG(*) AS Filas,
 SUM(CAST(Quantity AS BIGINT)) AS Unidades FROM dbo.FactInventorySnapshot;
