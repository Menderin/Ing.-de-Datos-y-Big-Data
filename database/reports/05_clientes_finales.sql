-- Controles adicionales de C2-C5. No modifica tablas permanentes.
USE AdventureWorksDW;
SET NOCOUNT ON;
SELECT 'C2' AS Reporte, SUM(LineTotal) AS Ventas,
 SUM(LineTotal)/NULLIF(COUNT(DISTINCT CustomerKey),0) AS VentaPorComprador
FROM dbo.FactSales;
;WITH ClientSales AS (SELECT c.CustomerID,SUM(f.LineTotal) AS Venta
 FROM dbo.FactSales f JOIN dbo.DimCustomer c ON c.CustomerKey=f.CustomerKey GROUP BY c.CustomerID),
 TopClients AS (SELECT TOP(10) * FROM ClientSales ORDER BY Venta DESC,CustomerID)
SELECT 'C2_TOP10' AS Reporte,SUM(Venta) AS VentasTop10,
 SUM(Venta)/(SELECT SUM(Venta) FROM ClientSales) AS ParticipacionTop10 FROM TopClients;
DECLARE @ref date=(SELECT MAX(d.FullDate) FROM dbo.FactSales f JOIN dbo.DimDate d ON d.DateKey=f.OrderDateKey);
;WITH History AS (SELECT f.CustomerKey,COUNT(DISTINCT f.SalesOrderID) AS Ordenes,MAX(d.FullDate) AS Ultima
 FROM dbo.FactSales f JOIN dbo.DimDate d ON d.DateKey=f.OrderDateKey GROUP BY f.CustomerKey)
SELECT 'C3' AS Reporte, SUM(CASE WHEN Ordenes=1 THEN 1 ELSE 0 END) AS CompraUnica,
 SUM(CASE WHEN Ordenes BETWEEN 2 AND 3 THEN 1 ELSE 0 END) AS Recurrentes,
 SUM(CASE WHEN Ordenes>3 THEN 1 ELSE 0 END) AS Frecuentes,
 AVG(CAST(DATEDIFF(DAY,Ultima,@ref) AS decimal(18,6))) AS RecenciaMedia,@ref AS Referencia FROM History;
SELECT 'C4' AS Reporte,
 (SELECT COUNT(DISTINCT CountryRegionName) FROM dbo.DimCustomer WHERE CountryRegionName NOT IN ('','No Informado')) AS Paises,
 (SELECT COUNT(*) FROM (SELECT CountryRegionName,StateProvinceName FROM dbo.DimCustomer WHERE StateProvinceName NOT IN ('','No Informado') GROUP BY CountryRegionName,StateProvinceName) p) AS Provincias,
 (SELECT COUNT(*) FROM (SELECT CountryRegionName,StateProvinceName,City FROM dbo.DimCustomer WHERE City NOT IN ('','No Informado') GROUP BY CountryRegionName,StateProvinceName,City) c) AS Ciudades,
 (SELECT COUNT(*) FROM dbo.DimCustomer WHERE CountryRegionName IS NULL OR CountryRegionName IN ('','No Informado')) AS SinPais;
SELECT 'C5' AS Reporte,OnlineOrderFlag AS Online,COUNT(DISTINCT SalesOrderID) AS Ordenes,
 SUM(LineTotal)/NULLIF(COUNT(DISTINCT SalesOrderID),0) AS Ticket,SUM(LineTotal) AS Ventas
FROM dbo.FactSales GROUP BY OnlineOrderFlag;
IF (SELECT COUNT(DISTINCT SalesOrderID) FROM dbo.FactSales) <>
 ((SELECT COUNT(DISTINCT SalesOrderID) FROM dbo.FactSales WHERE OnlineOrderFlag=1)+
  (SELECT COUNT(DISTINCT SalesOrderID) FROM dbo.FactSales WHERE OnlineOrderFlag=0))
 THROW 51022, 'Una orden aparece en ambos canales: revisar fuente.', 1;
PRINT 'C5: particion de ordenes por canal OK';

-- Regresion de la captura: marzo 2012, tiendas del territorio del cliente Central.
SELECT 'C2_MARZO2012_TIENDAS_CENTRAL' AS Caso,
 COUNT(DISTINCT f.CustomerKey) AS Compradores, SUM(f.LineTotal) AS Ventas
FROM dbo.FactSales f JOIN dbo.DimCustomer c ON c.CustomerKey=f.CustomerKey
 JOIN dbo.DimDate d ON d.DateKey=f.OrderDateKey
WHERE d.[Year]=2012 AND d.[Month]=3 AND c.CustomerType='Store' AND c.TerritoryName='Central';
