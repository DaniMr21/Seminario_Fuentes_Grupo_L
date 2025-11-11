# Acceso a los datos:

library(tidyverse)
library(readr)


aire <- read_delim("INPUT/DATA/DataExtract.csv", 
                      delim = ",", escape_double = FALSE, trim_ws = TRUE)

fertilidad <- read_delim("INPUT/DATA/Fertilidad.csv", 
                         delim = ",", escape_double = FALSE, trim_ws = TRUE)

modelos <- read_delim("INPUT/DATA/Models and objetive.csv", 
                         delim = ",", escape_double = FALSE, trim_ws = TRUE)

View(aire)
View(fertilidad)

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
