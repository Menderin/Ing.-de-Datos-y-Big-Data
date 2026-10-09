# Piloto V1: resumen de ventas

**Estado actual:** el mismo proyecto contiene C1-C5 de Clientes y V1 de Ventas. Ver [C2-C5: contenido y pruebas](clientes-finales.md). Son seis páginas, cuatro tablas, tres relaciones, 44 medidas y 74 visuales. Las cifras de estructura en las notas históricas posteriores describen etapas anteriores. C2-C5 requieren revisión de apertura, DAX y filtros en Desktop.

El proyecto ahora incluye también [C1 - Panorama de clientes](C1-panorama-clientes.md), como página inicial. Ambas páginas comparten un solo modelo: cuatro tablas, tres relaciones y 14 medidas en total. Los 26 visuales se distribuyen entre C1 (12) y V1 (14). Para C1 se debe actualizar el modelo antes de revisar la nueva página. Las cifras y el alcance descritos más abajo corresponden a V1.

Proyecto editable de Power BI conectado a `AdventureWorksDW`. Permite probar un reporte real antes de extender el modelo a los otros 14. No se creó otra aplicación HTML.

El proyecto contiene tres tablas (`FactSales`, `DimDate`, `DimTerritory`), dos relaciones varios-a-uno con filtro desde la dimensión hacia los hechos, siete tarjetas numéricas, un aviso de estado, dos gráficos y cuatro filtros desplegables: año, mes, territorio y canal. Canal distingue Online y Asistido, no B2C y B2B.

## Abrir y cargar

1. Iniciar Docker Desktop y verificar que SQL Server esté levantado. Si ya cargaste el DW, no es necesario volver a ejecutar el ETL.
2. Abrir [PilotoVentas.pbip](PilotoVentas.pbip) con Power BI Desktop. Usar una versión compatible con proyectos PBIP y definiciones de reporte PBIR.
3. Pulsar **Actualizar**. Servidor: `localhost,1433`; base: `AdventureWorksDW`.
4. Cuando solicite credenciales, elegir autenticación de base de datos: usuario `sa` y contraseña de tu `.env`. Las credenciales no están incluidas en el proyecto.
5. Si aparece un aviso de certificado, comprobar que corresponde al SQL Server local. No confiar en certificados desconocidos ni desactivar el cifrado globalmente.

El proyecto no incluye caché de datos; antes de actualizar puede mostrar tarjetas vacías. Las relaciones y medidas del piloto ya están definidas: no importar las doce tablas ni pegar nuevamente todas las medidas del modelo completo.

