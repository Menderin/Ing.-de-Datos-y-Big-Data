-- Preparacion tolerante. Ejecutar mediante los orquestadores, en una sola sesion.
USE [$(TargetDatabase)];
GO
IF OBJECT_ID('dbo.EtlRun','U') IS NULL
 CREATE TABLE dbo.EtlRun (RunID uniqueidentifier PRIMARY KEY, StartedAt datetime2 NOT NULL,
 FinishedAt datetime2 NULL, SourceDatabase sysname NOT NULL, Status varchar(30) NOT NULL);
IF OBJECT_ID('dbo.EtlIssue','U') IS NULL
 CREATE TABLE dbo.EtlIssue (IssueID bigint IDENTITY PRIMARY KEY, RunID uniqueidentifier NOT NULL,
 SourceTable nvarchar(128) NOT NULL, SourceRowID bigint NOT NULL, Severity varchar(12) NOT NULL,
 FieldName nvarchar(128) NOT NULL, Reason nvarchar(500) NOT NULL, RawData nvarchar(max) NOT NULL);
IF OBJECT_ID('dbo.EtlTableSummary','U') IS NULL
 CREATE TABLE dbo.EtlTableSummary (RunID uniqueidentifier NOT NULL, SourceTable nvarchar(128) NOT NULL,
 Received bigint NOT NULL, Accepted bigint NOT NULL, Rejected bigint NOT NULL,
 PRIMARY KEY (RunID, SourceTable));
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('dbo.EtlIssue') AND name='IX_EtlIssue_Run_Table_Row')
 CREATE INDEX IX_EtlIssue_Run_Table_Row ON dbo.EtlIssue(RunID,SourceTable,Severity,SourceRowID);
GO
SET XACT_ABORT ON;
SET NOCOUNT ON;
BEGIN TRANSACTION;
DECLARE @lockResult int;
EXEC @lockResult = sys.sp_getapplock @Resource='AdventureWorksDW_ETL', @LockMode='Exclusive',
 @LockOwner='Transaction', @LockTimeout=0;
IF @lockResult < 0 THROW 51000, 'Otro ETL esta cargando este DW.', 1;
CREATE TABLE #EtlContext (RunID uniqueidentifier NOT NULL);
INSERT #EtlContext VALUES (NEWID());
INSERT dbo.EtlRun SELECT RunID, SYSUTCDATETIME(), NULL, '$(SourceDatabase)', 'RUNNING' FROM #EtlContext;
GO
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.tables t JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Sales' AND t.name=N'SalesTerritory')
 THROW 51001, 'Falta tabla fuente Sales.SalesTerritory.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Sales' AND t.name=N'SalesTerritory' AND c.name=N'TerritoryID' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Sales.SalesTerritory.TerritoryID.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Sales' AND t.name=N'SalesTerritory' AND c.name=N'Name' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Sales.SalesTerritory.Name.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Sales' AND t.name=N'SalesTerritory' AND c.name=N'CountryRegionCode' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Sales.SalesTerritory.CountryRegionCode.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Sales' AND t.name=N'SalesTerritory' AND c.name=N'Group' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Sales.SalesTerritory.Group.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.tables t JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Person' AND t.name=N'Person')
 THROW 51001, 'Falta tabla fuente Person.Person.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Person' AND t.name=N'Person' AND c.name=N'BusinessEntityID' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Person.Person.BusinessEntityID.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Person' AND t.name=N'Person' AND c.name=N'FirstName' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Person.Person.FirstName.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Person' AND t.name=N'Person' AND c.name=N'MiddleName' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Person.Person.MiddleName.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Person' AND t.name=N'Person' AND c.name=N'LastName' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Person.Person.LastName.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.tables t JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'HumanResources' AND t.name=N'Employee')
 THROW 51001, 'Falta tabla fuente HumanResources.Employee.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'HumanResources' AND t.name=N'Employee' AND c.name=N'BusinessEntityID' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: HumanResources.Employee.BusinessEntityID.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'HumanResources' AND t.name=N'Employee' AND c.name=N'JobTitle' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: HumanResources.Employee.JobTitle.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.tables t JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Sales' AND t.name=N'Store')
 THROW 51001, 'Falta tabla fuente Sales.Store.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Sales' AND t.name=N'Store' AND c.name=N'BusinessEntityID' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Sales.Store.BusinessEntityID.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Sales' AND t.name=N'Store' AND c.name=N'Name' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Sales.Store.Name.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.tables t JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Person' AND t.name=N'Address')
 THROW 51001, 'Falta tabla fuente Person.Address.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Person' AND t.name=N'Address' AND c.name=N'AddressID' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Person.Address.AddressID.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Person' AND t.name=N'Address' AND c.name=N'City' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Person.Address.City.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Person' AND t.name=N'Address' AND c.name=N'StateProvinceID' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Person.Address.StateProvinceID.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.tables t JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Person' AND t.name=N'StateProvince')
 THROW 51001, 'Falta tabla fuente Person.StateProvince.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Person' AND t.name=N'StateProvince' AND c.name=N'StateProvinceID' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Person.StateProvince.StateProvinceID.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Person' AND t.name=N'StateProvince' AND c.name=N'Name' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Person.StateProvince.Name.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Person' AND t.name=N'StateProvince' AND c.name=N'CountryRegionCode' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Person.StateProvince.CountryRegionCode.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.tables t JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Person' AND t.name=N'CountryRegion')
 THROW 51001, 'Falta tabla fuente Person.CountryRegion.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Person' AND t.name=N'CountryRegion' AND c.name=N'CountryRegionCode' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Person.CountryRegion.CountryRegionCode.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Person' AND t.name=N'CountryRegion' AND c.name=N'Name' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Person.CountryRegion.Name.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.tables t JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Person' AND t.name=N'BusinessEntityAddress')
 THROW 51001, 'Falta tabla fuente Person.BusinessEntityAddress.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Person' AND t.name=N'BusinessEntityAddress' AND c.name=N'BusinessEntityID' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Person.BusinessEntityAddress.BusinessEntityID.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Person' AND t.name=N'BusinessEntityAddress' AND c.name=N'AddressID' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Person.BusinessEntityAddress.AddressID.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Person' AND t.name=N'BusinessEntityAddress' AND c.name=N'AddressTypeID' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Person.BusinessEntityAddress.AddressTypeID.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.tables t JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'ProductCategory')
 THROW 51001, 'Falta tabla fuente Production.ProductCategory.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'ProductCategory' AND c.name=N'ProductCategoryID' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.ProductCategory.ProductCategoryID.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'ProductCategory' AND c.name=N'Name' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.ProductCategory.Name.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.tables t JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'ProductSubcategory')
 THROW 51001, 'Falta tabla fuente Production.ProductSubcategory.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'ProductSubcategory' AND c.name=N'ProductSubcategoryID' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.ProductSubcategory.ProductSubcategoryID.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'ProductSubcategory' AND c.name=N'ProductCategoryID' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.ProductSubcategory.ProductCategoryID.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'ProductSubcategory' AND c.name=N'Name' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.ProductSubcategory.Name.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.tables t JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'Product')
 THROW 51001, 'Falta tabla fuente Production.Product.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'Product' AND c.name=N'ProductID' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.Product.ProductID.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'Product' AND c.name=N'Name' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.Product.Name.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'Product' AND c.name=N'ProductNumber' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.Product.ProductNumber.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'Product' AND c.name=N'MakeFlag' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.Product.MakeFlag.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'Product' AND c.name=N'FinishedGoodsFlag' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.Product.FinishedGoodsFlag.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'Product' AND c.name=N'Color' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.Product.Color.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'Product' AND c.name=N'SafetyStockLevel' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.Product.SafetyStockLevel.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'Product' AND c.name=N'ReorderPoint' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.Product.ReorderPoint.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'Product' AND c.name=N'StandardCost' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.Product.StandardCost.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'Product' AND c.name=N'ListPrice' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.Product.ListPrice.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'Product' AND c.name=N'ProductSubcategoryID' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.Product.ProductSubcategoryID.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.tables t JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Sales' AND t.name=N'Customer')
 THROW 51001, 'Falta tabla fuente Sales.Customer.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Sales' AND t.name=N'Customer' AND c.name=N'CustomerID' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Sales.Customer.CustomerID.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Sales' AND t.name=N'Customer' AND c.name=N'PersonID' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Sales.Customer.PersonID.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Sales' AND t.name=N'Customer' AND c.name=N'StoreID' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Sales.Customer.StoreID.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Sales' AND t.name=N'Customer' AND c.name=N'TerritoryID' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Sales.Customer.TerritoryID.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.tables t JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Sales' AND t.name=N'SalesPerson')
 THROW 51001, 'Falta tabla fuente Sales.SalesPerson.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Sales' AND t.name=N'SalesPerson' AND c.name=N'BusinessEntityID' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Sales.SalesPerson.BusinessEntityID.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Sales' AND t.name=N'SalesPerson' AND c.name=N'SalesQuota' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Sales.SalesPerson.SalesQuota.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Sales' AND t.name=N'SalesPerson' AND c.name=N'Bonus' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Sales.SalesPerson.Bonus.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Sales' AND t.name=N'SalesPerson' AND c.name=N'CommissionPct' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Sales.SalesPerson.CommissionPct.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Sales' AND t.name=N'SalesPerson' AND c.name=N'TerritoryID' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Sales.SalesPerson.TerritoryID.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.tables t JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Sales' AND t.name=N'SpecialOffer')
 THROW 51001, 'Falta tabla fuente Sales.SpecialOffer.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Sales' AND t.name=N'SpecialOffer' AND c.name=N'SpecialOfferID' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Sales.SpecialOffer.SpecialOfferID.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Sales' AND t.name=N'SpecialOffer' AND c.name=N'Description' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Sales.SpecialOffer.Description.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Sales' AND t.name=N'SpecialOffer' AND c.name=N'DiscountPct' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Sales.SpecialOffer.DiscountPct.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Sales' AND t.name=N'SpecialOffer' AND c.name=N'Type' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Sales.SpecialOffer.Type.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Sales' AND t.name=N'SpecialOffer' AND c.name=N'Category' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Sales.SpecialOffer.Category.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.tables t JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'Location')
 THROW 51001, 'Falta tabla fuente Production.Location.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'Location' AND c.name=N'LocationID' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.Location.LocationID.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'Location' AND c.name=N'Name' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.Location.Name.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'Location' AND c.name=N'CostRate' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.Location.CostRate.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'Location' AND c.name=N'Availability' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.Location.Availability.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.tables t JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'ScrapReason')
 THROW 51001, 'Falta tabla fuente Production.ScrapReason.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'ScrapReason' AND c.name=N'ScrapReasonID' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.ScrapReason.ScrapReasonID.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'ScrapReason' AND c.name=N'Name' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.ScrapReason.Name.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.tables t JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Sales' AND t.name=N'SalesOrderHeader')
 THROW 51001, 'Falta tabla fuente Sales.SalesOrderHeader.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Sales' AND t.name=N'SalesOrderHeader' AND c.name=N'SalesOrderID' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Sales.SalesOrderHeader.SalesOrderID.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Sales' AND t.name=N'SalesOrderHeader' AND c.name=N'OrderDate' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Sales.SalesOrderHeader.OrderDate.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Sales' AND t.name=N'SalesOrderHeader' AND c.name=N'DueDate' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Sales.SalesOrderHeader.DueDate.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Sales' AND t.name=N'SalesOrderHeader' AND c.name=N'ShipDate' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Sales.SalesOrderHeader.ShipDate.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Sales' AND t.name=N'SalesOrderHeader' AND c.name=N'CustomerID' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Sales.SalesOrderHeader.CustomerID.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Sales' AND t.name=N'SalesOrderHeader' AND c.name=N'TerritoryID' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Sales.SalesOrderHeader.TerritoryID.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Sales' AND t.name=N'SalesOrderHeader' AND c.name=N'SalesPersonID' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Sales.SalesOrderHeader.SalesPersonID.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Sales' AND t.name=N'SalesOrderHeader' AND c.name=N'OnlineOrderFlag' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Sales.SalesOrderHeader.OnlineOrderFlag.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.tables t JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Sales' AND t.name=N'SalesOrderDetail')
 THROW 51001, 'Falta tabla fuente Sales.SalesOrderDetail.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Sales' AND t.name=N'SalesOrderDetail' AND c.name=N'SalesOrderID' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Sales.SalesOrderDetail.SalesOrderID.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Sales' AND t.name=N'SalesOrderDetail' AND c.name=N'SalesOrderDetailID' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Sales.SalesOrderDetail.SalesOrderDetailID.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Sales' AND t.name=N'SalesOrderDetail' AND c.name=N'ProductID' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Sales.SalesOrderDetail.ProductID.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Sales' AND t.name=N'SalesOrderDetail' AND c.name=N'SpecialOfferID' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Sales.SalesOrderDetail.SpecialOfferID.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Sales' AND t.name=N'SalesOrderDetail' AND c.name=N'OrderQty' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Sales.SalesOrderDetail.OrderQty.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Sales' AND t.name=N'SalesOrderDetail' AND c.name=N'UnitPrice' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Sales.SalesOrderDetail.UnitPrice.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Sales' AND t.name=N'SalesOrderDetail' AND c.name=N'UnitPriceDiscount' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Sales.SalesOrderDetail.UnitPriceDiscount.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Sales' AND t.name=N'SalesOrderDetail' AND c.name=N'LineTotal' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Sales.SalesOrderDetail.LineTotal.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.tables t JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'WorkOrder')
 THROW 51001, 'Falta tabla fuente Production.WorkOrder.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'WorkOrder' AND c.name=N'WorkOrderID' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.WorkOrder.WorkOrderID.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'WorkOrder' AND c.name=N'ProductID' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.WorkOrder.ProductID.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'WorkOrder' AND c.name=N'ScrapReasonID' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.WorkOrder.ScrapReasonID.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'WorkOrder' AND c.name=N'StartDate' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.WorkOrder.StartDate.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'WorkOrder' AND c.name=N'EndDate' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.WorkOrder.EndDate.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'WorkOrder' AND c.name=N'DueDate' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.WorkOrder.DueDate.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'WorkOrder' AND c.name=N'OrderQty' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.WorkOrder.OrderQty.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'WorkOrder' AND c.name=N'StockedQty' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.WorkOrder.StockedQty.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'WorkOrder' AND c.name=N'ScrappedQty' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.WorkOrder.ScrappedQty.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.tables t JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'WorkOrderRouting')
 THROW 51001, 'Falta tabla fuente Production.WorkOrderRouting.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'WorkOrderRouting' AND c.name=N'WorkOrderID' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.WorkOrderRouting.WorkOrderID.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'WorkOrderRouting' AND c.name=N'ProductID' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.WorkOrderRouting.ProductID.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'WorkOrderRouting' AND c.name=N'LocationID' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.WorkOrderRouting.LocationID.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'WorkOrderRouting' AND c.name=N'OperationSequence' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.WorkOrderRouting.OperationSequence.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'WorkOrderRouting' AND c.name=N'ScheduledStartDate' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.WorkOrderRouting.ScheduledStartDate.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'WorkOrderRouting' AND c.name=N'ScheduledEndDate' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.WorkOrderRouting.ScheduledEndDate.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'WorkOrderRouting' AND c.name=N'ActualStartDate' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.WorkOrderRouting.ActualStartDate.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'WorkOrderRouting' AND c.name=N'ActualEndDate' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.WorkOrderRouting.ActualEndDate.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'WorkOrderRouting' AND c.name=N'ActualResourceHrs' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.WorkOrderRouting.ActualResourceHrs.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'WorkOrderRouting' AND c.name=N'PlannedCost' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.WorkOrderRouting.PlannedCost.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'WorkOrderRouting' AND c.name=N'ActualCost' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.WorkOrderRouting.ActualCost.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.tables t JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'ProductInventory')
 THROW 51001, 'Falta tabla fuente Production.ProductInventory.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'ProductInventory' AND c.name=N'ProductID' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.ProductInventory.ProductID.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'ProductInventory' AND c.name=N'LocationID' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.ProductInventory.LocationID.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'ProductInventory' AND c.name=N'Shelf' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.ProductInventory.Shelf.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'ProductInventory' AND c.name=N'Bin' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.ProductInventory.Bin.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns c JOIN [$(SourceDatabase)].sys.tables t ON c.object_id=t.object_id JOIN [$(SourceDatabase)].sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'Production' AND t.name=N'ProductInventory' AND c.name=N'Quantity' AND TYPE_NAME(c.system_type_id) IN ('int','bigint','smallint','tinyint','bit','money','smallmoney','decimal','numeric','float','real','date','datetime','datetime2','smalldatetime','char','varchar','nchar','nvarchar'))
 THROW 51002, 'Falta columna o tipo no soportado: Production.ProductInventory.Quantity.', 1;
GO
PRINT 'Preparando Sales.SalesTerritory...';
SELECT IDENTITY(bigint,1,1) AS __RowID, (SELECT CONVERT(nvarchar(max),s.[TerritoryID],126) AS [TerritoryID],CONVERT(nvarchar(max),s.[Name],126) AS [Name],CONVERT(nvarchar(max),s.[CountryRegionCode],126) AS [CountryRegionCode],CONVERT(nvarchar(max),s.[Group],126) AS [Group] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS __Raw,
 TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[TerritoryID],126))),N'')) AS [TerritoryID],
 NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Name],126))),N'') AS [Name],
 NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[CountryRegionCode],126))),N'') AS [CountryRegionCode],
 NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Group],126))),N'') AS [Group]
INTO #src_Sales_SalesTerritory
FROM [$(SourceDatabase)].Sales.SalesTerritory s WITH (HOLDLOCK);
INSERT dbo.EtlTableSummary
SELECT c.RunID,N'Sales.SalesTerritory',n.RowsReceived,0,0 FROM #EtlContext c
CROSS APPLY (SELECT COUNT_BIG(*) AS RowsReceived FROM #src_Sales_SalesTerritory) n;
-- Validar sobre los valores originales sin provocar errores de conversion.
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Sales.SalesTerritory',st.__RowID,'REJECT',e.FieldName,e.Reason,st.__Raw
FROM #src_Sales_SalesTerritory st
CROSS APPLY OPENJSON(st.__Raw) WITH ([TerritoryID] nvarchar(max) '$.TerritoryID',[Name] nvarchar(max) '$.Name',[CountryRegionCode] nvarchar(max) '$.CountryRegionCode',[Group] nvarchar(max) '$.Group') s
CROSS APPLY (VALUES (N'TerritoryID', CASE WHEN TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[TerritoryID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[TerritoryID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[TerritoryID],126))),N'')) < 1 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[TerritoryID],126))),N'')) > 2147483647 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[TerritoryID],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[TerritoryID],126))),N''))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'Name', CASE WHEN NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Name],126))),N'') IS NULL OR LEN(NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Name],126))),N'')) > 50 THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'CountryRegionCode', CASE WHEN NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[CountryRegionCode],126))),N'') IS NULL OR LEN(NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[CountryRegionCode],126))),N'')) > 5 THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'Group', CASE WHEN NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Group],126))),N'') IS NULL OR LEN(NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Group],126))),N'')) > 50 THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END)) e(FieldName,Reason)
CROSS JOIN #EtlContext c WHERE e.Reason IS NOT NULL;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Sales.SalesTerritory',st.__RowID,'NORMALIZED',e.FieldName,e.Reason,st.__Raw
FROM #src_Sales_SalesTerritory st
CROSS APPLY OPENJSON(st.__Raw) WITH ([TerritoryID] nvarchar(max) '$.TerritoryID',[Name] nvarchar(max) '$.Name',[CountryRegionCode] nvarchar(max) '$.CountryRegionCode',[Group] nvarchar(max) '$.Group') s
CROSS APPLY (VALUES (N'Name', CASE WHEN DATALENGTH(CONVERT(nvarchar(max),s.[Name],126)) <> DATALENGTH(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Name],126)))) OR (s.[Name] IS NOT NULL AND NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Name],126))),N'') IS NULL) THEN N'Espacios recortados / texto vacio convertido a NULL' END),
 (N'CountryRegionCode', CASE WHEN DATALENGTH(CONVERT(nvarchar(max),s.[CountryRegionCode],126)) <> DATALENGTH(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[CountryRegionCode],126)))) OR (s.[CountryRegionCode] IS NOT NULL AND NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[CountryRegionCode],126))),N'') IS NULL) THEN N'Espacios recortados / texto vacio convertido a NULL' END),
 (N'Group', CASE WHEN DATALENGTH(CONVERT(nvarchar(max),s.[Group],126)) <> DATALENGTH(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Group],126)))) OR (s.[Group] IS NOT NULL AND NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Group],126))),N'') IS NULL) THEN N'Espacios recortados / texto vacio convertido a NULL' END)) e(FieldName,Reason)
