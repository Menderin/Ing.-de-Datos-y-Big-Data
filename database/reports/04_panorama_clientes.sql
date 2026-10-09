-- C1: controles de cartera y compradores por periodo. Solo lectura.
USE AdventureWorksDW;
SET NOCOUNT ON;
DECLARE @Cases TABLE (Caso varchar(50), Anio int NULL, Tipo nvarchar(20) NULL, Territorio nvarchar(50) NULL);
INSERT INTO @Cases VALUES ('sin_filtros',NULL,NULL,NULL),('anio_2013',2013,NULL,NULL),
 ('sin_ventas_2010',2010,NULL,NULL),('individuales',NULL,'Individual',NULL),
 ('tiendas',NULL,'Store',NULL),('southwest',NULL,NULL,'Southwest'),
 ('2013_tiendas_southwest',2013,'Store','Southwest');
SELECT k.Caso,r.Registrados,b.Compradores,r.Registrados-b.Compradores AS SinCompra,
 CAST(b.Compradores AS decimal(18,8))/NULLIF(r.Registrados,0) AS PorcentajeCompradores
FROM @Cases k
CROSS APPLY (SELECT COUNT_BIG(*) AS Registrados FROM dbo.DimCustomer c
 WHERE (k.Tipo IS NULL OR c.CustomerType=k.Tipo)
 AND (k.Territorio IS NULL OR c.TerritoryName=k.Territorio)) r
CROSS APPLY (SELECT COUNT(DISTINCT f.CustomerKey) AS Compradores
 FROM dbo.FactSales f JOIN dbo.DimCustomer c ON c.CustomerKey=f.CustomerKey
 JOIN dbo.DimDate d ON d.DateKey=f.OrderDateKey
 WHERE (k.Anio IS NULL OR d.[Year]=k.Anio)
 AND (k.Tipo IS NULL OR c.CustomerType=k.Tipo)
 AND (k.Territorio IS NULL OR c.TerritoryName=k.Territorio)) b
ORDER BY k.Caso;

SELECT CustomerType,COUNT_BIG(*) AS Registrados FROM dbo.DimCustomer GROUP BY CustomerType;
IF EXISTS (SELECT 1 FROM dbo.FactSales f LEFT JOIN dbo.DimCustomer c ON c.CustomerKey=f.CustomerKey WHERE c.CustomerKey IS NULL)
 THROW 51020, 'C1: ventas con cliente inexistente.', 1;
IF (SELECT COUNT_BIG(*) FROM dbo.FactSales) <> (SELECT COUNT_BIG(*) FROM dbo.FactSales f JOIN dbo.DimCustomer c ON c.CustomerKey=f.CustomerKey)
 THROW 51021, 'C1: la union de clientes altera las filas de venta.', 1;
PRINT 'C1: integridad y cardinalidad de clientes OK';
