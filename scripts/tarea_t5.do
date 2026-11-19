* =============================================================================
* T5 — Do-file automatizado (CASEN)
* Autor: Camila Bravo Figueroa      Fecha: 19-11-2026
* =============================================================================

* --- 1. Encabezado y macros de configuración ---
version 14
clear all
set more off
capture mkdir "output"
capture log close
log using "output/tarea_t5.log", replace text

* --- Parámetros (lo único que se edita) ---
local datos      "data/raw/casen_reducido.csv"
local depvar     "ingreso"
local educvar    "educ"
local numericas  "`depvar' `educvar' edad experiencia"
local controles  "educ experiencia"
local grupos     "sector region genero"
local sectorvar  "sector"
local tramo_ini  4
local tramo_fin  20
local tramo_paso 4
global umbral    = 500000

/* Usé local para que vivan solo mientras corre este do-file y se borren al 
terminar, evitando que se crucen o se sobrescriban con otros scripts. En cambio, 
usé global umbral = 500000 para poder compartir el mismo umbral de ingreso entre 
distintos do-files durante toda la sesión de Stata.*/

* --- 2. Carga y preparación de datos ---

import delimited "`datos'", clear varnames(1) encoding("utf-8")

* Experiencia potencial de Mincer
generate experiencia = max(edad - educ - 6, 0)
label variable experiencia "Experiencia potencial (años)"

* Indicadora 0/1 para sexo con etiquetas de valores
generate mujer = (genero == "F")
label variable mujer "Mujer"
label define mujer_lbl 0 "Hombre" 1 "Mujer"
label values mujer mujer_lbl

* --- 3. Loop foreach sobre variables numéricas ---

foreach v of local numericas {
    display _newline "=== Variable: `v' ==="
    summarize `v', detail
}

* --- 4. Loop forvalues con rango económico ---

forvalues t = `tramo_ini'(`tramo_paso')`tramo_fin' {
    quietly count if `educvar' >= `t' & `educvar' < `t' + `tramo_paso'
    display "Educación de `t' a " `t' + `tramo_paso' - 1 " años: " r(N) " personas"
}

* --- 5. Programa reutilizable + loop ---

capture program drop descriptivos_grupo
program define descriptivos_grupo
    display _newline "=== `2' por `1' ==="
    tabulate `1'
    tabstat `2' `3', by(`1') statistics(mean sd n)
end

foreach g of local grupos {
    descriptivos_grupo `g' `depvar' `educvar'
}

* --- 6. Variable temporal (tempvar) ---

tempvar ing_miles
generate `ing_miles' = `depvar' / 1000
summarize `ing_miles'

/* Usamos tempvar porque Stata le asigna un nombre interno único que nunca choca 
ni sobrescribe una variable que ya exista en la base de datos. Además, se borra 
automáticamente al terminar el do-file (incluso si el código se detiene por un 
error), evitando dejar variables auxiliares sueltas en la base.
*/

* --- 7. Manejo de missing con el umbral ---

count if `depvar' > $umbral & !missing(`depvar')

/* En Stata, el valor perdido (.) se evalúa como si fuera infinito positivo (mayor
que cualquier número). Si filtramos solo por `depvar' > $umbral sin excluir los
faltantes, Stata incluiría por error a las personas sin dato de ingreso como si
superaran el umbral, inflando el conteo real.
*/

* --- 8. Modelos guardados y comparados ---

quietly regress `depvar' `controles'
estimates store m1
quietly regress `depvar' `controles' mujer
estimates store m2

estimates table m1 m2, b(%9.0f) se stats(N r2) stfmt(%5.3f)

estimates restore m2
display "Coeficiente de educación (m2): $" %9.0fc _b[`educvar'] " por año adicional"

* --- 9. Regresión por sector, matriz J() y exportación a Excel ---

levelsof `sectorvar', local(sectores)
local k : word count `sectores'
matrix R = J(`k', 3, .)

local i = 1
foreach s of local sectores {
    quietly regress `depvar' `educvar' if `sectorvar' == "`s'"
    matrix R[`i', 1] = _b[`educvar']
    matrix R[`i', 2] = _se[`educvar']
    matrix R[`i', 3] = e(N)
    local i = `i' + 1
}

matrix colnames R = beta_educ ee n
matrix rownames R = `sectores'
matrix list R, format(%9.0f)

putexcel set "output/tarea_t5_por_sector.xlsx", replace
putexcel A1 = ("Sector") B1 = ("Beta educ") C1 = ("Error est.") D1 = ("n")
putexcel B2 = matrix(R)

local fila = 2
foreach s of local sectores {
    putexcel A`fila' = ("`s'")
    local fila = `fila' + 1
}

* --- 10. Cierre e interpretación ---

log close

/* En m2, cada año adicional de educación se asocia a $42.246 más de ingreso
mensual, controlando por experiencia y sexo (sin implicar causalidad). Entre m1 y
m2 el coeficiente casi no cambia ($42.019 a $42.246) y el R2 sube de 0,458 a 0,475
(N = 55); solo se agrega mujer, con coeficiente de -$55.686 (error estándar de
$43.302), que no se distingue de cero. Por sector, los coeficientes son positivos
pero poco precisos (n entre 5 en Construcción y 15 en Servicios). La principal
limitación es la muestra pequeña (55 obs.) y posibles variables omitidas.
*/
