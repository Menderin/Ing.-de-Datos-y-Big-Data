-- ==============================================================================
-- 03_etl_dimensions.sql
-- Extracción, Transformación y Carga (ETL) de Tablas Dimensionales
-- Fuente: AdventureWorks2022 -> Destino: AdventureWorksDW
-- Proyecto: Ingeniería de Datos y Big Data - Entrega 2
-- ==============================================================================

USE [AdventureWorksDW];
GO

SET NOCOUNT ON;

PRINT '==============================================================================';
PRINT 'INICIANDO CARGA ETL DE DIMENSIONES';
PRINT '==============================================================================';

-- ------------------------------------------------------------------------------
-- 1. Cargar DimTerritory
-- ------------------------------------------------------------------------------
PRINT 'Cargando DimTerritory...';
DELETE FROM dbo.DimTerritory;

INSERT INTO dbo.DimTerritory (
    TerritoryID,
    TerritoryName,
    CountryRegionCode,
    [Group]
)
SELECT 
    TerritoryID,
    Name AS TerritoryName,
    CountryRegionCode,
    [Group]
FROM AdventureWorks2022.Sales.SalesTerritory
ORDER BY TerritoryID;

PRINT 'DimTerritory cargada: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' registros.';

-- ------------------------------------------------------------------------------
-- 2. Cargar DimSalesPerson
-- ------------------------------------------------------------------------------
PRINT 'Cargando DimSalesPerson...';
DELETE FROM dbo.DimSalesPerson;

-- Registro especial para ventas por internet / sin vendedor asignado
INSERT INTO dbo.DimSalesPerson (
    SalesPersonKey,
    BusinessEntityID,
    FullName,
    JobTitle,
    SalesQuota,
    Bonus,
    CommissionPct,
    TerritoryID
) VALUES (
    0, 0, 'Venta Online / Sin Vendedor', 'Canal Digital', 0, 0, 0, NULL
);

-- Vendedores oficiales registrados en la fuerza de venta
INSERT INTO dbo.DimSalesPerson (
    SalesPersonKey,
    BusinessEntityID,
    FullName,
    JobTitle,
    SalesQuota,
    Bonus,
    CommissionPct,
    TerritoryID
)
SELECT 
    sp.BusinessEntityID AS SalesPersonKey,
    sp.BusinessEntityID,
    CONCAT(p.FirstName, ' ', p.LastName) AS FullName,
    e.JobTitle,
    sp.SalesQuota,
    sp.Bonus,
    sp.CommissionPct,
    sp.TerritoryID
FROM AdventureWorks2022.Sales.SalesPerson sp
JOIN AdventureWorks2022.Person.Person p ON sp.BusinessEntityID = p.BusinessEntityID
JOIN AdventureWorks2022.HumanResources.Employee e ON sp.BusinessEntityID = e.BusinessEntityID
ORDER BY sp.BusinessEntityID;

PRINT 'DimSalesPerson cargada: ' + CAST(@@ROWCOUNT + 1 AS VARCHAR(10)) + ' registros (incluye canal online).';

-- ------------------------------------------------------------------------------
-- 3. Cargar DimCustomer
-- ------------------------------------------------------------------------------
PRINT 'Cargando DimCustomer...';
DELETE FROM dbo.DimCustomer;

INSERT INTO dbo.DimCustomer (
    CustomerID,
    CustomerType,
    CustomerName,
    StoreName,
    City,
    StateProvinceName,
    CountryRegionName,
    TerritoryID
)
SELECT 
    c.CustomerID,
    CASE 
        WHEN c.PersonID IS NOT NULL AND c.StoreID IS NULL THEN 'Individual'
        ELSE 'Store'
    END AS CustomerType,
    COALESCE(s.Name, NULLIF(LTRIM(RTRIM(CONCAT(p.FirstName, ' ', COALESCE(p.MiddleName + ' ', ''), p.LastName))), ''), 'Cliente ' + CAST(c.CustomerID AS VARCHAR(20))) AS CustomerName,
    s.Name AS StoreName,
    COALESCE(a.City, 'No Informado') AS City,
    COALESCE(sp.Name, 'No Informado') AS StateProvinceName,
    COALESCE(cr.Name, 'No Informado') AS CountryRegionName,
    COALESCE(c.TerritoryID, 0) AS TerritoryID
