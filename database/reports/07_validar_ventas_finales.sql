USE AdventureWorksDW;
SET NOCOUNT ON;

-- Controles de lectura: no altera fuente ni DW. Costos estándar vigentes.
SELECT COUNT_BIG(*) AS Lineas, COUNT(DISTINCT SalesOrderID) AS Ordenes,
       SUM(LineTotal) AS VentaNeta, SUM(OrderQty) AS Unidades,
       COUNT(DISTINCT ProductKey) AS Productos,
       MIN(OrderDateKey) AS PrimeraFecha, MAX(OrderDateKey) AS UltimaFecha
FROM dbo.FactSales;

SELECT TOP (10) p.ProductID, p.ProductName, SUM(f.LineTotal) AS VentaNeta,
       SUM(f.OrderQty) AS Unidades, SUM(f.GrossMargin) AS MargenEstimado
FROM dbo.FactSales f JOIN dbo.DimProduct p ON p.ProductKey=f.ProductKey
GROUP BY p.ProductID,p.ProductName
ORDER BY VentaNeta DESC,p.ProductID;

SELECT t.[Group],t.CountryRegionCode,t.TerritoryName,
       SUM(f.LineTotal) AS VentaNeta,COUNT(DISTINCT f.SalesOrderID) AS Ordenes,
       COUNT(DISTINCT f.CustomerKey) AS Compradores
FROM dbo.FactSales f JOIN dbo.DimTerritory t ON t.TerritoryKey=f.TerritoryKey
GROUP BY t.[Group],t.CountryRegionCode,t.TerritoryName
ORDER BY VentaNeta DESC;

SELECT COUNT(DISTINCT f.SalesPersonKey) AS Vendedores,
       COUNT(DISTINCT f.SalesOrderID) AS OrdenesConVendedor,
       SUM(f.LineTotal) AS VentaConVendedor
FROM dbo.FactSales f JOIN dbo.DimSalesPerson s ON s.SalesPersonKey=f.SalesPersonKey
WHERE s.SalesPersonKey<>0;

SELECT SUM(CONVERT(decimal(38,6),OrderQty)*UnitPrice) AS VentaBruta,
       SUM(DiscountAmount) AS Descuento,
       SUM(LineTotal) AS VentaNeta,
       SUM(LineTotal)-SUM(CONVERT(decimal(38,6),OrderQty)*UnitPrice)+SUM(DiscountAmount) AS AjusteRedondeo,
       SUM(CASE WHEN UnitPriceDiscount>0 THEN LineTotal ELSE 0 END) AS VentaConDescuento
FROM dbo.FactSales;

SELECT o.[Type],COUNT_BIG(*) AS Lineas,
       SUM(f.LineTotal) AS VentaNeta,SUM(f.DiscountAmount) AS Descuento,
       SUM(CASE WHEN f.UnitPriceDiscount>0 THEN 1 ELSE 0 END) AS LineasConDescuento
FROM dbo.FactSales f JOIN dbo.DimSpecialOffer o ON o.SpecialOfferKey=f.SpecialOfferKey
GROUP BY o.[Type] ORDER BY VentaNeta DESC;

-- Relaciones nuevas: cero huérfanos y claves de dimensiones únicas.
SELECT SUM(CASE WHEN s.SalesPersonKey IS NULL THEN 1 ELSE 0 END) AS VendedorHuerfano,
       SUM(CASE WHEN o.SpecialOfferKey IS NULL THEN 1 ELSE 0 END) AS OfertaHuerfana
FROM dbo.FactSales f
LEFT JOIN dbo.DimSalesPerson s ON s.SalesPersonKey=f.SalesPersonKey
LEFT JOIN dbo.DimSpecialOffer o ON o.SpecialOfferKey=f.SpecialOfferKey;
SELECT 'Vendedores' AS Dimension,COUNT(*) AS Filas,COUNT(DISTINCT SalesPersonKey) AS Claves FROM dbo.DimSalesPerson
UNION ALL SELECT 'Ofertas',COUNT(*),COUNT(DISTINCT SpecialOfferKey) FROM dbo.DimSpecialOffer;

SELECT COUNT_BIG(*) AS VentasFueraCalendario
FROM dbo.FactSales f LEFT JOIN dbo.DimDate d ON d.DateKey=f.OrderDateKey AND d.DateKey<>-1
WHERE d.DateKey IS NULL;
