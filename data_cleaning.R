# Data Incubator Project
## Predicting accidents in highways in Brazil

library(tidyverse)
library(lubridate)
library(ggmap)
library(maps)
library(mapdata)
library(raster)
library(maptools)
library(gridExtra)
library(broom)

# Loading and preparing data ---------------------------------------------------

## looking at data from 2007 - 2017
#url.2007 <- "http://www1.prf.gov.br/arquivos/index.php/s/EzXry9IsLLJosSg/download"
#url.2008 <- "http://www1.prf.gov.br/arquivos/index.php/s/WEP8Pu4sA64V7f6/download"
#url.2009 <- "http://www1.prf.gov.br/arquivos/index.php/s/QZXR9LVr4lynqbA/download"
#url.2010 <- "http://www1.prf.gov.br/arquivos/index.php/s/tx9oSTOPYrSqDhb/download"
#url.2011 <- "http://www1.prf.gov.br/arquivos/index.php/s/mBWHzsujvZ7nZbe/download"
#url.2012 <- "http://www1.prf.gov.br/arquivos/index.php/s/VIeiSbpxRxan33L/download"
#url.2013 <- "http://www1.prf.gov.br/arquivos/index.php/s/ZBJgHd4fmYV2Hhr/download"
#url.2014 <- "http://www1.prf.gov.br/arquivos/index.php/s/1QYIZKqjcUDOrXm/download"
#url.2015 <- "http://www1.prf.gov.br/arquivos/index.php/s/qqAsQep7J8FzpR5/download"
#url.2016 <- "http://www1.prf.gov.br/arquivos/index.php/s/AhSKXYgrFtfXMK3/download"
#url.2017 <- "http://www1.prf.gov.br/arquivos/index.php/s/nqvFu7xEF6HhbAq/download"

files <- dir(pattern = "*.csv")
files

# from 2007 to 2011
data.some <- files[1:5] %>% 
    purrr::map(read_csv2) %>% 
    bind_rows() %>% 
    mutate_at(vars(data_inversa), funs(as.character(.))) %>% 
    mutate(year = as.numeric(str_sub(data_inversa, start= -4))) %>% 
    mutate(month = as.numeric(gsub(".*[/]([^.]+)[/].*", "\\1", data_inversa))) %>% 
    mutate(day = as.numeric(gsub("/.*","", data_inversa))) %>% 
    dplyr::select(-data_inversa, -horario) %>% 
    mutate_at(vars(id, br, km, pessoas, mortos, feridos_leves, feridos_graves,
                   ilesos, ignorados, feridos, veiculos), funs(as.integer(.))) %>% 
    mutate_at(vars(municipio), funs(as.character(.))) %>% 
    mutate_at(vars(uf, dia_semana), funs(as.factor(.))) 

# from 2012 to 2015   
data.rest <- files[6:9] %>%
    purrr::map(read_csv2) %>% 
    bind_rows() %>%
    #mutate(time = as_datetime(paste(data_inversa, horario, sep = " "))) %>% 
    mutate(year = year(data_inversa)) %>% 
    mutate(month = month(data_inversa)) %>% 
    mutate(day = day(data_inversa)) %>% 
    dplyr::select(-data_inversa, -horario) %>% 
    mutate_at(vars(id, br, km, pessoas, mortos, feridos_leves, feridos_graves,
                   ilesos, ignorados, feridos, veiculos), funs(as.integer(.))) %>% 
    mutate_at(vars(municipio), funs(as.character(.))) %>% 
    mutate_at(vars(uf, dia_semana), funs(as.factor(.)))

# 2017   
data2017.1 <- read_delim("datatran2017.csv", delim = ";", locale = locale(encoding="latin1"),
                       escape_backslash = TRUE, trim_ws = TRUE,
                       escape_double = FALSE, quote = '\\\"')
