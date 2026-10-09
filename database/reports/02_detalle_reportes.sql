-- Detalle para contrastar tablas y graficos. Solo lectura.
USE AdventureWorksDW;
SET NOCOUNT ON;

PRINT 'C1 - Cartera por tipo y territorio del cliente (no territorio de la venta)';
;WITH Buyers AS (SELECT DISTINCT CustomerKey FROM dbo.FactSales)
SELECT c.CustomerType,c.TerritoryName,COUNT_BIG(*) AS Registrados,
 COUNT(b.CustomerKey) AS Compradores,COUNT_BIG(*)-COUNT(b.CustomerKey) AS SinCompra
FROM dbo.DimCustomer c LEFT JOIN Buyers b ON b.CustomerKey=c.CustomerKey
GROUP BY c.CustomerType,c.TerritoryName ORDER BY c.CustomerType,c.TerritoryName;

PRINT 'C2 - Top 50 y Pareto; empates comparten porcentaje acumulado';
;WITH Sales AS (SELECT CustomerKey,SUM(LineTotal) AS Ventas,COUNT(DISTINCT SalesOrderID) AS Ordenes,SUM(GrossMargin) AS Margen
 FROM dbo.FactSales GROUP BY CustomerKey), Ranked AS (
 SELECT *,SUM(Ventas) OVER(ORDER BY Ventas DESC RANGE UNBOUNDED PRECEDING) AS Acumulado,
 SUM(Ventas) OVER() AS Total FROM Sales)
SELECT TOP(50) c.CustomerID,c.CustomerName,c.CustomerType,r.Ventas,r.Ordenes,r.Margen,
 CAST(r.Acumulado AS decimal(28,6))/NULLIF(CAST(r.Total AS decimal(28,6)),0) AS PorcentajeAcumulado
FROM Ranked r JOIN dbo.DimCustomer c ON c.CustomerKey=r.CustomerKey ORDER BY r.Ventas DESC,c.CustomerID;

PRINT 'C3 - Frecuencia y recencia; referencia = ultima venta de la carga';
DECLARE @reference date=(SELECT MAX(d.FullDate) FROM dbo.FactSales f JOIN dbo.DimDate d ON d.DateKey=f.OrderDateKey);
;WITH History AS (SELECT CustomerKey,COUNT(DISTINCT SalesOrderID) AS Ordenes,MAX(OrderDateKey) AS UltimaCompra,
 SUM(LineTotal) AS Ventas FROM dbo.FactSales GROUP BY CustomerKey), Segments AS (
 SELECT h.*,d.FullDate,DATEDIFF(DAY,d.FullDate,@reference) AS Recencia,
 CASE WHEN Ordenes>3 THEN 'Frecuente' WHEN Ordenes>=2 THEN 'Recurrente' ELSE 'Compra unica' END AS Segmento
 FROM History h JOIN dbo.DimDate d ON d.DateKey=h.UltimaCompra)
SELECT Segmento,COUNT_BIG(*) AS Clientes,SUM(Ventas) AS Ventas,AVG(CAST(Recencia AS decimal(18,4))) AS RecenciaMedia
FROM Segments GROUP BY Segmento ORDER BY Segmento;

PRINT 'C4 - Geografia del cliente; no confundir con el territorio comercial de V3';
;WITH CustomerSales AS (SELECT CustomerKey,SUM(LineTotal) AS Ventas FROM dbo.FactSales GROUP BY CustomerKey)
SELECT c.CountryRegionName,c.StateProvinceName,COUNT_BIG(*) AS Clientes,COUNT(s.CustomerKey) AS Compradores,
 SUM(COALESCE(s.Ventas,0)) AS Ventas FROM dbo.DimCustomer c LEFT JOIN CustomerSales s ON s.CustomerKey=c.CustomerKey
GROUP BY c.CountryRegionName,c.StateProvinceName ORDER BY Ventas DESC;

