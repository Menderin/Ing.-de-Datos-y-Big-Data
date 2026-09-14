# Informe Técnico - Entrega 1 (LaTeX)

Este directorio contiene el código fuente completo en LaTeX del **Informe Técnico de la Entrega 1** para la asignatura **Ingeniería de Datos y Big Data** (Universidad Católica del Norte, Sede Coquimbo).

## Estructura del directorio

```text
informe/
├── main.tex           # Documento principal en LaTeX (completo y autónomo)
├── figuras/           # Diagramas y evidencias gráficas incorporadas
│   ├── arquitectura_propuesta.png
│   ├── ssms_tablas.png
│   ├── modelo_relacional.png
│   ├── mockup_clientes.png
│   ├── mockup_produccion.png
│   └── mockup_ventas.png
└── README.md          # Instrucciones de compilación
```

## Instrucciones de Compilación

### Opción 1: Overleaf (Recomendada)
1. Comprimir la carpeta `informe/` en un archivo `.zip`.
2. Crear un nuevo proyecto en [Overleaf](https://www.overleaf.com) seleccionando **Upload Project**.
3. Compilar con el motor por defecto (**pdfLaTeX** o **XeLaTeX**).

### Opción 2: Compilación local en Linux / Windows
Si dispones de una distribución de TeX (TeX Live, MiKTeX, MacTeX o Tectonic):

```bash
cd informe
pdflatex main.tex
pdflatex main.tex # Segunda pasada para actualizar índice y referencias
```

O usando `latexmk`:

```bash
latexmk -pdf main.tex
```

O usando `tectonic`:

```bash
tectonic main.tex
```
