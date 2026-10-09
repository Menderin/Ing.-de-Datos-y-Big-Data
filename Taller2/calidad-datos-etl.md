# Calidad de datos y carga tolerante

## Criterio adoptado

El objetivo es obtener resultados a partir de los registros válidos aunque la fuente contenga errores. No se detiene todo el ETL por un dato incorrecto ni se reemplazan importes ausentes por cero. Las reglas siguientes son decisiones del equipo; no una transcripción del enunciado.

Se distingue entre normalización segura, datos incompletos permitidos, filas rechazadas y fallos técnicos.

## Tratamiento por caso

| Caso | Tratamiento |
| --- | --- |
| Espacios al principio/final de textos | Se recortan y se registra `NORMALIZED`. |
| Texto opcional vacío | Se convierte a NULL; color se presenta como `N/A`. |
| Nombre obligatorio vacío o texto demasiado largo | Se rechaza la fila, sin truncar silenciosamente. |
| Número o fecha mal formateado | `TRY_CONVERT` evita el fallo de conversión; se rechaza la fila si el valor era obligatorio o venía informado pero era inválido. |
| Cantidad o precio obligatorio NULL | Se rechaza la fila; no se inventa un cero. |
| Cantidades negativas, fracciones en cantidades enteras, descuentos fuera de 0–1 | Se rechaza la fila. Costos y precios cero sí son válidos. |
| Valores o cálculos fuera del rango del tipo de destino | Se rechaza la fila antes de cargar el hecho. |
| Fecha opcional ausente | Se representa con `DateKey = -1`. Una fecha informada pero ilegible no se trata como «no aplica». |
| Cuota de vendedor NULL | Se conserva como NULL. |
| Venta online sin vendedor | Se usa el miembro especial `SalesPersonKey = 0`. Venta asistida sin vendedor válido se rechaza. |
| Orden sin desperdicio ni motivo de descarte | Se usa `ScrapReasonKey = 0`. Desperdicio positivo sin motivo se rechaza. |
| Dirección, territorio del cliente o categoría descriptiva ausente | Se conserva la entidad si tiene identificación válida y se muestra un descriptor de ausencia. Referencias descriptivas rotas generan `WARNING`. |
| Cliente sin persona ni tienda válida | Se rechaza y se propaga el rechazo a sus ventas. |
| Referencia obligatoria inexistente o a una entidad rechazada | Se rechaza la fila dependiente. No se fabrican clientes, productos ni territorios para conservar una venta. |
| Clave de negocio duplicada | Se rechazan todas sus copias: no hay criterio confiable para escoger una. |
| Oferta y producto válidos por separado, pero combinación inexistente | Se rechaza la venta: se verifica `Sales.SpecialOfferProduct`. |
| Producto de una operación distinto al de su orden | Se rechaza la operación. |
| Fechas en orden imposible, total de venta incoherente, cantidades de producción que no cuadran | Se rechaza la fila. El total de línea admite diferencia de redondeo de hasta 0,01. |
| Tablas sin filas | Son válidas: el resumen registra cero recibidos, aceptados y rechazados. |
| Tabla/columna requerida ausente, tipo no soportado, error SQL o descuadre interno | Se aborta y revierte la carga, conservando el DW previo. |

Las reglas de no negatividad corresponden a ventas y producción de AdventureWorks. No deben extrapolarse a devoluciones o ajustes contables de otros modelos, donde un valor negativo podría ser correcto.

## Cómo se ejecuta

1. El orquestador verifica los nombres y crea la base destino si no existe.
2. `00_prepare_source.sql` inicia la transacción, obtiene un bloqueo exclusivo del ETL y prepara tablas temporales tipadas a partir de 22 tablas fuente. La lectura mantiene bloqueos hasta terminar para evitar cambios concurrentes en los datos ya leídos.
3. Se normalizan textos, verifican tipos, rangos, duplicados y reglas de negocio, y se propagan los rechazos a las filas dependientes. La fuente permanece intacta.
4. Se reconstruyen las ocho dimensiones y cuatro hechos únicamente con las filas aceptadas. El calendario conserva 2010–2015 como rango mínimo y se amplía con las fechas aceptadas de la nueva fuente.
5. La auditoría verifica conteos, importes, cantidades y restricciones del DW. Además exige que cada fila recibida esté aceptada o tenga un rechazo registrado.
6. Solo después de pasar la auditoría se confirma la transacción. Un fallo anterior a esa confirmación revierte también los cambios del esquema y los datos.

