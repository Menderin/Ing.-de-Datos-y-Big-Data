"""Pruebas de integracion aisladas. Requiere Docker y .env; no altera AdventureWorks.

python database/etl/test_etl.py
"""
import json
import unittest
import uuid
from pathlib import Path

from run_etl import build_pipeline, execute_sql, load_env_password, validate_name

ROOT = Path(__file__).resolve().parents[2]


def literal(value):
    return "NULL" if value is None else "N'" + str(value).replace("'", "''") + "'"


class PipelineTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        suffix = uuid.uuid4().hex[:12]
        cls.source = "EtlTestSource_" + suffix
        cls.target = "EtlTestDW_" + suffix
        cls.password = load_env_password(ROOT)
        cls.fixture = json.loads((Path(__file__).with_name("test_fixture.json")).read_text(encoding="utf-8"))
        cls.sql(f"USE master; CREATE DATABASE [{cls.source}];")
        schema = f"USE [{cls.source}];\nGO\n"
        for name in ("Sales", "Person", "Production", "HumanResources"):
            schema += f"CREATE SCHEMA [{name}];\nGO\n"
        for table in cls.fixture:
            columns = ",".join(f"[{c}] nvarchar(4000) NULL" for c in table["columns"])
            schema += f"CREATE TABLE {table['table']} ({columns});\n"
        cls.sql(schema)

    @classmethod
    def tearDownClass(cls):
        # Solo las dos bases con nombres UUID creadas por esta ejecucion.
        for name in (cls.source, cls.target):
            assert name.startswith(("EtlTestSource_", "EtlTestDW_"))
            validate_name(name)
            cls.sql(f"USE master; IF DB_ID(N'{name}') IS NOT NULL BEGIN "
                    f"ALTER DATABASE [{name}] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; "
                    f"DROP DATABASE [{name}]; END;")

    @classmethod
    def sql(cls, text):
        return execute_sql(text, cls.password)

    def setUp(self):
        inserts = f"USE [{self.source}];\n"
        for table in self.fixture:
            inserts += f"DELETE FROM {table['table']};\n"
            for row in table["rows"]:
                columns = ','.join(f'[{c}]' for c in table['columns'])
                inserts += f"INSERT {table['table']} ({columns}) VALUES ({','.join(literal(v) for v in row)});\n"
        self.sql(inserts)

    def mutate(self, sql):
        self.sql(f"USE [{self.source}]; {sql}")

    def load(self):
        self.sql(build_pipeline(ROOT, self.source, self.target))

    def check(self, predicate):
        # sqlcmd -b convierte THROW en fallo real de la prueba.
        self.sql(f"USE [{self.target}]; IF NOT ({predicate}) "
                 "THROW 51999, 'Asercion de prueba no satisfecha.', 1;")

    def latest_issues(self, condition):
        return "EXISTS(SELECT 1 FROM dbo.EtlIssue WHERE RunID=" \
               "(SELECT TOP(1) RunID FROM dbo.EtlRun ORDER BY StartedAt DESC) AND " + condition + ")"

    def test_clean_and_repeatable(self):
        self.load()
        self.load()
        self.check("(SELECT COUNT(*) FROM dbo.FactSales)=2 AND "
                   "(SELECT SUM(LineTotal) FROM dbo.FactSales)=60 AND "
                   "(SELECT COUNT(*) FROM dbo.FactWorkOrder)=2 AND "
                   "(SELECT COUNT(*) FROM dbo.FactInventorySnapshot)=2 AND "
                   "EXISTS(SELECT 1 FROM dbo.DimDate WHERE DateKey=20160101)")
        self.check("NOT " + self.latest_issues("Severity='REJECT'"))

    def test_console_layout(self):
        self.mutate("UPDATE Production.Product SET Color=' ' WHERE ProductID='1';")
        output = self.sql(build_pipeline(ROOT, self.source, self.target))
        self.assertIn('CUADRATURA DE LA CARGA', output)
        self.assertIn('FILAS POR TABLA FUENTE', output)
        self.assertIn('Normalizaciones:', output)
        self.assertNotIn('Changed database context', output)
        self.assertNotIn('Null value is eliminated', output)
        self.assertNotIn('40.000000', output)
        for line in output.splitlines():
            self.assertLessEqual(len(line), 78, line)

    def test_bad_numeric_null_negative_and_overflow(self):
        for column, value in (("OrderQty", "abc"), ("OrderQty", None),
                              ("UnitPrice", "-20"), ("OrderQty", "1.5"),
                              ("UnitPrice", "99999999999999999999999999999999")):
            with self.subTest(column=column, value=value):
                self.mutate(f"UPDATE Sales.SalesOrderDetail SET OrderQty='2',UnitPrice='20' "
                            "WHERE SalesOrderID='1'; "
                            f"UPDATE Sales.SalesOrderDetail SET [{column}]={literal(value)} WHERE SalesOrderID='1';")
                self.load()
                self.check("(SELECT COUNT(*) FROM dbo.FactSales)=1 AND "
                           "(SELECT SUM(LineTotal) FROM dbo.FactSales)=20")
                self.check(self.latest_issues("Severity='REJECT' AND SourceTable='Sales.SalesOrderDetail'"))

    def test_empty_and_too_long_required_text(self):
        for name in ("   ", "x" * 101):
            with self.subTest(name=name):
                self.mutate(f"UPDATE Production.Product SET Name={literal(name)} WHERE ProductID='1';")
                self.load()
                self.check("(SELECT COUNT(*) FROM dbo.DimProduct)=1 AND "
                           "(SELECT COUNT(*) FROM dbo.FactSales)=1 AND "
                           "(SELECT COUNT(*) FROM dbo.FactWorkOrder)=1 AND "
                           "(SELECT COUNT(*) FROM dbo.FactWorkOrderRouting)=0")

    def test_unknown_reference_and_duplicate_key(self):
        self.mutate("UPDATE Sales.SalesOrderDetail SET ProductID='999' WHERE SalesOrderID='1'; "
                    "INSERT Sales.SalesOrderDetail SELECT * FROM Sales.SalesOrderDetail WHERE SalesOrderID='2';")
        self.load()
        self.check("(SELECT COUNT(*) FROM dbo.FactSales)=0")
        self.check(self.latest_issues("Severity='REJECT' AND Reason LIKE '%duplicad%'"))
        self.check(self.latest_issues("Severity='REJECT' AND FieldName LIKE '%ProductID%'"))

    def test_optional_nulls_and_descriptors(self):
        self.mutate("UPDATE Production.Product SET Color='  ',ProductSubcategoryID='999' WHERE ProductID='1'; "
                    "UPDATE Sales.Customer SET TerritoryID=NULL WHERE CustomerID='1'; "
                    "UPDATE Production.Product SET Name=N'  Bicicleta ágil  ' WHERE ProductID='1';")
        self.load()
        self.check("(SELECT COUNT(*) FROM dbo.FactSales)=2 AND "
                   "EXISTS(SELECT 1 FROM dbo.DimProduct WHERE ProductID=1 AND Color='N/A' "
                   "AND SubcategoryName=N'Sin Subcategoría' AND ProductName=N'Bicicleta ágil') AND "
                   "EXISTS(SELECT 1 FROM dbo.FactSales WHERE SalesOrderID=1 AND ShipDateKey=-1)")
        self.check(self.latest_issues("Severity='WARNING'"))
        self.check(self.latest_issues("Severity='NORMALIZED'"))

    def test_bad_dates_totals_and_production(self):
        self.mutate("UPDATE Sales.SalesOrderHeader SET OrderDate='fecha incorrecta' WHERE SalesOrderID='1'; "
                    "UPDATE Sales.SalesOrderDetail SET LineTotal='999' WHERE SalesOrderID='2'; "
                    "UPDATE Production.WorkOrder SET ScrappedQty='11' WHERE WorkOrderID='1'; "
                    "UPDATE Production.WorkOrderRouting SET ActualEndDate='2010-01-01';")
        self.load()
        self.check("(SELECT COUNT(*) FROM dbo.FactSales)=0 AND "
                   "(SELECT COUNT(*) FROM dbo.FactWorkOrder)=1 AND "
                   "(SELECT COUNT(*) FROM dbo.FactWorkOrderRouting)=0")
        self.check(self.latest_issues("Severity='REJECT' AND RawData LIKE '%fecha incorrecta%'"))

    def test_computed_money_overflow(self):
        self.mutate("UPDATE Production.Product SET StandardCost='900000000000000' WHERE ProductID='1';")
        self.load()
        self.check("(SELECT COUNT(*) FROM dbo.FactSales)=1 AND "
                   "(SELECT COUNT(*) FROM dbo.FactInventorySnapshot)=1")
        self.check(self.latest_issues("Reason LIKE '%fuera de rango money%'"))

    def test_empty_tables_and_summary(self):
        self.mutate("DELETE Sales.SalesOrderDetail; DELETE Sales.SalesOrderHeader; DELETE Production.WorkOrderRouting;")
        self.load()
        self.check("(SELECT COUNT(*) FROM dbo.FactSales)=0 AND "
                   "EXISTS(SELECT 1 FROM dbo.EtlTableSummary WHERE RunID="
                   "(SELECT TOP(1) RunID FROM dbo.EtlRun ORDER BY StartedAt DESC) "
                   "AND SourceTable='Sales.SalesOrderDetail' AND Received=0 AND Accepted=0 AND Rejected=0)")

    def test_offer_product_pair_and_routing_product(self):
        self.mutate("DELETE Sales.SpecialOfferProduct WHERE ProductID='1'; "
                    "UPDATE Production.WorkOrderRouting SET ProductID='2';")
        self.load()
        self.check("(SELECT COUNT(*) FROM dbo.FactSales)=1 AND "
                   "(SELECT COUNT(*) FROM dbo.FactWorkOrderRouting)=0")
        self.check(self.latest_issues("Reason LIKE '%Combinacion oferta/producto%'"))

    def test_long_composed_customer_name(self):
        self.mutate("UPDATE Person.Person SET FirstName=REPLICATE('a',50), "
                    "MiddleName=REPLICATE('b',50),LastName=REPLICATE('c',50);")
        self.load()
        self.check("EXISTS(SELECT 1 FROM dbo.DimCustomer WHERE CustomerID=1 AND LEN(CustomerName)=152) "
                   "AND (SELECT COUNT(*) FROM dbo.FactSales)=2")

    def test_failure_rolls_back_published_data(self):
        self.load()
        self.sql(f"USE [{self.target}]; CREATE TABLE dbo.TestLastRun(RunID uniqueidentifier); "
                 "INSERT dbo.TestLastRun SELECT TOP(1) RunID FROM dbo.EtlRun ORDER BY StartedAt DESC;")
        pipeline = build_pipeline(ROOT, self.source, self.target)
        pipeline = pipeline.replace("PRINT 'Etapa: 05_audit_and_validation.sql';",
                                    "THROW 51998, 'Fallo tecnico intencional de prueba.', 1;")
        with self.assertRaises(RuntimeError):
            self.sql(pipeline)
        self.check("(SELECT COUNT(*) FROM dbo.FactSales)=2 AND "
                   "(SELECT SUM(LineTotal) FROM dbo.FactSales)=60 AND "
                   "(SELECT TOP(1) RunID FROM dbo.EtlRun ORDER BY StartedAt DESC)="
                   "(SELECT RunID FROM dbo.TestLastRun)")
        self.sql(f"USE [{self.target}]; DROP TABLE dbo.TestLastRun;")

    def test_missing_column_preserves_dw(self):
        self.load()
        self.mutate("ALTER TABLE Production.Product DROP COLUMN Color;")
        try:
            with self.assertRaises(RuntimeError):
                self.load()
            self.check("(SELECT COUNT(*) FROM dbo.FactSales)=2")
        finally:
            self.mutate("ALTER TABLE Production.Product ADD Color nvarchar(4000) NULL;")
            # Las columnas se reordenan en el INSERT de futuras pruebas.


if __name__ == '__main__':
    unittest.main(verbosity=2)
