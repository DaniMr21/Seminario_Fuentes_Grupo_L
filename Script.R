library(tidyverse)
library(readr)
library(janitor)
library(stringr)

library(ggplot2)
library(ggrepel)

#-------------------------------------------------------------------------------
# Lectura

aire <- read_delim(
  "INPUT/DATA/DataExtract.csv",
  delim = ",", escape_double = FALSE, trim_ws = TRUE
)

fertilidad <- read_delim(
  "INPUT/DATA/Fertilidad.csv",
  delim = ",", escape_double = FALSE, trim_ws = TRUE
)

# (Opcional; no se usa abajo, pero lo leo por si lo necesitas)
modelos <- read_delim(
  "INPUT/DATA/Models and objetive.csv",
  delim = ",", escape_double = FALSE, trim_ws = TRUE
)

#-------------------------------------------------------------------------------
# Limpieza básica

aire       <- clean_names(aire)
fertilidad <- clean_names(fertilidad)


#-------------------------------------------------------------------------------
# FERTILIDAD (Eurostat): anual con códigos -> nombres país

# Mantener 'geo' como código y luego mapear a 'country'
fert_codes <- fertilidad |>
  filter(freq == "A") |>
  transmute(
    geo  = geo,                         # código Eurostat
    year = as.integer(time_period),
    tfr  = as.numeric(obs_value)
  )

# Mapeo de códigos Eurostat -> nombre país
fert_xwalk <- fert_codes |>
  mutate(country = case_when(
    geo == "AD" ~ "Andorra",
    geo == "AL" ~ "Albania",
    geo == "AM" ~ "Armenia",
    geo == "AT" ~ "Austria",
    geo == "AZ" ~ "Azerbaijan",
    geo == "BA" ~ "Bosnia and Herzegovina",
    geo == "BE" ~ "Belgium",
    geo == "BG" ~ "Bulgaria",
    geo == "BY" ~ "Belarus",
    geo == "CH" ~ "Switzerland",
    geo == "CY" ~ "Cyprus",
    geo == "CZ" ~ "Czechia",                  # usa "Czech Republic" si así sale en 'aire'
    geo == "DE" ~ "Germany",
    geo == "DK" ~ "Denmark",
    geo == "EE" ~ "Estonia",
    geo == "EL" ~ "Greece",                   # EL = Greece
    geo == "ES" ~ "Spain",
    geo == "FI" ~ "Finland",
    geo == "FR" ~ "France",
    geo == "GE" ~ "Georgia",
    geo == "GI" ~ "Gibraltar",
    geo == "HR" ~ "Croatia",
    geo == "HU" ~ "Hungary",
    geo == "IE" ~ "Ireland",
    geo == "IS" ~ "Iceland",
    geo == "IT" ~ "Italy",
    geo == "LI" ~ "Liechtenstein",
    geo == "LT" ~ "Lithuania",
    geo == "LU" ~ "Luxembourg",
    geo == "LV" ~ "Latvia",
    geo == "MC" ~ "Monaco",
    geo == "MD" ~ "Moldova",
    geo == "ME" ~ "Montenegro",
    geo == "MK" ~ "North Macedonia",
    geo == "MT" ~ "Malta",
    geo == "NL" ~ "Netherlands",
    geo == "NO" ~ "Norway",
    geo == "PL" ~ "Poland",
    geo == "PT" ~ "Portugal",
    geo == "RO" ~ "Romania",
    geo == "RS" ~ "Serbia",
    geo == "RU" ~ "Russia",
    geo == "SE" ~ "Sweden",
    geo == "SI" ~ "Slovenia",
    geo == "SK" ~ "Slovakia",
    geo == "SM" ~ "San Marino",
    geo == "TR" ~ "Türkiye",    # si 'aire' usa "Turkey", abajo lo homogeneizamos
    geo == "UA" ~ "Ukraine",
    geo == "UK" ~ "United Kingdom",
    geo == "VA" ~ "Vatican City",
    geo == "XK" ~ "Kosovo",
    # Agregados (no países) -> fuera del join
    geo %in% c("EU27_2020","EU27","EU28","EA19","EFTA") ~ NA_character_
  )) |>
  filter(!is.na(country)) |>
  select(country, year, tfr)

#-------------------------------------------------------------------------------
# AIRE: conteo por país-año
# Normalizo nombres y tipos; además, homogeneizo algunos alias típicos
aire_conteo <- aire |>
  mutate(
    country = str_trim(country),
    year    = as.integer(year),
    # Homogeneización de alias frecuentes (solo se aplica si existen)
    country = recode(country,
                     "Turkey" = "Türkiye",
                     "Czech Republic" = "Czechia",
                     "Russian Federation" = "Russia",
                     "Republic of Moldova" = "Moldova",
                     "UK" = "United Kingdom",
                     "Great Britain" = "United Kingdom"
    )
  ) |>
  count(country, year, name = "n_obs_aire") |>
  arrange(country, year)

write_csv(aire_conteo, "OUTPUT/DATA/aire_conteo_country_year.csv")

#-------------------------------------------------------------------------------
# Resumen de fertilidad por país (nombres ya homogeneizados)

