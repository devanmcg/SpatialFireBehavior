pacman::p_load(tidyverse)

# Load imputed dataset 
load(paste0(getwd(), '/r objects/imp_sc.Rdata'))



# Max soil surface temperature 
  # Fit model
    soil_ADMB <- glmmADMB::glmmadmb(SoilMaxC ~ RH + MaxWindSpeed +
                            FuelMoisture + tHa,
                          random = ~ 1|location/year/plot ,
                          data = filter(imp_sc, SoilMaxC <= 3.9),
                          family="gamma",
                          link="log",  
                          admb.opts=glmmADMB::admbControl(shess = TRUE, 
                                                          noinit = TRUE, 
                                                          impSamp = 10) )
  # Retrieve regression results
    soil_terms <-   
      confint(soil_ADMB) %>%
      as.data.frame %>%
      rownames_to_column("term") %>%
      rename(lwr = `2.5 %`, upr = `97.5 %`) %>%
      full_join(
        coef(soil_ADMB) %>%
          as.data.frame() %>% 
          rownames_to_column("term") %>%
          rename(estimate = '.') )

# Maximum aboveground temp (plant canopy)  
  # Fit model
    canopy_ADMB <- glmmADMB::glmmadmb(MaxC ~ RH + MaxWindSpeed +
                                        FuelMoisture + tHa,
                          random = ~ 1|location/year/plot ,
                          data=imp_sc,
                          family="gamma",
                          link="log",  
                          admb.opts=glmmADMB::admbControl(shess = TRUE, 
                                                          noinit = TRUE, 
                                                          impSamp = 10))
  # Retrieve regression results
  canopy_terms <-   
    confint(canopy_ADMB) %>%
    as.data.frame %>%
    rownames_to_column("term") %>%
    rename(lwr = `2.5 %`, upr = `97.5 %`) %>%
    full_join(
      coef(canopy_ADMB) %>%
        as.data.frame() %>% 
        rownames_to_column("term") %>%
        rename(estimate = '.') )
  
# Rate of spread 
  # Fit model 
    ros_ADMB <- glmmADMB::glmmadmb(ros ~ RH + MaxWindSpeed +
                                    FuelMoisture + tHa,
                          random = ~ 1|location/year/plot ,
                          data=imp_sc,
                          family="gamma",
                          link="log",  
                          admb.opts=glmmADMB::admbControl(shess = TRUE, 
                                                          noinit = TRUE, 
                                                          impSamp = 10))
  # Retrieve regression results  
    ros_terms <-   
      confint(ros_ADMB) %>%
      as.data.frame %>%
      rownames_to_column("term") %>%
      rename(lwr = `2.5 %`, upr = `97.5 %`) %>%
      full_join(
        coef(ros_ADMB) %>%
          as.data.frame() %>% 
          rownames_to_column("term") %>%
          rename(estimate = '.') )

# Compile results 
    
    response_CIs <-   
      bind_rows(
        mutate(soil_terms, response = 'Temp. at surface'), 
        mutate(canopy_terms, response = 'Temp. above surface'),
        mutate(ros_terms, response = "Rate of spread") 
      ) %>%
      as_tibble() 
    
  # save(response_CIs, file="./r objects/response_CIs.Rdata")
    