pacman::p_load(tidyverse)

load(paste0(FilePath, "/data/AnalysisData.Rdata"))

# MICE regression 

pacman::p_load(mice, broom.mixed)

#
# Imputations
#
  # View pattern of missing data
    AnalysisData %>%
        md.pattern() 

  # Calculate imputed datasets
    imp <- AnalysisData %>% 
                mutate_at(vars(plot, array), as.character) %>%
                 mice(m=500, seed = 23109, print=F)
    
    imp_raw <- 
      complete(imp) %>%
              as_tibble() %>% 
                mutate(across(location:array, as.factor)) 
    
    imp_sc <- 
      imp_raw %>%
       mutate_at(vars(AirTemp:tHa), ~as.numeric(scale(., center=F)))
  
    # save(imp_raw, file = paste0(FilePath, '/r objects/imp_raw.Rdata'))
    # save(imp_sc, file = paste0(FilePath, '/r objects/imp_sc.Rdata'))

    