fert_resumen_nombres <- fert_xwalk |>
  group_by(country) |>
  summarise(
    n_years  = n(),
    year_min = min(year, na.rm = TRUE),
    year_max = max(year, na.rm = TRUE),
    tfr_mean = mean(tfr, na.rm = TRUE),
    tfr_min  = min(tfr, na.rm = TRUE),
    tfr_max  = max(tfr, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(country)

write_csv(fert_resumen_nombres, "OUTPUT/DATA/fert_resumen_por_pais.csv")

#-------------------------------------------------------------------------------
# JOINS SOLICITADOS

# A) Panel país–año con resumen de fertilidad adjunto (join por country)
panel_aire_year_con_fert <- aire_conteo |>
  left_join(fert_resumen_nombres, by = "country")

write_csv(panel_aire_year_con_fert,
          "OUTPUT/DATA/panel_aire_year_con_fert_resumen.csv")

# B) Resumen por país: agregamos aire y fertilidad
aire_resumen_pais <- aire_conteo |>
  group_by(country) |>
  summarise(
    n_years_aire     = n_distinct(year),
    year_min_aire    = min(year, na.rm = TRUE),
    year_max_aire    = max(year, na.rm = TRUE),
    total_obs_aire   = sum(n_obs_aire, na.rm = TRUE),
    avg_obs_por_year = mean(n_obs_aire, na.rm = TRUE),
    .groups = "drop"
  )

resumen_aire_fert_pais <- aire_resumen_pais |>
  full_join(fert_resumen_nombres, by = "country") |>
  arrange(country)

write_csv(resumen_aire_fert_pais,
          "OUTPUT/DATA/resumen_aire_fert_pais.csv")

# C) Promedios de TFR usando solo años que existen en 'aire_conteo' (solapamiento)
fert_resumen_overlap <- fert_xwalk |>
  semi_join(aire_conteo |> distinct(country, year), by = c("country","year")) |>
  group_by(country) |>
  summarise(
    n_years_ovlp  = n(),
    year_min_ovlp = min(year, na.rm = TRUE),
    year_max_ovlp = max(year, na.rm = TRUE),
    tfr_mean_ovlp = mean(tfr, na.rm = TRUE),
    .groups = "drop"
  )

resumen_aire_fert_ovlp <- aire_resumen_pais |>
  full_join(fert_resumen_overlap, by = "country") |>
  arrange(country)

write_csv(resumen_aire_fert_ovlp,
          "OUTPUT/DATA/resumen_aire_fert_pais_overlap.csv")

# QC de nombres que no machéan

faltan_en_fert <- aire_conteo |> distinct(country) |>
  anti_join(fert_resumen_nombres |> distinct(country), by = "country")
faltan_en_aire <- fert_resumen_nombres |> distinct(country) |>
  anti_join(aire_conteo |> distinct(country), by = "country")

print(faltan_en_fert)
print(faltan_en_aire)

# Muestras rápidas
print(head(aire_conteo, 10))
print(head(fert_resumen_nombres, 10))
print(head(resumen_aire_fert_pais, 10))

#-------------------------------------------------------------------------------
#Gráfico 

resumen_aire_fert_pais %>%
  filter(!is.na(tfr_mean), !is.na(total_obs_aire)) %>%
  ggplot(aes(x = tfr_mean, y = total_obs_aire)) +
  geom_point(alpha = 0.7) +
  geom_smooth(method = "lm", se = TRUE) +
  labs(
    title = "Observaciones de aire vs TFR medio (por país)",
    x = "TFR medio",
    y = "Observaciones de aire (total)"
  ) +
  theme_minimal()

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#PA LA SEGUNDA PREGUNTA

library(readxl)

# Leer directamente desde la hoja principal
oms <- read_excel("INPUT/DATA/OMS_Datos.xlsx", sheet = "AAP_2022_city_v9")

# 1. Nos aseguramos de tener solo Europa (por si acaso)
oms_europa <- oms %>%
  filter(`WHO Region` == "European Region")

# 2. Crear variable 'country' con nombres armonizados
oms_europa_limpio <- oms_europa %>%
  mutate(
    country = str_trim(`WHO Country Name`),
    country = recode(
      country,
      "Turkey"             = "Türkiye",
      "Russian Federation" = "Russia",
      "Republic of Moldova" = "Moldova"
    )
  )

# 3. JOIN: tabla OMS (ciudad-año) + resumen de fertilidad por país
oms_europa_con_fert <- oms_europa_limpio %>%
  left_join(fert_resumen_nombres, by = "country")

# Opcional: mirar qué países de OMS no tienen fertilidad
faltan_fert_oms <- oms_europa_limpio %>%
  distinct(country) %>%
  anti_join(fert_resumen_nombres %>% distinct(country), by = "country")

faltan_fert_oms

pais_no2_fert <- oms_europa_con_fert %>%
  group_by(country) %>%
  summarise(
    no2_mean   = mean(`NO2 (μg/m3)`, na.rm = TRUE),
    no2_median = median(`NO2 (μg/m3)`, na.rm = TRUE),
    n_cities   = n_distinct(`City or Locality`),
    tfr_mean   = first(tfr_mean),   # viene del resumen de fertilidad
    .groups = "drop"
  ) %>%
  filter(!is.na(no2_mean), !is.na(tfr_mean))

library(ggplot2)
library(ggrepel)

ggplot(pais_no2_fert,
       aes(x = no2_mean,
           y = tfr_mean,
           size = n_cities)) +
  geom_point(alpha = 0.7) +
  geom_smooth(method = "lm", se = TRUE, linetype = "dashed") +
  geom_text_repel(aes(label = country),
                  size = 3,
                  max.overlaps = 30) +
  scale_size_continuous(name = "Nº de ciudades\nmonitorizadas") +
  labs(
    title = "NO₂ medio vs fertilidad media por país europeo",
    subtitle = "Tamaño del punto = nº de ciudades con datos de NO₂",
    x = "NO₂ medio (µg/m³, OMS)",
    y = "TFR medio (Eurostat)"
  ) +
  theme_minimal()
