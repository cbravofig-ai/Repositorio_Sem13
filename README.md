# T5 - Do-file automatizado en Stata (CASEN)
 
Este repositorio contiene el desarrollo de la Tarea 5 (Semana 13), donde transformé 
el do-file manual de la A5 en un script parametrizado y reutilizable. La idea 
central es que, al modificar los parámetros del encabezado, todo el análisis se 
actualice y ejecute sin errores, guardando tanto la bitácora como las tablas de 
resultados.
 
**Resultado principal:** Cada año adicional de educación se asocia a $42.246 más de
ingreso mensual, controlando por experiencia y sexo. Con solo 55 observaciones (5 a 15
por sector), el resultado debe leerse como descriptivo y no como un patrón
generalizable.
 
## Datos
 
Los datos utilizados corresponden a un subconjunto de la encuesta CASEN almacenado en:
 
`data/raw/casen_reducido.csv`
 
Incluye 60 personas, con información sobre región, sector económico, años de
educación, edad, ingreso y género. La variable `ingreso` tiene 5 valores perdidos,
por lo que los modelos usan 55 observaciones.
 
## Qué se automatizó
 
- **Macros de configuración:** todo lo que puede cambiar (archivo de datos, variable
  dependiente, controles, grupos, umbral de ingreso y rango de los tramos de educación)
  está al inicio del do-file. `local` para lo que vive solo en este do-file y `global`
  para el umbral, que podría compartirse entre do-files.
- **`foreach`** sobre una lista de variables numéricas, que reemplaza los `summarize`
  repetidos de la A5.
- **`forvalues`** que cuenta personas por tramos de educación, usando `r(N)`.
- **Un programa** (`descriptivos_grupo`) que recibe el grupo, la variable de ingreso y la
  de educación como argumentos, y se llama desde un loop para `sector`, `region` y `genero`.
- **`tempvar`** para una variable intermedia (ingreso en miles) que no queda en los datos.
- **Modelos guardados** con `estimates store` y comparados en una tabla.
- **Una regresión por sector** en un loop, guardada en una matriz `J()` y exportada a
  Excel con `putexcel`.
  
## Qué habría que editar para reutilizarlo con otros datos
 
Solo el bloque de parámetros al inicio del do-file:
 
| Macro | Qué controla |
|---|---|
| `datos` | Ruta del archivo CSV |
| `depvar` | Variable dependiente (hoy `ingreso`) |
| `educvar` | Variable de educación (hoy `educ`) |
| `numericas` | Variables a describir |
| `controles` | Controles de los modelos |
| `grupos` | Variables categóricas para el programa |
| `sectorvar` | Variable por la que se hacen las regresiones separadas |
| `tramo_ini`, `tramo_fin`, `tramo_paso` | Rango y ancho de los tramos de educación |
| `umbral` (global) | Umbral de ingreso para el conteo |
 
Si los datos nuevos no tienen la misma estructura, también habría que revisar las
definiciones de `experiencia` y `mujer` en la sección de preparación de datos.
 
## Cómo correrlo
 
1. Abrir Stata (probado en Stata/SE 18.0) y ubicarse en la carpeta del proyecto con
   `cd "ruta/a/Repositorio_Sem13"`.
2. Ejecutar el do-file completo desde el inicio: `do scripts/tarea_t5.do`.
3. Revisar el resultado en `output/tarea_t5.log` y `output/tarea_t5_por_sector.xlsx`.

## Estructura
 
```text
Repositorio_Sem13/
├── data/
│   ├── raw/
│   │   └── casen_reducido.csv
│   └── processed/
│       └── casen_limpio.dta
├── scripts/
│   ├── semana13_sesion1_guion.do
│   ├── semana13_sesion2_guion.do
│   └── tarea_t5.do
├── output/
│   ├── tarea_t5.log
│   ├── tarea_t5_por_sector.xlsx
│   ├── s13_modelos.rtf
│   └── s13_por_sector.xlsx
├── README.md
└── .gitattributes
```
 
**Nota**: El desarrollo de la T5 se encuentra en el script `scripts/tarea_t5.do`, con su
bitácora en `output/tarea_t5.log` y su exportación en `output/tarea_t5_por_sector.xlsx`.
Cualquier otro archivo dentro de `scripts/` y `output/` corresponde a material de apoyo
utilizado durante las sesiones de clase, al igual que los datos procesados en la carpeta
`data/processed`.
 
## Autor
 
Camila Bravo Figueroa — noviembre 2026
 
## Declaración de autoría y uso de IA
 
- Herramienta utilizada: Claude Sonnet 5.5
- Para qué la usé: Como apoyo puntual de revisión para contrastar mi avance con 
  la pauta de la T5, en lo cual me propuso código para corregir algunos puntos 
  (macros de tramos, educación y sector, y el programa con argumentos). Resolvió 
  dudas específicas de sintaxis en Stata (como las opciones de `log using` y el 
  formato del `display`) y apoyarme en la comprensión de las líneas de código. 
  Finalmente, me apoyó en la redacción de este README, específicamente en la 
  sección de la edición para reutilizar el do-file.
- Qué hice yo: Escribí la primera versión completa de `scripts/tarea_t5.do` (macros
  iniciales, loops, programa, `tempvar`, modelos, matriz y `putexcel`), la corrí en
  Stata/SE 18.0, revisé y apliqué los cambios sugeridos, volví a correr el
  do-file, generé el `.log` y el Excel, y verifiqué que las cifras de mi
  interpretación coincidieran con el log.
- Verificación: confirmo que entiendo y puedo explicar todo lo que entrego.