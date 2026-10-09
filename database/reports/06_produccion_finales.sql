-- Solo lectura: referencias de P1-P5 y controles de granularidad.
USE AdventureWorksDW;
SET NOCOUNT ON;

SELECT 'P1' AS Reporte, COUNT_BIG(*) AS Ordenes,
 SUM(CAST(OrderQty AS bigint)) AS Ordenadas,
 SUM(CAST(StockedQty AS bigint)) AS Almacenadas,
 SUM(CAST(ScrappedQty AS bigint)) AS Descartadas,
 SUM(CASE WHEN CAST(StockedQty AS bigint)+ScrappedQty<>OrderQty THEN 1 ELSE 0 END) AS Inconsistencias
FROM dbo.FactWorkOrder;

SELECT 'P2' AS Reporte, SUM(CAST(ScrapCost AS decimal(28,4))) AS CostoEstimado,
 CAST(SUM(CAST(ScrappedQty AS bigint)) AS decimal(28,6))/NULLIF(SUM(CAST(OrderQty AS bigint)),0) AS Tasa,
 SUM(CASE WHEN ScrappedQty>0 THEN 1 ELSE 0 END) AS OrdenesConDescarte,
 COUNT(DISTINCT CASE WHEN ScrappedQty>0 AND ScrapReasonKey<>0 THEN ScrapReasonKey END) AS MotivosUtilizados
FROM dbo.FactWorkOrder;

;WITH Stock AS (
 SELECT ProductKey,SUM(CAST(Quantity AS bigint)) AS Unidades
 FROM dbo.FactInventorySnapshot GROUP BY ProductKey
)
SELECT 'P3' AS Reporte,
 (SELECT SUM(CAST(Quantity AS bigint)) FROM dbo.FactInventorySnapshot) AS Stock,
 (SELECT SUM(CAST(InventoryValue AS decimal(28,4))) FROM dbo.FactInventorySnapshot) AS ValorEstimado,
 COUNT(*) AS ProductosConRegistro,
 SUM(CASE WHEN s.Unidades<p.ReorderPoint THEN 1 ELSE 0 END) AS BajoReordenGlobal
FROM Stock s JOIN dbo.DimProduct p ON p.ProductKey=s.ProductKey;

SELECT 'P4' AS Reporte,COUNT_BIG(*) AS Operaciones,
 SUM(ActualResourceHrs) AS Horas,SUM(CAST(ActualCost AS decimal(28,4))) AS CostoReal,
 SUM(CAST(PlannedCost AS decimal(28,4))) AS CostoPlanificado,
 SUM(CAST(CostVariance AS decimal(28,4))) AS Variacion,
 SUM(CASE WHEN ActualStartDateKey=-1 THEN 1 ELSE 0 END) AS SinInicioReal
FROM dbo.FactWorkOrderRouting;

SELECT 'P5' AS Reporte,COUNT_BIG(*) AS Productos,
 SUM(CASE WHEN MakeFlag=1 THEN 1 ELSE 0 END) AS Fabricados,
 SUM(CASE WHEN MakeFlag=0 THEN 1 ELSE 0 END) AS NoFabricados,
 SUM(CASE WHEN FinishedGoodsFlag=1 THEN 1 ELSE 0 END) AS Terminados
FROM dbo.DimProduct;

-- Revisar que las dimensiones no multipliquen ni eliminen hechos.
SELECT 'JOIN_WORK_ORDER' AS Control,COUNT_BIG(*) AS Filas,
 SUM(CAST(f.OrderQty AS bigint)) AS Unidades
FROM dbo.FactWorkOrder f JOIN dbo.DimProduct p ON p.ProductKey=f.ProductKey
 JOIN dbo.DimScrapReason r ON r.ScrapReasonKey=f.ScrapReasonKey;
SELECT 'JOIN_ROUTING' AS Control,COUNT_BIG(*) AS Filas,SUM(f.ActualResourceHrs) AS Horas
FROM dbo.FactWorkOrderRouting f JOIN dbo.DimProduct p ON p.ProductKey=f.ProductKey
 JOIN dbo.DimLocation l ON l.LocationKey=f.LocationKey;
SELECT 'JOIN_INVENTORY' AS Control,COUNT_BIG(*) AS Filas,SUM(CAST(f.Quantity AS bigint)) AS Stock
FROM dbo.FactInventorySnapshot f JOIN dbo.DimProduct p ON p.ProductKey=f.ProductKey
 JOIN dbo.DimLocation l ON l.LocationKey=f.LocationKey;

-- Calendario: sin eventos el indicador no debe inventar actividad.
SELECT 'FECHAS_PRODUCCION' AS Control,MIN(StartDateKey) AS Desde,MAX(StartDateKey) AS Hasta,
 SUM(CASE WHEN StartDateKey BETWEEN 20100101 AND 20101231 THEN 1 ELSE 0 END) AS Ordenes2010,
 SUM(CASE WHEN StartDateKey BETWEEN 20150101 AND 20151231 THEN 1 ELSE 0 END) AS Ordenes2015
FROM dbo.FactWorkOrder;

-- Referencia por ubicacion: el valor local varia, el umbral es global.
SELECT l.LocationName,COUNT(DISTINCT f.ProductKey) AS Productos,
 SUM(CAST(f.Quantity AS bigint)) AS StockLocal
FROM dbo.FactInventorySnapshot f JOIN dbo.DimLocation l ON l.LocationKey=f.LocationKey
GROUP BY l.LocationName ORDER BY l.LocationName;
