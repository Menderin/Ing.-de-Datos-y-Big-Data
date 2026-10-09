-- Controles de los 15 reportes. Solo lectura; valores de toda la carga actual.
USE AdventureWorksDW;
SET NOCOUNT ON;
CREATE TABLE #ReportControls(Code varchar(2) PRIMARY KEY, Payload nvarchar(max));

INSERT #ReportControls SELECT 'C1',(
 SELECT COUNT_BIG(*) AS registrados,
 SUM(CASE WHEN CustomerType='Individual' THEN 1 ELSE 0 END) AS individuales,
 SUM(CASE WHEN CustomerType='Store' THEN 1 ELSE 0 END) AS tiendas,
 (SELECT COUNT(DISTINCT CustomerKey) FROM dbo.FactSales) AS compradores
 FROM dbo.DimCustomer FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);

INSERT #ReportControls SELECT 'C2',(
 SELECT SUM(LineTotal) AS ventas,COUNT(DISTINCT CustomerKey) AS compradores,
 COUNT(DISTINCT SalesOrderID) AS ordenes,
 CAST(SUM(LineTotal) AS decimal(28,6))/NULLIF(COUNT(DISTINCT CustomerKey),0) AS ventas_por_cliente,
 CAST(COUNT(DISTINCT SalesOrderID) AS decimal(18,6))/NULLIF(COUNT(DISTINCT CustomerKey),0) AS ordenes_por_cliente,
 (SELECT SUM(t.Ventas) FROM (SELECT TOP(10) SUM(f.LineTotal) AS Ventas
   FROM dbo.FactSales f JOIN dbo.DimCustomer c ON c.CustomerKey=f.CustomerKey
   WHERE c.CustomerType='Store' GROUP BY c.CustomerKey ORDER BY SUM(f.LineTotal) DESC,c.CustomerKey) t) AS top10_tiendas
 FROM dbo.FactSales FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);

;WITH CustomerHistory AS (
 SELECT CustomerKey,COUNT(DISTINCT SalesOrderID) AS Orders,MAX(OrderDateKey) AS LastDate
 FROM dbo.FactSales GROUP BY CustomerKey
), Reference AS (SELECT MAX(d.FullDate) AS RefDate FROM dbo.FactSales f JOIN dbo.DimDate d ON d.DateKey=f.OrderDateKey)
INSERT #ReportControls SELECT 'C3',(
 SELECT COUNT_BIG(*) AS compradores,
 COALESCE(SUM(CASE WHEN h.Orders>3 THEN 1 ELSE 0 END),0) AS frecuentes,
 COALESCE(SUM(CASE WHEN h.Orders BETWEEN 2 AND 3 THEN 1 ELSE 0 END),0) AS recurrentes,
 COALESCE(SUM(CASE WHEN h.Orders=1 THEN 1 ELSE 0 END),0) AS compra_unica,
 AVG(CAST(DATEDIFF(DAY,d.FullDate,r.RefDate) AS decimal(18,6))) AS recencia_media_dias,
 MAX(r.RefDate) AS fecha_referencia
 FROM CustomerHistory h JOIN dbo.DimDate d ON d.DateKey=h.LastDate CROSS JOIN Reference r
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);

INSERT #ReportControls SELECT 'C4',(
 SELECT COUNT(DISTINCT CASE WHEN TerritoryName<>'No Informado' THEN TerritoryName END) AS territorios_con_clientes,
 COUNT(DISTINCT CASE WHEN CountryRegionName<>'No Informado' THEN CountryRegionName END) AS paises_con_clientes,
 SUM(CASE WHEN CountryRegionName='No Informado' THEN 1 ELSE 0 END) AS clientes_sin_pais,
 (SELECT TOP(1) TerritoryName FROM dbo.DimCustomer WHERE TerritoryName<>'No Informado'
  GROUP BY TerritoryName ORDER BY COUNT_BIG(*) DESC,TerritoryName) AS territorio_lider_clientes
 FROM dbo.DimCustomer FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);

INSERT #ReportControls SELECT 'C5',(
 SELECT (SELECT COUNT(DISTINCT SalesOrderID) FROM dbo.FactSales WHERE OnlineOrderFlag=1) AS ordenes_online,
 (SELECT COUNT(DISTINCT SalesOrderID) FROM dbo.FactSales WHERE OnlineOrderFlag=0) AS ordenes_asistidas,
 SUM(CASE WHEN OnlineOrderFlag=1 THEN LineTotal ELSE 0 END) AS ventas_online,
 SUM(CASE WHEN OnlineOrderFlag=0 THEN LineTotal ELSE 0 END) AS ventas_asistidas,
 CAST(SUM(CASE WHEN OnlineOrderFlag=1 THEN LineTotal ELSE 0 END) AS decimal(28,6)) /
 NULLIF((SELECT COUNT(DISTINCT SalesOrderID) FROM dbo.FactSales WHERE OnlineOrderFlag=1),0) AS ticket_online,
 CAST(SUM(CASE WHEN OnlineOrderFlag=0 THEN LineTotal ELSE 0 END) AS decimal(28,6)) /
 NULLIF((SELECT COUNT(DISTINCT SalesOrderID) FROM dbo.FactSales WHERE OnlineOrderFlag=0),0) AS ticket_asistido
 FROM dbo.FactSales FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);

