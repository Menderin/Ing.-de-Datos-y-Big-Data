# P1-P5 · Reportes de producción

Las cinco páginas están en `PilotoVentas.pbip`, junto con C1-C5 y V1.
Producción usa violeta oscuro `#493164`, acentos `#8060AB` y fondos lavanda.
Clientes conserva su azul; el verde queda reservado como identidad de ventas.

## Abrir las páginas

1. Cerrar el proyecto abierto en Desktop. Si hay cambios manuales sin guardar que
   se quieran conservar, guardarlos en una copia para no sobrescribir las nuevas definiciones.
2. Abrir `PilotoVentas.pbip` desde esta carpeta.
3. Pulsar **Actualizar** para importar las seis tablas añadidas del DW.
4. Recorrer P1-P5. No hace falta ejecutar el ETL ni restaurar la fuente de nuevo.

La conexión sigue siendo `localhost,1433`, base `AdventureWorksDW`, con las
credenciales SQL Server ya configuradas. Hay 11 páginas implementadas como
definiciones: C1-C5, P1-P5 y V1; V2-V5 siguen pendientes.

## Preguntas y contenido

| Página | Pregunta | Indicadores / gráficos |
|---|---|---|
| P1 · Panorama de producción | ¿Cuánto se ordenó fabricar y cuánto se almacenó? | Líneas por mes de inicio y columnas apiladas de almacenadas/descartadas por categoría; detalle por producto con tasa de descarte. |
| P2 · Calidad y desperdicio | ¿Dónde se concentra el descarte y qué motivos se registraron? | Pareto de unidades por motivo con línea acumulada en eje 0–100 %; matriz producto/motivo con intensidad de color; detalle producto/motivo. |
| P3 · Inventario y reposición | ¿Qué existencias tenemos y qué productos requieren atención? | Barras de stock por ubicación; tabla de reposición con umbral, stock global, brecha y estado coloreado; detalle de existencias locales por estante/casillero. |
| P4 · Operaciones y centros | ¿Qué centros consumen recursos y cómo se comparan los costos? | Barras de horas por centro; matriz de costos planificados/reales y desviación con color; detalle por centro/secuencia de operación. |
| P5 · Composición del catálogo | ¿Cómo se compone el portafolio y qué fabricamos internamente? | Columnas apiladas de origen productivo por categoría; treemap de referencias por categoría/subcategoría; catálogo detallado. |

P2 tiene más altura de página para dar al Pareto y al mapa de calor todo el ancho
del lienzo; la matriz y el detalle se recorren verticalmente sin solaparse.
No se añadieron visuales externos: el mapa de calor utiliza una matriz nativa.
La intensidad de celda usa bandas de unidades: 1–49 / 50–99 / 100–499 / 500+,
de claro a oscuro; son rangos descriptivos, no umbrales de calidad definidos por el profesor.
Las celdas sin descarte se conservan vacías.

La línea del Pareto acumula los motivos dentro de los filtros elegidos, ordenados
por unidades descendentes. Los motivos empatados comparten el acumulado del grupo;
no se supone que el 20 % de los motivos explique el 80 % del desperdicio.
En P1 el descarte es pequeño: consultar el tooltip o la tasa del detalle, no solo el área de la columna.
En P3 la brecha es stock global − reorden; negativa se destaca en tono de alerta,
cero no es alerta. En P4 las desviaciones positivas se destacan en naranja suave,
negativas en verde suave y cero en lavanda neutral: el color no implica una eficiencia demostrada.

