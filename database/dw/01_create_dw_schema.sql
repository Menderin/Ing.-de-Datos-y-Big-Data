-- ==============================================================================
-- 01_create_dw_schema.sql
-- Creación de la Base de Datos y Esquema Dimensional (Data Warehouse)
-- Proyecto: Ingeniería de Datos y Big Data - Entrega 2
-- ==============================================================================

USE [master];
GO

SET NOCOUNT ON;

-- 1. Crear base de datos AdventureWorksDW si no existe
IF DB_ID(N'AdventureWorksDW') IS NULL
BEGIN
    PRINT 'Creando base de datos analitica AdventureWorksDW...';
    CREATE DATABASE [AdventureWorksDW];
END
GO

USE [AdventureWorksDW];
GO

-- 2. Eliminar tablas de hechos si existen (por orden de dependencias referenciales)
IF OBJECT_ID('dbo.FactSales', 'U') IS NOT NULL DROP TABLE dbo.FactSales;
IF OBJECT_ID('dbo.FactWorkOrderRouting', 'U') IS NOT NULL DROP TABLE dbo.FactWorkOrderRouting;
IF OBJECT_ID('dbo.FactWorkOrder', 'U') IS NOT NULL DROP TABLE dbo.FactWorkOrder;
IF OBJECT_ID('dbo.FactInventorySnapshot', 'U') IS NOT NULL DROP TABLE dbo.FactInventorySnapshot;

-- 3. Eliminar tablas de dimensiones si existen
IF OBJECT_ID('dbo.DimCustomer', 'U') IS NOT NULL DROP TABLE dbo.DimCustomer;
IF OBJECT_ID('dbo.DimProduct', 'U') IS NOT NULL DROP TABLE dbo.DimProduct;
IF OBJECT_ID('dbo.DimTerritory', 'U') IS NOT NULL DROP TABLE dbo.DimTerritory;
IF OBJECT_ID('dbo.DimSalesPerson', 'U') IS NOT NULL DROP TABLE dbo.DimSalesPerson;
IF OBJECT_ID('dbo.DimSpecialOffer', 'U') IS NOT NULL DROP TABLE dbo.DimSpecialOffer;
IF OBJECT_ID('dbo.DimLocation', 'U') IS NOT NULL DROP TABLE dbo.DimLocation;
IF OBJECT_ID('dbo.DimScrapReason', 'U') IS NOT NULL DROP TABLE dbo.DimScrapReason;
IF OBJECT_ID('dbo.DimDate', 'U') IS NOT NULL DROP TABLE dbo.DimDate;
GO

PRINT 'Creando tablas dimensionales...';

-- ------------------------------------------------------------------------------
-- Dimensión de Tiempo / Calendario
-- ------------------------------------------------------------------------------
CREATE TABLE dbo.DimDate (
    DateKey INT NOT NULL PRIMARY KEY,            -- Formato YYYYMMDD (-1 para no aplica)
    FullDate DATE NOT NULL,
    [Year] INT NOT NULL,
    [Quarter] INT NOT NULL,
    QuarterName VARCHAR(10) NOT NULL,            -- 'Q1', 'Q2', etc.
    [Month] INT NOT NULL,
    MonthName VARCHAR(20) NOT NULL,              -- 'Enero', 'Febrero', etc.
    MonthYear VARCHAR(20) NOT NULL,              -- '2013-05'
    [DayOfMonth] INT NOT NULL,
    DayOfWeekNumber INT NOT NULL,                -- 1 (Domingo) a 7 (Sábado)
    DayOfWeekName VARCHAR(20) NOT NULL,          -- 'Lunes', 'Martes', etc.
    IsWeekend BIT NOT NULL
);

-- ------------------------------------------------------------------------------
-- Dimensión Clientes (B2C y B2B)
-- ------------------------------------------------------------------------------
CREATE TABLE dbo.DimCustomer (
    CustomerKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    CustomerID INT NOT NULL,                     -- Clave de negocio OLTP
    CustomerType VARCHAR(20) NOT NULL,           -- 'Individual' o 'Store'
    CustomerName VARCHAR(150) NOT NULL,          -- Nombre de persona o razón social
    StoreName VARCHAR(150) NULL,
    City VARCHAR(50) NOT NULL,
    StateProvinceName VARCHAR(50) NOT NULL,
    CountryRegionName VARCHAR(50) NOT NULL,
    TerritoryID INT NOT NULL
);
CREATE UNIQUE NONCLUSTERED INDEX IX_DimCustomer_CustomerID ON dbo.DimCustomer(CustomerID);

