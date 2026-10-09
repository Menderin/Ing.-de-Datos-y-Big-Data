-- Auditoria de filas aceptadas, rechazos explicados y cuadratura.
USE [$(TargetDatabase)];
GO
SET NOCOUNT ON;
CREATE TABLE #Audit (Control nvarchar(128), Expected decimal(38,6), Actual decimal(38,6));
INSERT #Audit SELECT N'Filas DimCustomer',(SELECT COUNT_BIG(*)+0 FROM #src_Sales_Customer),(SELECT COUNT_BIG(*) FROM dbo.DimCustomer);
INSERT #Audit SELECT N'Filas DimProduct',(SELECT COUNT_BIG(*)+0 FROM #src_Production_Product),(SELECT COUNT_BIG(*) FROM dbo.DimProduct);
INSERT #Audit SELECT N'Filas DimTerritory',(SELECT COUNT_BIG(*)+0 FROM #src_Sales_SalesTerritory),(SELECT COUNT_BIG(*) FROM dbo.DimTerritory);
INSERT #Audit SELECT N'Filas DimSalesPerson',(SELECT COUNT_BIG(*)+1 FROM #src_Sales_SalesPerson),(SELECT COUNT_BIG(*) FROM dbo.DimSalesPerson);
INSERT #Audit SELECT N'Filas DimSpecialOffer',(SELECT COUNT_BIG(*)+0 FROM #src_Sales_SpecialOffer),(SELECT COUNT_BIG(*) FROM dbo.DimSpecialOffer);
INSERT #Audit SELECT N'Filas DimLocation',(SELECT COUNT_BIG(*)+0 FROM #src_Production_Location),(SELECT COUNT_BIG(*) FROM dbo.DimLocation);
INSERT #Audit SELECT N'Filas DimScrapReason',(SELECT COUNT_BIG(*)+1 FROM #src_Production_ScrapReason),(SELECT COUNT_BIG(*) FROM dbo.DimScrapReason);
INSERT #Audit SELECT N'Filas FactSales',(SELECT COUNT_BIG(*)+0 FROM #src_Sales_SalesOrderDetail),(SELECT COUNT_BIG(*) FROM dbo.FactSales);
INSERT #Audit SELECT N'Filas FactWorkOrder',(SELECT COUNT_BIG(*)+0 FROM #src_Production_WorkOrder),(SELECT COUNT_BIG(*) FROM dbo.FactWorkOrder);
INSERT #Audit SELECT N'Filas FactWorkOrderRouting',(SELECT COUNT_BIG(*)+0 FROM #src_Production_WorkOrderRouting),(SELECT COUNT_BIG(*) FROM dbo.FactWorkOrderRouting);
INSERT #Audit SELECT N'Filas FactInventorySnapshot',(SELECT COUNT_BIG(*)+0 FROM #src_Production_ProductInventory),(SELECT COUNT_BIG(*) FROM dbo.FactInventorySnapshot);
INSERT #Audit SELECT N'Ventas netas',COALESCE((SELECT SUM(LineTotal) FROM #src_Sales_SalesOrderDetail),0),COALESCE((SELECT SUM(LineTotal) FROM dbo.FactSales),0);
INSERT #Audit SELECT N'Unidades vendidas',COALESCE((SELECT SUM(CAST(OrderQty AS bigint)) FROM #src_Sales_SalesOrderDetail),0),COALESCE((SELECT SUM(CAST(OrderQty AS bigint)) FROM dbo.FactSales),0);
INSERT #Audit SELECT N'Unidades planificadas',COALESCE((SELECT SUM(CAST(OrderQty AS bigint)) FROM #src_Production_WorkOrder),0),COALESCE((SELECT SUM(CAST(OrderQty AS bigint)) FROM dbo.FactWorkOrder),0);
INSERT #Audit SELECT N'Unidades desechadas',COALESCE((SELECT SUM(CAST(ScrappedQty AS bigint)) FROM #src_Production_WorkOrder),0),COALESCE((SELECT SUM(CAST(ScrappedQty AS bigint)) FROM dbo.FactWorkOrder),0);
INSERT #Audit SELECT N'Horas reales',COALESCE((SELECT SUM(ActualResourceHrs) FROM #src_Production_WorkOrderRouting),0),COALESCE((SELECT SUM(ActualResourceHrs) FROM dbo.FactWorkOrderRouting),0);
INSERT #Audit SELECT N'Costo real',COALESCE((SELECT SUM(CAST(ActualCost AS decimal(38,4))) FROM #src_Production_WorkOrderRouting),0),COALESCE((SELECT SUM(CAST(ActualCost AS decimal(38,4))) FROM dbo.FactWorkOrderRouting),0);
INSERT #Audit SELECT N'Stock fisico',COALESCE((SELECT SUM(CAST(Quantity AS bigint)) FROM #src_Production_ProductInventory),0),COALESCE((SELECT SUM(CAST(Quantity AS bigint)) FROM dbo.FactInventorySnapshot),0);
-- PRINT evita que sqlcmd reserve el ancho completo de nvarchar/decimal.
-- Solo cambia la presentacion: la auditoria usa los valores originales.
PRINT '';
PRINT 'CUADRATURA DE LA CARGA (antes de publicar)';
PRINT REPLICATE('-',78);
PRINT LEFT('Control'+SPACE(28),28)+' '+RIGHT(SPACE(19)+'Fuente aceptada',19)+' '+RIGHT(SPACE(19)+'DW',19)+' Estado';
PRINT REPLICATE('-',78);
DECLARE @control nvarchar(128), @expected decimal(38,6), @actual decimal(38,6);
DECLARE @expectedText nvarchar(60), @actualText nvarchar(60), @auditState varchar(9);
DECLARE audit_output CURSOR LOCAL FAST_FORWARD FOR SELECT Control,Expected,Actual FROM #Audit ORDER BY
 CASE WHEN Control LIKE 'Filas %' THEN 0 ELSE 1 END,Control;