El formato condicional usa expresiones nativas por celda, siguiendo el mecanismo
documentado por [Microsoft](https://learn.microsoft.com/en-us/power-bi/create-reports/desktop-conditional-table-formatting).

## Modelo y límites de interpretación

- `DimProduct` filtra ventas y los tres hechos de producción, en una sola dirección.
  No se conectan hechos entre sí ni se multiplican órdenes por operaciones.
- P1/P2 usan `FactWorkOrder`, una fila por orden. Su fecha activa es **inicio**.
  Las unidades almacenadas son las asociadas a las órdenes iniciadas en el período;
  no representan necesariamente unidades terminadas ese mes. No hay plan maestro independiente.
  Se suman unidades de distintos productos, incluidos componentes y piezas intermedias:
  el total no debe interpretarse como bicicletas terminadas.
- P2 calcula tasa como suma de descartadas / suma de ordenadas, con `DIVIDE`.
  El costo es descartadas × costo estándar del producto, no costo histórico demostrado.
  Solo aparecen motivos con descarte positivo, incluido un motivo no informado si
  una nueva fuente tiene descartes sin motivo. No se interpreta como causa raíz comprobada.
- P3 es una foto actual sin filtro de fecha. Los productos con registro cero se
  distinguen de productos sin registro: ausencia no se convierte en stock cero.
  El punto de reorden se compara una vez por producto con la suma de todas sus ubicaciones.
  El indicador **bajo reorden global** conserva ese alcance aunque se filtre ubicación;
  el stock, valor, conteo local y filas de detalle sí se restringen a la ubicación.
  Por ello la alerta global no tiene como denominador los productos locales de la tarjeta vecina.
- P4 usa `FactWorkOrderRouting`, una fila por operación. Su fecha activa es inicio real.
  Operaciones sin inicio real pueden aparecer sin filtro temporal, pero no se atribuyen
  a un mes inventado. El encabezado informa el conteo dentro del contexto seleccionado.
  Horas consumidas no equivalen a capacidad utilizada ni a eficiencia comparativa.
  La variación de costo cero de esta fuente se conserva.
- P5 usa exclusivamente `DimProduct`. No repite stock, ventas ni margen.
  `MakeFlag` indica fabricación interna y `FinishedGoodsFlag` producto terminado.
  No fabricado no implica compra reciente; sin categoría puede ser material intermedio.
- La jerarquía `DimProduct[Catalogo]` queda disponible en el modelo para futuras
  exploraciones categoría → subcategoría → producto; no se afirma que los gráficos
  tengan drill down implementado en esta versión.

## Referencias SQL verificadas

Sin filtros, sobre el DW actual:

| Página | Valores de referencia |
|---|---|
| P1 | 72.591 órdenes; 4.507.721 ordenadas; 4.497.070 almacenadas; 10.651 descartadas. |
| P2 | 0,236283 % de descarte; 359.947,1751 de costo estimado; 729 órdenes con descarte; 16 motivos utilizados. |
| P3 | 335.974 unidades; 20.092.679,1712 de valor estimado; 432 productos con registro; 7 bajo reorden global. |
| P4 | 67.131 operaciones; 228.962,20 horas; 3.487.969,50 de costo real y planificado; variación cero; cero sin inicio real. |
| P5 | 504 productos; 239 fabricados; 265 no fabricados; 295 terminados. |

`database/reports/06_produccion_finales.sql` es de solo lectura y comprueba también
que las uniones dimensionales no alteren filas o cantidades. El rango de inicio
de órdenes es 03-06-2011 a 02-06-2014: 2010 y 2015 no tienen actividad.
Las páginas muestran ausencia de datos, sin fabricar tasas para denominadores vacíos.

## Comprobaciones y pendientes

- Corrección de P1/P5 tras revisión en Desktop: el identificador nativo de las
  columnas apiladas es `columnChart`. `stackedColumnChart` no es un visual registrado,
  por lo que Desktop lo interpretaba como personalizado faltante. Se corrigieron
  ambos visuales y el generador. El validador ahora rechaza tipos no registrados
  en la lista de visuales nativos usados por este proyecto; el esquema JSON solo
  valida que el identificador sea una cadena y no detectaba este problema.

- Referencias del modelo, relaciones unidireccionales, disposición sin solapamientos
  y esquemas JSON oficiales de Microsoft comprobados.
- Totales y uniones comprobados mediante SQL sobre el DW operativo.
- `comprobar_produccion.dax` permite contrastar medidas, meses, ubicaciones y un
  período vacío en la vista de consultas DAX después de actualizar Desktop.
- El Pareto y la brecha de reorden se ejecutaron como medidas temporales de consulta
  en el motor local de Desktop, sin modificar el modelo abierto: 16 motivos,
  10.651 unidades, acumulado final 100 %, siete productos bajo reorden y período
  2015 sin descarte/acumulado (BLANK, sin división por cero). No había medidas
  con error en el modelo abierto antes de la prueba.
- **Pendiente:** reabrir/actualizar las páginas rediseñadas y revisar visualmente
  tamaños, colores e interacciones en Power BI Desktop. Las pruebas DAX de consulta
  no sustituyen el renderizado y la interacción de los visuales reales.