CROSS JOIN #EtlContext c WHERE e.Reason IS NOT NULL;
-- Rechazar todas las copias de una clave duplicada; no elegir una arbitrariamente.
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Sales.SalesTerritory',s.__RowID,'REJECT',N'TerritoryID',N'Clave de negocio duplicada',s.__Raw
FROM #src_Sales_SalesTerritory s JOIN (SELECT [TerritoryID] FROM #src_Sales_SalesTerritory GROUP BY [TerritoryID] HAVING COUNT_BIG(*)>1) dup
ON s.[TerritoryID]=dup.[TerritoryID] CROSS JOIN #EtlContext c;
DELETE s FROM #src_Sales_SalesTerritory s WHERE EXISTS
 (SELECT 1 FROM dbo.EtlIssue i JOIN #EtlContext c ON i.RunID=c.RunID
 WHERE i.SourceTable=N'Sales.SalesTerritory' AND i.SourceRowID=s.__RowID AND i.Severity='REJECT');
GO
PRINT 'Preparando Person.Person...';
SELECT IDENTITY(bigint,1,1) AS __RowID, (SELECT CONVERT(nvarchar(max),s.[BusinessEntityID],126) AS [BusinessEntityID],CONVERT(nvarchar(max),s.[FirstName],126) AS [FirstName],CONVERT(nvarchar(max),s.[MiddleName],126) AS [MiddleName],CONVERT(nvarchar(max),s.[LastName],126) AS [LastName] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS __Raw,
 TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[BusinessEntityID],126))),N'')) AS [BusinessEntityID],
 NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[FirstName],126))),N'') AS [FirstName],
 NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[MiddleName],126))),N'') AS [MiddleName],
 NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[LastName],126))),N'') AS [LastName]
INTO #src_Person_Person
FROM [$(SourceDatabase)].Person.Person s WITH (HOLDLOCK);
INSERT dbo.EtlTableSummary
SELECT c.RunID,N'Person.Person',n.RowsReceived,0,0 FROM #EtlContext c
CROSS APPLY (SELECT COUNT_BIG(*) AS RowsReceived FROM #src_Person_Person) n;
-- Validar sobre los valores originales sin provocar errores de conversion.
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Person.Person',st.__RowID,'REJECT',e.FieldName,e.Reason,st.__Raw
FROM #src_Person_Person st
CROSS APPLY OPENJSON(st.__Raw) WITH ([BusinessEntityID] nvarchar(max) '$.BusinessEntityID',[FirstName] nvarchar(max) '$.FirstName',[MiddleName] nvarchar(max) '$.MiddleName',[LastName] nvarchar(max) '$.LastName') s
CROSS APPLY (VALUES (N'BusinessEntityID', CASE WHEN TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[BusinessEntityID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[BusinessEntityID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[BusinessEntityID],126))),N'')) < 1 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[BusinessEntityID],126))),N'')) > 2147483647 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[BusinessEntityID],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[BusinessEntityID],126))),N''))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'FirstName', CASE WHEN NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[FirstName],126))),N'') IS NULL OR LEN(NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[FirstName],126))),N'')) > 50 THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'MiddleName', CASE WHEN LEN(NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[MiddleName],126))),N'')) > 50 THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'LastName', CASE WHEN NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[LastName],126))),N'') IS NULL OR LEN(NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[LastName],126))),N'')) > 50 THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END)) e(FieldName,Reason)
CROSS JOIN #EtlContext c WHERE e.Reason IS NOT NULL;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Person.Person',st.__RowID,'NORMALIZED',e.FieldName,e.Reason,st.__Raw
FROM #src_Person_Person st
CROSS APPLY OPENJSON(st.__Raw) WITH ([BusinessEntityID] nvarchar(max) '$.BusinessEntityID',[FirstName] nvarchar(max) '$.FirstName',[MiddleName] nvarchar(max) '$.MiddleName',[LastName] nvarchar(max) '$.LastName') s
CROSS APPLY (VALUES (N'FirstName', CASE WHEN DATALENGTH(CONVERT(nvarchar(max),s.[FirstName],126)) <> DATALENGTH(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[FirstName],126)))) OR (s.[FirstName] IS NOT NULL AND NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[FirstName],126))),N'') IS NULL) THEN N'Espacios recortados / texto vacio convertido a NULL' END),
 (N'MiddleName', CASE WHEN DATALENGTH(CONVERT(nvarchar(max),s.[MiddleName],126)) <> DATALENGTH(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[MiddleName],126)))) OR (s.[MiddleName] IS NOT NULL AND NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[MiddleName],126))),N'') IS NULL) THEN N'Espacios recortados / texto vacio convertido a NULL' END),
 (N'LastName', CASE WHEN DATALENGTH(CONVERT(nvarchar(max),s.[LastName],126)) <> DATALENGTH(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[LastName],126)))) OR (s.[LastName] IS NOT NULL AND NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[LastName],126))),N'') IS NULL) THEN N'Espacios recortados / texto vacio convertido a NULL' END)) e(FieldName,Reason)
CROSS JOIN #EtlContext c WHERE e.Reason IS NOT NULL;
-- Rechazar todas las copias de una clave duplicada; no elegir una arbitrariamente.
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Person.Person',s.__RowID,'REJECT',N'BusinessEntityID',N'Clave de negocio duplicada',s.__Raw
FROM #src_Person_Person s JOIN (SELECT [BusinessEntityID] FROM #src_Person_Person GROUP BY [BusinessEntityID] HAVING COUNT_BIG(*)>1) dup
ON s.[BusinessEntityID]=dup.[BusinessEntityID] CROSS JOIN #EtlContext c;
DELETE s FROM #src_Person_Person s WHERE EXISTS
 (SELECT 1 FROM dbo.EtlIssue i JOIN #EtlContext c ON i.RunID=c.RunID
 WHERE i.SourceTable=N'Person.Person' AND i.SourceRowID=s.__RowID AND i.Severity='REJECT');
GO
PRINT 'Preparando HumanResources.Employee...';
SELECT IDENTITY(bigint,1,1) AS __RowID, (SELECT CONVERT(nvarchar(max),s.[BusinessEntityID],126) AS [BusinessEntityID],CONVERT(nvarchar(max),s.[JobTitle],126) AS [JobTitle] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS __Raw,
 TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[BusinessEntityID],126))),N'')) AS [BusinessEntityID],
 NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[JobTitle],126))),N'') AS [JobTitle]
INTO #src_HumanResources_Employee
FROM [$(SourceDatabase)].HumanResources.Employee s WITH (HOLDLOCK);
INSERT dbo.EtlTableSummary
SELECT c.RunID,N'HumanResources.Employee',n.RowsReceived,0,0 FROM #EtlContext c
CROSS APPLY (SELECT COUNT_BIG(*) AS RowsReceived FROM #src_HumanResources_Employee) n;
-- Validar sobre los valores originales sin provocar errores de conversion.
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'HumanResources.Employee',st.__RowID,'REJECT',e.FieldName,e.Reason,st.__Raw
FROM #src_HumanResources_Employee st
CROSS APPLY OPENJSON(st.__Raw) WITH ([BusinessEntityID] nvarchar(max) '$.BusinessEntityID',[JobTitle] nvarchar(max) '$.JobTitle') s
CROSS APPLY (VALUES (N'BusinessEntityID', CASE WHEN TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[BusinessEntityID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[BusinessEntityID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[BusinessEntityID],126))),N'')) < 1 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[BusinessEntityID],126))),N'')) > 2147483647 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[BusinessEntityID],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[BusinessEntityID],126))),N''))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'JobTitle', CASE WHEN NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[JobTitle],126))),N'') IS NULL OR LEN(NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[JobTitle],126))),N'')) > 50 THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END)) e(FieldName,Reason)
CROSS JOIN #EtlContext c WHERE e.Reason IS NOT NULL;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'HumanResources.Employee',st.__RowID,'NORMALIZED',e.FieldName,e.Reason,st.__Raw
FROM #src_HumanResources_Employee st
CROSS APPLY OPENJSON(st.__Raw) WITH ([BusinessEntityID] nvarchar(max) '$.BusinessEntityID',[JobTitle] nvarchar(max) '$.JobTitle') s
CROSS APPLY (VALUES (N'JobTitle', CASE WHEN DATALENGTH(CONVERT(nvarchar(max),s.[JobTitle],126)) <> DATALENGTH(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[JobTitle],126)))) OR (s.[JobTitle] IS NOT NULL AND NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[JobTitle],126))),N'') IS NULL) THEN N'Espacios recortados / texto vacio convertido a NULL' END)) e(FieldName,Reason)
CROSS JOIN #EtlContext c WHERE e.Reason IS NOT NULL;
-- Rechazar todas las copias de una clave duplicada; no elegir una arbitrariamente.
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'HumanResources.Employee',s.__RowID,'REJECT',N'BusinessEntityID',N'Clave de negocio duplicada',s.__Raw
FROM #src_HumanResources_Employee s JOIN (SELECT [BusinessEntityID] FROM #src_HumanResources_Employee GROUP BY [BusinessEntityID] HAVING COUNT_BIG(*)>1) dup
ON s.[BusinessEntityID]=dup.[BusinessEntityID] CROSS JOIN #EtlContext c;
DELETE s FROM #src_HumanResources_Employee s WHERE EXISTS
 (SELECT 1 FROM dbo.EtlIssue i JOIN #EtlContext c ON i.RunID=c.RunID
 WHERE i.SourceTable=N'HumanResources.Employee' AND i.SourceRowID=s.__RowID AND i.Severity='REJECT');
GO
PRINT 'Preparando Sales.Store...';
SELECT IDENTITY(bigint,1,1) AS __RowID, (SELECT CONVERT(nvarchar(max),s.[BusinessEntityID],126) AS [BusinessEntityID],CONVERT(nvarchar(max),s.[Name],126) AS [Name] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS __Raw,
 TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[BusinessEntityID],126))),N'')) AS [BusinessEntityID],
 NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Name],126))),N'') AS [Name]
INTO #src_Sales_Store
FROM [$(SourceDatabase)].Sales.Store s WITH (HOLDLOCK);
INSERT dbo.EtlTableSummary
SELECT c.RunID,N'Sales.Store',n.RowsReceived,0,0 FROM #EtlContext c
CROSS APPLY (SELECT COUNT_BIG(*) AS RowsReceived FROM #src_Sales_Store) n;
-- Validar sobre los valores originales sin provocar errores de conversion.
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Sales.Store',st.__RowID,'REJECT',e.FieldName,e.Reason,st.__Raw
FROM #src_Sales_Store st
CROSS APPLY OPENJSON(st.__Raw) WITH ([BusinessEntityID] nvarchar(max) '$.BusinessEntityID',[Name] nvarchar(max) '$.Name') s
CROSS APPLY (VALUES (N'BusinessEntityID', CASE WHEN TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[BusinessEntityID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[BusinessEntityID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[BusinessEntityID],126))),N'')) < 1 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[BusinessEntityID],126))),N'')) > 2147483647 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[BusinessEntityID],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[BusinessEntityID],126))),N''))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'Name', CASE WHEN NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Name],126))),N'') IS NULL OR LEN(NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Name],126))),N'')) > 100 THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END)) e(FieldName,Reason)
CROSS JOIN #EtlContext c WHERE e.Reason IS NOT NULL;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Sales.Store',st.__RowID,'NORMALIZED',e.FieldName,e.Reason,st.__Raw
FROM #src_Sales_Store st
CROSS APPLY OPENJSON(st.__Raw) WITH ([BusinessEntityID] nvarchar(max) '$.BusinessEntityID',[Name] nvarchar(max) '$.Name') s
CROSS APPLY (VALUES (N'Name', CASE WHEN DATALENGTH(CONVERT(nvarchar(max),s.[Name],126)) <> DATALENGTH(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Name],126)))) OR (s.[Name] IS NOT NULL AND NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Name],126))),N'') IS NULL) THEN N'Espacios recortados / texto vacio convertido a NULL' END)) e(FieldName,Reason)
CROSS JOIN #EtlContext c WHERE e.Reason IS NOT NULL;
-- Rechazar todas las copias de una clave duplicada; no elegir una arbitrariamente.
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Sales.Store',s.__RowID,'REJECT',N'BusinessEntityID',N'Clave de negocio duplicada',s.__Raw
FROM #src_Sales_Store s JOIN (SELECT [BusinessEntityID] FROM #src_Sales_Store GROUP BY [BusinessEntityID] HAVING COUNT_BIG(*)>1) dup
ON s.[BusinessEntityID]=dup.[BusinessEntityID] CROSS JOIN #EtlContext c;
DELETE s FROM #src_Sales_Store s WHERE EXISTS
 (SELECT 1 FROM dbo.EtlIssue i JOIN #EtlContext c ON i.RunID=c.RunID
 WHERE i.SourceTable=N'Sales.Store' AND i.SourceRowID=s.__RowID AND i.Severity='REJECT');
GO
PRINT 'Preparando Person.Address...';
SELECT IDENTITY(bigint,1,1) AS __RowID, (SELECT CONVERT(nvarchar(max),s.[AddressID],126) AS [AddressID],CONVERT(nvarchar(max),s.[City],126) AS [City],CONVERT(nvarchar(max),s.[StateProvinceID],126) AS [StateProvinceID] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS __Raw,
 TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[AddressID],126))),N'')) AS [AddressID],
 NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[City],126))),N'') AS [City],
 TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[StateProvinceID],126))),N'')) AS [StateProvinceID]
INTO #src_Person_Address
FROM [$(SourceDatabase)].Person.Address s WITH (HOLDLOCK);
INSERT dbo.EtlTableSummary
SELECT c.RunID,N'Person.Address',n.RowsReceived,0,0 FROM #EtlContext c
CROSS APPLY (SELECT COUNT_BIG(*) AS RowsReceived FROM #src_Person_Address) n;
-- Validar sobre los valores originales sin provocar errores de conversion.
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Person.Address',st.__RowID,'REJECT',e.FieldName,e.Reason,st.__Raw
FROM #src_Person_Address st
CROSS APPLY OPENJSON(st.__Raw) WITH ([AddressID] nvarchar(max) '$.AddressID',[City] nvarchar(max) '$.City',[StateProvinceID] nvarchar(max) '$.StateProvinceID') s
CROSS APPLY (VALUES (N'AddressID', CASE WHEN TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[AddressID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[AddressID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[AddressID],126))),N'')) < 1 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[AddressID],126))),N'')) > 2147483647 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[AddressID],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[AddressID],126))),N''))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'City', CASE WHEN NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[City],126))),N'') IS NULL OR LEN(NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[City],126))),N'')) > 50 THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'StateProvinceID', CASE WHEN TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[StateProvinceID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[StateProvinceID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[StateProvinceID],126))),N'')) < 1 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[StateProvinceID],126))),N'')) > 2147483647 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[StateProvinceID],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[StateProvinceID],126))),N''))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END)) e(FieldName,Reason)
CROSS JOIN #EtlContext c WHERE e.Reason IS NOT NULL;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Person.Address',st.__RowID,'NORMALIZED',e.FieldName,e.Reason,st.__Raw
FROM #src_Person_Address st
CROSS APPLY OPENJSON(st.__Raw) WITH ([AddressID] nvarchar(max) '$.AddressID',[City] nvarchar(max) '$.City',[StateProvinceID] nvarchar(max) '$.StateProvinceID') s
CROSS APPLY (VALUES (N'City', CASE WHEN DATALENGTH(CONVERT(nvarchar(max),s.[City],126)) <> DATALENGTH(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[City],126)))) OR (s.[City] IS NOT NULL AND NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[City],126))),N'') IS NULL) THEN N'Espacios recortados / texto vacio convertido a NULL' END)) e(FieldName,Reason)
CROSS JOIN #EtlContext c WHERE e.Reason IS NOT NULL;
-- Rechazar todas las copias de una clave duplicada; no elegir una arbitrariamente.
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Person.Address',s.__RowID,'REJECT',N'AddressID',N'Clave de negocio duplicada',s.__Raw
FROM #src_Person_Address s JOIN (SELECT [AddressID] FROM #src_Person_Address GROUP BY [AddressID] HAVING COUNT_BIG(*)>1) dup
ON s.[AddressID]=dup.[AddressID] CROSS JOIN #EtlContext c;
DELETE s FROM #src_Person_Address s WHERE EXISTS
 (SELECT 1 FROM dbo.EtlIssue i JOIN #EtlContext c ON i.RunID=c.RunID
 WHERE i.SourceTable=N'Person.Address' AND i.SourceRowID=s.__RowID AND i.Severity='REJECT');
GO
PRINT 'Preparando Person.StateProvince...';
SELECT IDENTITY(bigint,1,1) AS __RowID, (SELECT CONVERT(nvarchar(max),s.[StateProvinceID],126) AS [StateProvinceID],CONVERT(nvarchar(max),s.[Name],126) AS [Name],CONVERT(nvarchar(max),s.[CountryRegionCode],126) AS [CountryRegionCode] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS __Raw,
 TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[StateProvinceID],126))),N'')) AS [StateProvinceID],
 NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Name],126))),N'') AS [Name],
 NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[CountryRegionCode],126))),N'') AS [CountryRegionCode]