data2017.2 <- as.tibble(sapply(data2017.1, function(x) gsub("\"", "", x)))
data2017.3 <- as.data.frame(apply(data2017.2, 2, function(x) gsub('  ', '',x)))
colnames(data2017.3) <- gsub("\"", "", colnames(data2017.3), fixed = TRUE)
colnames(data2017.3) <- gsub(",", "", colnames(data2017.3), fixed = TRUE)
data2017.3$uop <- gsub(",", "", data2017.3$uop, fixed = TRUE)
data2017 <- as.tibble(data2017.3) %>% 
    dplyr::select(-latitude, -longitude, -regional, -delegacia, -uop) %>% 
    mutate(time = as.Date(data_inversa)) %>% 
    mutate(year = year(time)) %>% 
    mutate(month = month(time)) %>% 
    mutate(day = day(time)) %>% 
    dplyr::select(-data_inversa, -horario, -time) %>% 
    mutate_at(vars(id, br, km, pessoas, mortos, feridos_leves, feridos_graves,
                   ilesos, ignorados, feridos, veiculos), 
              funs(as.numeric(as.character(.)))) %>% 
    mutate_at(vars(municipio), funs(as.character(.))) %>% 
    mutate_at(vars(uf, dia_semana), funs(as.factor(.)))

# 2016
data2016 <- read_csv2("datatran2016_atual.csv") %>% 
    mutate_at(vars(data_inversa), funs(dmy(.))) %>%
    mutate(year = year(data_inversa)) %>% 
    mutate(month = month(data_inversa)) %>% 
    mutate(day = day(data_inversa)) %>% 
    dplyr::select(-data_inversa, -horario) %>% 
    mutate_at(vars(id, br, km, pessoas, mortos, feridos_leves, feridos_graves,
                   ilesos, ignorados, feridos, veiculos), funs(as.integer(.))) %>% 
    mutate_at(vars(municipio), funs(as.character(.))) %>% 
    mutate_at(vars(uf, dia_semana), funs(as.factor(.)))

# putting everything together
data.all <- bind_rows(data.rest, data.some, data2017, data2016) 

# data cleaning
data1 <- data.all %>% mutate(cause_accident = case_when(
    str_detect(causa_acidente, "Veloci") ~ "Speeding",
    str_detect(causa_acidente, "Anim") ~ "Animal Crossings",
    str_detect(causa_acidente, "Defeito na via") ~ "Poor Road",
    str_detect(causa_acidente, "Pista Escorregadia") ~ "Poor Road",
    str_detect(causa_acidente, "Sinalizaca") ~ "Poor Road",
    str_detect(causa_acidente, "Falta de Aten") ~ "Distracted Driving",
    str_detect(causa_acidente, "Falta de aten") ~ "Distracted Driving",
    str_detect(causa_acidente, "guar") ~ "Improper Driving",
    str_detect(causa_acidente, "Avarias") ~ "Improper Driving",
    str_detect(causa_acidente,  "Defici") ~ "Improper Driving",
    str_detect(causa_acidente, "Desob") ~ "Improper Driving",
    str_detect(causa_acidente, "Ultra") ~ "Wrong Overtaking",
    str_detect(causa_acidente,  "Defeito m") ~ "Mechanical Defect",
    str_detect(causa_acidente, "Defeito M") ~ "Mechanical Defect",
    str_detect(causa_acidente, "Dormindo") ~ "Fatigue",
    str_detect(causa_acidente, "Fen") ~ "Other",
    str_detect(causa_acidente, "Restri") ~ "Other",
    str_detect(causa_acidente, "pedestre") ~ "Other",
    str_detect(causa_acidente, "Mal") ~ "Other",
    str_detect(causa_acidente, "Carga") ~ "Other",
    str_detect(causa_acidente, "Objeto") ~ "Other",
    str_detect(causa_acidente, "Outras") ~ "Other",
    str_detect(causa_acidente, "Agress") ~ "Other",
    str_detect(causa_acidente, "Inges") ~ "Alcohol/Psychoactive Subs")) %>% 
    dplyr::select(-causa_acidente) 

