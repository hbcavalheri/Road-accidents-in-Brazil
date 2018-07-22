detach(package:dplyr)
library(dplyr)

# Figure 1 ---------------------------------------------------------------------

cause.graph <- data %>%
    dplyr::group_by(cause_accident) %>% 
    dplyr::summarise(total = n(), fatalities = sum(fatal)) %>% 
    mutate(prop.fatal = (fatalities/sum(fatalities))*100, 
           prop.total = (total/sum(total))*100) %>%
    filter(!is.na(cause_accident)) %>% 
    filter(cause_accident != "Other") %>% 
    ggplot() +
    geom_bar(aes(reorder(cause_accident, prop.fatal), prop.fatal), 
             stat = "identity", position = "dodge", alpha = 0.8, fill = "pink",
             color = 'red') +
    coord_flip() +
    ylab("Fatalities (%)") +
    xlab("") +
    theme(panel.background = element_blank(),
          panel.grid = element_blank(),
          axis.line = element_line(colour = "black"),
          axis.text = element_text(size = 20, color = "black"),
          axis.title.x = element_text(size = 22)) 

png("figure1.png", width=13, height=8, res=300, units = 'in', 
    type = 'cairo')
grid.arrange(cause.graph)
dev.off()

# Figure 2 ---------------------------------------------------------------------

pista <- data %>% 
    dplyr::group_by(tipo_pista) %>% 
    dplyr::summarise(total = n(), fatal = sum(mortos)) %>% 
    filter(!is.na(tipo_pista)) %>% 
    mutate(prop = (fatal/sum(fatal))*100) %>% 
    ggplot() +
    geom_bar(aes("", prop, fill = tipo_pista, color = tipo_pista), 
             stat = "identity", width = 1) +
    coord_polar("y", start = 0) +
    theme(panel.background = element_blank(),
          panel.border = element_blank(),
          axis.title = element_blank(),
          axis.text = element_blank(), 
          legend.key.size = unit(10, "mm"),
          legend.text = element_text(size = 25),
          legend.title = element_text(size = 25)) +
    geom_text(aes(x = c(1.1, 1.2, 1.1), y = c(87.5, 75.5, 30)), 
              label = c("23%", "3%", "74%"), size = 10, color = "white",
              fontface = "bold") +
    scale_fill_manual(values = c("purple", "gold3", "springgreen3"), 
                      labels = c("Two-lane", "More than two lanes", 
                                 "Single-lane"), name = "Type of Road") +
    scale_color_manual(values = c("purple", "gold3", "springgreen3"), 
                       labels = c("Two-lane", "More than two lanes", 
                                  "Single-lane"), name = "Type of Road")

fase <- data %>% 
    dplyr::group_by(fase_dia) %>% 
    dplyr::summarise(total = n(), fatal = sum(mortos)) %>% 
    filter(!is.na(fase_dia)) %>% 
    mutate(prop = (fatal/sum(fatal))*100) %>% 
    mutate_at(vars(fase_dia), 
              funs(factor(., levels = c("Dawn", "Day", "Dusk", "Night")))) %>% 
    ggplot() +
    geom_bar(aes("", prop, fill = fase_dia, color = fase_dia), 
             stat = "identity", width = 1) +
    coord_polar("y", start = 0) +
    theme(panel.background = element_blank(),
          panel.border = element_blank(),
          axis.title = element_blank(),
          axis.text = element_blank(),
          legend.key.size = unit(10, "mm"),
          legend.text = element_text(size = 25),
          legend.title = element_text(size = 25)) +
    scale_fill_manual(values = c("orange", "#FDE725FF", "#31688EFF", "#440154FF"), 
                      name = "Light Conditions",
                      labels = c("Dawn", "Day", "Dusk", "Night                         ")) +
    scale_color_manual(values = c("orange", "#FDE725FF", "#31688EFF", "#440154FF"), 
                       name = "Light Conditions",
                       labels = c("Dawn", "Day", "Dusk", "Night                         ")) +
    geom_text(aes(x = c(1.1, 1, 1.2, 1), y = c(96.5, 75, 49, 25)), 
              label = c("7%", "40%", "6%", "47%"), size = 10, color = "white",
              fontface = "bold") 

png("figure2.png", width = 18, height = 6, res = 300, units = 'in', 
    type = 'cairo')
grid.arrange(pista, fase, ncol = 2)
dev.off()

