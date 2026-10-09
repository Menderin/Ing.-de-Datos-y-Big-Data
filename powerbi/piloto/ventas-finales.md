# Reportes finales de ventas

Las páginas V1–V5 forman parte de `PilotoVentas.pbip`, junto con clientes y producción. Mantienen los bloques aprobados, con cabecera verde oscuro, fondo verde muy claro y acentos verdes. No se requiere volver a ejecutar el ETL: se importan columnas y dimensiones que ya existen en el DW.

| Página | Pregunta principal | Visualizaciones |
| --- | --- | --- |
| V1 · Panorama de ventas | ¿Cuánto vendemos, qué margen estimado queda y cómo evoluciona el negocio? | Líneas mensuales de venta/costo/margen, anillo por canal, detalle mensual. |
| V2 · Productos y mezcla comercial | ¿Qué productos generan más venta y cómo se distribuye entre categorías? | Top 10 por venta neta, columnas con niveles categoría/subcategoría/producto, detalle de unidades, precio neto y margen. |
| V3 · Mercados y territorios | ¿Qué mercados concentran las ventas y cómo evolucionan? | Columnas mensuales apiladas por grupo, barras con niveles grupo/país/territorio, detalle territorial. |
| V4 · Desempeño de vendedores | ¿Qué vendedores aportan venta y cuál es el tamaño de sus operaciones? | Ranking de vendedores, tendencia mensual y detalle de órdenes, compradores, ticket y margen estimado. |
| V5 · Descuentos y ofertas | ¿Qué importe se descuenta y cómo se llega de venta bruta a neta? | Cascada con total final automático, anillo con/sin descuento aplicado y detalle por oferta registrada. |

## Reglas de interpretación

- Fecha de venta: `OrderDateKey`. El calendario puede contener períodos sin actividad; los filtros de estas páginas muestran opciones con ventas. Si una combinación queda vacía, la cabecera informa «Sin ventas para la selección»; no se inventan importes.
- Venta neta = `LineTotal`, sin impuestos ni flete. Costo y margen se basan en el costo estándar vigente, no en costo histórico ni utilidad neta. No se comparan años parciales como si fueran completos.
- V2 recalcula el top 10 sobre los productos seleccionados, ordenando por venta neta y resolviendo empates por clave. No es ranking de clientes ni de producción.
- V3 utiliza el territorio de la operación, no el domicilio del comprador. Los compradores distintos no son sumables entre territorios. País se muestra como código de la dimensión.
- V4 excluye la clave de vendedor 0. No se muestran cuotas, metas, bonus ni comisiones actuales como si fueran históricas. Las ventas sin vendedor permanecen en los otros reportes. Filtrar territorio significa territorio de venta, no asignación actual del vendedor.
- V5 distingue `UnitPriceDiscount > 0` (descuento aplicado) de `DimSpecialOffer[Type]` (oferta registrada). Las ofertas por volumen pueden registrar líneas sin descuento. La tasa es descuento monetario / venta bruta, no promedio de porcentajes por línea.
- La cascada suma venta bruta, descuento negativo y ajuste de redondeo. El total automático final corresponde a venta neta; no se añade una segunda venta neta como incremento. Si el ajuste es cero, no se dibuja ese paso.
- `PuenteVenta` es una tabla auxiliar desconectada de tres pasos, no una tabla de hechos del DW. No participa en las relaciones analíticas.

## Validaciones realizadas

- Referencias, límites del lienzo, ausencia de solapamientos, relaciones unidireccionales y tipos de visual nativos.
- Deserialización del modelo con las bibliotecas de Power BI y validación de los esquemas JSON oficiales de Microsoft.
- Consultas SQL de lectura en `database/reports/07_validar_ventas_finales.sql`: 121.317 líneas, 31.465 órdenes, 266 productos con venta; 17 vendedores con 3.806 órdenes y venta 80.487.704,179188. Cero claves huérfanas de vendedor/oferta y cero fechas de venta fuera del calendario.
- Conciliación: venta bruta 110.373.889,313400; descuento 527.507,9262; ajuste 0,012688; venta neta 109.846.381,399888. Las cifras son referencia de esta carga, no restricciones para otra fuente.
- Prueba DAX temporal de lectura en el modelo abierto: top 10 de V2 coincide con SQL; 266 productos, 10 territorios y precio neto por unidad 399,566342. Cambiar a marzo de 2012 y categoría Bikes recalcula el top; seleccionar 2015 deja los importes sin actividad. No se alteró el modelo abierto.

## Revisión en Desktop

1. Guardar cambios manuales del proyecto abierto en una copia si se desea conservarlos.
2. Cerrar y reabrir `PilotoVentas.pbip`. No guardar encima la versión anterior abierta.
3. Pulsar **Actualizar** para importar vendedores, ofertas y las nuevas columnas de ventas.
4. Revisar V1–V5 sin filtros y con combinaciones restrictivas. Ejecutar `comprobar_ventas.dax` para contrastar con SQL.
5. Probar las flechas de Drill Down de V2 (segundo gráfico) y V3 (segundo gráfico). Los niveles están configurados en el visual; su interacción efectiva debe verificarse en Desktop, no se da por comprobada por existir el JSON.

Los nuevos visuales y las medidas que dependen de las nuevas importaciones todavía requieren apertura, actualización y revisión en Desktop. La validación estructural/SQL no sustituye esa prueba.
