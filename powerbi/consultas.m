// =============================================================================
// consultas.m - Consultas de Power Query (lenguaje M) para AdventureWorksDW
// =============================================================================
// Uso: Power BI Desktop > Obtener datos > Consulta en blanco > Editor avanzado.
// Crear UNA consulta por bloque (12 en total), pegar el cuerpo y nombrarla
// exactamente igual que el titulo del bloque (DimDate, DimCustomer, ...).
// Modo de almacenamiento: Importar.
// Servidor: localhost,1433   Base: AdventureWorksDW   Usuario: sa (clave de .env)
// =============================================================================


// ---- Consulta: DimDate ------------------------------------------------------
// Se excluye la fila especial DateKey = -1 (1900-01-01) para poder marcar la
// tabla como "tabla de fechas" (requiere fechas continuas y unicas).
let
    Origen = Sql.Database("localhost,1433", "AdventureWorksDW"),
    Tabla = Origen{[Schema = "dbo", Item = "DimDate"]}[Data],
    SinNoAplica = Table.SelectRows(Tabla, each [DateKey] <> -1)
in
    SinNoAplica


// ---- Consulta: DimCustomer --------------------------------------------------
let
    Origen = Sql.Database("localhost,1433", "AdventureWorksDW"),
    Tabla = Origen{[Schema = "dbo", Item = "DimCustomer"]}[Data]
in
    Tabla


// ---- Consulta: DimProduct ---------------------------------------------------
let
    Origen = Sql.Database("localhost,1433", "AdventureWorksDW"),
    Tabla = Origen{[Schema = "dbo", Item = "DimProduct"]}[Data]
in
    Tabla


// ---- Consulta: DimTerritory -------------------------------------------------
let
    Origen = Sql.Database("localhost,1433", "AdventureWorksDW"),
    Tabla = Origen{[Schema = "dbo", Item = "DimTerritory"]}[Data]
in
    Tabla


// ---- Consulta: DimSalesPerson -----------------------------------------------
let
    Origen = Sql.Database("localhost,1433", "AdventureWorksDW"),
    Tabla = Origen{[Schema = "dbo", Item = "DimSalesPerson"]}[Data]
in
    Tabla


// ---- Consulta: DimSpecialOffer ----------------------------------------------
let
    Origen = Sql.Database("localhost,1433", "AdventureWorksDW"),
    Tabla = Origen{[Schema = "dbo", Item = "DimSpecialOffer"]}[Data]
in
    Tabla


// ---- Consulta: DimLocation --------------------------------------------------
let
    Origen = Sql.Database("localhost,1433", "AdventureWorksDW"),
    Tabla = Origen{[Schema = "dbo", Item = "DimLocation"]}[Data]
in
    Tabla


// ---- Consulta: DimScrapReason -----------------------------------------------
let
    Origen = Sql.Database("localhost,1433", "AdventureWorksDW"),
    Tabla = Origen{[Schema = "dbo", Item = "DimScrapReason"]}[Data]
in
    Tabla


// ---- Consulta: FactSales ----------------------------------------------------
let
    Origen = Sql.Database("localhost,1433", "AdventureWorksDW"),
    Tabla = Origen{[Schema = "dbo", Item = "FactSales"]}[Data]
in
    Tabla


// ---- Consulta: FactWorkOrder ------------------------------------------------
let
    Origen = Sql.Database("localhost,1433", "AdventureWorksDW"),
    Tabla = Origen{[Schema = "dbo", Item = "FactWorkOrder"]}[Data]
in
    Tabla


// ---- Consulta: FactWorkOrderRouting -----------------------------------------
let
    Origen = Sql.Database("localhost,1433", "AdventureWorksDW"),
    Tabla = Origen{[Schema = "dbo", Item = "FactWorkOrderRouting"]}[Data]
in
    Tabla


// ---- Consulta: FactInventorySnapshot ----------------------------------------
let
    Origen = Sql.Database("localhost,1433", "AdventureWorksDW"),
    Tabla = Origen{[Schema = "dbo", Item = "FactInventorySnapshot"]}[Data]
in
    Tabla
