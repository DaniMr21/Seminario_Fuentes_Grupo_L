<center>
<img src="INPUT/IMAGES/portada.png" alt="Gráfico de portada" width="70%">
</center>

# Impacto de la vigilancia del aire sobre la fertilidad en la población europea  
**Autores:** Daniel Marina de la Cal, Nerea Yi Estepar Calvo y Patricia Ibarrondo Revilla  
**Fecha:** 2025-11-24  

---

## Introducción

La fertilidad humana es sensible a condiciones ambientales que afectan tanto a la salud reproductiva como a las decisiones familiares. Entre estos factores, la **calidad del aire** puede influir mediante:

- Alteraciones hormonales  
- Inflamación sistémica  
- Estrés oxidativo  
- Percepción del riesgo ambiental  

Además, la **vigilancia de la calidad del aire** (densidad de estaciones, frecuencia de reporte, cobertura territorial) actúa como un indicador de capacidad institucional y políticas ambientales.

Este estudio examina la **relación entre vigilancia/contaminación atmosférica y fertilidad** a nivel de país en Europa, desde un enfoque **ecológico y descriptivo**.


## Objetivo general

Evaluar si la vigilancia de la calidad del aire y ciertos contaminantes atmosféricos se relacionan con la **Tasa Global de Fecundidad (TFR)** en países europeos.


## Objetivos específicos

1. **Vigilancia vs fertilidad**  
   ¿Existe asociación entre la intensidad de vigilancia del aire y la TFR?

2. **NO₂ vs fertilidad**  
   ¿Los niveles medios de NO₂ están relacionados con la TFR?

3. **CO₂ vs fertilidad**  
   ¿Existe relación (posible relación negativa) entre emisiones per cápita de CO₂ y la fertilidad?

4. **PM₂.₅ vs fertilidad**  
   ¿La proporción de observaciones dedicadas al PM₂.₅ se asocia con la TFR?


## Metodología

- Datos de **Eurostat**: TFR y población.
- Datos de **EEA (AQ e-Reporting)**: observaciones de vigilancia, estaciones, contaminantes.
- Datos de **OMS AAP 2022**: niveles urbanos de NO₂.
- Datos de **UNESCO/OWID**: emisiones de CO₂.
- Limpieza y homogeneización de nombres de países.
- Normalización por población (obs por millón; estaciones por millón).
- Modelos OLS con **errores estándar robustos (HC1)**.
- Gráficos: dispersión, barras, burbujas y animaciones.


# Resultados

## Vigilancia del aire vs fertilidad

Se esperaba una relación positiva: *más vigilancia → entornos más saludables → mayor TFR*.  

### Qué se encontró:
- No existen patrones visuales claros en los gráficos.
- La regresión lineal robusta muestra:
  - Coeficiente ≈ 0  
  - Valor p = 0.749 → **no significativo**  

### Conclusión:
**No existe asociación entre la intensidad de vigilancia y la fertilidad.**  
Hipótesis rechazada.


## NO₂ medio vs fertilidad

Se esperaba una relación negativa: *más NO₂ → menor TFR*.

### Qué se encontró:
- Gráficos extremadamente dispersos.
- Línea de regresión horizontal.
- Pearson ρ = 0.0724  
- Valor p = 0.675 → **no significativo**  

### Conclusión:
**NO₂ no predice la fertilidad media en países europeos.**  
Hipótesis rechazada.


## Emisiones de CO₂ vs fertilidad

Se esperaba que *más CO₂ (más industrialización) → menor fertilidad*.

### Qué se encontró:
- Los países de alta emisión no muestran TFR particularmente bajas.
- Animación año a año → tendencias planas.
- Pearson ρ = −0.043  
- Valor p = 0.8839 → **no significativo**  

### Conclusión:
**Las emisiones de CO₂ no explican la fertilidad europea.**  
Hipótesis rechazada.

## Importancia del PM₂.₅ en la vigilancia vs fertilidad

Se analiza la proporción de observaciones que cada país dedica al PM₂.₅.

### Qué se encontró:
- La prioridad del PM₂.₅ varía entre países, pero:
  - No existe un gradiente de TFR al aumentar la proporción de PM₂.₅.
  - Gráfico de dispersión → nube desordenada.
- Regresión robusta:
  - Pendiente positiva pero **no significativa** (p = 0.0983)

### Inclusión:
**La prioridad al PM₂.₅ no está relacionada con la fertilidad.**  
Hipótesis rechazada.


# Conclusiones finales

Tras analizar múltiples dimensiones de la calidad del aire:

- **Vigilancia total**
- **NO₂**
- **CO₂**
- **PM₂.₅**

Ninguna mostró **asociaciones estadísticamente significativas** con la TFR media a nivel país en Europa.

### Razón principal:
La **TFR europea es extremadamente homogénea** (≈ 1.55 en casi todos los países), mientras que la contaminación varía enormemente. Esta baja variación demográfica impide detectar asociaciones con indicadores ambientales agregados.

### Limitaciones:
- Estudio **ecológico** (no causal).
- Unidad de análisis = país → pierde resolución.
- No se controlan factores económicos/estructurales:
  - Políticas familiares
  - Urbanización
  - Mercado laboral
  - Edad media materna
  - Migración
  - Acceso a vivienda



# Referencias

Eurostat. (s. f.). Fertility statistics (TFR by country and year). Oficina de Estadística de la Unión Europea.

Air Quality e-Reporting (AQ e-Reporting). (2022, August 5). https://www.eea.europa.eu/en/datahub/datahubitem-view/3b390c9c-f321-490a-b25a-ae93b2ed80c1

Emisiones globales de CO2. (2025, August 18). https://data.unesco.org/explore/dataset/co2001/information/?flg=es-es

World Health Organization. (2022). Ambient Air Pollution Database (AAP 2022). WHO, Department of Environment, Climate Change and Health.

Carré, J., Gatimel, N., Moreau, J., Parinaud, J., & Léandri, R. (2017). Does air pollution play a role in infertility? A systematic review. Environmental Health, 16(1), 82.

Landrigan, P. J., Fuller, R., Acosta, N. J. R., et al. (2018). The Lancet Commission on pollution and health. The Lancet, 391(10119), 462–512.

WHO. (2021). WHO global air quality guidelines: Particulate matter (PM₂.₅ and PM₁₀), ozone, nitrogen dioxide, sulfur dioxide and carbon monoxide. World Health Organization.