PRINT 'C5 - Canal y tipo de cliente son ejes distintos';
SELECT c.CustomerType,CASE WHEN f.OnlineOrderFlag=1 THEN 'Online' ELSE 'Asistido' END AS Canal,
 COUNT(DISTINCT f.SalesOrderID) AS Ordenes,SUM(f.LineTotal) AS Ventas,SUM(f.GrossMargin) AS Margen,
 CAST(SUM(f.LineTotal) AS decimal(28,6))/NULLIF(COUNT(DISTINCT f.SalesOrderID),0) AS Ticket
FROM dbo.FactSales f JOIN dbo.DimCustomer c ON c.CustomerKey=f.CustomerKey GROUP BY c.CustomerType,f.OnlineOrderFlag;

PRINT 'P1 - Produccion por mes de inicio y categoria';
SELECT d.MonthYear,p.CategoryName,COUNT_BIG(*) AS Ordenes,SUM(CAST(f.OrderQty AS bigint)) AS Planificadas,
 SUM(CAST(f.StockedQty AS bigint)) AS Almacenadas,SUM(CAST(f.ScrappedQty AS bigint)) AS Desechadas
FROM dbo.FactWorkOrder f JOIN dbo.DimDate d ON d.DateKey=f.StartDateKey JOIN dbo.DimProduct p ON p.ProductKey=f.ProductKey
GROUP BY d.MonthYear,p.CategoryName ORDER BY d.MonthYear,p.CategoryName;

PRINT 'P2 - Motivos reales; excluir miembro Sin Desperdicio';
SELECT r.ScrapReasonName,COUNT_BIG(*) AS Ordenes,SUM(CAST(f.ScrappedQty AS bigint)) AS Unidades,
 SUM(CAST(f.ScrapCost AS decimal(28,4))) AS Costo
FROM dbo.FactWorkOrder f JOIN dbo.DimScrapReason r ON r.ScrapReasonKey=f.ScrapReasonKey
WHERE f.ScrappedQty>0 AND f.ScrapReasonKey<>0 GROUP BY r.ScrapReasonName ORDER BY Costo DESC;

PRINT 'P3 - Foto actual; sumar stock por producto antes de comparar con reorden';
;WITH Stock AS (SELECT ProductKey,SUM(CAST(Quantity AS bigint)) AS Unidades FROM dbo.FactInventorySnapshot GROUP BY ProductKey)
SELECT p.ProductID,p.ProductName,s.Unidades,p.ReorderPoint,
 CASE WHEN s.Unidades<p.ReorderPoint THEN 'Bajo reorden' ELSE 'Suficiente' END AS Estado
FROM Stock s JOIN dbo.DimProduct p ON p.ProductKey=s.ProductKey ORDER BY s.Unidades-p.ReorderPoint,p.ProductID;

PRINT 'P4 - Operaciones por centro; fecha activa propuesta = inicio real';
SELECT l.LocationName,COUNT_BIG(*) AS Operaciones,SUM(f.ActualResourceHrs) AS Horas,
 SUM(CAST(f.PlannedCost AS decimal(28,4))) AS CostoPlanificado,SUM(CAST(f.ActualCost AS decimal(28,4))) AS CostoReal,
 SUM(CAST(f.CostVariance AS decimal(28,4))) AS Variacion
FROM dbo.FactWorkOrderRouting f JOIN dbo.DimLocation l ON l.LocationKey=f.LocationKey
GROUP BY l.LocationName ORDER BY Horas DESC;

PRINT 'P5 - Catalogo con ventas y stock; preagregar cada hecho, nunca unir hechos por producto sin agrupar';
;WITH Sales AS (SELECT ProductKey,SUM(LineTotal) AS Ventas FROM dbo.FactSales GROUP BY ProductKey),
 Stock AS (SELECT ProductKey,SUM(CAST(Quantity AS bigint)) AS Unidades FROM dbo.FactInventorySnapshot GROUP BY ProductKey)