# Figure 3 ---------------------------------------------------------------------

chuva <- data %>% 
    filter(condicao_metereologica %in% c("chuva", "ceu claro")) %>%
    filter(fase_dia != "Dawn" & fase_dia != "Dusk") %>% 
    dplyr::group_by(tipo_pista, fase_dia, condicao_metereologica) %>% 
    dplyr::summarise(fatalities = sum(fatal))

ceu <- chuva %>% 
    filter(!is.na(tipo_pista)) %>% 
    dplyr::group_by(condicao_metereologica, tipo_pista) %>% 
    dplyr::summarise(total = sum(fatalities)) %>% 
    inner_join(chuva) %>% 
    rowwise() %>% 
    mutate(prop = (fatalities / total) * 100) %>% 
    mutate_at(vars(condicao_metereologica), 
              funs(case_when(condicao_metereologica == "ceu claro" ~ "Clear", 
                             condicao_metereologica == "chuva" ~ "Rain"))) %>% 
    mutate(pista = case_when(tipo_pista == "simples" ~ "Single-lane", 
                             tipo_pista == "dupla" ~ "Two-lane",
                             tipo_pista == "multipla" ~ "Multi-lane")) %>% 
    mutate_at(vars(pista), funs(factor(., levels = c("Single-lane", "Two-lane",
                                                "Multi-lane"))))

weather <- ceu %>% 
    ggplot() +
    geom_bar(aes(condicao_metereologica, prop, group = fase_dia, color = fase_dia, 
                 fill = fase_dia), stat = "identity", position = "dodge") +
    facet_wrap(~ pista) +
    scale_color_manual(values = c("#440154FF", "#FDE725FF"), name = "Light Condition",
                       labels = c("Night", "Day")) +
    scale_fill_manual(values = c("#440154FF", "#FDE725FF"), name = "Light Condition",
                      labels = c("Night", "Day")) +
    xlab("Weather Condition") +
    ylab("Fatalities (%)") +
    theme(panel.background = element_blank(),
          panel.grid = element_blank(),
          strip.text = element_text(size = 30, face = "bold"),
          legend.text = element_text(size = 22),
          legend.title = element_text(size = 22),
          axis.title = element_text(size = 25),
          axis.text = element_text(size = 22),
          legend.key.size = unit(10, "mm"))

png("figure3.png", width = 16, height = 10, res = 300, units = 'in', 
    type = 'cairo')
grid.arrange(weather)
dev.off()

# Figure 4 ---------------------------------------------------------------------

seasonal <- data %>% 
    mutate_at(vars(year, month, day), funs(factor(.))) %>% 
    dplyr::group_by(year, month) %>% 
    dplyr::summarise(fatalities = sum(fatal)) %>% 
    mutate(prop = (fatalities/sum(fatalities))*100)  

seasonal.avr <- seasonal %>% 
    dplyr::group_by(month) %>% 
    dplyr::summarise(avr = mean(prop))

graph.seasonal <- seasonal %>%
    ggplot() +
    geom_line(aes(month, prop, group = year), stat="smooth", method = "loess", 
              se = FALSE, color = "springgreen3", alpha = 0.3, size = 0.6) +
    xlab("Month") +
    ylab("Fatalities (%)") +
    scale_x_discrete(breaks = 1:12, labels = c("Jan", "Feb", "Mar", "Apr", 
                                               "May", "Jun", "Jul", "Aug", "Sep",
                                               "Oct", "Nov", "Dec")) +
    geom_line(data = seasonal.avr, aes(month, avr, group = 1), se = FALSE, 
              method = "loess", stat="smooth", color = "darkgreen", 
              alpha = 0.7, size = 2) +
    theme(panel.grid = element_line(color = "white"),
          panel.background = element_rect(fill = "gray97"),
          axis.line = element_line('black'),
          axis.title = element_text(size = 23),
          axis.text = element_text(size = 18),
          plot.title = element_text(face = "bold", size = 17)) +
    annotate("text", x = 11.75, y = 7.7, label = "Summer\nbreak", size = 7) +
    annotate("text", x = 6, y = 7.3, label = "Winter break", size = 7) +
    geom_segment(aes(x = 6, y = 7.5, xend = 6, yend = 8), size = 1, 
                 arrow = arrow(length = unit(0.5, "cm"))) +
    geom_segment(aes(x = 11.75, y = 8, xend = 11.75, yend = 8.5), size = 1, 
                 arrow = arrow(length = unit(0.5, "cm")))

