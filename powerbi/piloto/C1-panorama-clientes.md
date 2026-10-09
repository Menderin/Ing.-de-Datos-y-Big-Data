# C1 - Panorama de clientes

Página implementada en el mismo `PilotoVentas.pbip`, junto a V1. Se mantuvo el nombre del archivo para no duplicar el proyecto ni romper los accesos existentes.

## Contenido

La presentación está organizada por bloques: cabecera azul oscuro con el aviso de alcance, filtros con fondo azul claro, cuatro tarjetas blancas de indicadores, dos paneles de análisis y un panel de detalle. El lienzo usa un fondo gris claro, bordes suaves y espacios entre secciones. La altura se amplió a 1024 para que la tabla no quede pegada a los gráficos. No se modificaron medidas ni filtros por este ajuste visual.

- Cuatro tarjetas: registrados, compradores del periodo, sin compras en el periodo y porcentaje de compradores.
- Composición de la cartera por personas y tiendas.
- Compradores y clientes sin compra por territorio del cliente.
- Tabla: ID, nombre, tipo, territorio, órdenes y primera compra del periodo seleccionado.
- Filtros desplegables: año, mes, tipo de cliente y territorio del cliente.
- Aviso sobre el alcance de los filtros y selecciones sin compras.

## Reglas

`DimCustomer` filtra a `FactSales` mediante `CustomerKey`, en una relación activa varios-a-uno y unidireccional. No se conecta `DimCustomer` a `DimTerritory`: C1 utiliza el territorio del cliente; V1 utiliza el territorio de la venta.

Registrados cuenta filas de la dimensión y no cambia al seleccionar fechas. Compradores cuenta clientes distintos de ventas en el contexto seleccionado. Sin compra es registrados menos compradores. Un cliente sin compras no equivale automáticamente a un cliente inactivo.

La composición por tipo representa la cartera, no las ventas. La fecha de primera compra es la primera compra dentro del periodo seleccionado, no una fecha de alta. Los clientes sin órdenes se conservan en la tabla con cero órdenes y fecha vacía. El ID evita mezclar clientes con el mismo nombre.

A diferencia de V1, los filtros de C1 no excluyen opciones por no tener ventas: es necesario poder analizar la cartera sin compras, incluidos 2010 y 2015. El calendario del DW no se modificó.

## Resultados SQL de referencia

| Selección | Registrados | Compradores | Sin compra | Porcentaje |
| --- | ---: | ---: | ---: | ---: |
| Sin filtros | 19.820 | 19.119 | 701 | 96,46 % |
| Año 2013 | 19.820 | 11.095 | 8.725 | 55,98 % |
| Año 2010 | 19.820 | 0 | 19.820 | 0,00 % |
| Personas, sin fecha | 18.484 | 18.484 | 0 | 100,00 % |
| Tiendas, sin fecha | 1.336 | 635 | 701 | 47,53 % |
| Southwest, sin fecha | 4.696 | 4.565 | 131 | 97,21 % |
| 2013 + tiendas + Southwest | 246 | 99 | 147 | 40,24 % |

Estas cifras corresponden a la carga actual. No se deben exigir a otra fuente del profesor.

## Abrir y verificar

1. Cerrar el proyecto anterior sin guardar cambios sobre esta definición si no hay trabajo propio pendiente. Si hiciste cambios propios, guardarlos en una copia antes de reabrir.
2. Abrir `PilotoVentas.pbip` y pulsar Actualizar: se añadió `DimCustomer` y una columna a `FactSales`.
3. Revisar la pestaña **C1 - Panorama de clientes**, que ahora es la página inicial.
4. Limpiar todos los filtros antes de probar cada fila de la tabla anterior. No usar una selección de gráfico adicional sin tenerla en cuenta.
5. Ejecutar [comprobar_clientes.dax](comprobar_clientes.dax) en la Vista de consultas DAX.
6. Comprobar que V1 sigue mostrando los mismos totales sin filtros.

La definición y las referencias del proyecto pasaron las comprobaciones locales y de esquemas JSON; el SQL verificó siete escenarios y la integridad de la unión de clientes. La apertura, los gráficos y DAX de C1 aún deben comprobarse en Power BI Desktop.

SQL reproducible desde la raíz del repositorio:

```powershell
.\database\etl\consultar_control.ps1 -SqlFile database/reports/04_panorama_clientes.sql
```