data2 <- data1 %>%  
    mutate(type_accident = case_when(
        str_detect(tipo_acidente, "Sa") ~ "saida da pista",
        str_detect(tipo_acidente, "lateral") ~ "colisao lateral",
        str_detect(tipo_acidente, "objeto") ~ "colisao com objeto",
        str_detect(tipo_acidente, "Queda") ~ "queda do veiculo",
        str_detect(tipo_acidente, "Capotamento") ~ "capotamento",
        str_detect(tipo_acidente, "versal") ~ "colisao transversal",
        str_detect(tipo_acidente, "seira") ~ "colisao traseira",
        str_detect(tipo_acidente, "frontal") ~ "colisao frontal",
        str_detect(tipo_acidente, "nimal") ~ "atropelamento de animal",
        str_detect(tipo_acidente, "bamento") ~ "tombamento",
        str_detect(tipo_acidente, "cicleta") ~ "colisao com bicicleta",
        str_detect(tipo_acidente, "ventuais") ~ "danos eventuais",
        str_detect(tipo_acidente, "Inc") ~ "incendio",
        str_detect(tipo_acidente, "arga") ~ "derramamento de carga",
        str_detect(tipo_acidente, "gavetamento") ~ "engavetamento")) %>% 
    mutate_at(vars(fase_dia), 
              funs(factor(trimws(tolower(.)), exclude = "(null)"))) %>% 
    dplyr::select(-tipo_acidente, -classificacao_acidente) %>% 
    mutate_at(vars(sentido_via), 
              funs(factor(trimws(tolower(.)), exclude = "N\u008bo Informado "))) %>% 
    mutate_at(vars(condicao_metereologica), 
              funs(factor(trimws(tolower(.)), exclude = "(null)"))) %>% 
    mutate_at(vars(condicao_metereologica), 
              funs(recode(., "c\u008eu claro" = "ceu claro",
                          "nevoeiro/neblina" = "neblina", 
                          "garoa/chuvisco" = "garoa"))) %>% 
    mutate_at(vars(condicao_metereologica), 
              funs(factor(., exclude = c("ignorado", "ignorada")))) 

data <- data2 %>% 
    mutate_at(vars(tipo_pista), funs(str_replace(., ".*ltipla.*", "multipla"))) %>% 
    mutate_at(vars(tipo_pista), funs(factor(tolower(trimws(.)), exclude = "(null)"))) %>% 
    mutate_at(vars(tracado_via), 
              funs(recode(., "Interse\u008d\u008bo de vias" = "interseccao",
                          "Desvio Tempor\u0087rio " = "desvio temporario", 
                          "T\u009cnel " = "tunel",
                          "Rotat\u0097ria " = "rotatoria"))) %>% 
    mutate_at(vars(tracado_via), 
              funs(factor(trimws(tolower(.)), 
                          exclude = c("(null)", "N\u008bo Informado ", 
                                      "n\u008bo informado")))) %>% 
    mutate_at(vars(uso_solo), funs(factor(trimws(tolower(.)), 
                                          exclude = c("(null)", "N\u008bo ", "Sim ", 
                                                      "n\u008bo", "sim")))) %>% 
    mutate(weekday = case_when(str_detect(dia_semana, "mingo") ~ "Sunday",
                               str_detect(dia_semana, "gunda") ~ "Monday",
                               str_detect(dia_semana, "er") ~ "Tuesday",
                               str_detect(dia_semana, "uart") ~ "Wednesday",
                               str_detect(dia_semana, "uint") ~ "Thursday",
                               str_detect(dia_semana, "x") ~ "Friday",
                               str_detect(dia_semana, "bado") ~ "Saturday")) %>% 
    dplyr::select(-dia_semana, -ano) %>% 
    mutate(fatal = case_when(mortos == 0 ~ FALSE,
                             mortos > 0 ~ TRUE)) %>% 
    mutate_at(vars(uf), funs(factor(trimws(.), exclude = c("(null)")))) %>% 
    mutate_at(vars(fase_dia), 
              funs(recode(., "amanhecer" = "Dawn",
                          "anoitecer" = "Dusk", 
                          "plena noite" = "Night",
                          "pleno dia" = "Day")))

data
