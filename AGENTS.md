# AGENTS.md

## 1. Contexto general del proyecto

Este repositorio corresponde al proyecto/taller de la asignatura **Ingeniería de Datos y Big Data**.

El proyecto consiste en diseñar e implementar progresivamente una plataforma de reportabilidad basada en datos de **Adventure Works / AdventureWorks Cycles**.

El flujo general esperado del proyecto es:

Fuente de datos transaccional
→ ETL
→ Data Warehouse / Base OLAP
→ Power BI

Existe una arquitectura de referencia entregada por el profesor que además incluye una capa de:

Cubos de datos / Semántica BI

Sin embargo, todavía debe confirmarse si dicha capa se utilizará realmente en nuestra implementación o si se eliminará de la arquitectura final.

No asumir que debe eliminarse hasta verificarlo en el material de `Docs/` o tener una indicación explícita del profesor.

---

## 2. Objetivo funcional

La solución completa debe ser capaz de:

1. Obtener datos desde una fuente transaccional.
2. Extraer, transformar y cargar los datos mediante un proceso ETL.
3. Almacenarlos en un repositorio analítico / Data Warehouse.
4. Consumir los datos desde Power BI.
5. Mostrar información estratégica mediante dashboards.

La solución debe considerar tres perspectivas de análisis:

- Clientes
- Procesos / Producción
- Ventas

Cada perspectiva debe contar con al menos cinco reportes.

Por lo tanto, se espera diseñar al menos:

- 5 reportes de Clientes
- 5 reportes de Producción
- 5 reportes de Ventas

Total mínimo: 15 reportes.

---

## 3. Entregas del proyecto

### Entrega 1

Fecha indicada por el profesor:

**Lunes 14 de septiembre de 2026**

Incluye:

1. Diseño de la arquitectura de la solución.
2. Diseño de los reportes solicitados.
3. Base de datos transaccional (fuente de datos) implementada.

IMPORTANTE:

En esta entrega todavía NO es necesario implementar:

- ETL.
- Data Warehouse / Base OLAP.
- Dashboards finales en Power BI.

Solo deben quedar diseñados conceptualmente cuando corresponda.

---

### Entrega 2

Incluye:

- Tareas ETL implementadas y operativas.
- Base de datos OLAP implementada y operativa.
- Diseño final de los reportes.

---

### Entrega 3

Incluye:

- Reportes implementados en Power BI.

Existe bonificación por incluir funcionalidades de Drill Down.

---

## 4. Estado actual de la Entrega 1

### 4.1 Arquitectura

Existe una arquitectura base entregada por el profesor en el PPT/PDF.

La arquitectura mostrada contiene aproximadamente:

1. Fuente de datos
   - SQL Server
   - Base transaccional / OLTP

2. ETL
   - Extracción
   - Transformación
   - Carga

3. Repositorio de datos
   - SQL Server
   - Data Warehouse
   - Modelo dimensional

4. Cubos de datos / Semántica BI
   - OLAP
   - Modelos multidimensionales
   - Agregaciones
   - Métricas

5. Visualización
   - Power BI
   - Dashboards
   - Informes

La intención actual del equipo es probablemente simplificar la arquitectura a:

AdventureWorks / SQL Server
→ ETL
→ Data Warehouse / OLAP
→ Power BI

pero NO modificar todavía definitivamente el bloque de
"Cubos de datos / Semántica BI"
sin comprobar primero las instrucciones del profesor.

---

### 4.2 Diseño de reportes

Todavía deben definirse nuestros propios diseños.

Deben existir al menos:

#### Clientes

5 reportes.

Posibles tipos de análisis, solo como ideas:

- Perfil de clientes.
- Clientes con mayores ventas.
- Distribución geográfica.
- Frecuencia de compra.
- Clientes activos/inactivos.

Estas son ideas iniciales, NO requisitos definidos por el profesor.

---

#### Producción

5 reportes.

Posibles ideas:

- Producción por producto.
- Inventario.
- Órdenes de producción.
- Eficiencia de producción.
- Productos o categorías.

Estas son ideas iniciales, NO requisitos definidos por el profesor.

---

#### Ventas

5 reportes.

Posibles ideas:

- Ventas totales.
- Ventas por territorio.
- Ventas por producto.
- Ventas por categoría.
- Rendimiento de vendedores.

Estas son ideas iniciales, NO requisitos definidos por el profesor.

Antes de cerrar estos reportes se debe explorar la base de datos AdventureWorks para conocer qué información existe realmente.

No diseñar indicadores que no puedan obtenerse razonablemente desde la fuente de datos.

---

### 4.3 Base de datos transaccional

El profesor proporcionó un archivo con extensión:

`.bak`