week.graph <- data %>% 
    mutate_at(vars(weekday), funs(factor(., levels = c("Sunday", "Monday", 
                                                       "Tuesday", "Wednesday",
                                                       "Thursday", "Friday",
                                                       "Saturday")))) %>% 
    group_by(weekday) %>% 
    summarise(fatalities = sum(fatal)) %>% 
    mutate(prop = (fatalities/sum(fatalities))*100) %>% 
    ggplot() +
    geom_bar(aes(weekday, prop, fill = prop, color = prop), stat = "identity", 
             show.legend = FALSE) +
    scale_fill_gradient(low = "springgreen", high = "darkgreen") +
    scale_color_gradient(low = "springgreen", high = "darkgreen") +
    theme(panel.background = element_blank(), 
          panel.grid = element_blank(),
          axis.line = element_line(colour = "black"),
          axis.text = element_text(size = 20, color = "black"),
          axis.title = element_text(size = 20),
          plot.title = element_text(hjust = 0.5, size = 30, face = "bold"),
          axis.text.x = element_text(angle = 45, hjust = 1)) +
    ylab("Fatalities (%)") +
    xlab("")

png("figure4.png", width = 8, height = 12, res = 300, units = 'in', 
    type = 'cairo')
grid.arrange(week.graph, graph.seasonal, nrow = 2)
dev.off()

# Figure 5 ---------------------------------------------------------------------

rodo <- data %>% 
    mutate_at(vars(br), funs(factor(.))) %>% 
    group_by(br) %>% 
    summarise(fatalities = sum(fatal)) %>% 
    mutate(prop = (fatalities/sum(fatalities))*100) %>% 
    filter(!is.na(br)) %>% 
    filter(br != 0)

rodo.bar <- rodo %>%
    filter(prop > 2.4) %>% 
    mutate(br.new = paste("BR", br, sep = "-")) %>% 
    ggplot() +
    geom_bar(aes(reorder(br.new, -prop), prop, fill = prop, color = prop), stat = "identity", 
             show.legend = FALSE) +
    scale_fill_gradient(low = "pink", high = "darkred") +
    scale_color_gradient(low = "pink", high = "darkred") +
    theme(panel.background = element_blank(), 
          panel.grid = element_blank(),
          axis.line = element_line(colour = "black"),
          axis.text = element_text(size = 30, color = "black"),
          axis.title = element_text(size = 30),
          plot.title = element_text(hjust = 0.5, size = 30, face = "bold"),
          axis.text.x = element_text(angle = 45, hjust = 1)) +
    ylab("Fatalities (%)\n") +
    xlab("")

png("figure5.png", width=13, height=8, res=300, units = 'in', 
    type = 'cairo')
grid.arrange(rodo.bar)
dev.off()

# Figure 6 ---------------------------------------------------------------------

#url.rodovias.table <- "http://www.dnit.gov.br/sistema-nacional-de-viacao/sistema-nacional-de-viacao"
#url.rodovias.shp <- "http://servicos.dnit.gov.br/vgeo/#"

mapa <- borders("world", regions = "Brazil", fill = "gray98", colour = "gray98")

brazil <- ggplot() + 
    mapa +
    xlab("Longitude") + 
    ylab("Latitude") + 
    theme(panel.border = element_blank(), 
          panel.grid.major = element_line(colour = "grey80"), 
          panel.grid.minor = element_blank())


estados <- rgdal::readOGR("Brazil_Admin_1.shp")
estados1 <- fortify(estados)

estados2 <- estados1 %>% 
    mutate(state = case_when(id == "0" ~ "AC", id == "1" ~ "AM",id == "2" ~ "MA", 
                             id == "3" ~ "PA", id == "4" ~ "RO", id == "5" ~ "TO",
                             id == "6" ~ "DF", id == "7" ~ "MS", id == "8" ~ "MG",
                             id == "9" ~ "MS", id == "10" ~ "RS", id == "11" ~ "PR",
                             id == "12" ~ "SC", id == "13" ~ "CE", id == "14" ~ "PI",
                             id == "15" ~ "AL", id == "16" ~ "BA", id == "17" ~ "ES",
                             id == "18" ~ "PB", id == "19" ~ "RJ", id == "20" ~ "RN",
                             id == "21" ~ "SE", id == "22" ~ "RR", id == "23" ~ "AP",
                             id == "24" ~ "GO", id == "25" ~ "SP", id == "26" ~ "PE"))


