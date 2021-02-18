pacman::p_load(tidyverse, mice)


AnalysisData <- read_csv(paste0(getwd(), "/data/AnalysisDataKY.csv"))

# MICE regression 

#
# Imputations
#
  # View pattern of missing data
    AnalysisData %>%
      select(AirTemp:tHa, -LAI) %>% 
        md.pattern() 

  # Calculate imputed datasets
    imp_sc <- AnalysisData %>% 
            select(-LAI, -JD) %>%
            mutate_at(vars(AirTemp:tHa), ~as.numeric(scale(., center=F))) %>%
                      mutate(across(location:array, as.factor)) %>%
                       mice(m=5, seed = 23109, print=F)
    
    imp_raw <- 
      complete(imp, 'long') %>%
      as_tibble() %>%
      unite("TreeID", c(location, block, pasture,
                        year, plot, array), sep = ".") %>%
      select(-patch, -.id, -.imp, -FireCode) %>%
      pivot_longer(names_to = "response", 
                   values_to = "values", 
                   -TreeID) %>%
      group_by(TreeID, response) %>%
      summarize(value = median(values)) %>%
      ungroup() %>%
      pivot_wider(names_from = response, 
                  values_from = value) %>%
      separate(TreeID, c("location", "block", "pasture",
                         "year", "plot", "array")) %>% 
      mutate(across(location:array, as.factor))  
    

    # save(imp_raw, file = paste0(FilePath, '/r objects/imp_raw.Rdata'))
    # save(imp_sc, file = paste0(FilePath, '/r objects/imp_sc.Rdata'))