INTO #src_Person_StateProvince
FROM [$(SourceDatabase)].Person.StateProvince s WITH (HOLDLOCK);
INSERT dbo.EtlTableSummary
SELECT c.RunID,N'Person.StateProvince',n.RowsReceived,0,0 FROM #EtlContext c
CROSS APPLY (SELECT COUNT_BIG(*) AS RowsReceived FROM #src_Person_StateProvince) n;
-- Validar sobre los valores originales sin provocar errores de conversion.
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Person.StateProvince',st.__RowID,'REJECT',e.FieldName,e.Reason,st.__Raw
FROM #src_Person_StateProvince st
CROSS APPLY OPENJSON(st.__Raw) WITH ([StateProvinceID] nvarchar(max) '$.StateProvinceID',[Name] nvarchar(max) '$.Name',[CountryRegionCode] nvarchar(max) '$.CountryRegionCode') s
CROSS APPLY (VALUES (N'StateProvinceID', CASE WHEN TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[StateProvinceID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[StateProvinceID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[StateProvinceID],126))),N'')) < 1 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[StateProvinceID],126))),N'')) > 2147483647 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[StateProvinceID],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[StateProvinceID],126))),N''))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'Name', CASE WHEN NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Name],126))),N'') IS NULL OR LEN(NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Name],126))),N'')) > 50 THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'CountryRegionCode', CASE WHEN NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[CountryRegionCode],126))),N'') IS NULL OR LEN(NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[CountryRegionCode],126))),N'')) > 5 THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END)) e(FieldName,Reason)
CROSS JOIN #EtlContext c WHERE e.Reason IS NOT NULL;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Person.StateProvince',st.__RowID,'NORMALIZED',e.FieldName,e.Reason,st.__Raw
FROM #src_Person_StateProvince st
CROSS APPLY OPENJSON(st.__Raw) WITH ([StateProvinceID] nvarchar(max) '$.StateProvinceID',[Name] nvarchar(max) '$.Name',[CountryRegionCode] nvarchar(max) '$.CountryRegionCode') s
CROSS APPLY (VALUES (N'Name', CASE WHEN DATALENGTH(CONVERT(nvarchar(max),s.[Name],126)) <> DATALENGTH(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Name],126)))) OR (s.[Name] IS NOT NULL AND NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Name],126))),N'') IS NULL) THEN N'Espacios recortados / texto vacio convertido a NULL' END),
 (N'CountryRegionCode', CASE WHEN DATALENGTH(CONVERT(nvarchar(max),s.[CountryRegionCode],126)) <> DATALENGTH(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[CountryRegionCode],126)))) OR (s.[CountryRegionCode] IS NOT NULL AND NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[CountryRegionCode],126))),N'') IS NULL) THEN N'Espacios recortados / texto vacio convertido a NULL' END)) e(FieldName,Reason)
CROSS JOIN #EtlContext c WHERE e.Reason IS NOT NULL;
-- Rechazar todas las copias de una clave duplicada; no elegir una arbitrariamente.
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Person.StateProvince',s.__RowID,'REJECT',N'StateProvinceID',N'Clave de negocio duplicada',s.__Raw
FROM #src_Person_StateProvince s JOIN (SELECT [StateProvinceID] FROM #src_Person_StateProvince GROUP BY [StateProvinceID] HAVING COUNT_BIG(*)>1) dup
ON s.[StateProvinceID]=dup.[StateProvinceID] CROSS JOIN #EtlContext c;
DELETE s FROM #src_Person_StateProvince s WHERE EXISTS
 (SELECT 1 FROM dbo.EtlIssue i JOIN #EtlContext c ON i.RunID=c.RunID
 WHERE i.SourceTable=N'Person.StateProvince' AND i.SourceRowID=s.__RowID AND i.Severity='REJECT');
GO
PRINT 'Preparando Person.CountryRegion...';
SELECT IDENTITY(bigint,1,1) AS __RowID, (SELECT CONVERT(nvarchar(max),s.[CountryRegionCode],126) AS [CountryRegionCode],CONVERT(nvarchar(max),s.[Name],126) AS [Name] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS __Raw,
 NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[CountryRegionCode],126))),N'') AS [CountryRegionCode],
 NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Name],126))),N'') AS [Name]
INTO #src_Person_CountryRegion
FROM [$(SourceDatabase)].Person.CountryRegion s WITH (HOLDLOCK);
INSERT dbo.EtlTableSummary
SELECT c.RunID,N'Person.CountryRegion',n.RowsReceived,0,0 FROM #EtlContext c
CROSS APPLY (SELECT COUNT_BIG(*) AS RowsReceived FROM #src_Person_CountryRegion) n;
-- Validar sobre los valores originales sin provocar errores de conversion.
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Person.CountryRegion',st.__RowID,'REJECT',e.FieldName,e.Reason,st.__Raw
FROM #src_Person_CountryRegion st
CROSS APPLY OPENJSON(st.__Raw) WITH ([CountryRegionCode] nvarchar(max) '$.CountryRegionCode',[Name] nvarchar(max) '$.Name') s
CROSS APPLY (VALUES (N'CountryRegionCode', CASE WHEN NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[CountryRegionCode],126))),N'') IS NULL OR LEN(NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[CountryRegionCode],126))),N'')) > 5 THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'Name', CASE WHEN NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Name],126))),N'') IS NULL OR LEN(NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Name],126))),N'')) > 50 THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END)) e(FieldName,Reason)
CROSS JOIN #EtlContext c WHERE e.Reason IS NOT NULL;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Person.CountryRegion',st.__RowID,'NORMALIZED',e.FieldName,e.Reason,st.__Raw
FROM #src_Person_CountryRegion st
CROSS APPLY OPENJSON(st.__Raw) WITH ([CountryRegionCode] nvarchar(max) '$.CountryRegionCode',[Name] nvarchar(max) '$.Name') s
CROSS APPLY (VALUES (N'CountryRegionCode', CASE WHEN DATALENGTH(CONVERT(nvarchar(max),s.[CountryRegionCode],126)) <> DATALENGTH(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[CountryRegionCode],126)))) OR (s.[CountryRegionCode] IS NOT NULL AND NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[CountryRegionCode],126))),N'') IS NULL) THEN N'Espacios recortados / texto vacio convertido a NULL' END),
 (N'Name', CASE WHEN DATALENGTH(CONVERT(nvarchar(max),s.[Name],126)) <> DATALENGTH(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Name],126)))) OR (s.[Name] IS NOT NULL AND NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Name],126))),N'') IS NULL) THEN N'Espacios recortados / texto vacio convertido a NULL' END)) e(FieldName,Reason)
CROSS JOIN #EtlContext c WHERE e.Reason IS NOT NULL;
-- Rechazar todas las copias de una clave duplicada; no elegir una arbitrariamente.
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Person.CountryRegion',s.__RowID,'REJECT',N'CountryRegionCode',N'Clave de negocio duplicada',s.__Raw
FROM #src_Person_CountryRegion s JOIN (SELECT [CountryRegionCode] FROM #src_Person_CountryRegion GROUP BY [CountryRegionCode] HAVING COUNT_BIG(*)>1) dup
ON s.[CountryRegionCode]=dup.[CountryRegionCode] CROSS JOIN #EtlContext c;
DELETE s FROM #src_Person_CountryRegion s WHERE EXISTS
 (SELECT 1 FROM dbo.EtlIssue i JOIN #EtlContext c ON i.RunID=c.RunID
 WHERE i.SourceTable=N'Person.CountryRegion' AND i.SourceRowID=s.__RowID AND i.Severity='REJECT');
GO
PRINT 'Preparando Person.BusinessEntityAddress...';
SELECT IDENTITY(bigint,1,1) AS __RowID, (SELECT CONVERT(nvarchar(max),s.[BusinessEntityID],126) AS [BusinessEntityID],CONVERT(nvarchar(max),s.[AddressID],126) AS [AddressID],CONVERT(nvarchar(max),s.[AddressTypeID],126) AS [AddressTypeID] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS __Raw,
 TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[BusinessEntityID],126))),N'')) AS [BusinessEntityID],
 TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[AddressID],126))),N'')) AS [AddressID],
 TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[AddressTypeID],126))),N'')) AS [AddressTypeID]
INTO #src_Person_BusinessEntityAddress
FROM [$(SourceDatabase)].Person.BusinessEntityAddress s WITH (HOLDLOCK);
INSERT dbo.EtlTableSummary
SELECT c.RunID,N'Person.BusinessEntityAddress',n.RowsReceived,0,0 FROM #EtlContext c
CROSS APPLY (SELECT COUNT_BIG(*) AS RowsReceived FROM #src_Person_BusinessEntityAddress) n;
-- Validar sobre los valores originales sin provocar errores de conversion.
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Person.BusinessEntityAddress',st.__RowID,'REJECT',e.FieldName,e.Reason,st.__Raw
FROM #src_Person_BusinessEntityAddress st
CROSS APPLY OPENJSON(st.__Raw) WITH ([BusinessEntityID] nvarchar(max) '$.BusinessEntityID',[AddressID] nvarchar(max) '$.AddressID',[AddressTypeID] nvarchar(max) '$.AddressTypeID') s
CROSS APPLY (VALUES (N'BusinessEntityID', CASE WHEN TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[BusinessEntityID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[BusinessEntityID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[BusinessEntityID],126))),N'')) < 1 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[BusinessEntityID],126))),N'')) > 2147483647 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[BusinessEntityID],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[BusinessEntityID],126))),N''))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'AddressID', CASE WHEN TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[AddressID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[AddressID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[AddressID],126))),N'')) < 1 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[AddressID],126))),N'')) > 2147483647 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[AddressID],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[AddressID],126))),N''))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'AddressTypeID', CASE WHEN TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[AddressTypeID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[AddressTypeID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[AddressTypeID],126))),N'')) < 1 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[AddressTypeID],126))),N'')) > 2147483647 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[AddressTypeID],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[AddressTypeID],126))),N''))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END)) e(FieldName,Reason)
CROSS JOIN #EtlContext c WHERE e.Reason IS NOT NULL;
-- Rechazar todas las copias de una clave duplicada; no elegir una arbitrariamente.
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Person.BusinessEntityAddress',s.__RowID,'REJECT',N'BusinessEntityID,AddressID,AddressTypeID',N'Clave de negocio duplicada',s.__Raw
FROM #src_Person_BusinessEntityAddress s JOIN (SELECT [BusinessEntityID],[AddressID],[AddressTypeID] FROM #src_Person_BusinessEntityAddress GROUP BY [BusinessEntityID],[AddressID],[AddressTypeID] HAVING COUNT_BIG(*)>1) dup
ON s.[BusinessEntityID]=dup.[BusinessEntityID] AND s.[AddressID]=dup.[AddressID] AND s.[AddressTypeID]=dup.[AddressTypeID] CROSS JOIN #EtlContext c;
DELETE s FROM #src_Person_BusinessEntityAddress s WHERE EXISTS
 (SELECT 1 FROM dbo.EtlIssue i JOIN #EtlContext c ON i.RunID=c.RunID
 WHERE i.SourceTable=N'Person.BusinessEntityAddress' AND i.SourceRowID=s.__RowID AND i.Severity='REJECT');
GO
PRINT 'Preparando Production.ProductCategory...';
SELECT IDENTITY(bigint,1,1) AS __RowID, (SELECT CONVERT(nvarchar(max),s.[ProductCategoryID],126) AS [ProductCategoryID],CONVERT(nvarchar(max),s.[Name],126) AS [Name] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS __Raw,
 TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductCategoryID],126))),N'')) AS [ProductCategoryID],
 NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Name],126))),N'') AS [Name]
INTO #src_Production_ProductCategory
FROM [$(SourceDatabase)].Production.ProductCategory s WITH (HOLDLOCK);
INSERT dbo.EtlTableSummary
SELECT c.RunID,N'Production.ProductCategory',n.RowsReceived,0,0 FROM #EtlContext c
CROSS APPLY (SELECT COUNT_BIG(*) AS RowsReceived FROM #src_Production_ProductCategory) n;
-- Validar sobre los valores originales sin provocar errores de conversion.
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Production.ProductCategory',st.__RowID,'REJECT',e.FieldName,e.Reason,st.__Raw
FROM #src_Production_ProductCategory st
CROSS APPLY OPENJSON(st.__Raw) WITH ([ProductCategoryID] nvarchar(max) '$.ProductCategoryID',[Name] nvarchar(max) '$.Name') s
CROSS APPLY (VALUES (N'ProductCategoryID', CASE WHEN TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductCategoryID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductCategoryID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductCategoryID],126))),N'')) < 1 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductCategoryID],126))),N'')) > 2147483647 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductCategoryID],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductCategoryID],126))),N''))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'Name', CASE WHEN NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Name],126))),N'') IS NULL OR LEN(NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Name],126))),N'')) > 50 THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END)) e(FieldName,Reason)
CROSS JOIN #EtlContext c WHERE e.Reason IS NOT NULL;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Production.ProductCategory',st.__RowID,'NORMALIZED',e.FieldName,e.Reason,st.__Raw
FROM #src_Production_ProductCategory st
CROSS APPLY OPENJSON(st.__Raw) WITH ([ProductCategoryID] nvarchar(max) '$.ProductCategoryID',[Name] nvarchar(max) '$.Name') s
CROSS APPLY (VALUES (N'Name', CASE WHEN DATALENGTH(CONVERT(nvarchar(max),s.[Name],126)) <> DATALENGTH(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Name],126)))) OR (s.[Name] IS NOT NULL AND NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Name],126))),N'') IS NULL) THEN N'Espacios recortados / texto vacio convertido a NULL' END)) e(FieldName,Reason)
CROSS JOIN #EtlContext c WHERE e.Reason IS NOT NULL;
-- Rechazar todas las copias de una clave duplicada; no elegir una arbitrariamente.
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Production.ProductCategory',s.__RowID,'REJECT',N'ProductCategoryID',N'Clave de negocio duplicada',s.__Raw
FROM #src_Production_ProductCategory s JOIN (SELECT [ProductCategoryID] FROM #src_Production_ProductCategory GROUP BY [ProductCategoryID] HAVING COUNT_BIG(*)>1) dup
ON s.[ProductCategoryID]=dup.[ProductCategoryID] CROSS JOIN #EtlContext c;
DELETE s FROM #src_Production_ProductCategory s WHERE EXISTS
 (SELECT 1 FROM dbo.EtlIssue i JOIN #EtlContext c ON i.RunID=c.RunID
 WHERE i.SourceTable=N'Production.ProductCategory' AND i.SourceRowID=s.__RowID AND i.Severity='REJECT');
GO
PRINT 'Preparando Production.ProductSubcategory...';
SELECT IDENTITY(bigint,1,1) AS __RowID, (SELECT CONVERT(nvarchar(max),s.[ProductSubcategoryID],126) AS [ProductSubcategoryID],CONVERT(nvarchar(max),s.[ProductCategoryID],126) AS [ProductCategoryID],CONVERT(nvarchar(max),s.[Name],126) AS [Name] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS __Raw,
 TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductSubcategoryID],126))),N'')) AS [ProductSubcategoryID],
 TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductCategoryID],126))),N'')) AS [ProductCategoryID],
 NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Name],126))),N'') AS [Name]
INTO #src_Production_ProductSubcategory
FROM [$(SourceDatabase)].Production.ProductSubcategory s WITH (HOLDLOCK);
INSERT dbo.EtlTableSummary
SELECT c.RunID,N'Production.ProductSubcategory',n.RowsReceived,0,0 FROM #EtlContext c
CROSS APPLY (SELECT COUNT_BIG(*) AS RowsReceived FROM #src_Production_ProductSubcategory) n;
-- Validar sobre los valores originales sin provocar errores de conversion.
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Production.ProductSubcategory',st.__RowID,'REJECT',e.FieldName,e.Reason,st.__Raw
FROM #src_Production_ProductSubcategory st
CROSS APPLY OPENJSON(st.__Raw) WITH ([ProductSubcategoryID] nvarchar(max) '$.ProductSubcategoryID',[ProductCategoryID] nvarchar(max) '$.ProductCategoryID',[Name] nvarchar(max) '$.Name') s
CROSS APPLY (VALUES (N'ProductSubcategoryID', CASE WHEN TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductSubcategoryID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductSubcategoryID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductSubcategoryID],126))),N'')) < 1 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductSubcategoryID],126))),N'')) > 2147483647 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductSubcategoryID],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductSubcategoryID],126))),N''))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'ProductCategoryID', CASE WHEN TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductCategoryID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductCategoryID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductCategoryID],126))),N'')) < 1 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductCategoryID],126))),N'')) > 2147483647 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductCategoryID],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductCategoryID],126))),N''))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'Name', CASE WHEN NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Name],126))),N'') IS NULL OR LEN(NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Name],126))),N'')) > 50 THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END)) e(FieldName,Reason)
CROSS JOIN #EtlContext c WHERE e.Reason IS NOT NULL;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Production.ProductSubcategory',st.__RowID,'NORMALIZED',e.FieldName,e.Reason,st.__Raw
FROM #src_Production_ProductSubcategory st
CROSS APPLY OPENJSON(st.__Raw) WITH ([ProductSubcategoryID] nvarchar(max) '$.ProductSubcategoryID',[ProductCategoryID] nvarchar(max) '$.ProductCategoryID',[Name] nvarchar(max) '$.Name') s
CROSS APPLY (VALUES (N'Name', CASE WHEN DATALENGTH(CONVERT(nvarchar(max),s.[Name],126)) <> DATALENGTH(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Name],126)))) OR (s.[Name] IS NOT NULL AND NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Name],126))),N'') IS NULL) THEN N'Espacios recortados / texto vacio convertido a NULL' END)) e(FieldName,Reason)
CROSS JOIN #EtlContext c WHERE e.Reason IS NOT NULL;
-- Rechazar todas las copias de una clave duplicada; no elegir una arbitrariamente.
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Production.ProductSubcategory',s.__RowID,'REJECT',N'ProductSubcategoryID',N'Clave de negocio duplicada',s.__Raw
FROM #src_Production_ProductSubcategory s JOIN (SELECT [ProductSubcategoryID] FROM #src_Production_ProductSubcategory GROUP BY [ProductSubcategoryID] HAVING COUNT_BIG(*)>1) dup
ON s.[ProductSubcategoryID]=dup.[ProductSubcategoryID] CROSS JOIN #EtlContext c;
DELETE s FROM #src_Production_ProductSubcategory s WHERE EXISTS
 (SELECT 1 FROM dbo.EtlIssue i JOIN #EtlContext c ON i.RunID=c.RunID
 WHERE i.SourceTable=N'Production.ProductSubcategory' AND i.SourceRowID=s.__RowID AND i.Severity='REJECT');