INSERT #ReportControls SELECT 'P1',(
 SELECT COUNT_BIG(*) AS ordenes, SUM(CAST(OrderQty AS bigint)) AS planificadas,
 SUM(CAST(StockedQty AS bigint)) AS almacenadas,SUM(CAST(ScrappedQty AS bigint)) AS desechadas
 FROM dbo.FactWorkOrder FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);

INSERT #ReportControls SELECT 'P2',(
 SELECT SUM(CAST(ScrapCost AS decimal(28,4))) AS costo_descarte,
 CAST(SUM(CAST(ScrappedQty AS bigint)) AS decimal(28,6))/NULLIF(CAST(SUM(CAST(OrderQty AS bigint)) AS decimal(28,6)),0) AS tasa_descarte,
 SUM(CASE WHEN ScrappedQty>0 THEN 1 ELSE 0 END) AS ordenes_con_descarte,
 (SELECT COUNT(*) FROM dbo.DimScrapReason WHERE ScrapReasonKey<>0) AS motivos_registrados,
 (SELECT COUNT(DISTINCT ScrapReasonKey) FROM dbo.FactWorkOrder WHERE ScrappedQty>0 AND ScrapReasonKey<>0) AS motivos_utilizados
 FROM dbo.FactWorkOrder FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);

;WITH Stock AS (SELECT ProductKey,SUM(CAST(Quantity AS bigint)) AS Units FROM dbo.FactInventorySnapshot GROUP BY ProductKey)
INSERT #ReportControls SELECT 'P3',(
 SELECT SUM(CAST(Quantity AS bigint)) AS unidades,
 SUM(CAST(InventoryValue AS decimal(28,4))) AS valor_inventario,
 COUNT(DISTINCT ProductKey) AS productos_con_registro,
 (SELECT COUNT(DISTINCT ProductKey) FROM dbo.FactInventorySnapshot WHERE Quantity>0) AS productos_stock_positivo,
 COUNT(DISTINCT LocationKey) AS ubicaciones_con_registro,
 (SELECT COUNT(*) FROM dbo.DimLocation) AS ubicaciones_catalogo,
 (SELECT COUNT(*) FROM Stock s JOIN dbo.DimProduct p ON p.ProductKey=s.ProductKey WHERE s.Units<p.ReorderPoint) AS bajo_reorden
 FROM dbo.FactInventorySnapshot FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);

INSERT #ReportControls SELECT 'P4',(
 SELECT COUNT_BIG(*) AS operaciones,SUM(ActualResourceHrs) AS horas,
 SUM(CAST(ActualCost AS decimal(28,4))) AS costo_real,
 SUM(CAST(PlannedCost AS decimal(28,4))) AS costo_planificado,
 SUM(CAST(CostVariance AS decimal(28,4))) AS variacion,
 SUM(CASE WHEN ActualStartDateKey=-1 THEN 1 ELSE 0 END) AS operaciones_sin_inicio_real
 FROM dbo.FactWorkOrderRouting FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);

INSERT #ReportControls SELECT 'P5',(
 SELECT COUNT_BIG(*) AS productos,
 SUM(CASE WHEN FinishedGoodsFlag=1 THEN 1 ELSE 0 END) AS terminados,
 SUM(CASE WHEN MakeFlag=1 THEN 1 ELSE 0 END) AS fabricados,
 (SELECT COUNT(DISTINCT CategoryName) FROM dbo.DimProduct WHERE CategoryName<>N'Sin Categoría') AS categorias_informadas,
 SUM(CASE WHEN CategoryName=N'Sin Categoría' THEN 1 ELSE 0 END) AS productos_sin_categoria
 FROM dbo.DimProduct FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);

INSERT #ReportControls SELECT 'V1',(
 SELECT SUM(LineTotal) AS ventas,SUM(CAST(TotalProductCost AS decimal(28,4))) AS costo,
 SUM(GrossMargin) AS margen,
 CAST(SUM(GrossMargin) AS decimal(28,6))/NULLIF(CAST(SUM(LineTotal) AS decimal(28,6)),0) AS margen_pct,
 COUNT(DISTINCT SalesOrderID) AS ordenes,
 CAST(SUM(LineTotal) AS decimal(28,6))/NULLIF(COUNT(DISTINCT SalesOrderID),0) AS ticket,
 SUM(CAST(OrderQty AS bigint)) AS unidades
 FROM dbo.FactSales FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);

