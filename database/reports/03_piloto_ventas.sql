-- Casos para contrastar filtros del piloto V1. Solo lectura.
USE AdventureWorksDW;
SET NOCOUNT ON;
DECLARE @cases TABLE(Code varchar(30),YearFilter int,MonthFilter int,Territory nvarchar(50),Online bit);
INSERT @cases VALUES
 ('sin_filtros',NULL,NULL,NULL,NULL),('anio_2013',2013,NULL,NULL,NULL),
 ('southwest',NULL,NULL,'Southwest',NULL),('2013_southwest',2013,NULL,'Southwest',NULL),
 ('junio_2013',2013,6,NULL,NULL),('online',NULL,NULL,NULL,1),
 ('2013_southwest_online',2013,NULL,'Southwest',1),('sin_ventas_2010',2010,NULL,NULL,NULL);
DECLARE @code varchar(30),@year int,@month int,@territory nvarchar(50),@online bit,@payload nvarchar(max);
DECLARE cases CURSOR LOCAL FAST_FORWARD FOR SELECT Code,YearFilter,MonthFilter,Territory,Online FROM @cases;
OPEN cases;
FETCH NEXT FROM cases INTO @code,@year,@month,@territory,@online;
WHILE @@FETCH_STATUS=0 BEGIN
 SELECT @payload=(SELECT COUNT_BIG(*) AS lineas,SUM(f.LineTotal) AS ventas,
  SUM(CAST(f.TotalProductCost AS decimal(28,4))) AS costo,SUM(f.GrossMargin) AS margen,
  CAST(SUM(f.GrossMargin) AS decimal(28,6))/NULLIF(CAST(SUM(f.LineTotal) AS decimal(28,6)),0) AS margen_pct,
  COUNT(DISTINCT f.SalesOrderID) AS ordenes,
  CAST(SUM(f.LineTotal) AS decimal(28,6))/NULLIF(COUNT(DISTINCT f.SalesOrderID),0) AS ticket,
  SUM(CAST(f.OrderQty AS bigint)) AS unidades
 FROM dbo.FactSales f JOIN dbo.DimDate d ON d.DateKey=f.OrderDateKey JOIN dbo.DimTerritory t ON t.TerritoryKey=f.TerritoryKey
 WHERE (@year IS NULL OR d.[Year]=@year) AND (@month IS NULL OR d.[Month]=@month)
 AND (@territory IS NULL OR t.TerritoryName=@territory) AND (@online IS NULL OR f.OnlineOrderFlag=@online)
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
 PRINT N'PILOT|'+@code+N'|'+@payload;
 FETCH NEXT FROM cases INTO @code,@year,@month,@territory,@online;
END;
CLOSE cases;
DEALLOCATE cases;

-- Verificar que las uniones conservan todas las lineas e importes.
IF (SELECT COUNT_BIG(*) FROM dbo.FactSales) <> (
 SELECT COUNT_BIG(*) FROM dbo.FactSales f
 JOIN dbo.DimDate d ON d.DateKey=f.OrderDateKey JOIN dbo.DimTerritory t ON t.TerritoryKey=f.TerritoryKey)
 THROW 51101,'El join de fecha/territorio pierde o multiplica ventas.',1;
PRINT 'CHECK|join_fecha_territorio|OK';

DECLARE @total decimal(38,6)=(SELECT SUM(LineTotal) FROM dbo.FactSales);
DECLARE @byMonth decimal(38,6)=(SELECT SUM(s.Ventas) FROM (
 SELECT d.MonthYear,SUM(f.LineTotal) AS Ventas FROM dbo.FactSales f JOIN dbo.DimDate d ON d.DateKey=f.OrderDateKey GROUP BY d.MonthYear) s);
DECLARE @byTerritory decimal(38,6)=(SELECT SUM(s.Ventas) FROM (
 SELECT t.TerritoryKey,SUM(f.LineTotal) AS Ventas FROM dbo.FactSales f JOIN dbo.DimTerritory t ON t.TerritoryKey=f.TerritoryKey GROUP BY t.TerritoryKey) s);
IF COALESCE(@total,0)<>COALESCE(@byMonth,0) OR COALESCE(@total,0)<>COALESCE(@byTerritory,0)
 THROW 51102,'La agrupacion mensual/territorial no reconcilia.',1;
PRINT 'CHECK|reconciliacion_graficos|OK';