GO
PRINT 'Preparando Production.Product...';
SELECT IDENTITY(bigint,1,1) AS __RowID, (SELECT CONVERT(nvarchar(max),s.[ProductID],126) AS [ProductID],CONVERT(nvarchar(max),s.[Name],126) AS [Name],CONVERT(nvarchar(max),s.[ProductNumber],126) AS [ProductNumber],CONVERT(nvarchar(max),s.[MakeFlag],126) AS [MakeFlag],CONVERT(nvarchar(max),s.[FinishedGoodsFlag],126) AS [FinishedGoodsFlag],CONVERT(nvarchar(max),s.[Color],126) AS [Color],CONVERT(nvarchar(max),s.[SafetyStockLevel],126) AS [SafetyStockLevel],CONVERT(nvarchar(max),s.[ReorderPoint],126) AS [ReorderPoint],CONVERT(nvarchar(max),s.[StandardCost],126) AS [StandardCost],CONVERT(nvarchar(max),s.[ListPrice],126) AS [ListPrice],CONVERT(nvarchar(max),s.[ProductSubcategoryID],126) AS [ProductSubcategoryID] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS __Raw,
 TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductID],126))),N'')) AS [ProductID],
 NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Name],126))),N'') AS [Name],
 NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductNumber],126))),N'') AS [ProductNumber],
 TRY_CONVERT(bit,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[MakeFlag],126))),N'')) AS [MakeFlag],
 TRY_CONVERT(bit,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[FinishedGoodsFlag],126))),N'')) AS [FinishedGoodsFlag],
 NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Color],126))),N'') AS [Color],
 TRY_CONVERT(smallint,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SafetyStockLevel],126))),N'')) AS [SafetyStockLevel],
 TRY_CONVERT(smallint,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ReorderPoint],126))),N'')) AS [ReorderPoint],
 TRY_CONVERT(money,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[StandardCost],126))),N'')) AS [StandardCost],
 TRY_CONVERT(money,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ListPrice],126))),N'')) AS [ListPrice],
 TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductSubcategoryID],126))),N'')) AS [ProductSubcategoryID]
INTO #src_Production_Product
FROM [$(SourceDatabase)].Production.Product s WITH (HOLDLOCK);
INSERT dbo.EtlTableSummary
SELECT c.RunID,N'Production.Product',n.RowsReceived,0,0 FROM #EtlContext c
CROSS APPLY (SELECT COUNT_BIG(*) AS RowsReceived FROM #src_Production_Product) n;
-- Validar sobre los valores originales sin provocar errores de conversion.
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Production.Product',st.__RowID,'REJECT',e.FieldName,e.Reason,st.__Raw
FROM #src_Production_Product st
CROSS APPLY OPENJSON(st.__Raw) WITH ([ProductID] nvarchar(max) '$.ProductID',[Name] nvarchar(max) '$.Name',[ProductNumber] nvarchar(max) '$.ProductNumber',[MakeFlag] nvarchar(max) '$.MakeFlag',[FinishedGoodsFlag] nvarchar(max) '$.FinishedGoodsFlag',[Color] nvarchar(max) '$.Color',[SafetyStockLevel] nvarchar(max) '$.SafetyStockLevel',[ReorderPoint] nvarchar(max) '$.ReorderPoint',[StandardCost] nvarchar(max) '$.StandardCost',[ListPrice] nvarchar(max) '$.ListPrice',[ProductSubcategoryID] nvarchar(max) '$.ProductSubcategoryID') s
CROSS APPLY (VALUES (N'ProductID', CASE WHEN TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductID],126))),N'')) < 1 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductID],126))),N'')) > 2147483647 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductID],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductID],126))),N''))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'Name', CASE WHEN NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Name],126))),N'') IS NULL OR LEN(NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Name],126))),N'')) > 100 THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'ProductNumber', CASE WHEN NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductNumber],126))),N'') IS NULL OR LEN(NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductNumber],126))),N'')) > 30 THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'MakeFlag', CASE WHEN TRY_CONVERT(bit,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[MakeFlag],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[MakeFlag],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[MakeFlag],126))),N'')) < 0 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[MakeFlag],126))),N'')) > 1 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[MakeFlag],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[MakeFlag],126))),N''))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'FinishedGoodsFlag', CASE WHEN TRY_CONVERT(bit,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[FinishedGoodsFlag],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[FinishedGoodsFlag],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[FinishedGoodsFlag],126))),N'')) < 0 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[FinishedGoodsFlag],126))),N'')) > 1 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[FinishedGoodsFlag],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[FinishedGoodsFlag],126))),N''))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'Color', CASE WHEN LEN(NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Color],126))),N'')) > 20 THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'SafetyStockLevel', CASE WHEN TRY_CONVERT(smallint,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SafetyStockLevel],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SafetyStockLevel],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SafetyStockLevel],126))),N'')) < 0 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SafetyStockLevel],126))),N'')) > 32767 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SafetyStockLevel],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SafetyStockLevel],126))),N''))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'ReorderPoint', CASE WHEN TRY_CONVERT(smallint,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ReorderPoint],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ReorderPoint],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ReorderPoint],126))),N'')) < 0 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ReorderPoint],126))),N'')) > 32767 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ReorderPoint],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ReorderPoint],126))),N''))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'StandardCost', CASE WHEN TRY_CONVERT(money,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[StandardCost],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[StandardCost],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[StandardCost],126))),N'')) < 0 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[StandardCost],126))),N'')) > 922337203685477.6 THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'ListPrice', CASE WHEN TRY_CONVERT(money,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ListPrice],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ListPrice],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ListPrice],126))),N'')) < 0 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ListPrice],126))),N'')) > 922337203685477.6 THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'ProductSubcategoryID', CASE WHEN NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductSubcategoryID],126))),N'') IS NOT NULL AND (TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductSubcategoryID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductSubcategoryID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductSubcategoryID],126))),N'')) < 1 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductSubcategoryID],126))),N'')) > 2147483647 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductSubcategoryID],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductSubcategoryID],126))),N'')))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END)) e(FieldName,Reason)
CROSS JOIN #EtlContext c WHERE e.Reason IS NOT NULL;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Production.Product',st.__RowID,'NORMALIZED',e.FieldName,e.Reason,st.__Raw
FROM #src_Production_Product st
CROSS APPLY OPENJSON(st.__Raw) WITH ([ProductID] nvarchar(max) '$.ProductID',[Name] nvarchar(max) '$.Name',[ProductNumber] nvarchar(max) '$.ProductNumber',[MakeFlag] nvarchar(max) '$.MakeFlag',[FinishedGoodsFlag] nvarchar(max) '$.FinishedGoodsFlag',[Color] nvarchar(max) '$.Color',[SafetyStockLevel] nvarchar(max) '$.SafetyStockLevel',[ReorderPoint] nvarchar(max) '$.ReorderPoint',[StandardCost] nvarchar(max) '$.StandardCost',[ListPrice] nvarchar(max) '$.ListPrice',[ProductSubcategoryID] nvarchar(max) '$.ProductSubcategoryID') s
CROSS APPLY (VALUES (N'Name', CASE WHEN DATALENGTH(CONVERT(nvarchar(max),s.[Name],126)) <> DATALENGTH(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Name],126)))) OR (s.[Name] IS NOT NULL AND NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Name],126))),N'') IS NULL) THEN N'Espacios recortados / texto vacio convertido a NULL' END),
 (N'ProductNumber', CASE WHEN DATALENGTH(CONVERT(nvarchar(max),s.[ProductNumber],126)) <> DATALENGTH(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductNumber],126)))) OR (s.[ProductNumber] IS NOT NULL AND NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductNumber],126))),N'') IS NULL) THEN N'Espacios recortados / texto vacio convertido a NULL' END),
 (N'Color', CASE WHEN DATALENGTH(CONVERT(nvarchar(max),s.[Color],126)) <> DATALENGTH(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Color],126)))) OR (s.[Color] IS NOT NULL AND NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Color],126))),N'') IS NULL) THEN N'Espacios recortados / texto vacio convertido a NULL' END)) e(FieldName,Reason)
CROSS JOIN #EtlContext c WHERE e.Reason IS NOT NULL;
-- Rechazar todas las copias de una clave duplicada; no elegir una arbitrariamente.
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Production.Product',s.__RowID,'REJECT',N'ProductID',N'Clave de negocio duplicada',s.__Raw
FROM #src_Production_Product s JOIN (SELECT [ProductID] FROM #src_Production_Product GROUP BY [ProductID] HAVING COUNT_BIG(*)>1) dup
ON s.[ProductID]=dup.[ProductID] CROSS JOIN #EtlContext c;
DELETE s FROM #src_Production_Product s WHERE EXISTS
 (SELECT 1 FROM dbo.EtlIssue i JOIN #EtlContext c ON i.RunID=c.RunID
 WHERE i.SourceTable=N'Production.Product' AND i.SourceRowID=s.__RowID AND i.Severity='REJECT');
GO
PRINT 'Preparando Sales.Customer...';
SELECT IDENTITY(bigint,1,1) AS __RowID, (SELECT CONVERT(nvarchar(max),s.[CustomerID],126) AS [CustomerID],CONVERT(nvarchar(max),s.[PersonID],126) AS [PersonID],CONVERT(nvarchar(max),s.[StoreID],126) AS [StoreID],CONVERT(nvarchar(max),s.[TerritoryID],126) AS [TerritoryID] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS __Raw,
 TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[CustomerID],126))),N'')) AS [CustomerID],
 TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[PersonID],126))),N'')) AS [PersonID],
 TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[StoreID],126))),N'')) AS [StoreID],
 TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[TerritoryID],126))),N'')) AS [TerritoryID]
INTO #src_Sales_Customer
FROM [$(SourceDatabase)].Sales.Customer s WITH (HOLDLOCK);
INSERT dbo.EtlTableSummary
SELECT c.RunID,N'Sales.Customer',n.RowsReceived,0,0 FROM #EtlContext c
CROSS APPLY (SELECT COUNT_BIG(*) AS RowsReceived FROM #src_Sales_Customer) n;
-- Validar sobre los valores originales sin provocar errores de conversion.
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Sales.Customer',st.__RowID,'REJECT',e.FieldName,e.Reason,st.__Raw
FROM #src_Sales_Customer st
CROSS APPLY OPENJSON(st.__Raw) WITH ([CustomerID] nvarchar(max) '$.CustomerID',[PersonID] nvarchar(max) '$.PersonID',[StoreID] nvarchar(max) '$.StoreID',[TerritoryID] nvarchar(max) '$.TerritoryID') s
CROSS APPLY (VALUES (N'CustomerID', CASE WHEN TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[CustomerID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[CustomerID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[CustomerID],126))),N'')) < 1 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[CustomerID],126))),N'')) > 2147483647 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[CustomerID],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[CustomerID],126))),N''))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'PersonID', CASE WHEN NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[PersonID],126))),N'') IS NOT NULL AND (TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[PersonID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[PersonID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[PersonID],126))),N'')) < 1 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[PersonID],126))),N'')) > 2147483647 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[PersonID],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[PersonID],126))),N'')))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'StoreID', CASE WHEN NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[StoreID],126))),N'') IS NOT NULL AND (TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[StoreID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[StoreID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[StoreID],126))),N'')) < 1 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[StoreID],126))),N'')) > 2147483647 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[StoreID],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[StoreID],126))),N'')))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'TerritoryID', CASE WHEN NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[TerritoryID],126))),N'') IS NOT NULL AND (TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[TerritoryID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[TerritoryID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[TerritoryID],126))),N'')) < 1 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[TerritoryID],126))),N'')) > 2147483647 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[TerritoryID],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[TerritoryID],126))),N'')))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END)) e(FieldName,Reason)
CROSS JOIN #EtlContext c WHERE e.Reason IS NOT NULL;
-- Rechazar todas las copias de una clave duplicada; no elegir una arbitrariamente.
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Sales.Customer',s.__RowID,'REJECT',N'CustomerID',N'Clave de negocio duplicada',s.__Raw
FROM #src_Sales_Customer s JOIN (SELECT [CustomerID] FROM #src_Sales_Customer GROUP BY [CustomerID] HAVING COUNT_BIG(*)>1) dup
ON s.[CustomerID]=dup.[CustomerID] CROSS JOIN #EtlContext c;
DELETE s FROM #src_Sales_Customer s WHERE EXISTS
 (SELECT 1 FROM dbo.EtlIssue i JOIN #EtlContext c ON i.RunID=c.RunID
 WHERE i.SourceTable=N'Sales.Customer' AND i.SourceRowID=s.__RowID AND i.Severity='REJECT');
GO
PRINT 'Preparando Sales.SalesPerson...';
SELECT IDENTITY(bigint,1,1) AS __RowID, (SELECT CONVERT(nvarchar(max),s.[BusinessEntityID],126) AS [BusinessEntityID],CONVERT(nvarchar(max),s.[SalesQuota],126) AS [SalesQuota],CONVERT(nvarchar(max),s.[Bonus],126) AS [Bonus],CONVERT(nvarchar(max),s.[CommissionPct],126) AS [CommissionPct],CONVERT(nvarchar(max),s.[TerritoryID],126) AS [TerritoryID] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS __Raw,
 TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[BusinessEntityID],126))),N'')) AS [BusinessEntityID],
 TRY_CONVERT(money,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SalesQuota],126))),N'')) AS [SalesQuota],
 TRY_CONVERT(money,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Bonus],126))),N'')) AS [Bonus],
 TRY_CONVERT(decimal(5,4),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[CommissionPct],126))),N'')) AS [CommissionPct],
 TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[TerritoryID],126))),N'')) AS [TerritoryID]
INTO #src_Sales_SalesPerson
FROM [$(SourceDatabase)].Sales.SalesPerson s WITH (HOLDLOCK);
INSERT dbo.EtlTableSummary
SELECT c.RunID,N'Sales.SalesPerson',n.RowsReceived,0,0 FROM #EtlContext c
CROSS APPLY (SELECT COUNT_BIG(*) AS RowsReceived FROM #src_Sales_SalesPerson) n;
-- Validar sobre los valores originales sin provocar errores de conversion.
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Sales.SalesPerson',st.__RowID,'REJECT',e.FieldName,e.Reason,st.__Raw
FROM #src_Sales_SalesPerson st
CROSS APPLY OPENJSON(st.__Raw) WITH ([BusinessEntityID] nvarchar(max) '$.BusinessEntityID',[SalesQuota] nvarchar(max) '$.SalesQuota',[Bonus] nvarchar(max) '$.Bonus',[CommissionPct] nvarchar(max) '$.CommissionPct',[TerritoryID] nvarchar(max) '$.TerritoryID') s
CROSS APPLY (VALUES (N'BusinessEntityID', CASE WHEN TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[BusinessEntityID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[BusinessEntityID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[BusinessEntityID],126))),N'')) < 1 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[BusinessEntityID],126))),N'')) > 2147483647 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[BusinessEntityID],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[BusinessEntityID],126))),N''))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'SalesQuota', CASE WHEN NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SalesQuota],126))),N'') IS NOT NULL AND (TRY_CONVERT(money,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SalesQuota],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SalesQuota],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SalesQuota],126))),N'')) < 0 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SalesQuota],126))),N'')) > 922337203685477.6) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'Bonus', CASE WHEN TRY_CONVERT(money,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Bonus],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Bonus],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Bonus],126))),N'')) < 0 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Bonus],126))),N'')) > 922337203685477.6 THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'CommissionPct', CASE WHEN TRY_CONVERT(decimal(5,4),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[CommissionPct],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[CommissionPct],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[CommissionPct],126))),N'')) < 0 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[CommissionPct],126))),N'')) > 1 THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'TerritoryID', CASE WHEN NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[TerritoryID],126))),N'') IS NOT NULL AND (TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[TerritoryID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[TerritoryID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[TerritoryID],126))),N'')) < 1 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[TerritoryID],126))),N'')) > 2147483647 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[TerritoryID],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[TerritoryID],126))),N'')))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END)) e(FieldName,Reason)
CROSS JOIN #EtlContext c WHERE e.Reason IS NOT NULL;
-- Rechazar todas las copias de una clave duplicada; no elegir una arbitrariamente.
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Sales.SalesPerson',s.__RowID,'REJECT',N'BusinessEntityID',N'Clave de negocio duplicada',s.__Raw
FROM #src_Sales_SalesPerson s JOIN (SELECT [BusinessEntityID] FROM #src_Sales_SalesPerson GROUP BY [BusinessEntityID] HAVING COUNT_BIG(*)>1) dup
ON s.[BusinessEntityID]=dup.[BusinessEntityID] CROSS JOIN #EtlContext c;
DELETE s FROM #src_Sales_SalesPerson s WHERE EXISTS
 (SELECT 1 FROM dbo.EtlIssue i JOIN #EtlContext c ON i.RunID=c.RunID
 WHERE i.SourceTable=N'Sales.SalesPerson' AND i.SourceRowID=s.__RowID AND i.Severity='REJECT');
GO
PRINT 'Preparando Sales.SpecialOffer...';
SELECT IDENTITY(bigint,1,1) AS __RowID, (SELECT CONVERT(nvarchar(max),s.[SpecialOfferID],126) AS [SpecialOfferID],CONVERT(nvarchar(max),s.[Description],126) AS [Description],CONVERT(nvarchar(max),s.[DiscountPct],126) AS [DiscountPct],CONVERT(nvarchar(max),s.[Type],126) AS [Type],CONVERT(nvarchar(max),s.[Category],126) AS [Category] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS __Raw,
 TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SpecialOfferID],126))),N'')) AS [SpecialOfferID],
 NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Description],126))),N'') AS [Description],
 TRY_CONVERT(decimal(5,4),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[DiscountPct],126))),N'')) AS [DiscountPct],
 NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Type],126))),N'') AS [Type],
 NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Category],126))),N'') AS [Category]
INTO #src_Sales_SpecialOffer
FROM [$(SourceDatabase)].Sales.SpecialOffer s WITH (HOLDLOCK);
INSERT dbo.EtlTableSummary
SELECT c.RunID,N'Sales.SpecialOffer',n.RowsReceived,0,0 FROM #EtlContext c
CROSS APPLY (SELECT COUNT_BIG(*) AS RowsReceived FROM #src_Sales_SpecialOffer) n;
-- Validar sobre los valores originales sin provocar errores de conversion.
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Sales.SpecialOffer',st.__RowID,'REJECT',e.FieldName,e.Reason,st.__Raw
FROM #src_Sales_SpecialOffer st
CROSS APPLY OPENJSON(st.__Raw) WITH ([SpecialOfferID] nvarchar(max) '$.SpecialOfferID',[Description] nvarchar(max) '$.Description',[DiscountPct] nvarchar(max) '$.DiscountPct',[Type] nvarchar(max) '$.Type',[Category] nvarchar(max) '$.Category') s
CROSS APPLY (VALUES (N'SpecialOfferID', CASE WHEN TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SpecialOfferID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SpecialOfferID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SpecialOfferID],126))),N'')) < 1 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SpecialOfferID],126))),N'')) > 2147483647 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SpecialOfferID],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SpecialOfferID],126))),N''))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'Description', CASE WHEN NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Description],126))),N'') IS NULL OR LEN(NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Description],126))),N'')) > 255 THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'DiscountPct', CASE WHEN TRY_CONVERT(decimal(5,4),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[DiscountPct],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[DiscountPct],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[DiscountPct],126))),N'')) < 0 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[DiscountPct],126))),N'')) > 1 THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'Type', CASE WHEN NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Type],126))),N'') IS NULL OR LEN(NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Type],126))),N'')) > 50 THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'Category', CASE WHEN NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Category],126))),N'') IS NULL OR LEN(NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Category],126))),N'')) > 50 THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END)) e(FieldName,Reason)
CROSS JOIN #EtlContext c WHERE e.Reason IS NOT NULL;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Sales.SpecialOffer',st.__RowID,'NORMALIZED',e.FieldName,e.Reason,st.__Raw
FROM #src_Sales_SpecialOffer st
CROSS APPLY OPENJSON(st.__Raw) WITH ([SpecialOfferID] nvarchar(max) '$.SpecialOfferID',[Description] nvarchar(max) '$.Description',[DiscountPct] nvarchar(max) '$.DiscountPct',[Type] nvarchar(max) '$.Type',[Category] nvarchar(max) '$.Category') s
CROSS APPLY (VALUES (N'Description', CASE WHEN DATALENGTH(CONVERT(nvarchar(max),s.[Description],126)) <> DATALENGTH(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Description],126)))) OR (s.[Description] IS NOT NULL AND NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Description],126))),N'') IS NULL) THEN N'Espacios recortados / texto vacio convertido a NULL' END),
 (N'Type', CASE WHEN DATALENGTH(CONVERT(nvarchar(max),s.[Type],126)) <> DATALENGTH(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Type],126)))) OR (s.[Type] IS NOT NULL AND NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Type],126))),N'') IS NULL) THEN N'Espacios recortados / texto vacio convertido a NULL' END),
 (N'Category', CASE WHEN DATALENGTH(CONVERT(nvarchar(max),s.[Category],126)) <> DATALENGTH(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Category],126)))) OR (s.[Category] IS NOT NULL AND NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Category],126))),N'') IS NULL) THEN N'Espacios recortados / texto vacio convertido a NULL' END)) e(FieldName,Reason)
