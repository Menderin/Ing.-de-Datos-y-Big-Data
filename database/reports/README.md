# Validación SQL de los 15 reportes

Estas consultas leen `AdventureWorksDW`. No restauran bases, no ejecutan el ETL y no cambian datos permanentes. Algunas crean tablas temporales de sesión.

| Archivo | Uso |
| --- | --- |
| [01_controles_reportes.sql](01_controles_reportes.sql) | Indicadores de C1–C5, P1–P5 y V1–V5 |
| [02_detalle_reportes.sql](02_detalle_reportes.sql) | Desgloses para tablas y gráficos; evita multiplicar filas al combinar hechos |
| [03_piloto_ventas.sql](03_piloto_ventas.sql) | Ocho escenarios de filtros del piloto y controles de sus relaciones |
| [04_panorama_clientes.sql](04_panorama_clientes.sql) | Siete escenarios de C1 y controles de integridad de clientes |
| [05_clientes_finales.sql](05_clientes_finales.sql) | Referencias específicas de C2-C5, localidades sin mezclar homónimos y partición de órdenes por canal |
| [validar_reportes.py](validar_reportes.py) | Comprueba paquetes, reconciliaciones y controles SQL |
| [test_validar_reportes.py](test_validar_reportes.py) | Pruebas locales del comprobador, sin Docker |

## Ejecutar

Con Docker iniciado y el DW previamente cargado, desde la raíz del repositorio:

```powershell
python database/reports/validar_reportes.py
python database/reports/test_validar_reportes.py
```

El primer comando requiere Python, Docker y la contraseña local de `.env`. Para otro DW ya creado se puede agregar `--database OtroDW`. `--json` muestra resultados completos; los decimales se serializan como cadenas para conservar precisión.

También se pueden abrir los archivos SQL en SSMS y ejecutarlos. Cambiar únicamente el `USE` si el DW tiene otro nombre.

## Resultado comprobado con la base actual

Se ejecutaron consultas de los 15 reportes y ocho escenarios de filtros. Pasaron 28 controles de consistencia (26 comprobaciones numéricas y dos controles SQL de relaciones/gráficos), además de seis pruebas del comprobador. El detalle SQL también se ejecutó sin errores.

Algunos valores de referencia:

| Indicador | Valor |
| --- | ---: |
| Ventas netas | 109.846.381,399888 |
| Órdenes de venta | 31.465 |
| Unidades vendidas | 274.914 |
| Clientes registrados / compradores | 19.820 / 19.119 |
| Órdenes de producción | 72.591 |
| Existencias | 335.974 |
| Productos con registros de inventario / stock positivo | 432 / 428 |

La referencia completa está en [referencia_sql.json](../../powerbi/piloto/referencia_sql.json). Es una captura de esta carga, no valores obligatorios para una nueva base del profesor. Tras cambiar la fuente, volver a consultar y revisar los controles; no exigir que los totales nuevos sean iguales a los actuales.

## Alcance y precauciones

- SQL comprueba los datos y las uniones del DW. No sustituye las pruebas de relaciones, contexto de filtros y medidas DAX en Power BI.
- No todos los reportes comparten filtros: la cartera de clientes no cambia automáticamente al filtrar fechas; los compradores sí dependen de las ventas.
- Inventario es una instantánea, no una serie histórica. Cuotas y bonus son atributos actuales, no acumulados por año.
- La recencia se calcula respecto de la última fecha de venta cargada, no respecto de hoy.
- El promedio de precio por línea no equivale al precio neto ponderado por unidades.
- Para descuentos se admite la diferencia de redondeo entre importes de cuatro y seis decimales. No se exige una igualdad artificial.

Ver el [diseño final](../../reports/diseno_final_reportes.md) y el [piloto de Power BI](../../powerbi/piloto/README.md).