rodo.uf <- data %>% 
    mutate_at(vars(br, uf), funs(factor(.))) %>% 
    filter(br %in% c(101, 116)) %>% 
    group_by(br, uf) %>% 
    summarise(fatalities = sum(fatal)) %>% 
    mutate(prop = (fatalities/sum(fatalities))*100) 

rodovias <- rgdal::readOGR("SNV_201803A.shp")
rodovias@data$id <- rownames(rodovias@data)
rodovias.df <- fortify(rodovias)
rodovias.df <- left_join(rodovias.df, rodovias@data, by = "id")
rodovias.df1 <- as.tibble(rodovias.df[,1:9]) %>% 
    filter(vl_br %in% rodo$br) %>% 
    full_join(rodo, by = c("vl_br" = "br")) %>% 
    mutate(cor = case_when(prop > 10 ~ "high", prop < 10 ~ "low")) %>% 
    left_join(rodo.uf, by = c("vl_br" = "br", 'sg_uf' = "uf"))

rodo.all <- brazil + 
    geom_polygon(data = estados2, aes(long, lat, group = group), color = "white", 
                 fill = "gray96", size = 0.7) +
      geom_path(data = rodovias.df1, aes(long, lat, group = group), 
               show.legend = FALSE, size = 0.2, color = "dimgray", alpha = 0.5) +
    geom_path(data = filter(rodovias.df1, vl_br %in% c(101, 116)), 
              aes(long, lat, group = group, color = prop.y), show.legend = TRUE, 
              size = 0.8) +
    theme(panel.background = element_blank(),
          panel.grid = element_blank(),
          panel.grid.major = element_blank(),
          axis.title = element_blank(),
          axis.text = element_blank(),
          axis.ticks = element_blank(), 
          legend.position = c(0.3, 0.3),
          legend.key.size = unit(8, "mm"),
          legend.key.width = unit(8, "mm"),
          legend.title.align = 0.5,
          legend.text = element_text(size = 18),
          legend.title = element_text(size = 20), 
          legend.background = element_blank()) +
    scale_color_gradient(low = "royalblue", high = "red", name = "Fatalities (%)") +
    geom_text(aes(x = c(-38, -35), y = c(-3, -4.5)), label = c("BR-116", "BR-101"),
              size = 6)
rodo.all


png("figure6.png", width=10, height=8, res=300, units = 'in', 
    type = 'cairo')
grid.arrange(rodo.all)
dev.off()

# Figure 7 ---------------------------------------------------------------------


rodovias.df2 <- as.tibble(rodovias.df[,c(1:9, 19)]) %>% 
    filter(vl_br %in% c(101, 116)) %>% 
    mutate(cor = case_when(ds_sup_fed == "DUP" ~ "dup", 
                           ds_sup_fed != "DUP"~ "low")) 

rodo.tipo <- brazil + 
    geom_polygon(data = estados2, aes(long, lat, group = group), color = "white", 
                 fill = "gray96", size = 0.7) +
    geom_path(data = rodovias.df1, aes(long, lat, group = group), 
              show.legend = FALSE, size = 0.2, color = "dimgray", alpha = 0.5) +
    geom_path(data = rodovias.df2, aes(long, lat, group = group, color = cor), show.legend = TRUE, 
              size = 0.8) +
    theme(panel.background = element_blank(),
          panel.grid = element_blank(),
          panel.grid.major = element_blank(),
          axis.title = element_blank(),
          axis.text = element_blank(),
          axis.ticks = element_blank(), 
          legend.position = c(0.3, 0.3),
          legend.key.size = unit(8, "mm"),
          legend.key.width = unit(8, "mm"),
          legend.title.align = 0.5,
          legend.text = element_text(size = 18),
          legend.title = element_text(size = 20), 
          legend.background = element_blank(), 
          legend.key = element_blank()) +
    scale_color_manual(name = "Type of Road", values = c("springgreen3", "purple"),
                       labels = c("Two or more lanes", "Single-lane")) +
    geom_text(aes(x = c(-38, -35), y = c(-3, -4.5)), label = c("BR-116", "BR-101"),
              size = 6)
rodo.tipo

png("figure7.png", width=10, height=8, res=300, units = 'in', 
    type = 'cairo')
grid.arrange(rodo.tipo)
dev.off()