Todavía debe inspeccionarse el nombre exacto y su contenido.

Hipótesis actual:

El archivo `.bak` corresponde a un backup de SQL Server de una base AdventureWorks.

Esta hipótesis es muy probable, pero debe verificarse técnicamente antes de tratarla como hecho.

La intención es restaurar esta base de datos y utilizarla como:

**Fuente de datos transaccional / OLTP**

para el proyecto.

---

## 5. Entorno técnico propuesto

Se planea utilizar:

- Docker Desktop
- SQL Server
- SQL Server Management Studio (SSMS)
- Power BI Desktop
- Git
- GitHub

Para la primera entrega, Docker se utilizaría únicamente como entorno para ejecutar SQL Server.

Arquitectura local esperada:

Host Windows
└── Docker Desktop
    └── Contenedor SQL Server
        └── Base AdventureWorks restaurada desde .bak

SSMS se utilizará desde Windows para conectarse al SQL Server ejecutándose dentro de Docker.

Ejemplo conceptual:

SSMS
→ localhost:1433
→ SQL Server en Docker
→ AdventureWorks

No asumir todavía nombres de usuario, contraseñas, nombres de base, volúmenes o configuración del contenedor.

Estos deben definirse en nuestro propio proyecto.

---

## 6. Reglas sobre Docker

No copiar configuraciones Docker de otros proyectos directamente.

Si se crea un:

`docker-compose.yml`

debe construirse específicamente para este proyecto y comprenderse cada configuración utilizada.

Debe documentarse al menos:

- Imagen utilizada.
- Versión de SQL Server.
- Puerto expuesto.
- Variables de entorno.
- Volúmenes.
- Persistencia de datos.
- Ubicación del `.bak`.
- Procedimiento de restauración.

Preferir una configuración simple antes que una configuración innecesariamente compleja.

---

## 7. Repositorio de referencia externo

Existe el siguiente repositorio:

https://github.com/Charmandiox9/Ing.-Datos-y-Big-Data

Este repositorio pertenece a un amigo que realizó anteriormente el mismo taller.

### IMPORTANTE

Este repositorio es SOLO REFERENCIA.

NO:

- copiar su solución;
- copiar directamente su docker-compose;
- copiar scripts;
- copiar consultas;
- copiar diseños de reportes;
- copiar documentación;
- replicar automáticamente su estructura;
- asumir que todas sus decisiones son las correctas.

Sí puede utilizarse para:

- entender qué tipo de entregables realizó;
- comparar interpretaciones del enunciado;
- observar el nivel de profundidad esperado;
- detectar herramientas que podrían ser necesarias;
- entender aproximadamente el flujo del taller;
- resolver dudas conceptuales sobre qué pudo haber pedido el profesor.

Nuestra implementación debe desarrollarse desde cero.

---

## 8. Fuentes de verdad del proyecto

La carpeta:

`Docs/`

contendrá el material oficial de la asignatura.

Ejemplo esperado:

Docs/
├── Proyecto_Entregable_1.pdf
├── Presentaciones/
├── Material_Profesor/
└── Otros/

El contenido de `Docs/` tiene prioridad sobre:

1. Este AGENTS.md.
2. Suposiciones previas.
3. El repositorio de referencia.
4. Conocimiento general.
5. Implementaciones de otros estudiantes.

Si existe una contradicción entre este archivo y el material oficial:

**seguir el material oficial y señalar la discrepancia.**

---

## 9. Regla de trabajo con documentación

Antes de responder preguntas como:

- "¿Qué pide el profesor?"
- "¿Esto debe entregarse?"
- "¿Qué arquitectura debemos utilizar?"
- "¿Qué herramienta exige?"
- "¿Qué debe incluir la entrega?"
- "¿Cuántos reportes son?"
- "¿Hay que hacer ETL ahora?"
- "¿Debemos usar Power BI ahora?"

se debe revisar primero el material disponible en:

`Docs/`

No responder estas preguntas únicamente desde memoria si existe documentación local disponible.

Diferenciar claramente entre:

- requisito explícito;
- interpretación;
- recomendación;
- inferencia técnica;
- decisión propia del equipo.

---

## 10. Estructura inicial sugerida del repositorio

La estructura puede evolucionar.

Una estructura inicial razonable sería:

.
├── AGENTS.md
├── README.md
├── Docs/
│   ├── Proyecto_Entregable_1.pdf
│   └── ...
│
├── database/
│   ├── backup/
│   │   └── <archivo>.bak
│   └── scripts/
│
├── docker/
│   └── ...
│
├── reports/
│   ├── clientes/
│   ├── produccion/
│   └── ventas/
│
└── architecture/
    └── ...

No crear carpetas adicionales sin necesidad.

