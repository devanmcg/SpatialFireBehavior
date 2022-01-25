pacman::p_load(tidyverse, sf, geonames, 
               grid, gridExtra)
source('https://raw.githubusercontent.com/devanmcg/rangeR/master/R/CustomGGplotThemes.R')

epa <- read_sf('S:/DevanMcG/GIS/SpatialData/US/EPAecoregions/L3', 
               'us_eco_l3_state_boundaries')
aea <- st_crs(epa)

load('C:/Users/devan.mcgranahan/GithubProjects/GreatPlainsFire/gis/Robjects/us_sf.Rdata')
us_sf <- us_sf %>%
          st_transform(aea) %>%
            st_simplify()

us_states <- 
  epa %>%
  select(STATE_NAME) %>%
  mutate(area = st_area(.)) %>%
  group_by(STATE_NAME) %>%
  summarize(area = sum(area)) %>%
  ungroup() %>%
  select(-area)  %>%
  st_simplify()

nd <- filter(us_states, STATE_NAME == "North Dakota")

nd_l3 <- st_crop(gp_l3, nd) %>%
  filter(L2 != 'Temperate Prairies') %>%
  mutate(area = st_area(.)) %>%
  group_by(L3) %>%
  arrange(desc(area)) %>%
  slice(1)

# Find map points 
pacman::p_load(geonames)
options(geonamesUsername="devanmcg")

points <- tibble(feature=c("city", "capital", "rec", "rec"),
                 name=c("Fargo", "Bismarck", "Hettinger", "Streeter"), 
                 state=c("ND")) 
map_points <- 
  points %>%
  split(.$name) %>%
  purrr::map( ~ GNsearch(name_equals = .x$name, 
                         country = "US", 
                         adminCode1=.x$state, 
                         featureClass="P")) %>%
  map_dfr(~ (.))  %>%
  full_join(points) %>%
  mutate(state = adminName1, 
         long=as.numeric(lng), 
         lat = as.numeric(lat)) %>%
  select(feature, name, state, long, lat) %>%
  st_as_sf(coords = c('long', 'lat'), 
           crs = 4326) %>%
  st_transform(aea) %>%
  mutate(name = case_when(
    name == "Hettinger" ~ "Hettinger REC", 
    name == "Streeter" ~ "Central Grasslands REC", 
    TRUE ~ name
  ))

mapping <- lst(us = us_states, 
               pts = map_points, 
               nd = nd,
               nd_l3 = nd_l3,
               gp_l1 = gp_l1, 
               gp_l3 = gp_l3)
# save(mapping, file = './paper/figures/mapping.Rdata')


# Make maps

load('./paper/figures/mapping.Rdata')

region_map <-
  ggplot() + theme_map(14)  +
  geom_sf(data = mapping$us, 
          fill = 'lightgrey', 
          color = NA)+ 
    geom_sf(data = mapping$gp_l1, 
            fill = 'lightblue') +
    geom_sf(data = mapping$nd,
            fill = 'darkblue', 
            color = "darkgrey") +
    geom_sf(data = mapping$us, 
            fill = NA, 
            color = "white")

  
state_map <-
  ggplot() + theme_map(14)  +
    geom_sf(data = mapping$nd,
            fill = 'NA', 
            color = "darkgrey") + 
    geom_sf(data = mapping$nd_l3,
            aes(fill = L3), 
            show.legend = FALSE) +
    geom_sf_label(data = mapping$nd_l3,
                  aes(label = L3)) +
    geom_sf(data = mapping$pts, 
            aes(shape = feature), 
            size = 4,
            show.legend = FALSE) +
    scale_shape_manual(values = c(16, 16, 17)) +
    geom_sf_text(data = mapping$pts,
                 aes(label = name), 
                 fontface = c("bold", 'bold', 'italic', 'italic'),
                 nudge_y = 20000,
                 nudge_x = c(-35000, 0, 0, -15000),
            show.legend = FALSE)

v1<-viewport(width = 1, height = 1, x = 0.5, y = 0.5) #plot area for the main map
v2<-viewport(width = 0.45, height = 0.45, x = 0.71, y = 0.75) #plot area for the inset map
print(state_map,vp=v1) 
print(region_map,vp=v2)
