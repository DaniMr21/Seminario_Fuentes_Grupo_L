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