La estructura debe permanecer simple durante la Entrega 1.

---

## 11. Prioridades inmediatas

El trabajo actual debe concentrarse en la Entrega 1.

Orden recomendado:

### Paso 1
Revisar completamente el PPT/PDF del profesor ubicado en `Docs/`.

### Paso 2
Identificar el archivo `.bak` proporcionado por el profesor.

Determinar:

- nombre;
- tamaño;
- versión probable;
- nombre de base esperado;
- compatibilidad con SQL Server.

### Paso 3
Crear nuestro propio entorno SQL Server con Docker.

### Paso 4
Restaurar el `.bak`.

### Paso 5
Verificar que la base transaccional funciona.

Comprobar:

- base ONLINE;
- esquemas;
- tablas;
- relaciones;
- cantidad de datos;
- consultas simples.

### Paso 6
Explorar AdventureWorks.

Identificar especialmente información relacionada con:

- Sales
- Production
- Person
- HumanResources
- Purchasing

### Paso 7
Diseñar nuestros 15 reportes basándonos en datos que realmente existen.

### Paso 8
Construir el diagrama final de arquitectura.

### Paso 9
Preparar evidencia/documentación de la Entrega 1.

---

## 12. Qué NO hacer todavía

Mientras trabajemos en la Entrega 1, evitar implementar prematuramente:

- procesos ETL completos;
- Data Warehouse final;
- esquema estrella definitivo;
- cubos OLAP;
- modelos semánticos complejos;
- medidas DAX finales;
- dashboards completos de Power BI.

Se pueden analizar o bosquejar si ayudan al diseño, pero no son la prioridad actual.

---

## 13. Principios técnicos

### Simplicidad

Preferir la solución más simple que satisfaga el requerimiento académico.

### Reproducibilidad

La base de datos debe poder levantarse nuevamente siguiendo instrucciones documentadas.

### Persistencia

Si SQL Server funciona mediante Docker, los datos no deberían perderse simplemente al reiniciar el contenedor.

### Trazabilidad

Documentar las decisiones relevantes.

Ejemplo:

¿Por qué usamos SQL Server?
¿Por qué Docker?
¿Por qué esos reportes?
¿Por qué esa arquitectura?

### Comprensión

No introducir herramientas únicamente porque aparezcan en un proyecto de referencia.

Cada componente utilizado debe tener una razón clara.

---

## 14. Convenciones durante el desarrollo

Cuando se proponga código, configuración o arquitectura:

1. Explicar brevemente para qué sirve.
2. Evitar complejidad innecesaria.
3. No inventar requisitos.
4. Diferenciar entre obligación académica y recomendación técnica.
5. Comprobar primero `Docs/` cuando la duda dependa del enunciado.
6. Evitar copiar la solución del repositorio de referencia.
7. Mantener el trabajo alineado con la entrega actual.

---

## 15. Estado conocido del caso AdventureWorks

El caso corresponde a Adventure Works Cycles.

Es una empresa ficticia dedicada a:

- fabricación de bicicletas;
- venta de bicicletas;
- repuestos;
- accesorios.

La base incluye datos relacionados con:

- producción;
- compras;
- ventas;
- recursos humanos;
- personas/clientes.

El proyecto busca utilizar estos datos para crear una solución de Business Intelligence y reportabilidad.

---

## 16. Decisiones pendientes

Las siguientes cuestiones todavía NO están cerradas:

- versión exacta de AdventureWorks;
- contenido exacto del `.bak`;
- versión de SQL Server a utilizar;
- configuración definitiva de Docker;
- si se utilizará o eliminará la capa de Cubos/Semántica BI;
- arquitectura final;
- lista definitiva de los 15 reportes;
- diseño visual de los reportes;
- herramienta ETL para Entrega 2;
- diseño del Data Warehouse;
- esquema dimensional;
- medidas de Power BI;
- Drill Down.

No asumir estas decisiones sin analizarlas.

---

## 17. Forma de colaboración esperada

Trabajar de manera incremental.

Para tareas grandes:

1. analizar;
2. proponer;
3. discutir decisiones;
4. implementar;
5. verificar.

No implementar grandes secciones del proyecto sin explicar primero qué se está haciendo.

Cuando haya varias alternativas técnicas, presentar ventajas y desventajas antes de seleccionar una.

---

## 18. Objetivo inmediato de la próxima sesión

Comenzar por la fuente de datos.

Concretamente:

1. localizar el `.bak`;
2. revisar qué contiene;
3. preparar Docker;
4. levantar SQL Server;
5. restaurar la base;
6. conectarse desde SSMS;
7. explorar AdventureWorks.

Una vez estable la fuente de datos, pasar al diseño de los reportes.