OPEN audit_output;
FETCH NEXT FROM audit_output INTO @control,@expected,@actual;
WHILE @@FETCH_STATUS=0
BEGIN
 SET @expectedText=FORMAT(@expected,N'#,##0.######','es-CL');
 SET @actualText=FORMAT(@actual,N'#,##0.######','es-CL');
 SET @auditState=CASE WHEN ABS(@expected-@actual)<0.01 THEN 'OK' ELSE 'DESCUADRE' END;
 IF LEN(@expectedText)<=19 AND LEN(@actualText)<=19
  PRINT LEFT(@control+SPACE(28),28)+' '+RIGHT(SPACE(19)+@expectedText,19)+' '+RIGHT(SPACE(19)+@actualText,19)+' '+@auditState;
 ELSE BEGIN
  -- No cortar importes extremos para que entren en una columna.
  PRINT @control+' ['+@auditState+']';
  PRINT '  Fuente: '+@expectedText;
  PRINT '  DW:     '+@actualText;
 END;
 FETCH NEXT FROM audit_output INTO @control,@expected,@actual;
END;
CLOSE audit_output;
DEALLOCATE audit_output;
PRINT REPLICATE('-',78);
IF EXISTS (SELECT 1 FROM #Audit WHERE ABS(Expected-Actual)>=0.01)
 THROW 51004, 'Descuadre interno entre staging aceptado y DW. Se revierte la carga.', 1;

-- Cada fila recibida se carga en staging o tiene al menos un motivo de rechazo.
IF EXISTS (
 SELECT 1 FROM dbo.EtlTableSummary q JOIN #EtlContext c ON q.RunID=c.RunID
 OUTER APPLY (SELECT COUNT_BIG(DISTINCT i.SourceRowID) AS n FROM dbo.EtlIssue i
 WHERE i.RunID=q.RunID AND i.SourceTable=q.SourceTable AND i.Severity='REJECT') r
 WHERE q.Received<>q.Accepted+r.n OR q.Rejected<>r.n)
 THROW 51005, 'Hay filas perdidas sin rechazo registrado. Se revierte la carga.', 1;

CREATE TABLE #ConstraintErrors ([Table] nvarchar(256),[Constraint] nvarchar(256),[Where] nvarchar(max));
INSERT #ConstraintErrors EXEC('DBCC CHECKCONSTRAINTS WITH ALL_CONSTRAINTS, NO_INFOMSGS');
IF EXISTS (SELECT 1 FROM #ConstraintErrors)
 THROW 51006, 'Integridad referencial o restricciones del DW invalidas.', 1;

UPDATE r SET FinishedAt=SYSUTCDATETIME(),
 Status=CASE WHEN EXISTS(SELECT 1 FROM dbo.EtlIssue i WHERE i.RunID=r.RunID AND Severity IN ('WARNING','REJECT'))
 THEN 'COMPLETED_WITH_WARNINGS' ELSE 'COMPLETED' END
FROM dbo.EtlRun r JOIN #EtlContext c ON r.RunID=c.RunID;
COMMIT TRANSACTION;

PRINT '';
PRINT 'RESUMEN DE LA EJECUCION';
PRINT REPLICATE('-',78);
DECLARE @run uniqueidentifier, @source sysname, @status varchar(30), @start datetime2, @finish datetime2;
SELECT @run=r.RunID,@source=r.SourceDatabase,@status=r.Status,@start=r.StartedAt,@finish=r.FinishedAt
FROM dbo.EtlRun r JOIN #EtlContext c ON r.RunID=c.RunID;
PRINT 'Estado:     '+@status;
PRINT 'Origen:     '+@source;
PRINT 'Destino:    '+DB_NAME();
PRINT 'Ejecucion:  '+CONVERT(varchar(36),@run);
PRINT 'Inicio UTC: '+CONVERT(varchar(19),@start,120);
PRINT 'Fin UTC:    '+CONVERT(varchar(19),@finish,120);
PRINT '';
PRINT 'FILAS POR TABLA FUENTE';
PRINT REPLICATE('-',78);
PRINT LEFT('Tabla'+SPACE(32),32)+' '+RIGHT(SPACE(14)+'Recibidas',14)+' '+RIGHT(SPACE(14)+'Aceptadas',14)+' '+RIGHT(SPACE(14)+'Rechazadas',14);
PRINT REPLICATE('-',78);
DECLARE @table nvarchar(128), @received bigint, @accepted bigint, @rejected bigint;
DECLARE summary_output CURSOR LOCAL FAST_FORWARD FOR
 SELECT SourceTable,Received,Accepted,Rejected FROM dbo.EtlTableSummary WHERE RunID=@run ORDER BY SourceTable;
OPEN summary_output;
FETCH NEXT FROM summary_output INTO @table,@received,@accepted,@rejected;
WHILE @@FETCH_STATUS=0
BEGIN
 IF LEN(CONVERT(varchar(20),@received))<=14
  PRINT LEFT(@table+SPACE(32),32)+' '+RIGHT(SPACE(14)+CONVERT(varchar(20),@received),14)+' '+RIGHT(SPACE(14)+CONVERT(varchar(20),@accepted),14)+' '+RIGHT(SPACE(14)+CONVERT(varchar(20),@rejected),14);
 ELSE BEGIN
  PRINT @table;
  PRINT '  Recibidas: '+CONVERT(varchar(20),@received);
  PRINT '  Aceptadas: '+CONVERT(varchar(20),@accepted);
  PRINT '  Rechazadas: '+CONVERT(varchar(20),@rejected);
 END;
 FETCH NEXT FROM summary_output INTO @table,@received,@accepted,@rejected;
END;
CLOSE summary_output;
DEALLOCATE summary_output;
PRINT REPLICATE('-',78);
DECLARE @normalized bigint,@warnings bigint,@rejects bigint;
SELECT @normalized=COUNT_BIG(*) FROM dbo.EtlIssue WHERE RunID=@run AND Severity='NORMALIZED';
SELECT @warnings=COUNT_BIG(*) FROM dbo.EtlIssue WHERE RunID=@run AND Severity='WARNING';
SELECT @rejects=COUNT_BIG(*) FROM dbo.EtlIssue WHERE RunID=@run AND Severity='REJECT';
PRINT '';
PRINT 'INCIDENCIAS';
PRINT '  Normalizaciones:     '+CONVERT(varchar(20),@normalized);
PRINT '  Advertencias:        '+CONVERT(varchar(20),@warnings);
PRINT '  Motivos de rechazo:  '+CONVERT(varchar(20),@rejects);
PRINT '  Una fila puede tener varios motivos de rechazo.';
PRINT '';
PRINT 'Carga publicada. Detalle: EtlRun, EtlTableSummary y EtlIssue.';
GO