-- ------------------------------------------------------------------------------
-- Dimensión Productos y Catálogo
-- ------------------------------------------------------------------------------
CREATE TABLE dbo.DimProduct (
    ProductKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ProductID INT NOT NULL,                      -- Clave de negocio OLTP
    ProductName VARCHAR(100) NOT NULL,
    ProductNumber VARCHAR(30) NOT NULL,
    MakeFlag BIT NOT NULL,
    FinishedGoodsFlag BIT NOT NULL,
    Color VARCHAR(20) NOT NULL,
    SafetyStockLevel SMALLINT NOT NULL,
    ReorderPoint SMALLINT NOT NULL,
    StandardCost MONEY NOT NULL,
    ListPrice MONEY NOT NULL,
    SubcategoryName VARCHAR(50) NOT NULL,
    CategoryName VARCHAR(50) NOT NULL
);
CREATE UNIQUE NONCLUSTERED INDEX IX_DimProduct_ProductID ON dbo.DimProduct(ProductID);

-- ------------------------------------------------------------------------------
-- Dimensión Territorios Comerciales
-- ------------------------------------------------------------------------------
CREATE TABLE dbo.DimTerritory (
    TerritoryKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    TerritoryID INT NOT NULL,                    -- Clave de negocio OLTP
    TerritoryName VARCHAR(50) NOT NULL,
    CountryRegionCode VARCHAR(5) NOT NULL,
    [Group] VARCHAR(50) NOT NULL
);
CREATE UNIQUE NONCLUSTERED INDEX IX_DimTerritory_TerritoryID ON dbo.DimTerritory(TerritoryID);

-- ------------------------------------------------------------------------------
-- Dimensión Vendedores y Ejecutivos Comerciales
-- ------------------------------------------------------------------------------
CREATE TABLE dbo.DimSalesPerson (
    SalesPersonKey INT NOT NULL PRIMARY KEY,     -- Usamos BusinessEntityID directo (0 = Venta Online / Directa)
    BusinessEntityID INT NOT NULL,
    FullName VARCHAR(150) NOT NULL,
    JobTitle VARCHAR(50) NOT NULL,
    SalesQuota MONEY NULL,
    Bonus MONEY NOT NULL,
    CommissionPct DECIMAL(5,4) NOT NULL,
    TerritoryID INT NULL
);

-- ------------------------------------------------------------------------------
-- Dimensión Ofertas y Promociones
-- ------------------------------------------------------------------------------
CREATE TABLE dbo.DimSpecialOffer (
    SpecialOfferKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    SpecialOfferID INT NOT NULL,                 -- Clave de negocio OLTP
    Description VARCHAR(255) NOT NULL,
    DiscountPct DECIMAL(5,4) NOT NULL,
    [Type] VARCHAR(50) NOT NULL,
    Category VARCHAR(50) NOT NULL
);
CREATE UNIQUE NONCLUSTERED INDEX IX_DimSpecialOffer_SpecialOfferID ON dbo.DimSpecialOffer(SpecialOfferID);

-- ------------------------------------------------------------------------------
-- Dimensión Ubicaciones / Centros de Trabajo de Producción
-- ------------------------------------------------------------------------------
CREATE TABLE dbo.DimLocation (
    LocationKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    LocationID SMALLINT NOT NULL,                -- Clave de negocio OLTP
    LocationName VARCHAR(50) NOT NULL,
    CostRate SMALLMONEY NOT NULL,
    Availability DECIMAL(8,2) NOT NULL
);
CREATE UNIQUE NONCLUSTERED INDEX IX_DimLocation_LocationID ON dbo.DimLocation(LocationID);

-- ------------------------------------------------------------------------------
-- Dimensión Motivos de Descarte / Merma
-- ------------------------------------------------------------------------------
CREATE TABLE dbo.DimScrapReason (
    ScrapReasonKey INT NOT NULL PRIMARY KEY,     -- Clave de negocio OLTP (0 = Sin Descarte)
    ScrapReasonID SMALLINT NOT NULL,
    ScrapReasonName VARCHAR(50) NOT NULL
);

PRINT 'Creando tablas de hechos...';