CROSS JOIN #EtlContext c WHERE e.Reason IS NOT NULL;
-- Rechazar todas las copias de una clave duplicada; no elegir una arbitrariamente.
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Sales.SpecialOffer',s.__RowID,'REJECT',N'SpecialOfferID',N'Clave de negocio duplicada',s.__Raw
FROM #src_Sales_SpecialOffer s JOIN (SELECT [SpecialOfferID] FROM #src_Sales_SpecialOffer GROUP BY [SpecialOfferID] HAVING COUNT_BIG(*)>1) dup
ON s.[SpecialOfferID]=dup.[SpecialOfferID] CROSS JOIN #EtlContext c;
DELETE s FROM #src_Sales_SpecialOffer s WHERE EXISTS
 (SELECT 1 FROM dbo.EtlIssue i JOIN #EtlContext c ON i.RunID=c.RunID
 WHERE i.SourceTable=N'Sales.SpecialOffer' AND i.SourceRowID=s.__RowID AND i.Severity='REJECT');
GO
PRINT 'Preparando Production.Location...';
SELECT IDENTITY(bigint,1,1) AS __RowID, (SELECT CONVERT(nvarchar(max),s.[LocationID],126) AS [LocationID],CONVERT(nvarchar(max),s.[Name],126) AS [Name],CONVERT(nvarchar(max),s.[CostRate],126) AS [CostRate],CONVERT(nvarchar(max),s.[Availability],126) AS [Availability] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS __Raw,
 TRY_CONVERT(smallint,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[LocationID],126))),N'')) AS [LocationID],
 NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Name],126))),N'') AS [Name],
 TRY_CONVERT(smallmoney,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[CostRate],126))),N'')) AS [CostRate],
 TRY_CONVERT(decimal(8,2),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Availability],126))),N'')) AS [Availability]
INTO #src_Production_Location
FROM [$(SourceDatabase)].Production.Location s WITH (HOLDLOCK);
INSERT dbo.EtlTableSummary
SELECT c.RunID,N'Production.Location',n.RowsReceived,0,0 FROM #EtlContext c
CROSS APPLY (SELECT COUNT_BIG(*) AS RowsReceived FROM #src_Production_Location) n;
-- Validar sobre los valores originales sin provocar errores de conversion.
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Production.Location',st.__RowID,'REJECT',e.FieldName,e.Reason,st.__Raw
FROM #src_Production_Location st
CROSS APPLY OPENJSON(st.__Raw) WITH ([LocationID] nvarchar(max) '$.LocationID',[Name] nvarchar(max) '$.Name',[CostRate] nvarchar(max) '$.CostRate',[Availability] nvarchar(max) '$.Availability') s
CROSS APPLY (VALUES (N'LocationID', CASE WHEN TRY_CONVERT(smallint,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[LocationID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[LocationID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[LocationID],126))),N'')) < 1 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[LocationID],126))),N'')) > 32767 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[LocationID],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[LocationID],126))),N''))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'Name', CASE WHEN NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Name],126))),N'') IS NULL OR LEN(NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Name],126))),N'')) > 50 THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'CostRate', CASE WHEN TRY_CONVERT(smallmoney,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[CostRate],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[CostRate],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[CostRate],126))),N'')) < 0 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[CostRate],126))),N'')) > 214748.3647 THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'Availability', CASE WHEN TRY_CONVERT(decimal(8,2),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Availability],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Availability],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Availability],126))),N'')) < 0 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Availability],126))),N'')) > 999999.99 THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END)) e(FieldName,Reason)
CROSS JOIN #EtlContext c WHERE e.Reason IS NOT NULL;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Production.Location',st.__RowID,'NORMALIZED',e.FieldName,e.Reason,st.__Raw
FROM #src_Production_Location st
CROSS APPLY OPENJSON(st.__Raw) WITH ([LocationID] nvarchar(max) '$.LocationID',[Name] nvarchar(max) '$.Name',[CostRate] nvarchar(max) '$.CostRate',[Availability] nvarchar(max) '$.Availability') s
CROSS APPLY (VALUES (N'Name', CASE WHEN DATALENGTH(CONVERT(nvarchar(max),s.[Name],126)) <> DATALENGTH(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Name],126)))) OR (s.[Name] IS NOT NULL AND NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Name],126))),N'') IS NULL) THEN N'Espacios recortados / texto vacio convertido a NULL' END)) e(FieldName,Reason)
CROSS JOIN #EtlContext c WHERE e.Reason IS NOT NULL;
-- Rechazar todas las copias de una clave duplicada; no elegir una arbitrariamente.
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Production.Location',s.__RowID,'REJECT',N'LocationID',N'Clave de negocio duplicada',s.__Raw
FROM #src_Production_Location s JOIN (SELECT [LocationID] FROM #src_Production_Location GROUP BY [LocationID] HAVING COUNT_BIG(*)>1) dup
ON s.[LocationID]=dup.[LocationID] CROSS JOIN #EtlContext c;
DELETE s FROM #src_Production_Location s WHERE EXISTS
 (SELECT 1 FROM dbo.EtlIssue i JOIN #EtlContext c ON i.RunID=c.RunID
 WHERE i.SourceTable=N'Production.Location' AND i.SourceRowID=s.__RowID AND i.Severity='REJECT');
GO
PRINT 'Preparando Production.ScrapReason...';
SELECT IDENTITY(bigint,1,1) AS __RowID, (SELECT CONVERT(nvarchar(max),s.[ScrapReasonID],126) AS [ScrapReasonID],CONVERT(nvarchar(max),s.[Name],126) AS [Name] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS __Raw,
 TRY_CONVERT(smallint,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ScrapReasonID],126))),N'')) AS [ScrapReasonID],
 NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Name],126))),N'') AS [Name]
INTO #src_Production_ScrapReason
FROM [$(SourceDatabase)].Production.ScrapReason s WITH (HOLDLOCK);
INSERT dbo.EtlTableSummary
SELECT c.RunID,N'Production.ScrapReason',n.RowsReceived,0,0 FROM #EtlContext c
CROSS APPLY (SELECT COUNT_BIG(*) AS RowsReceived FROM #src_Production_ScrapReason) n;
-- Validar sobre los valores originales sin provocar errores de conversion.
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Production.ScrapReason',st.__RowID,'REJECT',e.FieldName,e.Reason,st.__Raw
FROM #src_Production_ScrapReason st
CROSS APPLY OPENJSON(st.__Raw) WITH ([ScrapReasonID] nvarchar(max) '$.ScrapReasonID',[Name] nvarchar(max) '$.Name') s
CROSS APPLY (VALUES (N'ScrapReasonID', CASE WHEN TRY_CONVERT(smallint,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ScrapReasonID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ScrapReasonID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ScrapReasonID],126))),N'')) < 1 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ScrapReasonID],126))),N'')) > 32767 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ScrapReasonID],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ScrapReasonID],126))),N''))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'Name', CASE WHEN NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Name],126))),N'') IS NULL OR LEN(NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Name],126))),N'')) > 50 THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END)) e(FieldName,Reason)
CROSS JOIN #EtlContext c WHERE e.Reason IS NOT NULL;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Production.ScrapReason',st.__RowID,'NORMALIZED',e.FieldName,e.Reason,st.__Raw
FROM #src_Production_ScrapReason st
CROSS APPLY OPENJSON(st.__Raw) WITH ([ScrapReasonID] nvarchar(max) '$.ScrapReasonID',[Name] nvarchar(max) '$.Name') s
CROSS APPLY (VALUES (N'Name', CASE WHEN DATALENGTH(CONVERT(nvarchar(max),s.[Name],126)) <> DATALENGTH(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Name],126)))) OR (s.[Name] IS NOT NULL AND NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Name],126))),N'') IS NULL) THEN N'Espacios recortados / texto vacio convertido a NULL' END)) e(FieldName,Reason)
CROSS JOIN #EtlContext c WHERE e.Reason IS NOT NULL;
-- Rechazar todas las copias de una clave duplicada; no elegir una arbitrariamente.
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Production.ScrapReason',s.__RowID,'REJECT',N'ScrapReasonID',N'Clave de negocio duplicada',s.__Raw
FROM #src_Production_ScrapReason s JOIN (SELECT [ScrapReasonID] FROM #src_Production_ScrapReason GROUP BY [ScrapReasonID] HAVING COUNT_BIG(*)>1) dup
ON s.[ScrapReasonID]=dup.[ScrapReasonID] CROSS JOIN #EtlContext c;
DELETE s FROM #src_Production_ScrapReason s WHERE EXISTS
 (SELECT 1 FROM dbo.EtlIssue i JOIN #EtlContext c ON i.RunID=c.RunID
 WHERE i.SourceTable=N'Production.ScrapReason' AND i.SourceRowID=s.__RowID AND i.Severity='REJECT');
GO
PRINT 'Preparando Sales.SalesOrderHeader...';
SELECT IDENTITY(bigint,1,1) AS __RowID, (SELECT CONVERT(nvarchar(max),s.[SalesOrderID],126) AS [SalesOrderID],CONVERT(nvarchar(max),s.[OrderDate],126) AS [OrderDate],CONVERT(nvarchar(max),s.[DueDate],126) AS [DueDate],CONVERT(nvarchar(max),s.[ShipDate],126) AS [ShipDate],CONVERT(nvarchar(max),s.[CustomerID],126) AS [CustomerID],CONVERT(nvarchar(max),s.[TerritoryID],126) AS [TerritoryID],CONVERT(nvarchar(max),s.[SalesPersonID],126) AS [SalesPersonID],CONVERT(nvarchar(max),s.[OnlineOrderFlag],126) AS [OnlineOrderFlag] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS __Raw,
 TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SalesOrderID],126))),N'')) AS [SalesOrderID],
 TRY_CONVERT(date,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[OrderDate],126))),N''),126) AS [OrderDate],
 TRY_CONVERT(date,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[DueDate],126))),N''),126) AS [DueDate],
 TRY_CONVERT(date,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ShipDate],126))),N''),126) AS [ShipDate],
 TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[CustomerID],126))),N'')) AS [CustomerID],
 TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[TerritoryID],126))),N'')) AS [TerritoryID],
 TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SalesPersonID],126))),N'')) AS [SalesPersonID],
 TRY_CONVERT(bit,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[OnlineOrderFlag],126))),N'')) AS [OnlineOrderFlag]
INTO #src_Sales_SalesOrderHeader
FROM [$(SourceDatabase)].Sales.SalesOrderHeader s WITH (HOLDLOCK);
INSERT dbo.EtlTableSummary
SELECT c.RunID,N'Sales.SalesOrderHeader',n.RowsReceived,0,0 FROM #EtlContext c
CROSS APPLY (SELECT COUNT_BIG(*) AS RowsReceived FROM #src_Sales_SalesOrderHeader) n;
-- Validar sobre los valores originales sin provocar errores de conversion.
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Sales.SalesOrderHeader',st.__RowID,'REJECT',e.FieldName,e.Reason,st.__Raw
FROM #src_Sales_SalesOrderHeader st
CROSS APPLY OPENJSON(st.__Raw) WITH ([SalesOrderID] nvarchar(max) '$.SalesOrderID',[OrderDate] nvarchar(max) '$.OrderDate',[DueDate] nvarchar(max) '$.DueDate',[ShipDate] nvarchar(max) '$.ShipDate',[CustomerID] nvarchar(max) '$.CustomerID',[TerritoryID] nvarchar(max) '$.TerritoryID',[SalesPersonID] nvarchar(max) '$.SalesPersonID',[OnlineOrderFlag] nvarchar(max) '$.OnlineOrderFlag') s
CROSS APPLY (VALUES (N'SalesOrderID', CASE WHEN TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SalesOrderID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SalesOrderID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SalesOrderID],126))),N'')) < 1 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SalesOrderID],126))),N'')) > 2147483647 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SalesOrderID],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SalesOrderID],126))),N''))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'OrderDate', CASE WHEN TRY_CONVERT(date,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[OrderDate],126))),N''),126) IS NULL THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'DueDate', CASE WHEN TRY_CONVERT(date,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[DueDate],126))),N''),126) IS NULL THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'ShipDate', CASE WHEN NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ShipDate],126))),N'') IS NOT NULL AND TRY_CONVERT(date,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ShipDate],126))),N''),126) IS NULL THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'CustomerID', CASE WHEN TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[CustomerID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[CustomerID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[CustomerID],126))),N'')) < 1 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[CustomerID],126))),N'')) > 2147483647 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[CustomerID],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[CustomerID],126))),N''))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'TerritoryID', CASE WHEN TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[TerritoryID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[TerritoryID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[TerritoryID],126))),N'')) < 1 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[TerritoryID],126))),N'')) > 2147483647 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[TerritoryID],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[TerritoryID],126))),N''))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'SalesPersonID', CASE WHEN NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SalesPersonID],126))),N'') IS NOT NULL AND (TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SalesPersonID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SalesPersonID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SalesPersonID],126))),N'')) < 1 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SalesPersonID],126))),N'')) > 2147483647 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SalesPersonID],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SalesPersonID],126))),N'')))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'OnlineOrderFlag', CASE WHEN TRY_CONVERT(bit,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[OnlineOrderFlag],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[OnlineOrderFlag],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[OnlineOrderFlag],126))),N'')) < 0 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[OnlineOrderFlag],126))),N'')) > 1 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[OnlineOrderFlag],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[OnlineOrderFlag],126))),N''))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END)) e(FieldName,Reason)
CROSS JOIN #EtlContext c WHERE e.Reason IS NOT NULL;
-- Rechazar todas las copias de una clave duplicada; no elegir una arbitrariamente.
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Sales.SalesOrderHeader',s.__RowID,'REJECT',N'SalesOrderID',N'Clave de negocio duplicada',s.__Raw
FROM #src_Sales_SalesOrderHeader s JOIN (SELECT [SalesOrderID] FROM #src_Sales_SalesOrderHeader GROUP BY [SalesOrderID] HAVING COUNT_BIG(*)>1) dup
ON s.[SalesOrderID]=dup.[SalesOrderID] CROSS JOIN #EtlContext c;
DELETE s FROM #src_Sales_SalesOrderHeader s WHERE EXISTS
 (SELECT 1 FROM dbo.EtlIssue i JOIN #EtlContext c ON i.RunID=c.RunID
 WHERE i.SourceTable=N'Sales.SalesOrderHeader' AND i.SourceRowID=s.__RowID AND i.Severity='REJECT');
GO
PRINT 'Preparando Sales.SalesOrderDetail...';
SELECT IDENTITY(bigint,1,1) AS __RowID, (SELECT CONVERT(nvarchar(max),s.[SalesOrderID],126) AS [SalesOrderID],CONVERT(nvarchar(max),s.[SalesOrderDetailID],126) AS [SalesOrderDetailID],CONVERT(nvarchar(max),s.[ProductID],126) AS [ProductID],CONVERT(nvarchar(max),s.[SpecialOfferID],126) AS [SpecialOfferID],CONVERT(nvarchar(max),s.[OrderQty],126) AS [OrderQty],CONVERT(nvarchar(max),s.[UnitPrice],126) AS [UnitPrice],CONVERT(nvarchar(max),s.[UnitPriceDiscount],126) AS [UnitPriceDiscount],CONVERT(nvarchar(max),s.[LineTotal],126) AS [LineTotal] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS __Raw,
 TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SalesOrderID],126))),N'')) AS [SalesOrderID],
 TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SalesOrderDetailID],126))),N'')) AS [SalesOrderDetailID],
 TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductID],126))),N'')) AS [ProductID],
 TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SpecialOfferID],126))),N'')) AS [SpecialOfferID],
 TRY_CONVERT(smallint,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[OrderQty],126))),N'')) AS [OrderQty],
 TRY_CONVERT(money,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[UnitPrice],126))),N'')) AS [UnitPrice],
 TRY_CONVERT(money,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[UnitPriceDiscount],126))),N'')) AS [UnitPriceDiscount],
 TRY_CONVERT(decimal(38,6),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[LineTotal],126))),N'')) AS [LineTotal]