El formato sigue la documentación de Microsoft para [modelos semánticos PBIP](https://learn.microsoft.com/en-us/power-bi/developer/projects/projects-dataset) y [definiciones de reportes](https://learn.microsoft.com/en-us/power-bi/developer/projects/projects-report).

## Comprobar resultados

Sin filtros, deben aparecer:

| Tarjeta | Resultado de referencia |
| --- | ---: |
| Ventas netas | 109.846.381,40 |
| Costo de ventas | 100.474.477,77 |
| Margen bruto | 9.371.903,63 |
| Margen bruto % | 8,53 % |
| Órdenes | 31.465 |
| Ticket promedio | 3.491,07 |
| Unidades vendidas | 274.914 |

Probar los filtros individualmente y combinados. Limpiarlos antes de cada escenario:

Cada desplegable tiene un filtro visual `[Ordenes] > 0`: muestra opciones con ventas bajo el contexto actual. Con esta carga, 2010 y 2015 no deberían ofrecerse, ni abril al seleccionar 2011. Esto no borra fechas del DW ni introduce filtros globales sobre los gráficos. Para cambiar a otra combinación puede ser necesario limpiar primero el mes o el territorio seleccionado.

Si una selección externa, un filtro manual o una nueva carga deja cero órdenes, el aviso debe indicar «Sin ventas para la selección actual. Limpia o cambia los filtros». Los importes y ratios conservan BLANK; no se inventan valores. Los casos sin ventas se pueden comprobar desde la consulta DAX, aunque el desplegable ya no los ofrezca.

| Escenario | Ventas netas | Órdenes |
| --- | ---: | ---: |
| Sin filtros | 109.846.381,40 | 31.465 |
| Año 2013 | 43.622.479,05 | 14.182 |
| Southwest | 24.184.609,60 | 6.224 |
| 2013 + Southwest | 9.116.540,31 | 2.725 |
| Junio de 2013 | 5.081.069,13 | 719 |
| Online | 29.358.677,22 | 27.659 |
| 2013 + Southwest + Online | 1.917.288,98 | 2.431 |
| Año 2010, sin ventas | En blanco | 0 |

Para comprobar también costo, margen, ticket y unidades, copiar [comprobar_filtros.dax](comprobar_filtros.dax) en una consulta de la **Vista de consultas DAX** y ejecutarla. Es una consulta completa, no una medida para pegar en una tarjeta.

Comparar sus ocho filas con [referencia_sql.json](referencia_sql.json), sección `pilot`. Conteos exactos; diferencias de importes como máximo 0,01 y de ratios como máximo 0,000001. Los importes de ventas conservan seis decimales en origen; el formato visual de dos decimales no debe truncar los datos. Sin ventas, las sumas y divisiones quedan en blanco; las órdenes muestran cero.

En ambos gráficos, cambiar los filtros debe cambiar los resultados sin multiplicar ventas. El gráfico mensual usa año-mes para no mezclar meses de años distintos.

## Estado de verificación

### Corrección de la pantalla en blanco (7 de octubre de 2026)

El registro de Desktop 2.158.1304.0 mostraba `Cannot read properties of undefined (reading 'visualContainers')`. Se corrigió la versión del contenido en `definition/version.json`: `2.0.0`, manteniendo el esquema `versionMetadata/1.0.0`. Son versiones distintas; el esquema JSON no garantizaba la compatibilidad del valor anterior con Desktop. La versión corregida coincide con un [proyecto publicado por Microsoft](https://github.com/microsoft/BCApps/blob/main/src/Apps/W1/PowerBIReports/Power%20BI%20Files/Projects%20app/Projects%20app.Report/definition/version.json).

Para probar: cerrar el piloto en Desktop sin guardar la pantalla vacía y abrir de nuevo `PilotoVentas.pbip`. No hace falta recrear el DW. Si se pierde la caché local, pulsar Actualizar. El resultado de esta corrección en Desktop aún debe comprobarse; si persiste el error, conservar el nuevo registro para continuar el diagnóstico.

El comprobador ahora rechaza la versión anterior y verifica la página activa, sus carpetas y los identificadores de visuales. Las pruebas de regresión se ejecutan con `python powerbi/test_validar_piloto.py`.

- Consultas SQL: 15 reportes, ocho escenarios y 28 controles de consistencia comprobados.
- Archivos del piloto: referencias de tablas, medidas, relaciones y posiciones comprobadas; 21 archivos de metadatos contrastados con esquemas públicos de Microsoft.
- Presentación revisada: tarjetas distribuidas en dos filas, importes sin abreviar, etiquetas duplicadas ocultas y filtros desplegables. El modelo tiene ocho medidas (siete indicadores y un mensaje), y el reporte 14 visuales. Tras esta revisión son 21 archivos de metadatos.
- La captura del usuario confirmó que la versión anterior de la página se abrió y mostró datos. La presentación revisada, los filtros de disponibilidad y la nueva medida de estado aún deben comprobarse en Desktop. La automatización de la aplicación no está disponible en este entorno; no se han ejecutado las consultas DAX automáticamente.

Pendientes antes de considerar operativo el piloto:

- [ ] Abrir el proyecto sin errores en Desktop.
- [ ] Actualizar desde SQL Server correctamente.
- [ ] Comparar los ocho escenarios DAX con SQL.
- [ ] Revisar visualmente tarjetas, gráficos y filtros.

Pruebas adicionales de las capturas del usuario, ya contrastadas con SQL:

| Selección | Órdenes | Ventas netas |
| --- | ---: | ---: |
| Abril 2011 + Australia | 0 | En blanco |
| Junio 2011 + Australia | 61 | 206.252,91 |
| Noviembre 2011 + Northwest | 37 | 122.638,79 |

Ejecutar [comprobar_presentacion.dax](comprobar_presentacion.dax) en la Vista de consultas DAX para contrastar estos tres casos y el mensaje de estado.

Northeast y Northwest son territorios diferentes. La consulta del DW no encontró nombres duplicados, ni después de quitar espacios y normalizar mayúsculas.

Desde la raíz del repositorio, las comprobaciones reproducibles son:

```powershell
python database/reports/validar_reportes.py
python database/reports/test_validar_reportes.py
python powerbi/validar_piloto.py
python powerbi/validar_piloto.py --schemas
```

El último comando necesita conexión a los esquemas públicos de Microsoft. Comprobar metadatos no demuestra que el reporte se abra o se actualice: las cuatro pruebas de Desktop siguen siendo necesarias.

Si cambia la carga del DW, recalcular la referencia SQL; estos totales corresponden a AdventureWorks actual. Este piloto no implica que los 15 reportes finales ya estén implementados en Power BI.
