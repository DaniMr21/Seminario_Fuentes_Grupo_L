# Acceso a los datos:

library(tidyverse)
library(readr)


aire <- read_delim("INPUT/DATA/DataExtract.csv", 
                      delim = ",", escape_double = FALSE, trim_ws = TRUE)

fertilidad <- read_delim("INPUT/DATA/Fertilidad.csv", 
                         delim = ",", escape_double = FALSE, trim_ws = TRUE)

modelos <- read_delim("INPUT/DATA/Models and objetive.csv", 
                         delim = ",", escape_double = FALSE, trim_ws = TRUE)

#-------------------------------------------------------------------------------

library(janitor)

aire       <- clean_names(aire)
fertilidad <- clean_names(fertilidad)

#Fertilidad: elegir anual y dejar (country, year, tfr)
fert <- fertilidad |>
  filter(freq == "A") |>
  transmute(
    country = geo,
    year    = as.integer(time_period),
    tfr     = as.numeric(obs_value)
  )

View(aire)
View(fert)

#-------------------------------------------------------------------------------

# Conteo de filas en 'aire' por país y año
aire_conteo <- aire |>
  count(country, year, name = "n_obs_aire") |>
  arrange(country, year)

print(head(aire_conteo, 20))
write_csv(aire_conteo, "OUTPUT/DATA/aire_conteo_country_year.csv")

# Resumen de fertilidad por país
fert_resumen <- fert |>
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

print(head(fert_resumen, 20))
write_csv(fert_resumen, "OUTPUT/DATA/fert_resumen_por_pais.csv")

# Conteo por paises de Air Polluant
if ("air_pollutant" %in% names(aire)) {
  aire_poll <- aire |>
    count(country, year, air_pollutant, name = "n_obs") |>
    arrange(country, year, air_pollutant)
  print(head(aire_poll, 20))
  write_csv(aire_poll, "OUTPUT/DATA/aire_conteo_country_year_pollutant.csv")
}




