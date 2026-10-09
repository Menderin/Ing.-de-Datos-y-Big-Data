-- ==============================================================================
-- 02_populate_dim_date.sql
-- Poblado de DimDate: rango minimo 2010-2015, ampliado segun la fuente aceptada.
-- Proyecto: Ingeniería de Datos y Big Data - Entrega 2
-- ==============================================================================

USE [$(TargetDatabase)];
GO

SET NOCOUNT ON;
SET DATEFIRST 7;

PRINT 'Poblando dimension DimDate...';

-- Limpiar tabla previa si contiene registros
DELETE FROM dbo.DimDate;

-- 1. Insertar registro especial para fechas no aplicables o desconocidas (-1)
INSERT INTO dbo.DimDate (
    DateKey, FullDate, [Year], [Quarter], QuarterName, [Month], MonthName, MonthYear, [DayOfMonth], DayOfWeekNumber, DayOfWeekName, IsWeekend
) VALUES (
    -1, '1900-01-01', 1900, 0, 'N/A', 0, 'No Aplica', '1900-00', 0, 0, 'No Aplica', 0
);

-- 2. Generar calendario continuo adaptable usando CTE recursiva
DECLARE @StartDate date='2010-01-01', @EndDate date='2015-12-31';
DECLARE @MinDate date, @MaxDate date;
SELECT @MinDate=MIN(v.d), @MaxDate=MAX(v.d) FROM (
SELECT [OrderDate] AS d FROM #src_Sales_SalesOrderHeader
UNION ALL
SELECT [DueDate] AS d FROM #src_Sales_SalesOrderHeader
UNION ALL
SELECT [ShipDate] AS d FROM #src_Sales_SalesOrderHeader
UNION ALL
SELECT [StartDate] AS d FROM #src_Production_WorkOrder
UNION ALL
SELECT [EndDate] AS d FROM #src_Production_WorkOrder
UNION ALL
SELECT [DueDate] AS d FROM #src_Production_WorkOrder
UNION ALL
SELECT [ScheduledStartDate] AS d FROM #src_Production_WorkOrderRouting
UNION ALL
SELECT [ScheduledEndDate] AS d FROM #src_Production_WorkOrderRouting
UNION ALL
SELECT [ActualStartDate] AS d FROM #src_Production_WorkOrderRouting
UNION ALL
SELECT [ActualEndDate] AS d FROM #src_Production_WorkOrderRouting
) v WHERE v.d IS NOT NULL;
IF @MinDate<@StartDate SET @StartDate=@MinDate;
IF @MaxDate>@EndDate SET @EndDate=@MaxDate;
-- Evitar agotar recursos ante un rango extremo. No es un limite de filas de la fuente.
IF DATEDIFF(DAY,@StartDate,@EndDate)>366000
 THROW 51003, 'Rango de calendario superior a 1000 anios: revisar fuente antes de publicar.', 1;

WITH DateSequence AS (
    SELECT @StartDate AS [Date]
    UNION ALL
    SELECT DATEADD(DAY, 1, [Date])
    FROM DateSequence
    WHERE [Date] < @EndDate
)
INSERT INTO dbo.DimDate (
    DateKey,
    FullDate,
    [Year],
    [Quarter],
    QuarterName,
    [Month],
    MonthName,
    MonthYear,
    [DayOfMonth],
    DayOfWeekNumber,
    DayOfWeekName,
    IsWeekend
)
SELECT 
    YEAR([Date]) * 10000 + MONTH([Date]) * 100 + DAY([Date]) AS DateKey,
    [Date] AS FullDate,
    YEAR([Date]) AS [Year],
    DATEPART(QUARTER, [Date]) AS [Quarter],
    CONCAT('Q', DATEPART(QUARTER, [Date])) AS QuarterName,
    MONTH([Date]) AS [Month],
    CASE MONTH([Date])
        WHEN 1 THEN 'Enero'
        WHEN 2 THEN 'Febrero'
        WHEN 3 THEN 'Marzo'
        WHEN 4 THEN 'Abril'
        WHEN 5 THEN 'Mayo'
        WHEN 6 THEN 'Junio'
        WHEN 7 THEN 'Julio'
        WHEN 8 THEN 'Agosto'
        WHEN 9 THEN 'Septiembre'
        WHEN 10 THEN 'Octubre'
        WHEN 11 THEN 'Noviembre'
        WHEN 12 THEN 'Diciembre'
    END AS MonthName,
    CONVERT(VARCHAR(7), [Date], 120) AS MonthYear,
    DAY([Date]) AS [DayOfMonth],
    DATEPART(WEEKDAY, [Date]) AS DayOfWeekNumber,
    CASE DATEPART(WEEKDAY, [Date])
        WHEN 1 THEN 'Domingo'
        WHEN 2 THEN 'Lunes'
        WHEN 3 THEN 'Martes'
        WHEN 4 THEN 'Miércoles'
        WHEN 5 THEN 'Jueves'
        WHEN 6 THEN 'Viernes'
        WHEN 7 THEN 'Sábado'
    END AS DayOfWeekName,
    CASE WHEN DATEPART(WEEKDAY, [Date]) IN (1, 7) THEN 1 ELSE 0 END AS IsWeekend
FROM DateSequence
OPTION (MAXRECURSION 0);

PRINT 'DimDate poblada con exito: ' + CAST(@@ROWCOUNT + 1 AS VARCHAR(10)) + ' registros.';
GO
