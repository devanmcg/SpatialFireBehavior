pacman::p_load(tidyverse, sf)

# 'Flatten" imputed mids object into single tibble
  imp_d <- 
    complete(imp, 'long') %>%
      as_tibble() %>%
            unite("TreeID", c(location, block, pasture,
                              year, plot, array), sep = ".") %>%
            select(-patch, -.id, -.imp) %>%
            pivot_longer(names_to = "response", 
                         values_to = "values", 
                         -TreeID) %>%
            group_by(TreeID, response) %>%
              summarize(value = median(values)) %>%
            ungroup() %>%
            pivot_wider(names_from = response, 
                         values_from = value) %>%
            separate(TreeID, c("location", "block", "pasture",
                               "year", "plot", "array"))

# Assign triangle coordinates in sf object
  imp_sf <-        
    read_sf("mapping/DummyFireTowers/DummyTrianglePoints.shp") %>%
      select(SubPlot, FireTower) %>%
        unite("TreeID", c(SubPlot, FireTower), sep=".") %>%
      full_join(unite(imp_d, "TreeID", c(plot, array), sep=".")) 
  
# Convert sf object to tibble with coordinates
  imp_sf %>% as_tibble() %>%
    st_write("./data/imp_coords.csv",  layer_options = "GEOMETRY=AS_XY") 
  imp_coords <- read_csv("./data/imp_coords.csv")
  
  ggplot(imp_sf) +
    geom_sf()
  
  mite.xy <- select(imp_coords, X, Y) 
  mite.dbmem1 <- adespatial::dbmem(mite.xy, thresh=1.012, 
                                   MEM.autocor = "non-null",
                                   silent = FALSE)
  mite.dbmem1  
# Create sp object 
  CanTemp_sp <- 
    imp_coords %>%
    unite(FireID, c(location, block, pasture, year), sep=".") %>%
          select(FireID, X, Y, tempC) 
  
  
  CanTemp_sp1 <- filter(CanTemp_sp, FireID == "CG.BAR.NE.18")


  sp::coordinates(CanTemp_sp1) = ~X+Y
  airC_v <- gstat::variogram(tempC~1, CanTemp_sp)
  
  v = variogram(log(zinc)~x+y, meuse)
  v.fit = fit.variogram(v, vgm(1, "Sph", 700, 1))
  v.fit
  set = list(gls=1)
  v
  g = gstat(NULL, "log-zinc", log(zinc)~x+y, meuse, model=v.fit, set = set)
  variogram(g)  