INSERT #ReportControls SELECT 'V2',(
 SELECT SUM(CAST(f.OrderQty AS bigint)) AS unidades,COUNT(DISTINCT f.ProductKey) AS productos_vendidos,
 AVG(CAST(f.UnitPrice AS decimal(28,4))) AS precio_medio_por_linea,
 CAST(SUM(f.LineTotal) AS decimal(28,6))/NULLIF(SUM(CAST(f.OrderQty AS bigint)),0) AS precio_neto_por_unidad,
 CAST(SUM(CASE WHEN p.CategoryName='Bikes' THEN f.LineTotal ELSE 0 END) AS decimal(28,6)) /
 NULLIF(CAST(SUM(f.LineTotal) AS decimal(28,6)),0) AS participacion_bikes
 FROM dbo.FactSales f JOIN dbo.DimProduct p ON p.ProductKey=f.ProductKey
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);

INSERT #ReportControls SELECT 'V3',(
 SELECT COUNT(DISTINCT f.TerritoryKey) AS territorios_con_venta,
 SUM(CASE WHEN t.[Group]='North America' THEN f.LineTotal ELSE 0 END) AS ventas_norteamerica,
 SUM(CASE WHEN t.[Group] IN ('Europe','Pacific') THEN f.LineTotal ELSE 0 END) AS ventas_internacionales,
 SUM(CASE WHEN t.[Group] NOT IN ('North America','Europe','Pacific') THEN f.LineTotal ELSE 0 END) AS ventas_otro_grupo
 FROM dbo.FactSales f JOIN dbo.DimTerritory t ON t.TerritoryKey=f.TerritoryKey
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);

INSERT #ReportControls SELECT 'V4',(
 SELECT (SELECT COUNT(*) FROM dbo.DimSalesPerson WHERE SalesPersonKey<>0) AS vendedores_registrados,
 COUNT(DISTINCT f.SalesPersonKey) AS vendedores_con_venta,
 SUM(f.LineTotal) AS ventas_asistidas,
 (SELECT SUM(CAST(SalesQuota AS decimal(28,4))) FROM dbo.DimSalesPerson WHERE SalesPersonKey<>0 AND SalesQuota IS NOT NULL) AS cuota_actual,
 (SELECT COUNT(*) FROM dbo.DimSalesPerson WHERE SalesPersonKey<>0 AND SalesQuota IS NULL) AS vendedores_sin_cuota,
 SUM(CAST(f.LineTotal AS decimal(28,6))*s.CommissionPct) AS comision_estimada,
 (SELECT SUM(CAST(Bonus AS decimal(28,4))) FROM dbo.DimSalesPerson WHERE SalesPersonKey<>0) AS bonus_actual
 FROM dbo.FactSales f JOIN dbo.DimSalesPerson s ON s.SalesPersonKey=f.SalesPersonKey WHERE f.SalesPersonKey<>0
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);

INSERT #ReportControls SELECT 'V5',(
 SELECT SUM(CAST(f.OrderQty AS decimal(10,0))*f.UnitPrice) AS venta_bruta,
 SUM(CAST(f.DiscountAmount AS decimal(28,4))) AS descuento,SUM(f.LineTotal) AS venta_neta,
 CAST(SUM(CAST(f.DiscountAmount AS decimal(28,4))) AS decimal(28,6))/NULLIF(CAST(SUM(CAST(f.OrderQty AS decimal(10,0))*f.UnitPrice) AS decimal(28,6)),0) AS tasa_descuento,
 SUM(CASE WHEN f.UnitPriceDiscount>0 THEN 1 ELSE 0 END) AS lineas_descuento,
 SUM(CASE WHEN o.[Type]<>'No Discount' THEN f.LineTotal ELSE 0 END) AS ventas_oferta,
 SUM(CASE WHEN o.[Type]='No Discount' THEN f.LineTotal ELSE 0 END) AS ventas_regular
 FROM dbo.FactSales f JOIN dbo.DimSpecialOffer o ON o.SpecialOfferKey=f.SpecialOfferKey
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);

-- Paquetes pequenos completos, sin truncamiento del ancho de sqlcmd.
DECLARE @code varchar(2), @payload nvarchar(max);
DECLARE outputs CURSOR LOCAL FAST_FORWARD FOR SELECT Code,Payload FROM #ReportControls ORDER BY Code;
OPEN outputs;
FETCH NEXT FROM outputs INTO @code,@payload;
WHILE @@FETCH_STATUS=0 BEGIN
 IF DATALENGTH(@payload)>7600 THROW 51100,'Control demasiado grande para PRINT.',1;
 PRINT N'REPORT|'+@code+N'|'+@payload;
 FETCH NEXT FROM outputs INTO @code,@payload;
END;
CLOSE outputs;
DEALLOCATE outputs;
