# C2-C5: cuatro preguntas diferentes

Estas páginas se añadieron al mismo proyecto que C1 y V1. Comparten fondo gris claro, cabecera azul oscuro, filtros azul claro, tarjetas blancas y paneles con bordes suaves. No se modificó el DW.

| Página | Decisión que permite tomar | Diferencia respecto de C1/V1 |
| --- | --- | --- |
| C2 Valor y concentración | Priorizar cuentas y reconocer dependencia de pocos clientes | Ranking por cliente, top 10 y Pareto; no resumen de ventas por territorio |
| C3 Frecuencia y recencia | Reconocer recompra y clientes que llevan más tiempo sin comprar | Segmentos por órdenes y días desde la última compra; no ranking monetario |
| C4 Cobertura geográfica | Ver localidades cubiertas y vacíos de información geográfica | País, provincia y ciudad del cliente; sin ventas ni fechas |
| C5 Comportamiento por canal | Comparar volumen y tamaño de pedidos por canal | Online frente a asistido, cruzados con persona/tienda; no equivalencias automáticas |

## C2 - Valor y concentración

Cuatro tarjetas: ventas, venta promedio por comprador, ventas del top 10 y participación del top 10. Gráfico de diez clientes y evolución de la concentración mensual; el top 10 se recalcula para cada mes. Tabla completa de compradores con posición, ventas, órdenes, ticket y porcentaje acumulado de ventas.

Top 10 incluye personas y tiendas. Los empates se resuelven por CustomerID para obtener exactamente diez clientes cuando existen suficientes compradores. El acumulado Pareto agrupa empates de venta, por lo que dos clientes con ventas iguales pueden tener la misma participación acumulada. Su denominador es la cartera seleccionada, no solo las diez barras visibles. No se presupone una distribución 80/20.

Filtros: año, mes, tipo y territorio del cliente. La tabla puede contener muchos compradores; se ordena por ventas y permite desplazamiento. No se la presenta como un top 50 si no se limita a 50 filas.

## C3 - Frecuencia y recencia

Cuatro tarjetas: compra única, recurrentes (2–3 órdenes), frecuentes (>3) y recencia promedio. Barras de segmentos por tipo de cliente; dispersión de días desde la última compra frente a cantidad de órdenes. Tabla de compradores con segmento, última compra del periodo y recencia.

Se cuentan órdenes distintas, no líneas de detalle. La referencia temporal es la última fecha de venta de toda la carga, aun cuando cambien los filtros. No se usa hoy ni se inventan umbrales de abandono. Un cliente sin compras en el periodo no se clasifica como compra única y no entra en el promedio de recencia.

Filtros: año, mes, tipo y territorio del cliente. El gráfico de dispersión puede usar muestreo de Power BI cuando hay muchos puntos: las tarjetas y la tabla no deben tomarse del número de puntos dibujados. No se trata de un modelo RFM puntuado.

## C4 - Cobertura geográfica

Cuatro tarjetas: países, estados/provincias, ciudades y clientes sin país informado. Barras por país y localidad; tabla agregada por país, provincia y ciudad con clientes y participación en la cartera seleccionada.

Localidad utiliza ciudad + provincia + país para no mezclar lugares homónimos. Las tarjetas de provincias y ciudades cuentan combinaciones geográficas, no solo nombres distintos. Las ubicaciones «No Informado» no cuentan como lugares reales; sí deben aparecer en el análisis de calidad correspondiente.

Filtros: país, provincia, ciudad y tipo de cliente. No hay filtro temporal: analiza la ubicación actual de clientes, no ventas históricas ni penetración sobre una población externa desconocida. No depende de mapas en la nube.

## C5 - Comportamiento por canal

Cuatro tarjetas: órdenes y ticket promedio de cada canal. Líneas mensuales de ventas online/asistidas; participación de cada canal en las órdenes. Tabla canal × tipo de cliente con compradores, órdenes, ventas, ticket y margen estimado.

Filtros: año, mes, tipo y territorio del cliente. Se evita un selector de canal que oculte por defecto la comparación. Online/Asistido deriva de OnlineOrderFlag; Persona/Tienda deriva de CustomerType. Los compradores pueden utilizar ambos canales y no necesariamente se suman. Las órdenes sí deben formar una partición sin duplicados entre canales.

## Referencia SQL de la carga actual

| Indicador | Valor |
| --- | ---: |
| C2 venta por comprador | 5.745,40 |
| C2 venta top 10 | 7.922.046,38 |
| C2 participación top 10 | 7,21 % |
| C3 compra única / recurrentes / frecuentes | 11.649 / 6.677 / 793 |
| C3 recencia media | 190,3 días |
| C3 fecha de referencia | 30/06/2014 |
| C4 países / provincias / ciudades | 6 / 70 / 582 |
| C4 clientes sin país | 0 |
| C5 órdenes online / asistidas | 27.659 / 3.806 |
| C5 ticket online / asistido | 1.061,45 / 21.147,58 |

Los valores se obtuvieron con `database/reports/05_clientes_finales.sql`. Se conservaron los controles anteriores de los 15 reportes; las nuevas medidas DAX y la representación de las páginas aún requieren revisión en Desktop.

## Abrir y comprobar

### Corrección C2: barras vacías

El motor del modelo abierto indicó `The syntax for 'Id' is incorrect` en `C2 Posicion Cliente`; `C2 Venta Top 10` fallaba por depender de ella. Se cambió la variable a `ClienteActual` y se añadió una prueba de regresión. No era ausencia de ventas ni un problema de conexión.

La fórmula corregida se probó en el motor abierto mediante dos medidas temporales de consulta (sin editar el modelo en ejecución). Para 2012 + marzo + Tienda + Central devolvió diez compradores con posiciones 1–10 y barras por un total de 336.469,0906. Por eso la participación del top 10 es 100% en ese caso. Al reabrir el proyecto se debe confirmar la representación visual; el modelo que estaba abierto conserva la fórmula anterior hasta recargar el archivo.

1. Conservar cualquier edición propia en una copia antes de cerrar el proyecto.
2. Reabrir `PilotoVentas.pbip` y pulsar Actualizar para cargar medidas y columnas calculadas.
3. Las pestañas aparecen en orden C1, C2, C3, C4, C5 y V1; no tienen filtros sincronizados entre páginas.
4. Limpiar filtros y selecciones de gráficos antes de comparar cada referencia.
5. Ejecutar [comprobar_clientes_finales.dax](comprobar_clientes_finales.dax) en la Vista de consultas DAX. Conteos exactos, importes con tolerancia 0,01; recencia/ratios con tolerancia 0,000001 antes del formato visual.
6. Probar tipo Tienda y año 2013 en C2/C3/C5; en C4 probar país y provincia, comprobando que ciudades homónimas no se mezclan.
7. Comprobar que C1 y V1 mantienen sus resultados anteriores.

El proyecto ahora contiene seis páginas, cuatro tablas, tres relaciones, 44 medidas y 74 visuales. Las definiciones pasaron las comprobaciones de referencias, esquemas, posiciones sin solapamiento y estética; esto no demuestra por sí solo ejecución DAX en Desktop.