-- ------------------------------------------------------------------------------
-- Hecho 1: Ventas y Facturación (Perspectivas Ventas y Clientes)
-- Granularidad: Línea de detalle de orden de venta
-- ------------------------------------------------------------------------------
CREATE TABLE dbo.FactSales (
    FactSalesKey BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    SalesOrderID INT NOT NULL,
    SalesOrderDetailID INT NOT NULL,
    OrderDateKey INT NOT NULL,
    DueDateKey INT NOT NULL,
    ShipDateKey INT NOT NULL,
    CustomerKey INT NOT NULL,
    ProductKey INT NOT NULL,
    TerritoryKey INT NOT NULL,
    SalesPersonKey INT NOT NULL,
    SpecialOfferKey INT NOT NULL,
    OnlineOrderFlag BIT NOT NULL,
    OrderQty SMALLINT NOT NULL,
    UnitPrice MONEY NOT NULL,
    UnitPriceDiscount MONEY NOT NULL,
    DiscountAmount MONEY NOT NULL,
    LineTotal NUMERIC(38,6) NOT NULL,
    ProductStandardCost MONEY NOT NULL,
    TotalProductCost MONEY NOT NULL,
    GrossMargin NUMERIC(38,6) NOT NULL,
    CONSTRAINT FK_FactSales_DimDate_Order FOREIGN KEY (OrderDateKey) REFERENCES dbo.DimDate(DateKey),
    CONSTRAINT FK_FactSales_DimDate_Due FOREIGN KEY (DueDateKey) REFERENCES dbo.DimDate(DateKey),
    CONSTRAINT FK_FactSales_DimDate_Ship FOREIGN KEY (ShipDateKey) REFERENCES dbo.DimDate(DateKey),
    CONSTRAINT FK_FactSales_DimCustomer FOREIGN KEY (CustomerKey) REFERENCES dbo.DimCustomer(CustomerKey),
    CONSTRAINT FK_FactSales_DimProduct FOREIGN KEY (ProductKey) REFERENCES dbo.DimProduct(ProductKey),
    CONSTRAINT FK_FactSales_DimTerritory FOREIGN KEY (TerritoryKey) REFERENCES dbo.DimTerritory(TerritoryKey),
    CONSTRAINT FK_FactSales_DimSalesPerson FOREIGN KEY (SalesPersonKey) REFERENCES dbo.DimSalesPerson(SalesPersonKey),
    CONSTRAINT FK_FactSales_DimSpecialOffer FOREIGN KEY (SpecialOfferKey) REFERENCES dbo.DimSpecialOffer(SpecialOfferKey)
);

CREATE NONCLUSTERED INDEX IX_FactSales_OrderDateKey ON dbo.FactSales(OrderDateKey);
CREATE NONCLUSTERED INDEX IX_FactSales_CustomerKey ON dbo.FactSales(CustomerKey);
CREATE NONCLUSTERED INDEX IX_FactSales_ProductKey ON dbo.FactSales(ProductKey);
CREATE NONCLUSTERED INDEX IX_FactSales_TerritoryKey ON dbo.FactSales(TerritoryKey);

-- ------------------------------------------------------------------------------
-- Hecho 2: Órdenes de Trabajo y Desperdicio (Perspectiva Producción P1 y P2)
-- Granularidad: Orden de trabajo (WorkOrder)
-- ------------------------------------------------------------------------------
CREATE TABLE dbo.FactWorkOrder (
    FactWorkOrderKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    WorkOrderID INT NOT NULL,
    ProductKey INT NOT NULL,
    ScrapReasonKey INT NOT NULL,
    StartDateKey INT NOT NULL,
    EndDateKey INT NOT NULL,
    DueDateKey INT NOT NULL,
    OrderQty INT NOT NULL,
    StockedQty INT NOT NULL,
    ScrappedQty SMALLINT NOT NULL,
    ScrapCost MONEY NOT NULL,
    CONSTRAINT FK_FactWorkOrder_DimProduct FOREIGN KEY (ProductKey) REFERENCES dbo.DimProduct(ProductKey),
    CONSTRAINT FK_FactWorkOrder_DimScrapReason FOREIGN KEY (ScrapReasonKey) REFERENCES dbo.DimScrapReason(ScrapReasonKey),
    CONSTRAINT FK_FactWorkOrder_DimDate_Start FOREIGN KEY (StartDateKey) REFERENCES dbo.DimDate(DateKey),
    CONSTRAINT FK_FactWorkOrder_DimDate_End FOREIGN KEY (EndDateKey) REFERENCES dbo.DimDate(DateKey),
    CONSTRAINT FK_FactWorkOrder_DimDate_Due FOREIGN KEY (DueDateKey) REFERENCES dbo.DimDate(DateKey)
);