Es una recarga completa, no incremental. Las claves subrogadas generadas pueden cambiar: Power BI debe refrescar dimensiones y hechos juntos. Los scripts SQL no deben ejecutarse individualmente, porque necesitan compartir las tablas temporales y la transacción del orquestador.

## Trazabilidad

- `dbo.EtlRun`: identificador, origen, fechas UTC y estado de cada carga publicada.
- `dbo.EtlTableSummary`: recibidos, aceptados y rechazados por tabla y carga.
- `dbo.EtlIssue`: severidad, tabla, identificador de fila de staging, campo, motivo y valores originales de las columnas utilizadas en JSON.

`SourceRowID` identifica una fila dentro de esa carga, no es una clave permanente de AdventureWorks. La clave de negocio está en `RawData`. Una fila puede tener más de una incidencia: contar incidencias no equivale a contar filas rechazadas.

`COMPLETED` indica una carga sin advertencias ni rechazos (puede incluir normalizaciones). `COMPLETED_WITH_WARNINGS` indica una carga publicada con datos incompletos o rechazados. Los fallos técnicos se muestran en consola y dejan sin publicar la ejecución fallida; su registro transaccional también se revierte.

Los reportes reflejan exclusivamente filas aceptadas. Si una tabla pierde todos sus registros por rechazos, su resultado puede quedar vacío, pero el resumen y el estado lo hacen visible. No se estableció un porcentaje máximo de rechazo: ese umbral debe acordarse, no inventarse.

## Ejecución y revisión

```powershell
.\ejecutarETL.ps1
.\ejecutarETL.ps1 -SourceDatabase OtraAdventureWorks -TargetDatabase AdventureWorksDW
```

```bash
python database/etl/run_etl.py --source OtraAdventureWorks --target AdventureWorksDW
python database/etl/test_etl.py
```

Las pruebas requieren Docker, SQL Server iniciado, Python 3 y `.env`. Crean una fuente y un destino con prefijos `EtlTestSource_` y `EtlTestDW_`, nombres aleatorios, datos sintéticos y columnas de texto para simular formatos incorrectos. Solo esas dos bases se eliminan al finalizar. Nunca modifican la fuente real.

Se comprueban 12 casos de calidad: carga limpia y repetible; cantidades NULL/no numéricas/fraccionarias, negativos y desbordamientos; textos vacíos/largos; nombres compuestos completos; fechas y totales inconsistentes; duplicados y referencias inexistentes; nulos permitidos y normalizaciones; claves compuestas; tablas vacías; reversión ante fallo técnico y columna ausente. Los subcasos numéricos se ejecutan por separado. Una prueba adicional verifica que la consola use líneas de hasta 78 caracteres, no muestre decimales innecesarios ni advertencias artificiales por el conteo de incidencias.

Para consultar la última carga:

```sql
USE AdventureWorksDW;
DECLARE @run uniqueidentifier = (SELECT TOP (1) RunID FROM dbo.EtlRun ORDER BY StartedAt DESC);
SELECT * FROM dbo.EtlRun WHERE RunID = @run;
SELECT * FROM dbo.EtlTableSummary WHERE RunID = @run ORDER BY SourceTable;
SELECT Severity, SourceTable, FieldName, Reason, RawData
FROM dbo.EtlIssue WHERE RunID = @run ORDER BY IssueID;
```

## Límites explícitos

- No se corrigen automáticamente cantidades, precios, fechas ni claves ambiguas. Los rechazos se revisan y corrigen en el origen autorizado; después se repite la carga.
- Se aceptan fechas ISO convertibles por SQL Server. Un rango global del calendario superior a 366.000 días aborta como protección de recursos; debe revisarse antes de publicar.
- No hay historial dimensional SCD ni inventario histórico: `FactInventorySnapshot` conserva el estado de la carga actual.
- Las pruebas cubren casos concretos; no garantizan soportar cualquier corrupción o una estructura diferente del contrato esperado.
- Las incidencias pueden incluir datos personales. El historial permanece en SQL Server, no se exporta ni se versiona en Git. Una política de retención y permisos es una mejora posterior.