FROM AdventureWorks2022.Sales.Customer c
LEFT JOIN AdventureWorks2022.Person.Person p ON c.PersonID = p.BusinessEntityID
LEFT JOIN AdventureWorks2022.Sales.Store s ON c.StoreID = s.BusinessEntityID
OUTER APPLY (
    SELECT TOP 1 bea.AddressID
    FROM AdventureWorks2022.Person.BusinessEntityAddress bea
    WHERE bea.BusinessEntityID = COALESCE(c.PersonID, c.StoreID)
    ORDER BY bea.AddressTypeID
) addr_link
LEFT JOIN AdventureWorks2022.Person.Address a ON addr_link.AddressID = a.AddressID
LEFT JOIN AdventureWorks2022.Person.StateProvince sp ON a.StateProvinceID = sp.StateProvinceID
LEFT JOIN AdventureWorks2022.Person.CountryRegion cr ON sp.CountryRegionCode = cr.CountryRegionCode
ORDER BY c.CustomerID;

PRINT 'DimCustomer cargada: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' registros.';

-- ------------------------------------------------------------------------------
-- 4. Cargar DimProduct
-- ------------------------------------------------------------------------------
PRINT 'Cargando DimProduct...';
DELETE FROM dbo.DimProduct;

INSERT INTO dbo.DimProduct (
    ProductID,
    ProductName,
    ProductNumber,
    MakeFlag,
    FinishedGoodsFlag,
    Color,
    SafetyStockLevel,
    ReorderPoint,
    StandardCost,
    ListPrice,
    SubcategoryName,
    CategoryName
)
SELECT 
    p.ProductID,
    p.Name AS ProductName,
    p.ProductNumber,
    p.MakeFlag,
    p.FinishedGoodsFlag,
    COALESCE(p.Color, 'N/A') AS Color,
    p.SafetyStockLevel,
    p.ReorderPoint,
    p.StandardCost,
    p.ListPrice,
    COALESCE(psc.Name, 'Sin Subcategoría') AS SubcategoryName,
    COALESCE(pc.Name, 'Sin Categoría') AS CategoryName
FROM AdventureWorks2022.Production.Product p
LEFT JOIN AdventureWorks2022.Production.ProductSubcategory psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
LEFT JOIN AdventureWorks2022.Production.ProductCategory pc ON psc.ProductCategoryID = pc.ProductCategoryID
ORDER BY p.ProductID;

PRINT 'DimProduct cargada: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' registros.';

-- ------------------------------------------------------------------------------
-- 5. Cargar DimSpecialOffer
-- ------------------------------------------------------------------------------
PRINT 'Cargando DimSpecialOffer...';
DELETE FROM dbo.DimSpecialOffer;

INSERT INTO dbo.DimSpecialOffer (
    SpecialOfferID,
    Description,
    DiscountPct,
    [Type],
    Category
)
SELECT 
    SpecialOfferID,
    Description,
    DiscountPct,
    [Type],
    Category
FROM AdventureWorks2022.Sales.SpecialOffer
ORDER BY SpecialOfferID;

PRINT 'DimSpecialOffer cargada: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' registros.';

-- ------------------------------------------------------------------------------
-- 6. Cargar DimLocation
-- ------------------------------------------------------------------------------
PRINT 'Cargando DimLocation...';
DELETE FROM dbo.DimLocation;

INSERT INTO dbo.DimLocation (
    LocationID,
    LocationName,
    CostRate,
    Availability
)
SELECT 
    LocationID,
    Name AS LocationName,
    CostRate,
    Availability
FROM AdventureWorks2022.Production.Location
ORDER BY LocationID;

PRINT 'DimLocation cargada: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' registros.';

-- ------------------------------------------------------------------------------
-- 7. Cargar DimScrapReason
-- ------------------------------------------------------------------------------
PRINT 'Cargando DimScrapReason...';
DELETE FROM dbo.DimScrapReason;

-- Registro especial para órdenes de trabajo sin descarte
INSERT INTO dbo.DimScrapReason (
    ScrapReasonKey,
    ScrapReasonID,
    ScrapReasonName
) VALUES (
    0, 0, 'Sin Desperdicio / Conforme'
);

INSERT INTO dbo.DimScrapReason (
    ScrapReasonKey,
    ScrapReasonID,
    ScrapReasonName
)
SELECT 
    ScrapReasonID AS ScrapReasonKey,
    ScrapReasonID,
    Name AS ScrapReasonName
FROM AdventureWorks2022.Production.ScrapReason
ORDER BY ScrapReasonID;

PRINT 'DimScrapReason cargada: ' + CAST(@@ROWCOUNT + 1 AS VARCHAR(10)) + ' registros.';

PRINT '==============================================================================';
PRINT 'CARGA DE TODAS LAS DIMENSIONES COMPLETADA';
PRINT '==============================================================================';
GO