INTO #src_Sales_SalesOrderDetail
FROM [$(SourceDatabase)].Sales.SalesOrderDetail s WITH (HOLDLOCK);
INSERT dbo.EtlTableSummary
SELECT c.RunID,N'Sales.SalesOrderDetail',n.RowsReceived,0,0 FROM #EtlContext c
CROSS APPLY (SELECT COUNT_BIG(*) AS RowsReceived FROM #src_Sales_SalesOrderDetail) n;
-- Validar sobre los valores originales sin provocar errores de conversion.
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Sales.SalesOrderDetail',st.__RowID,'REJECT',e.FieldName,e.Reason,st.__Raw
FROM #src_Sales_SalesOrderDetail st
CROSS APPLY OPENJSON(st.__Raw) WITH ([SalesOrderID] nvarchar(max) '$.SalesOrderID',[SalesOrderDetailID] nvarchar(max) '$.SalesOrderDetailID',[ProductID] nvarchar(max) '$.ProductID',[SpecialOfferID] nvarchar(max) '$.SpecialOfferID',[OrderQty] nvarchar(max) '$.OrderQty',[UnitPrice] nvarchar(max) '$.UnitPrice',[UnitPriceDiscount] nvarchar(max) '$.UnitPriceDiscount',[LineTotal] nvarchar(max) '$.LineTotal') s
CROSS APPLY (VALUES (N'SalesOrderID', CASE WHEN TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SalesOrderID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SalesOrderID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SalesOrderID],126))),N'')) < 1 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SalesOrderID],126))),N'')) > 2147483647 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SalesOrderID],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SalesOrderID],126))),N''))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'SalesOrderDetailID', CASE WHEN TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SalesOrderDetailID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SalesOrderDetailID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SalesOrderDetailID],126))),N'')) < 1 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SalesOrderDetailID],126))),N'')) > 2147483647 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SalesOrderDetailID],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SalesOrderDetailID],126))),N''))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'ProductID', CASE WHEN TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductID],126))),N'')) < 1 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductID],126))),N'')) > 2147483647 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductID],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductID],126))),N''))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'SpecialOfferID', CASE WHEN TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SpecialOfferID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SpecialOfferID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SpecialOfferID],126))),N'')) < 1 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SpecialOfferID],126))),N'')) > 2147483647 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SpecialOfferID],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[SpecialOfferID],126))),N''))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'OrderQty', CASE WHEN TRY_CONVERT(smallint,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[OrderQty],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[OrderQty],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[OrderQty],126))),N'')) < 1 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[OrderQty],126))),N'')) > 32767 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[OrderQty],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[OrderQty],126))),N''))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'UnitPrice', CASE WHEN TRY_CONVERT(money,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[UnitPrice],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[UnitPrice],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[UnitPrice],126))),N'')) < 0 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[UnitPrice],126))),N'')) > 922337203685477.6 THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'UnitPriceDiscount', CASE WHEN TRY_CONVERT(money,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[UnitPriceDiscount],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[UnitPriceDiscount],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[UnitPriceDiscount],126))),N'')) < 0 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[UnitPriceDiscount],126))),N'')) > 1 THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'LineTotal', CASE WHEN TRY_CONVERT(decimal(38,6),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[LineTotal],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[LineTotal],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[LineTotal],126))),N'')) < 0 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[LineTotal],126))),N'')) > 1e+24 THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END)) e(FieldName,Reason)
CROSS JOIN #EtlContext c WHERE e.Reason IS NOT NULL;
-- Rechazar todas las copias de una clave duplicada; no elegir una arbitrariamente.
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Sales.SalesOrderDetail',s.__RowID,'REJECT',N'SalesOrderID,SalesOrderDetailID',N'Clave de negocio duplicada',s.__Raw
FROM #src_Sales_SalesOrderDetail s JOIN (SELECT [SalesOrderID],[SalesOrderDetailID] FROM #src_Sales_SalesOrderDetail GROUP BY [SalesOrderID],[SalesOrderDetailID] HAVING COUNT_BIG(*)>1) dup
ON s.[SalesOrderID]=dup.[SalesOrderID] AND s.[SalesOrderDetailID]=dup.[SalesOrderDetailID] CROSS JOIN #EtlContext c;
DELETE s FROM #src_Sales_SalesOrderDetail s WHERE EXISTS
 (SELECT 1 FROM dbo.EtlIssue i JOIN #EtlContext c ON i.RunID=c.RunID
 WHERE i.SourceTable=N'Sales.SalesOrderDetail' AND i.SourceRowID=s.__RowID AND i.Severity='REJECT');
GO
PRINT 'Preparando Production.WorkOrder...';
SELECT IDENTITY(bigint,1,1) AS __RowID, (SELECT CONVERT(nvarchar(max),s.[WorkOrderID],126) AS [WorkOrderID],CONVERT(nvarchar(max),s.[ProductID],126) AS [ProductID],CONVERT(nvarchar(max),s.[ScrapReasonID],126) AS [ScrapReasonID],CONVERT(nvarchar(max),s.[StartDate],126) AS [StartDate],CONVERT(nvarchar(max),s.[EndDate],126) AS [EndDate],CONVERT(nvarchar(max),s.[DueDate],126) AS [DueDate],CONVERT(nvarchar(max),s.[OrderQty],126) AS [OrderQty],CONVERT(nvarchar(max),s.[StockedQty],126) AS [StockedQty],CONVERT(nvarchar(max),s.[ScrappedQty],126) AS [ScrappedQty] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS __Raw,
 TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[WorkOrderID],126))),N'')) AS [WorkOrderID],
 TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductID],126))),N'')) AS [ProductID],
 TRY_CONVERT(smallint,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ScrapReasonID],126))),N'')) AS [ScrapReasonID],
 TRY_CONVERT(date,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[StartDate],126))),N''),126) AS [StartDate],
 TRY_CONVERT(date,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[EndDate],126))),N''),126) AS [EndDate],
 TRY_CONVERT(date,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[DueDate],126))),N''),126) AS [DueDate],
 TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[OrderQty],126))),N'')) AS [OrderQty],
 TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[StockedQty],126))),N'')) AS [StockedQty],
 TRY_CONVERT(smallint,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ScrappedQty],126))),N'')) AS [ScrappedQty]
INTO #src_Production_WorkOrder
FROM [$(SourceDatabase)].Production.WorkOrder s WITH (HOLDLOCK);
INSERT dbo.EtlTableSummary
SELECT c.RunID,N'Production.WorkOrder',n.RowsReceived,0,0 FROM #EtlContext c
CROSS APPLY (SELECT COUNT_BIG(*) AS RowsReceived FROM #src_Production_WorkOrder) n;
-- Validar sobre los valores originales sin provocar errores de conversion.
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Production.WorkOrder',st.__RowID,'REJECT',e.FieldName,e.Reason,st.__Raw
FROM #src_Production_WorkOrder st
CROSS APPLY OPENJSON(st.__Raw) WITH ([WorkOrderID] nvarchar(max) '$.WorkOrderID',[ProductID] nvarchar(max) '$.ProductID',[ScrapReasonID] nvarchar(max) '$.ScrapReasonID',[StartDate] nvarchar(max) '$.StartDate',[EndDate] nvarchar(max) '$.EndDate',[DueDate] nvarchar(max) '$.DueDate',[OrderQty] nvarchar(max) '$.OrderQty',[StockedQty] nvarchar(max) '$.StockedQty',[ScrappedQty] nvarchar(max) '$.ScrappedQty') s
CROSS APPLY (VALUES (N'WorkOrderID', CASE WHEN TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[WorkOrderID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[WorkOrderID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[WorkOrderID],126))),N'')) < 1 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[WorkOrderID],126))),N'')) > 2147483647 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[WorkOrderID],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[WorkOrderID],126))),N''))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'ProductID', CASE WHEN TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductID],126))),N'')) < 1 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductID],126))),N'')) > 2147483647 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductID],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductID],126))),N''))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'ScrapReasonID', CASE WHEN NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ScrapReasonID],126))),N'') IS NOT NULL AND (TRY_CONVERT(smallint,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ScrapReasonID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ScrapReasonID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ScrapReasonID],126))),N'')) < 1 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ScrapReasonID],126))),N'')) > 32767 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ScrapReasonID],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ScrapReasonID],126))),N'')))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'StartDate', CASE WHEN TRY_CONVERT(date,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[StartDate],126))),N''),126) IS NULL THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'EndDate', CASE WHEN NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[EndDate],126))),N'') IS NOT NULL AND TRY_CONVERT(date,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[EndDate],126))),N''),126) IS NULL THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'DueDate', CASE WHEN TRY_CONVERT(date,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[DueDate],126))),N''),126) IS NULL THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'OrderQty', CASE WHEN TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[OrderQty],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[OrderQty],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[OrderQty],126))),N'')) < 1 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[OrderQty],126))),N'')) > 2147483647 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[OrderQty],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[OrderQty],126))),N''))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'StockedQty', CASE WHEN TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[StockedQty],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[StockedQty],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[StockedQty],126))),N'')) < 0 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[StockedQty],126))),N'')) > 2147483647 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[StockedQty],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[StockedQty],126))),N''))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'ScrappedQty', CASE WHEN TRY_CONVERT(smallint,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ScrappedQty],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ScrappedQty],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ScrappedQty],126))),N'')) < 0 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ScrappedQty],126))),N'')) > 32767 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ScrappedQty],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ScrappedQty],126))),N''))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END)) e(FieldName,Reason)
CROSS JOIN #EtlContext c WHERE e.Reason IS NOT NULL;
-- Rechazar todas las copias de una clave duplicada; no elegir una arbitrariamente.
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Production.WorkOrder',s.__RowID,'REJECT',N'WorkOrderID',N'Clave de negocio duplicada',s.__Raw
FROM #src_Production_WorkOrder s JOIN (SELECT [WorkOrderID] FROM #src_Production_WorkOrder GROUP BY [WorkOrderID] HAVING COUNT_BIG(*)>1) dup
ON s.[WorkOrderID]=dup.[WorkOrderID] CROSS JOIN #EtlContext c;
DELETE s FROM #src_Production_WorkOrder s WHERE EXISTS
 (SELECT 1 FROM dbo.EtlIssue i JOIN #EtlContext c ON i.RunID=c.RunID
 WHERE i.SourceTable=N'Production.WorkOrder' AND i.SourceRowID=s.__RowID AND i.Severity='REJECT');
GO
PRINT 'Preparando Production.WorkOrderRouting...';
SELECT IDENTITY(bigint,1,1) AS __RowID, (SELECT CONVERT(nvarchar(max),s.[WorkOrderID],126) AS [WorkOrderID],CONVERT(nvarchar(max),s.[ProductID],126) AS [ProductID],CONVERT(nvarchar(max),s.[LocationID],126) AS [LocationID],CONVERT(nvarchar(max),s.[OperationSequence],126) AS [OperationSequence],CONVERT(nvarchar(max),s.[ScheduledStartDate],126) AS [ScheduledStartDate],CONVERT(nvarchar(max),s.[ScheduledEndDate],126) AS [ScheduledEndDate],CONVERT(nvarchar(max),s.[ActualStartDate],126) AS [ActualStartDate],CONVERT(nvarchar(max),s.[ActualEndDate],126) AS [ActualEndDate],CONVERT(nvarchar(max),s.[ActualResourceHrs],126) AS [ActualResourceHrs],CONVERT(nvarchar(max),s.[PlannedCost],126) AS [PlannedCost],CONVERT(nvarchar(max),s.[ActualCost],126) AS [ActualCost] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS __Raw,
 TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[WorkOrderID],126))),N'')) AS [WorkOrderID],
 TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductID],126))),N'')) AS [ProductID],
 TRY_CONVERT(smallint,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[LocationID],126))),N'')) AS [LocationID],
 TRY_CONVERT(smallint,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[OperationSequence],126))),N'')) AS [OperationSequence],
 TRY_CONVERT(date,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ScheduledStartDate],126))),N''),126) AS [ScheduledStartDate],
 TRY_CONVERT(date,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ScheduledEndDate],126))),N''),126) AS [ScheduledEndDate],
 TRY_CONVERT(date,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ActualStartDate],126))),N''),126) AS [ActualStartDate],
 TRY_CONVERT(date,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ActualEndDate],126))),N''),126) AS [ActualEndDate],
 TRY_CONVERT(decimal(9,4),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ActualResourceHrs],126))),N'')) AS [ActualResourceHrs],
 TRY_CONVERT(money,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[PlannedCost],126))),N'')) AS [PlannedCost],
 TRY_CONVERT(money,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ActualCost],126))),N'')) AS [ActualCost]
INTO #src_Production_WorkOrderRouting
FROM [$(SourceDatabase)].Production.WorkOrderRouting s WITH (HOLDLOCK);
INSERT dbo.EtlTableSummary
SELECT c.RunID,N'Production.WorkOrderRouting',n.RowsReceived,0,0 FROM #EtlContext c
CROSS APPLY (SELECT COUNT_BIG(*) AS RowsReceived FROM #src_Production_WorkOrderRouting) n;
-- Validar sobre los valores originales sin provocar errores de conversion.
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Production.WorkOrderRouting',st.__RowID,'REJECT',e.FieldName,e.Reason,st.__Raw
FROM #src_Production_WorkOrderRouting st
CROSS APPLY OPENJSON(st.__Raw) WITH ([WorkOrderID] nvarchar(max) '$.WorkOrderID',[ProductID] nvarchar(max) '$.ProductID',[LocationID] nvarchar(max) '$.LocationID',[OperationSequence] nvarchar(max) '$.OperationSequence',[ScheduledStartDate] nvarchar(max) '$.ScheduledStartDate',[ScheduledEndDate] nvarchar(max) '$.ScheduledEndDate',[ActualStartDate] nvarchar(max) '$.ActualStartDate',[ActualEndDate] nvarchar(max) '$.ActualEndDate',[ActualResourceHrs] nvarchar(max) '$.ActualResourceHrs',[PlannedCost] nvarchar(max) '$.PlannedCost',[ActualCost] nvarchar(max) '$.ActualCost') s
CROSS APPLY (VALUES (N'WorkOrderID', CASE WHEN TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[WorkOrderID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[WorkOrderID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[WorkOrderID],126))),N'')) < 1 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[WorkOrderID],126))),N'')) > 2147483647 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[WorkOrderID],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[WorkOrderID],126))),N''))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'ProductID', CASE WHEN TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductID],126))),N'')) < 1 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductID],126))),N'')) > 2147483647 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductID],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductID],126))),N''))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'LocationID', CASE WHEN TRY_CONVERT(smallint,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[LocationID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[LocationID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[LocationID],126))),N'')) < 1 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[LocationID],126))),N'')) > 32767 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[LocationID],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[LocationID],126))),N''))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'OperationSequence', CASE WHEN TRY_CONVERT(smallint,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[OperationSequence],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[OperationSequence],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[OperationSequence],126))),N'')) < 1 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[OperationSequence],126))),N'')) > 32767 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[OperationSequence],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[OperationSequence],126))),N''))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'ScheduledStartDate', CASE WHEN TRY_CONVERT(date,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ScheduledStartDate],126))),N''),126) IS NULL THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'ScheduledEndDate', CASE WHEN TRY_CONVERT(date,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ScheduledEndDate],126))),N''),126) IS NULL THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'ActualStartDate', CASE WHEN NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ActualStartDate],126))),N'') IS NOT NULL AND TRY_CONVERT(date,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ActualStartDate],126))),N''),126) IS NULL THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'ActualEndDate', CASE WHEN NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ActualEndDate],126))),N'') IS NOT NULL AND TRY_CONVERT(date,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ActualEndDate],126))),N''),126) IS NULL THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'ActualResourceHrs', CASE WHEN TRY_CONVERT(decimal(9,4),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ActualResourceHrs],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ActualResourceHrs],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ActualResourceHrs],126))),N'')) < 0 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ActualResourceHrs],126))),N'')) > 99999.9999 THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'PlannedCost', CASE WHEN TRY_CONVERT(money,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[PlannedCost],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[PlannedCost],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[PlannedCost],126))),N'')) < 0 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[PlannedCost],126))),N'')) > 922337203685477.6 THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'ActualCost', CASE WHEN TRY_CONVERT(money,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ActualCost],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ActualCost],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ActualCost],126))),N'')) < 0 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ActualCost],126))),N'')) > 922337203685477.6 THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END)) e(FieldName,Reason)
CROSS JOIN #EtlContext c WHERE e.Reason IS NOT NULL;
-- Rechazar todas las copias de una clave duplicada; no elegir una arbitrariamente.
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Production.WorkOrderRouting',s.__RowID,'REJECT',N'WorkOrderID,ProductID,OperationSequence',N'Clave de negocio duplicada',s.__Raw
FROM #src_Production_WorkOrderRouting s JOIN (SELECT [WorkOrderID],[ProductID],[OperationSequence] FROM #src_Production_WorkOrderRouting GROUP BY [WorkOrderID],[ProductID],[OperationSequence] HAVING COUNT_BIG(*)>1) dup
ON s.[WorkOrderID]=dup.[WorkOrderID] AND s.[ProductID]=dup.[ProductID] AND s.[OperationSequence]=dup.[OperationSequence] CROSS JOIN #EtlContext c;
DELETE s FROM #src_Production_WorkOrderRouting s WHERE EXISTS
 (SELECT 1 FROM dbo.EtlIssue i JOIN #EtlContext c ON i.RunID=c.RunID
 WHERE i.SourceTable=N'Production.WorkOrderRouting' AND i.SourceRowID=s.__RowID AND i.Severity='REJECT');
GO
PRINT 'Preparando Production.ProductInventory...';
SELECT IDENTITY(bigint,1,1) AS __RowID, (SELECT CONVERT(nvarchar(max),s.[ProductID],126) AS [ProductID],CONVERT(nvarchar(max),s.[LocationID],126) AS [LocationID],CONVERT(nvarchar(max),s.[Shelf],126) AS [Shelf],CONVERT(nvarchar(max),s.[Bin],126) AS [Bin],CONVERT(nvarchar(max),s.[Quantity],126) AS [Quantity] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS __Raw,
 TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductID],126))),N'')) AS [ProductID],
 TRY_CONVERT(smallint,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[LocationID],126))),N'')) AS [LocationID],
 NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Shelf],126))),N'') AS [Shelf],
 TRY_CONVERT(tinyint,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Bin],126))),N'')) AS [Bin],
 TRY_CONVERT(smallint,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Quantity],126))),N'')) AS [Quantity]
INTO #src_Production_ProductInventory
FROM [$(SourceDatabase)].Production.ProductInventory s WITH (HOLDLOCK);
INSERT dbo.EtlTableSummary
SELECT c.RunID,N'Production.ProductInventory',n.RowsReceived,0,0 FROM #EtlContext c
CROSS APPLY (SELECT COUNT_BIG(*) AS RowsReceived FROM #src_Production_ProductInventory) n;
-- Validar sobre los valores originales sin provocar errores de conversion.
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Production.ProductInventory',st.__RowID,'REJECT',e.FieldName,e.Reason,st.__Raw
FROM #src_Production_ProductInventory st
CROSS APPLY OPENJSON(st.__Raw) WITH ([ProductID] nvarchar(max) '$.ProductID',[LocationID] nvarchar(max) '$.LocationID',[Shelf] nvarchar(max) '$.Shelf',[Bin] nvarchar(max) '$.Bin',[Quantity] nvarchar(max) '$.Quantity') s
CROSS APPLY (VALUES (N'ProductID', CASE WHEN TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductID],126))),N'')) < 1 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductID],126))),N'')) > 2147483647 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductID],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[ProductID],126))),N''))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'LocationID', CASE WHEN TRY_CONVERT(smallint,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[LocationID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[LocationID],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[LocationID],126))),N'')) < 1 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[LocationID],126))),N'')) > 32767 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[LocationID],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[LocationID],126))),N''))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'Shelf', CASE WHEN NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Shelf],126))),N'') IS NULL OR LEN(NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Shelf],126))),N'')) > 10 THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'Bin', CASE WHEN TRY_CONVERT(tinyint,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Bin],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Bin],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Bin],126))),N'')) < 0 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Bin],126))),N'')) > 255 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Bin],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Bin],126))),N''))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END),
 (N'Quantity', CASE WHEN TRY_CONVERT(smallint,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Quantity],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Quantity],126))),N'')) IS NULL OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Quantity],126))),N'')) < 0 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Quantity],126))),N'')) > 32767 OR TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Quantity],126))),N'')) <> FLOOR(TRY_CONVERT(decimal(38,10),NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Quantity],126))),N''))) THEN N'Valor obligatorio ausente, formato invalido, longitud o rango no permitido' END)) e(FieldName,Reason)