CREATE NONCLUSTERED INDEX IX_FactWorkOrder_ProductKey ON dbo.FactWorkOrder(ProductKey);
CREATE NONCLUSTERED INDEX IX_FactWorkOrder_StartDateKey ON dbo.FactWorkOrder(StartDateKey);

-- ------------------------------------------------------------------------------
-- Hecho 3: Rendimiento Operacional por Centro de Trabajo (Perspectiva Producción P4)
-- Granularidad: Operación de orden de trabajo en una ubicación
-- ------------------------------------------------------------------------------
CREATE TABLE dbo.FactWorkOrderRouting (
    FactRoutingKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    WorkOrderID INT NOT NULL,
    ProductKey INT NOT NULL,
    LocationKey INT NOT NULL,
    OperationSequence SMALLINT NOT NULL,
    ScheduledStartDateKey INT NOT NULL,
    ScheduledEndDateKey INT NOT NULL,
    ActualStartDateKey INT NOT NULL,
    ActualEndDateKey INT NOT NULL,
    ActualResourceHrs DECIMAL(9,4) NOT NULL,
    PlannedCost MONEY NOT NULL,
    ActualCost MONEY NOT NULL,
    CostVariance MONEY NOT NULL,                  -- ActualCost - PlannedCost
    CONSTRAINT FK_FactRouting_DimProduct FOREIGN KEY (ProductKey) REFERENCES dbo.DimProduct(ProductKey),
    CONSTRAINT FK_FactRouting_DimLocation FOREIGN KEY (LocationKey) REFERENCES dbo.DimLocation(LocationKey),
    CONSTRAINT FK_FactRouting_DimDate_SchedStart FOREIGN KEY (ScheduledStartDateKey) REFERENCES dbo.DimDate(DateKey),
    CONSTRAINT FK_FactRouting_DimDate_SchedEnd FOREIGN KEY (ScheduledEndDateKey) REFERENCES dbo.DimDate(DateKey),
    CONSTRAINT FK_FactRouting_DimDate_ActStart FOREIGN KEY (ActualStartDateKey) REFERENCES dbo.DimDate(DateKey),
    CONSTRAINT FK_FactRouting_DimDate_ActEnd FOREIGN KEY (ActualEndDateKey) REFERENCES dbo.DimDate(DateKey)
);

CREATE NONCLUSTERED INDEX IX_FactRouting_ProductKey ON dbo.FactWorkOrderRouting(ProductKey);
CREATE NONCLUSTERED INDEX IX_FactRouting_LocationKey ON dbo.FactWorkOrderRouting(LocationKey);

-- ------------------------------------------------------------------------------
-- Hecho 4: Instantánea de Inventario Físico (Perspectiva Producción P3)
-- Granularidad: Existencia de producto por ubicación y casillero
-- ------------------------------------------------------------------------------
CREATE TABLE dbo.FactInventorySnapshot (
    FactInventoryKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ProductKey INT NOT NULL,
    LocationKey INT NOT NULL,
    Shelf VARCHAR(10) NOT NULL,
    Bin TINYINT NOT NULL,
    Quantity SMALLINT NOT NULL,
    InventoryValue MONEY NOT NULL,               -- Quantity * Product.StandardCost
    CONSTRAINT FK_FactInventory_DimProduct FOREIGN KEY (ProductKey) REFERENCES dbo.DimProduct(ProductKey),
    CONSTRAINT FK_FactInventory_DimLocation FOREIGN KEY (LocationKey) REFERENCES dbo.DimLocation(LocationKey)
);

CREATE NONCLUSTERED INDEX IX_FactInventory_ProductKey ON dbo.FactInventorySnapshot(ProductKey);
CREATE NONCLUSTERED INDEX IX_FactInventory_LocationKey ON dbo.FactInventorySnapshot(LocationKey);
GO

PRINT 'Esquema de AdventureWorksDW creado exitosamente.';
GO
