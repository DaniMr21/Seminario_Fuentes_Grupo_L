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


#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#Parte 3

library(tidyverse)
library(janitor)
library(jsonlite)
library(stringr)

# 1. LEER EL JSON COMO DATA FRAME (sin tidyjson, sin spread_all)
dioxidocarbono_df <- jsonlite::fromJSON(
  "INPUT/DATA/CO2.json",
  simplifyDataFrame = TRUE,   # lo aplana a data.frame directamente
  flatten = TRUE              # por si hay listas anidadas sencillas
) %>%
  as_tibble() %>%
  clean_names()

glimpse(dioxidocarbono_df)   # aquí deberías ver muchas filas y ~13–19 columnas

# 2. TABLA CO2_limpio (país-año)
CO2_limpio <- dioxidocarbono_df %>%
  transmute(
    country_raw = str_trim(country_name),
    year        = as.integer(year),
    co2_kt      = as.numeric(co2_emissions_kt)
  ) %>%
  mutate(
    country = recode(
      country_raw,
      "Turkey"              = "Türkiye",
      "Czech Republic"      = "Czechia",
      "Russian Federation"  = "Russia",
      "Republic of Moldova" = "Moldova",
      "UK"                  = "United Kingdom",
      "Great Britain"       = "United Kingdom"
    )
  ) %>%
  group_by(country, year) %>%
  summarise(
    co2_kt = sum(co2_kt, na.rm = TRUE),
    .groups = "drop"
  )

# 3. PANEL CO2 + FERTILIDAD (país–año)
CO2_fert_panel <- CO2_limpio %>%
  inner_join(fert_xwalk, by = c("country", "year"))

# 4. RESUMEN POR PAÍS
CO2_resumen_pais <- CO2_limpio %>%
  group_by(country) %>%
  summarise(
    n_years_co2   = n_distinct(year),
    year_min_co2  = min(year, na.rm = TRUE),
    year_max_co2  = max(year, na.rm = TRUE),
    co2_kt_mean   = mean(co2_kt, na.rm = TRUE),
    co2_kt_total  = sum(co2_kt, na.rm = TRUE),
    .groups = "drop"
  )

CO2_fert_resumen_pais <- CO2_resumen_pais %>%
  full_join(fert_resumen_nombres, by = "country") %>%
  arrange(country)

View(CO2_fert_resumen_pais)

#-----------------grafico

library(forcats)   # para reordenar factores

co2_lolli <- CO2_fert_resumen_pais %>%
  filter(!is.na(co2_kt_mean),
         !is.na(tfr_mean))

ggplot(co2_lolli,
       aes(x = co2_kt_mean,
           y = fct_reorder(country, co2_kt_mean))) +
  # palito
  geom_segment(aes(x = 0,
                   xend = co2_kt_mean,
                   y = fct_reorder(country, co2_kt_mean),
                   yend = fct_reorder(country, co2_kt_mean)),
               linewidth = 0.6,
               alpha = 0.6) +
  # punto, coloreado por TFR
  geom_point(aes(color = tfr_mean,
                 size  = tfr_mean),
             alpha = 0.9) +
  scale_size_continuous(name = "TFR medio") +
  scale_color_viridis_c(name = "TFR medio", option = "C") +
  labs(
    title    = "Ranking de emisiones medias de CO2 y fertilidad en Europa",
    subtitle = "Línea = emisiones medias de CO2 (kt) | Color/tamaño = TFR medio",
    x        = "CO₂ medio (kt, total país)",
    y        = NULL
  ) +
  theme_minimal(base_size = 11) +
  theme(
    panel.grid.major.y = element_blank(),
    panel.grid.minor   = element_blank(),
    legend.position    = "right",
    plot.title         = element_text(face = "bold")
  )

#----- grafico bacano

co2_fert_anim <- CO2_fert_panel %>%
  filter(!is.na(co2_kt),
         !is.na(tfr))

reg_stats <- co2_fert_anim %>%
  group_by(year) %>%
  summarise(
    n    = n(),
    beta = coef(lm(tfr ~ co2_kt))[2],
    r2   = summary(lm(tfr ~ co2_kt))$r.squared,
    .groups = "drop"
  )


library(gganimate)

p_anim <- ggplot(co2_fert_anim,
                 aes(x = co2_kt,
                     y = tfr)) +
  # puntos por país
  geom_point(aes(color = country),
             alpha = 0.7,
             size = 2,
             show.legend = FALSE) +
  # nombres de algunos países (opcionales: quita si molesta)
  ggrepel::geom_text_repel(
    data = ~ dplyr::filter(.x, co2_kt == max(co2_kt) | tfr == max(tfr)),
    aes(label = country),
    size = 3,
    max.overlaps = 30,
    show.legend = FALSE
  ) +
  # recta de regresión por año
  geom_smooth(method = "lm",
              se = TRUE,
              linetype = "dashed",
              color = "white") +
  # texto con stats por año (beta, R², n)
  geom_text(
    data = reg_stats,
    aes(x = -Inf, y = Inf,
        label = sprintf("β₁ = %.3f   R² = %.2f   n = %d", beta, r2, n)),
    hjust = -0.05,
    vjust = 1.2,
    size = 3.2,
    inherit.aes = FALSE
  ) +
  scale_x_continuous(labels = scales::comma) +
  labs(
    title = "Relación entre emisiones de CO₂ y fertilidad en Europa",
    subtitle = "Año: {frame_time}",
    x = "CO₂ total del país (kt)",
    y = "Tasa global de fecundidad (TFR)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title       = element_text(face = "bold")
  ) +
  transition_time(year) +
  ease_aes("linear")

# Ver la animación en el viewer
anim <- animate(p_anim,
                nframes = 150,
                fps = 10,
                renderer = gifski_renderer())

anim