CROSS JOIN #EtlContext c WHERE e.Reason IS NOT NULL;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Production.ProductInventory',st.__RowID,'NORMALIZED',e.FieldName,e.Reason,st.__Raw
FROM #src_Production_ProductInventory st
CROSS APPLY OPENJSON(st.__Raw) WITH ([ProductID] nvarchar(max) '$.ProductID',[LocationID] nvarchar(max) '$.LocationID',[Shelf] nvarchar(max) '$.Shelf',[Bin] nvarchar(max) '$.Bin',[Quantity] nvarchar(max) '$.Quantity') s
CROSS APPLY (VALUES (N'Shelf', CASE WHEN DATALENGTH(CONVERT(nvarchar(max),s.[Shelf],126)) <> DATALENGTH(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Shelf],126)))) OR (s.[Shelf] IS NOT NULL AND NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.[Shelf],126))),N'') IS NULL) THEN N'Espacios recortados / texto vacio convertido a NULL' END)) e(FieldName,Reason)
CROSS JOIN #EtlContext c WHERE e.Reason IS NOT NULL;
-- Rechazar todas las copias de una clave duplicada; no elegir una arbitrariamente.
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Production.ProductInventory',s.__RowID,'REJECT',N'ProductID,LocationID',N'Clave de negocio duplicada',s.__Raw
FROM #src_Production_ProductInventory s JOIN (SELECT [ProductID],[LocationID] FROM #src_Production_ProductInventory GROUP BY [ProductID],[LocationID] HAVING COUNT_BIG(*)>1) dup
ON s.[ProductID]=dup.[ProductID] AND s.[LocationID]=dup.[LocationID] CROSS JOIN #EtlContext c;
DELETE s FROM #src_Production_ProductInventory s WHERE EXISTS
 (SELECT 1 FROM dbo.EtlIssue i JOIN #EtlContext c ON i.RunID=c.RunID
 WHERE i.SourceTable=N'Production.ProductInventory' AND i.SourceRowID=s.__RowID AND i.Severity='REJECT');
GO
-- La FK de la linea de venta corresponde a la combinacion oferta/producto.
IF OBJECT_ID(N'[$(SourceDatabase)].Sales.SpecialOfferProduct',N'U') IS NULL
 THROW 51001, 'Falta tabla fuente Sales.SpecialOfferProduct.', 1;
IF NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns WHERE object_id=OBJECT_ID(N'[$(SourceDatabase)].Sales.SpecialOfferProduct') AND name='SpecialOfferID')
 OR NOT EXISTS (SELECT 1 FROM [$(SourceDatabase)].sys.columns WHERE object_id=OBJECT_ID(N'[$(SourceDatabase)].Sales.SpecialOfferProduct') AND name='ProductID')
 THROW 51002, 'Faltan columnas en Sales.SpecialOfferProduct.', 1;
GO
SELECT IDENTITY(bigint,1,1) AS __RowID,
 (SELECT CONVERT(nvarchar(max),s.SpecialOfferID) AS SpecialOfferID,
 CONVERT(nvarchar(max),s.ProductID) AS ProductID FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES) AS __Raw,
 TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.SpecialOfferID))),N'')) AS SpecialOfferID,
 TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max),s.ProductID))),N'')) AS ProductID
