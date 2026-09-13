# Evidencia de implementación de la base de datos transaccional

## Estado de la fuente de datos

La base de datos `AdventureWorks2022` fue restaurada desde `Data/AdventureWorks2022.bak` en SQL Server 2022, ejecutado mediante Docker. La instancia es accesible desde SQL Server Management Studio a través de `localhost,1433` y la base se encuentra en estado `ONLINE`.

## Estructura verificada

La fuente contiene 71 tablas de usuario distribuidas en seis esquemas:

| Esquema | Cantidad de tablas |
|---|---:|
| dbo | 3 |
| HumanResources | 6 |
| Person | 13 |
| Production | 25 |
| Purchasing | 5 |
| Sales | 19 |

También se verificó la existencia de datos operacionales, entre ellos:

| Tabla | Registros |
|---|---:|
| Person.Person | 19.972 |
| Sales.SalesOrderHeader | 31.465 |
| Sales.SalesOrderDetail | 121.317 |
| Production.Product | 504 |
| Production.WorkOrder | 72.591 |

## Panorama de relaciones

El archivo [diagrama-general-bd-transaccional.drawio](./diagrama-general-bd-transaccional.drawio) presenta una vista simplificada de las tablas centrales para las perspectivas de clientes, ventas y producción.

El flujo principal observado es:

```text
Cliente → Orden de venta → Detalle de venta → Producto
   ↓            ↓                              ↓
Persona     Territorio                  Categoría / Inventario
                ↓                              ↓
            Vendedor                    Orden de trabajo
```

Las relaciones se obtuvieron desde las claves foráneas registradas en SQL Server. El diagrama no pretende reproducir las 71 tablas, sino mostrar el subconjunto más relevante para comprender la fuente y diseñar los reportes solicitados.

## Interpretación para la Entrega 1

La implementación de la fuente transaccional queda demostrada mediante:

1. ejecución de SQL Server 2022 en Docker;
2. restauración exitosa del backup oficial;
3. base `AdventureWorks2022` en estado `ONLINE`;
4. acceso y exploración desde SSMS;
5. presencia de esquemas, tablas, relaciones y registros;
6. consultas ejecutadas correctamente sobre clientes, ventas y producción.

No se han implementado procesos ETL ni un Data Warehouse, ya que corresponden a etapas posteriores del proyecto.