SELECT p.ProductID,p.ProductName,p.CategoryName,p.MakeFlag,p.FinishedGoodsFlag,p.ListPrice,p.StandardCost,
 p.ListPrice-p.StandardCost AS MargenUnitarioLista,s.Ventas,i.Unidades AS StockActual
FROM dbo.DimProduct p LEFT JOIN Sales s ON s.ProductKey=p.ProductKey LEFT JOIN Stock i ON i.ProductKey=p.ProductKey ORDER BY p.ProductID;

PRINT 'V1 - Tendencia mensual por fecha de pedido';
SELECT d.MonthYear,SUM(f.LineTotal) AS Ventas,SUM(CAST(f.TotalProductCost AS decimal(28,4))) AS Costo,
 SUM(f.GrossMargin) AS Margen,COUNT(DISTINCT f.SalesOrderID) AS Ordenes,
 CAST(SUM(f.LineTotal) AS decimal(28,6))/NULLIF(COUNT(DISTINCT f.SalesOrderID),0) AS Ticket
FROM dbo.FactSales f JOIN dbo.DimDate d ON d.DateKey=f.OrderDateKey GROUP BY d.MonthYear ORDER BY d.MonthYear;

PRINT 'V2 - Ventas por categoria y subcategoria';
SELECT p.CategoryName,p.SubcategoryName,SUM(f.LineTotal) AS Ventas,SUM(f.GrossMargin) AS Margen,
 SUM(CAST(f.OrderQty AS bigint)) AS Unidades,COUNT(DISTINCT f.ProductKey) AS Productos
FROM dbo.FactSales f JOIN dbo.DimProduct p ON p.ProductKey=f.ProductKey
GROUP BY p.CategoryName,p.SubcategoryName ORDER BY Ventas DESC;

PRINT 'V3 - Territorio de la venta, no direccion actual del cliente';
SELECT t.[Group],t.CountryRegionCode,t.TerritoryName,SUM(f.LineTotal) AS Ventas,
 COUNT(DISTINCT f.CustomerKey) AS Compradores,COUNT(DISTINCT f.SalesOrderID) AS Ordenes
FROM dbo.FactSales f JOIN dbo.DimTerritory t ON t.TerritoryKey=f.TerritoryKey
GROUP BY t.[Group],t.CountryRegionCode,t.TerritoryName ORDER BY Ventas DESC;

PRINT 'V4 - Cuota y bonus actuales no se suman una vez por linea de venta';
;WITH Sales AS (SELECT SalesPersonKey,SUM(LineTotal) AS Ventas,COUNT(DISTINCT SalesOrderID) AS Ordenes
 FROM dbo.FactSales WHERE SalesPersonKey<>0 GROUP BY SalesPersonKey)
SELECT s.BusinessEntityID,s.FullName,s.SalesQuota,s.Bonus,s.CommissionPct,f.Ventas,f.Ordenes,
 CAST(f.Ventas AS decimal(28,6))/NULLIF(s.SalesQuota,0) AS IndiceVentasCuotaActual,
 f.Ventas*s.CommissionPct AS ComisionEstimada
FROM dbo.DimSalesPerson s LEFT JOIN Sales f ON f.SalesPersonKey=s.SalesPersonKey WHERE s.SalesPersonKey<>0 ORDER BY f.Ventas DESC;

PRINT 'V5 - Ofertas no equivale a descuento positivo en cada linea';
SELECT o.[Type],o.Category,COUNT_BIG(*) AS Lineas,
 SUM(CAST(f.OrderQty AS decimal(10,0))*f.UnitPrice) AS VentaBruta,
 SUM(CAST(f.DiscountAmount AS decimal(28,4))) AS Descuento,SUM(f.LineTotal) AS VentaNeta,
 SUM(f.GrossMargin) AS Margen
FROM dbo.FactSales f JOIN dbo.DimSpecialOffer o ON o.SpecialOfferKey=f.SpecialOfferKey
GROUP BY o.[Type],o.Category ORDER BY VentaNeta DESC;