INTO #src_Sales_SpecialOfferProduct FROM [$(SourceDatabase)].Sales.SpecialOfferProduct s WITH (HOLDLOCK);
INSERT dbo.EtlTableSummary SELECT c.RunID,N'Sales.SpecialOfferProduct',n.RowsReceived,0,0
FROM #EtlContext c CROSS APPLY (SELECT COUNT_BIG(*) AS RowsReceived FROM #src_Sales_SpecialOfferProduct) n;
INSERT dbo.EtlIssue(RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Sales.SpecialOfferProduct',s.__RowID,'REJECT',N'SpecialOfferID,ProductID',
 N'Clave oferta/producto ausente o formato invalido',s.__Raw
FROM #src_Sales_SpecialOfferProduct s CROSS JOIN #EtlContext c
WHERE s.SpecialOfferID IS NULL OR s.ProductID IS NULL OR s.SpecialOfferID<=0 OR s.ProductID<=0;
INSERT dbo.EtlIssue(RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Sales.SpecialOfferProduct',s.__RowID,'REJECT',N'SpecialOfferID,ProductID',
 N'Clave de negocio duplicada',s.__Raw
FROM #src_Sales_SpecialOfferProduct s CROSS JOIN #EtlContext c
JOIN (SELECT SpecialOfferID,ProductID FROM #src_Sales_SpecialOfferProduct
 GROUP BY SpecialOfferID,ProductID HAVING COUNT_BIG(*)>1) d
ON d.SpecialOfferID=s.SpecialOfferID AND d.ProductID=s.ProductID;
DELETE s FROM #src_Sales_SpecialOfferProduct s WHERE EXISTS
 (SELECT 1 FROM dbo.EtlIssue i JOIN #EtlContext c ON i.RunID=c.RunID
 WHERE i.SourceTable=N'Sales.SpecialOfferProduct' AND i.SourceRowID=s.__RowID AND i.Severity='REJECT');
GO
-- Validaciones cruzadas y propagacion de rechazos a registros dependientes.
DECLARE @changes int=1;
WHILE @changes>0
BEGIN
 SET @changes=0;
INSERT dbo.EtlIssue(RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Sales.SpecialOfferProduct',s.__RowID,'REJECT',N'SpecialOfferID,ProductID',
 N'Oferta o producto ausente o rechazado',s.__Raw
FROM #src_Sales_SpecialOfferProduct s CROSS JOIN #EtlContext c WHERE
 NOT EXISTS(SELECT 1 FROM #src_Sales_SpecialOffer p WHERE p.SpecialOfferID=s.SpecialOfferID)
 OR NOT EXISTS(SELECT 1 FROM #src_Production_Product p WHERE p.ProductID=s.ProductID);
DELETE s FROM #src_Sales_SpecialOfferProduct s WHERE
 NOT EXISTS(SELECT 1 FROM #src_Sales_SpecialOffer p WHERE p.SpecialOfferID=s.SpecialOfferID)
 OR NOT EXISTS(SELECT 1 FROM #src_Production_Product p WHERE p.ProductID=s.ProductID);
SET @changes+=@@ROWCOUNT;
INSERT dbo.EtlIssue(RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Sales.SalesOrderDetail',s.__RowID,'REJECT',N'SpecialOfferID,ProductID',
 N'Combinacion oferta/producto ausente o rechazada',s.__Raw
FROM #src_Sales_SalesOrderDetail s CROSS JOIN #EtlContext c WHERE NOT EXISTS
 (SELECT 1 FROM #src_Sales_SpecialOfferProduct p WHERE p.SpecialOfferID=s.SpecialOfferID AND p.ProductID=s.ProductID);
DELETE s FROM #src_Sales_SalesOrderDetail s WHERE NOT EXISTS
 (SELECT 1 FROM #src_Sales_SpecialOfferProduct p WHERE p.SpecialOfferID=s.SpecialOfferID AND p.ProductID=s.ProductID);
SET @changes+=@@ROWCOUNT;
INSERT dbo.EtlIssue(RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Production.WorkOrderRouting',s.__RowID,'REJECT',N'WorkOrderID,ProductID',
 N'Producto de la operacion no coincide con su orden',s.__Raw
FROM #src_Production_WorkOrderRouting s JOIN #src_Production_WorkOrder w ON w.WorkOrderID=s.WorkOrderID
CROSS JOIN #EtlContext c WHERE w.ProductID<>s.ProductID;
DELETE s FROM #src_Production_WorkOrderRouting s JOIN #src_Production_WorkOrder w ON w.WorkOrderID=s.WorkOrderID WHERE w.ProductID<>s.ProductID;
SET @changes+=@@ROWCOUNT;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
 SELECT c.RunID,N'Person.StateProvince',s.__RowID,'REJECT',N'CountryRegionCode',N'Referencia ausente o rechazada: Person.CountryRegion',s.__Raw FROM #src_Person_StateProvince s CROSS JOIN #EtlContext c WHERE s.[CountryRegionCode] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_Person_CountryRegion p WHERE p.[CountryRegionCode]=s.[CountryRegionCode]);
DELETE s FROM #src_Person_StateProvince s WHERE s.[CountryRegionCode] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_Person_CountryRegion p WHERE p.[CountryRegionCode]=s.[CountryRegionCode]);
SET @changes+=@@ROWCOUNT;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
 SELECT c.RunID,N'Person.Address',s.__RowID,'REJECT',N'StateProvinceID',N'Referencia ausente o rechazada: Person.StateProvince',s.__Raw FROM #src_Person_Address s CROSS JOIN #EtlContext c WHERE s.[StateProvinceID] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_Person_StateProvince p WHERE p.[StateProvinceID]=s.[StateProvinceID]);
DELETE s FROM #src_Person_Address s WHERE s.[StateProvinceID] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_Person_StateProvince p WHERE p.[StateProvinceID]=s.[StateProvinceID]);
SET @changes+=@@ROWCOUNT;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
 SELECT c.RunID,N'Person.BusinessEntityAddress',s.__RowID,'REJECT',N'AddressID',N'Referencia ausente o rechazada: Person.Address',s.__Raw FROM #src_Person_BusinessEntityAddress s CROSS JOIN #EtlContext c WHERE s.[AddressID] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_Person_Address p WHERE p.[AddressID]=s.[AddressID]);
DELETE s FROM #src_Person_BusinessEntityAddress s WHERE s.[AddressID] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_Person_Address p WHERE p.[AddressID]=s.[AddressID]);
SET @changes+=@@ROWCOUNT;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
 SELECT c.RunID,N'Production.ProductSubcategory',s.__RowID,'REJECT',N'ProductCategoryID',N'Referencia ausente o rechazada: Production.ProductCategory',s.__Raw FROM #src_Production_ProductSubcategory s CROSS JOIN #EtlContext c WHERE s.[ProductCategoryID] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_Production_ProductCategory p WHERE p.[ProductCategoryID]=s.[ProductCategoryID]);
DELETE s FROM #src_Production_ProductSubcategory s WHERE s.[ProductCategoryID] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_Production_ProductCategory p WHERE p.[ProductCategoryID]=s.[ProductCategoryID]);
SET @changes+=@@ROWCOUNT;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
 SELECT c.RunID,N'Production.Product',s.__RowID,'WARNING',N'ProductSubcategoryID',N'Referencia ausente o rechazada: Production.ProductSubcategory',s.__Raw FROM #src_Production_Product s CROSS JOIN #EtlContext c WHERE s.[ProductSubcategoryID] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_Production_ProductSubcategory p WHERE p.[ProductSubcategoryID]=s.[ProductSubcategoryID]);
UPDATE s SET [ProductSubcategoryID]=NULL FROM #src_Production_Product s WHERE s.[ProductSubcategoryID] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_Production_ProductSubcategory p WHERE p.[ProductSubcategoryID]=s.[ProductSubcategoryID]);
SET @changes+=@@ROWCOUNT;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
 SELECT c.RunID,N'Sales.Customer',s.__RowID,'WARNING',N'PersonID',N'Referencia ausente o rechazada: Person.Person',s.__Raw FROM #src_Sales_Customer s CROSS JOIN #EtlContext c WHERE s.[PersonID] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_Person_Person p WHERE p.[BusinessEntityID]=s.[PersonID]);
UPDATE s SET [PersonID]=NULL FROM #src_Sales_Customer s WHERE s.[PersonID] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_Person_Person p WHERE p.[BusinessEntityID]=s.[PersonID]);
SET @changes+=@@ROWCOUNT;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
 SELECT c.RunID,N'Sales.Customer',s.__RowID,'WARNING',N'StoreID',N'Referencia ausente o rechazada: Sales.Store',s.__Raw FROM #src_Sales_Customer s CROSS JOIN #EtlContext c WHERE s.[StoreID] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_Sales_Store p WHERE p.[BusinessEntityID]=s.[StoreID]);
UPDATE s SET [StoreID]=NULL FROM #src_Sales_Customer s WHERE s.[StoreID] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_Sales_Store p WHERE p.[BusinessEntityID]=s.[StoreID]);
SET @changes+=@@ROWCOUNT;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
 SELECT c.RunID,N'Sales.Customer',s.__RowID,'WARNING',N'TerritoryID',N'Referencia ausente o rechazada: Sales.SalesTerritory',s.__Raw FROM #src_Sales_Customer s CROSS JOIN #EtlContext c WHERE s.[TerritoryID] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_Sales_SalesTerritory p WHERE p.[TerritoryID]=s.[TerritoryID]);
UPDATE s SET [TerritoryID]=NULL FROM #src_Sales_Customer s WHERE s.[TerritoryID] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_Sales_SalesTerritory p WHERE p.[TerritoryID]=s.[TerritoryID]);
SET @changes+=@@ROWCOUNT;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
 SELECT c.RunID,N'Sales.SalesPerson',s.__RowID,'REJECT',N'BusinessEntityID',N'Referencia ausente o rechazada: Person.Person',s.__Raw FROM #src_Sales_SalesPerson s CROSS JOIN #EtlContext c WHERE s.[BusinessEntityID] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_Person_Person p WHERE p.[BusinessEntityID]=s.[BusinessEntityID]);
DELETE s FROM #src_Sales_SalesPerson s WHERE s.[BusinessEntityID] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_Person_Person p WHERE p.[BusinessEntityID]=s.[BusinessEntityID]);
SET @changes+=@@ROWCOUNT;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
 SELECT c.RunID,N'Sales.SalesPerson',s.__RowID,'REJECT',N'BusinessEntityID',N'Referencia ausente o rechazada: HumanResources.Employee',s.__Raw FROM #src_Sales_SalesPerson s CROSS JOIN #EtlContext c WHERE s.[BusinessEntityID] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_HumanResources_Employee p WHERE p.[BusinessEntityID]=s.[BusinessEntityID]);
DELETE s FROM #src_Sales_SalesPerson s WHERE s.[BusinessEntityID] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_HumanResources_Employee p WHERE p.[BusinessEntityID]=s.[BusinessEntityID]);
SET @changes+=@@ROWCOUNT;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
 SELECT c.RunID,N'Sales.SalesPerson',s.__RowID,'WARNING',N'TerritoryID',N'Referencia ausente o rechazada: Sales.SalesTerritory',s.__Raw FROM #src_Sales_SalesPerson s CROSS JOIN #EtlContext c WHERE s.[TerritoryID] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_Sales_SalesTerritory p WHERE p.[TerritoryID]=s.[TerritoryID]);
UPDATE s SET [TerritoryID]=NULL FROM #src_Sales_SalesPerson s WHERE s.[TerritoryID] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_Sales_SalesTerritory p WHERE p.[TerritoryID]=s.[TerritoryID]);
SET @changes+=@@ROWCOUNT;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
 SELECT c.RunID,N'Sales.SalesOrderHeader',s.__RowID,'REJECT',N'CustomerID',N'Referencia ausente o rechazada: Sales.Customer',s.__Raw FROM #src_Sales_SalesOrderHeader s CROSS JOIN #EtlContext c WHERE s.[CustomerID] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_Sales_Customer p WHERE p.[CustomerID]=s.[CustomerID]);
DELETE s FROM #src_Sales_SalesOrderHeader s WHERE s.[CustomerID] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_Sales_Customer p WHERE p.[CustomerID]=s.[CustomerID]);
SET @changes+=@@ROWCOUNT;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
 SELECT c.RunID,N'Sales.SalesOrderHeader',s.__RowID,'REJECT',N'TerritoryID',N'Referencia ausente o rechazada: Sales.SalesTerritory',s.__Raw FROM #src_Sales_SalesOrderHeader s CROSS JOIN #EtlContext c WHERE s.[TerritoryID] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_Sales_SalesTerritory p WHERE p.[TerritoryID]=s.[TerritoryID]);
DELETE s FROM #src_Sales_SalesOrderHeader s WHERE s.[TerritoryID] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_Sales_SalesTerritory p WHERE p.[TerritoryID]=s.[TerritoryID]);
SET @changes+=@@ROWCOUNT;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
 SELECT c.RunID,N'Sales.SalesOrderHeader',s.__RowID,'REJECT',N'SalesPersonID',N'Referencia ausente o rechazada: Sales.SalesPerson',s.__Raw FROM #src_Sales_SalesOrderHeader s CROSS JOIN #EtlContext c WHERE s.[SalesPersonID] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_Sales_SalesPerson p WHERE p.[BusinessEntityID]=s.[SalesPersonID]);
DELETE s FROM #src_Sales_SalesOrderHeader s WHERE s.[SalesPersonID] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_Sales_SalesPerson p WHERE p.[BusinessEntityID]=s.[SalesPersonID]);
SET @changes+=@@ROWCOUNT;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
 SELECT c.RunID,N'Sales.SalesOrderDetail',s.__RowID,'REJECT',N'SalesOrderID',N'Referencia ausente o rechazada: Sales.SalesOrderHeader',s.__Raw FROM #src_Sales_SalesOrderDetail s CROSS JOIN #EtlContext c WHERE s.[SalesOrderID] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_Sales_SalesOrderHeader p WHERE p.[SalesOrderID]=s.[SalesOrderID]);
DELETE s FROM #src_Sales_SalesOrderDetail s WHERE s.[SalesOrderID] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_Sales_SalesOrderHeader p WHERE p.[SalesOrderID]=s.[SalesOrderID]);
SET @changes+=@@ROWCOUNT;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
 SELECT c.RunID,N'Sales.SalesOrderDetail',s.__RowID,'REJECT',N'ProductID',N'Referencia ausente o rechazada: Production.Product',s.__Raw FROM #src_Sales_SalesOrderDetail s CROSS JOIN #EtlContext c WHERE s.[ProductID] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_Production_Product p WHERE p.[ProductID]=s.[ProductID]);
DELETE s FROM #src_Sales_SalesOrderDetail s WHERE s.[ProductID] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_Production_Product p WHERE p.[ProductID]=s.[ProductID]);
SET @changes+=@@ROWCOUNT;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
 SELECT c.RunID,N'Sales.SalesOrderDetail',s.__RowID,'REJECT',N'SpecialOfferID',N'Referencia ausente o rechazada: Sales.SpecialOffer',s.__Raw FROM #src_Sales_SalesOrderDetail s CROSS JOIN #EtlContext c WHERE s.[SpecialOfferID] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_Sales_SpecialOffer p WHERE p.[SpecialOfferID]=s.[SpecialOfferID]);
DELETE s FROM #src_Sales_SalesOrderDetail s WHERE s.[SpecialOfferID] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_Sales_SpecialOffer p WHERE p.[SpecialOfferID]=s.[SpecialOfferID]);
SET @changes+=@@ROWCOUNT;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
 SELECT c.RunID,N'Production.WorkOrder',s.__RowID,'REJECT',N'ProductID',N'Referencia ausente o rechazada: Production.Product',s.__Raw FROM #src_Production_WorkOrder s CROSS JOIN #EtlContext c WHERE s.[ProductID] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_Production_Product p WHERE p.[ProductID]=s.[ProductID]);
DELETE s FROM #src_Production_WorkOrder s WHERE s.[ProductID] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_Production_Product p WHERE p.[ProductID]=s.[ProductID]);
SET @changes+=@@ROWCOUNT;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
 SELECT c.RunID,N'Production.WorkOrder',s.__RowID,'REJECT',N'ScrapReasonID',N'Referencia ausente o rechazada: Production.ScrapReason',s.__Raw FROM #src_Production_WorkOrder s CROSS JOIN #EtlContext c WHERE s.[ScrapReasonID] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_Production_ScrapReason p WHERE p.[ScrapReasonID]=s.[ScrapReasonID]);
DELETE s FROM #src_Production_WorkOrder s WHERE s.[ScrapReasonID] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_Production_ScrapReason p WHERE p.[ScrapReasonID]=s.[ScrapReasonID]);
SET @changes+=@@ROWCOUNT;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
 SELECT c.RunID,N'Production.WorkOrderRouting',s.__RowID,'REJECT',N'WorkOrderID',N'Referencia ausente o rechazada: Production.WorkOrder',s.__Raw FROM #src_Production_WorkOrderRouting s CROSS JOIN #EtlContext c WHERE s.[WorkOrderID] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_Production_WorkOrder p WHERE p.[WorkOrderID]=s.[WorkOrderID]);
DELETE s FROM #src_Production_WorkOrderRouting s WHERE s.[WorkOrderID] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_Production_WorkOrder p WHERE p.[WorkOrderID]=s.[WorkOrderID]);
SET @changes+=@@ROWCOUNT;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
 SELECT c.RunID,N'Production.WorkOrderRouting',s.__RowID,'REJECT',N'ProductID',N'Referencia ausente o rechazada: Production.Product',s.__Raw FROM #src_Production_WorkOrderRouting s CROSS JOIN #EtlContext c WHERE s.[ProductID] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_Production_Product p WHERE p.[ProductID]=s.[ProductID]);
DELETE s FROM #src_Production_WorkOrderRouting s WHERE s.[ProductID] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_Production_Product p WHERE p.[ProductID]=s.[ProductID]);
SET @changes+=@@ROWCOUNT;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
 SELECT c.RunID,N'Production.WorkOrderRouting',s.__RowID,'REJECT',N'LocationID',N'Referencia ausente o rechazada: Production.Location',s.__Raw FROM #src_Production_WorkOrderRouting s CROSS JOIN #EtlContext c WHERE s.[LocationID] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_Production_Location p WHERE p.[LocationID]=s.[LocationID]);
DELETE s FROM #src_Production_WorkOrderRouting s WHERE s.[LocationID] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_Production_Location p WHERE p.[LocationID]=s.[LocationID]);
SET @changes+=@@ROWCOUNT;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
 SELECT c.RunID,N'Production.ProductInventory',s.__RowID,'REJECT',N'ProductID',N'Referencia ausente o rechazada: Production.Product',s.__Raw FROM #src_Production_ProductInventory s CROSS JOIN #EtlContext c WHERE s.[ProductID] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_Production_Product p WHERE p.[ProductID]=s.[ProductID]);
DELETE s FROM #src_Production_ProductInventory s WHERE s.[ProductID] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_Production_Product p WHERE p.[ProductID]=s.[ProductID]);
SET @changes+=@@ROWCOUNT;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
 SELECT c.RunID,N'Production.ProductInventory',s.__RowID,'REJECT',N'LocationID',N'Referencia ausente o rechazada: Production.Location',s.__Raw FROM #src_Production_ProductInventory s CROSS JOIN #EtlContext c WHERE s.[LocationID] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_Production_Location p WHERE p.[LocationID]=s.[LocationID]);
DELETE s FROM #src_Production_ProductInventory s WHERE s.[LocationID] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #src_Production_Location p WHERE p.[LocationID]=s.[LocationID]);
SET @changes+=@@ROWCOUNT;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
 SELECT c.RunID,N'Sales.Customer',s.__RowID,'REJECT',N'PersonID,StoreID',N'Cliente sin persona ni tienda validas',s.__Raw FROM #src_Sales_Customer s CROSS JOIN #EtlContext c WHERE s.PersonID IS NULL AND s.StoreID IS NULL;
DELETE s FROM #src_Sales_Customer s WHERE s.PersonID IS NULL AND s.StoreID IS NULL;
SET @changes+=@@ROWCOUNT;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
 SELECT c.RunID,N'Sales.SalesOrderHeader',s.__RowID,'REJECT',N'DueDate,ShipDate',N'Fecha de entrega/despacho anterior al pedido',s.__Raw FROM #src_Sales_SalesOrderHeader s CROSS JOIN #EtlContext c WHERE s.DueDate < s.OrderDate OR s.ShipDate < s.OrderDate;
DELETE s FROM #src_Sales_SalesOrderHeader s WHERE s.DueDate < s.OrderDate OR s.ShipDate < s.OrderDate;
SET @changes+=@@ROWCOUNT;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
 SELECT c.RunID,N'Sales.SalesOrderHeader',s.__RowID,'REJECT',N'SalesPersonID',N'Venta asistida sin vendedor',s.__Raw FROM #src_Sales_SalesOrderHeader s CROSS JOIN #EtlContext c WHERE s.OnlineOrderFlag=0 AND s.SalesPersonID IS NULL;
DELETE s FROM #src_Sales_SalesOrderHeader s WHERE s.OnlineOrderFlag=0 AND s.SalesPersonID IS NULL;
SET @changes+=@@ROWCOUNT;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
 SELECT c.RunID,N'Sales.SalesOrderDetail',s.__RowID,'REJECT',N'LineTotal',N'Total de linea no coincide con cantidad, precio y descuento',s.__Raw FROM #src_Sales_SalesOrderDetail s CROSS JOIN #EtlContext c WHERE ABS(s.LineTotal - CAST(s.OrderQty AS decimal(10,0))*s.UnitPrice*(1-s.UnitPriceDiscount)) > 0.01;
DELETE s FROM #src_Sales_SalesOrderDetail s WHERE ABS(s.LineTotal - CAST(s.OrderQty AS decimal(10,0))*s.UnitPrice*(1-s.UnitPriceDiscount)) > 0.01;
SET @changes+=@@ROWCOUNT;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
 SELECT c.RunID,N'Production.WorkOrder',s.__RowID,'REJECT',N'OrderQty,StockedQty,ScrappedQty',N'Unidades almacenadas y desechadas no cuadran con las ordenadas',s.__Raw FROM #src_Production_WorkOrder s CROSS JOIN #EtlContext c WHERE s.ScrappedQty>s.OrderQty OR CAST(s.StockedQty AS bigint)+s.ScrappedQty<>s.OrderQty;
DELETE s FROM #src_Production_WorkOrder s WHERE s.ScrappedQty>s.OrderQty OR CAST(s.StockedQty AS bigint)+s.ScrappedQty<>s.OrderQty;
SET @changes+=@@ROWCOUNT;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
 SELECT c.RunID,N'Production.WorkOrder',s.__RowID,'REJECT',N'EndDate',N'Fin anterior al inicio',s.__Raw FROM #src_Production_WorkOrder s CROSS JOIN #EtlContext c WHERE s.EndDate < s.StartDate;
DELETE s FROM #src_Production_WorkOrder s WHERE s.EndDate < s.StartDate;
SET @changes+=@@ROWCOUNT;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
 SELECT c.RunID,N'Production.WorkOrder',s.__RowID,'REJECT',N'ScrapReasonID',N'Descarte sin motivo',s.__Raw FROM #src_Production_WorkOrder s CROSS JOIN #EtlContext c WHERE s.ScrappedQty>0 AND s.ScrapReasonID IS NULL;
DELETE s FROM #src_Production_WorkOrder s WHERE s.ScrappedQty>0 AND s.ScrapReasonID IS NULL;
SET @changes+=@@ROWCOUNT;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
 SELECT c.RunID,N'Production.WorkOrderRouting',s.__RowID,'REJECT',N'ScheduledEndDate,ActualEndDate',N'Secuencia de fechas incoherente',s.__Raw FROM #src_Production_WorkOrderRouting s CROSS JOIN #EtlContext c WHERE s.ScheduledEndDate<s.ScheduledStartDate OR s.ActualEndDate<s.ActualStartDate OR (s.ActualEndDate IS NOT NULL AND s.ActualStartDate IS NULL);
DELETE s FROM #src_Production_WorkOrderRouting s WHERE s.ScheduledEndDate<s.ScheduledStartDate OR s.ActualEndDate<s.ActualStartDate OR (s.ActualEndDate IS NOT NULL AND s.ActualStartDate IS NULL);
SET @changes+=@@ROWCOUNT;
END;
GO
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Sales.SalesOrderDetail',s.__RowID,'REJECT',N'Importe calculado',N'Importe calculado fuera de rango money',s.__Raw FROM #src_Sales_SalesOrderDetail s JOIN #src_Production_Product p ON s.ProductID=p.ProductID CROSS JOIN #EtlContext c WHERE TRY_CONVERT(money,CAST(s.OrderQty AS decimal(10,0))*p.StandardCost) IS NULL OR TRY_CONVERT(money,CAST(s.OrderQty AS decimal(10,0))*s.UnitPrice*s.UnitPriceDiscount) IS NULL;
DELETE s FROM #src_Sales_SalesOrderDetail s JOIN #src_Production_Product p ON s.ProductID=p.ProductID WHERE TRY_CONVERT(money,CAST(s.OrderQty AS decimal(10,0))*p.StandardCost) IS NULL OR TRY_CONVERT(money,CAST(s.OrderQty AS decimal(10,0))*s.UnitPrice*s.UnitPriceDiscount) IS NULL;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Production.WorkOrder',s.__RowID,'REJECT',N'Importe calculado',N'Importe calculado fuera de rango money',s.__Raw FROM #src_Production_WorkOrder s JOIN #src_Production_Product p ON s.ProductID=p.ProductID CROSS JOIN #EtlContext c WHERE TRY_CONVERT(money,CAST(s.ScrappedQty AS decimal(10,0))*p.StandardCost) IS NULL;
DELETE s FROM #src_Production_WorkOrder s JOIN #src_Production_Product p ON s.ProductID=p.ProductID WHERE TRY_CONVERT(money,CAST(s.ScrappedQty AS decimal(10,0))*p.StandardCost) IS NULL;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Production.ProductInventory',s.__RowID,'REJECT',N'Importe calculado',N'Importe calculado fuera de rango money',s.__Raw FROM #src_Production_ProductInventory s JOIN #src_Production_Product p ON s.ProductID=p.ProductID CROSS JOIN #EtlContext c WHERE TRY_CONVERT(money,CAST(s.Quantity AS decimal(10,0))*p.StandardCost) IS NULL;
DELETE s FROM #src_Production_ProductInventory s JOIN #src_Production_Product p ON s.ProductID=p.ProductID WHERE TRY_CONVERT(money,CAST(s.Quantity AS decimal(10,0))*p.StandardCost) IS NULL;
INSERT dbo.EtlIssue (RunID,SourceTable,SourceRowID,Severity,FieldName,Reason,RawData)
SELECT c.RunID,N'Production.WorkOrderRouting',s.__RowID,'REJECT',N'WorkOrderID',N'Orden rechazada por importe fuera de rango',s.__Raw
FROM #src_Production_WorkOrderRouting s CROSS JOIN #EtlContext c WHERE NOT EXISTS
(SELECT 1 FROM #src_Production_WorkOrder p WHERE p.WorkOrderID=s.WorkOrderID);
DELETE s FROM #src_Production_WorkOrderRouting s WHERE NOT EXISTS
(SELECT 1 FROM #src_Production_WorkOrder p WHERE p.WorkOrderID=s.WorkOrderID);
GO
UPDATE q SET Accepted=(SELECT COUNT_BIG(*) FROM #src_Sales_SalesTerritory),Rejected=Received-(SELECT COUNT_BIG(*) FROM #src_Sales_SalesTerritory)
FROM dbo.EtlTableSummary q JOIN #EtlContext c ON q.RunID=c.RunID WHERE q.SourceTable=N'Sales.SalesTerritory';
UPDATE q SET Accepted=(SELECT COUNT_BIG(*) FROM #src_Person_Person),Rejected=Received-(SELECT COUNT_BIG(*) FROM #src_Person_Person)
FROM dbo.EtlTableSummary q JOIN #EtlContext c ON q.RunID=c.RunID WHERE q.SourceTable=N'Person.Person';
UPDATE q SET Accepted=(SELECT COUNT_BIG(*) FROM #src_HumanResources_Employee),Rejected=Received-(SELECT COUNT_BIG(*) FROM #src_HumanResources_Employee)
FROM dbo.EtlTableSummary q JOIN #EtlContext c ON q.RunID=c.RunID WHERE q.SourceTable=N'HumanResources.Employee';
UPDATE q SET Accepted=(SELECT COUNT_BIG(*) FROM #src_Sales_Store),Rejected=Received-(SELECT COUNT_BIG(*) FROM #src_Sales_Store)
FROM dbo.EtlTableSummary q JOIN #EtlContext c ON q.RunID=c.RunID WHERE q.SourceTable=N'Sales.Store';
UPDATE q SET Accepted=(SELECT COUNT_BIG(*) FROM #src_Person_Address),Rejected=Received-(SELECT COUNT_BIG(*) FROM #src_Person_Address)
FROM dbo.EtlTableSummary q JOIN #EtlContext c ON q.RunID=c.RunID WHERE q.SourceTable=N'Person.Address';
UPDATE q SET Accepted=(SELECT COUNT_BIG(*) FROM #src_Person_StateProvince),Rejected=Received-(SELECT COUNT_BIG(*) FROM #src_Person_StateProvince)
FROM dbo.EtlTableSummary q JOIN #EtlContext c ON q.RunID=c.RunID WHERE q.SourceTable=N'Person.StateProvince';
UPDATE q SET Accepted=(SELECT COUNT_BIG(*) FROM #src_Person_CountryRegion),Rejected=Received-(SELECT COUNT_BIG(*) FROM #src_Person_CountryRegion)
FROM dbo.EtlTableSummary q JOIN #EtlContext c ON q.RunID=c.RunID WHERE q.SourceTable=N'Person.CountryRegion';
UPDATE q SET Accepted=(SELECT COUNT_BIG(*) FROM #src_Person_BusinessEntityAddress),Rejected=Received-(SELECT COUNT_BIG(*) FROM #src_Person_BusinessEntityAddress)
FROM dbo.EtlTableSummary q JOIN #EtlContext c ON q.RunID=c.RunID WHERE q.SourceTable=N'Person.BusinessEntityAddress';
UPDATE q SET Accepted=(SELECT COUNT_BIG(*) FROM #src_Production_ProductCategory),Rejected=Received-(SELECT COUNT_BIG(*) FROM #src_Production_ProductCategory)
FROM dbo.EtlTableSummary q JOIN #EtlContext c ON q.RunID=c.RunID WHERE q.SourceTable=N'Production.ProductCategory';
UPDATE q SET Accepted=(SELECT COUNT_BIG(*) FROM #src_Production_ProductSubcategory),Rejected=Received-(SELECT COUNT_BIG(*) FROM #src_Production_ProductSubcategory)
FROM dbo.EtlTableSummary q JOIN #EtlContext c ON q.RunID=c.RunID WHERE q.SourceTable=N'Production.ProductSubcategory';
UPDATE q SET Accepted=(SELECT COUNT_BIG(*) FROM #src_Production_Product),Rejected=Received-(SELECT COUNT_BIG(*) FROM #src_Production_Product)
FROM dbo.EtlTableSummary q JOIN #EtlContext c ON q.RunID=c.RunID WHERE q.SourceTable=N'Production.Product';
UPDATE q SET Accepted=(SELECT COUNT_BIG(*) FROM #src_Sales_Customer),Rejected=Received-(SELECT COUNT_BIG(*) FROM #src_Sales_Customer)
FROM dbo.EtlTableSummary q JOIN #EtlContext c ON q.RunID=c.RunID WHERE q.SourceTable=N'Sales.Customer';
UPDATE q SET Accepted=(SELECT COUNT_BIG(*) FROM #src_Sales_SalesPerson),Rejected=Received-(SELECT COUNT_BIG(*) FROM #src_Sales_SalesPerson)
FROM dbo.EtlTableSummary q JOIN #EtlContext c ON q.RunID=c.RunID WHERE q.SourceTable=N'Sales.SalesPerson';
UPDATE q SET Accepted=(SELECT COUNT_BIG(*) FROM #src_Sales_SpecialOffer),Rejected=Received-(SELECT COUNT_BIG(*) FROM #src_Sales_SpecialOffer)
FROM dbo.EtlTableSummary q JOIN #EtlContext c ON q.RunID=c.RunID WHERE q.SourceTable=N'Sales.SpecialOffer';
UPDATE q SET Accepted=(SELECT COUNT_BIG(*) FROM #src_Production_Location),Rejected=Received-(SELECT COUNT_BIG(*) FROM #src_Production_Location)
FROM dbo.EtlTableSummary q JOIN #EtlContext c ON q.RunID=c.RunID WHERE q.SourceTable=N'Production.Location';
UPDATE q SET Accepted=(SELECT COUNT_BIG(*) FROM #src_Production_ScrapReason),Rejected=Received-(SELECT COUNT_BIG(*) FROM #src_Production_ScrapReason)
FROM dbo.EtlTableSummary q JOIN #EtlContext c ON q.RunID=c.RunID WHERE q.SourceTable=N'Production.ScrapReason';
UPDATE q SET Accepted=(SELECT COUNT_BIG(*) FROM #src_Sales_SalesOrderHeader),Rejected=Received-(SELECT COUNT_BIG(*) FROM #src_Sales_SalesOrderHeader)
FROM dbo.EtlTableSummary q JOIN #EtlContext c ON q.RunID=c.RunID WHERE q.SourceTable=N'Sales.SalesOrderHeader';
UPDATE q SET Accepted=(SELECT COUNT_BIG(*) FROM #src_Sales_SalesOrderDetail),Rejected=Received-(SELECT COUNT_BIG(*) FROM #src_Sales_SalesOrderDetail)
FROM dbo.EtlTableSummary q JOIN #EtlContext c ON q.RunID=c.RunID WHERE q.SourceTable=N'Sales.SalesOrderDetail';
UPDATE q SET Accepted=(SELECT COUNT_BIG(*) FROM #src_Production_WorkOrder),Rejected=Received-(SELECT COUNT_BIG(*) FROM #src_Production_WorkOrder)
FROM dbo.EtlTableSummary q JOIN #EtlContext c ON q.RunID=c.RunID WHERE q.SourceTable=N'Production.WorkOrder';
UPDATE q SET Accepted=(SELECT COUNT_BIG(*) FROM #src_Production_WorkOrderRouting),Rejected=Received-(SELECT COUNT_BIG(*) FROM #src_Production_WorkOrderRouting)
FROM dbo.EtlTableSummary q JOIN #EtlContext c ON q.RunID=c.RunID WHERE q.SourceTable=N'Production.WorkOrderRouting';
UPDATE q SET Accepted=(SELECT COUNT_BIG(*) FROM #src_Production_ProductInventory),Rejected=Received-(SELECT COUNT_BIG(*) FROM #src_Production_ProductInventory)
FROM dbo.EtlTableSummary q JOIN #EtlContext c ON q.RunID=c.RunID WHERE q.SourceTable=N'Production.ProductInventory';
UPDATE q SET Accepted=(SELECT COUNT_BIG(*) FROM #src_Sales_SpecialOfferProduct),Rejected=Received-(SELECT COUNT_BIG(*) FROM #src_Sales_SpecialOfferProduct)
FROM dbo.EtlTableSummary q JOIN #EtlContext c ON q.RunID=c.RunID WHERE q.SourceTable=N'Sales.SpecialOfferProduct';
GO

