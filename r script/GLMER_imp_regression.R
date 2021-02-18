pacman::p_load(tidyverse, broom.mixed)

# Load imputed dataset 
  load(paste0(getwd(), '/r objects/imp_sc.Rdata'))
  source('C:/Users/devan/GitHubProjects/SpatialFireBehavior/r script/mipo.R')

  
# Mixed-effect regression models 
#
# Rate of spread
#   
  # Fit model 
    ros_imp <- with(imp_sc, suppressMessages(
                lme4::glmer(ros ~ RH + WindSpeed + 
                              FuelMoisture + tHa + 
                              (1|location/block/year/plot), 
                            family=Gamma(link = "log"), 
                            control=lme4::glmerControl(optimizer="bobyqa", 
                                                       optCtrl=list(maxfun=100000)) )) )
    ros_imp_pooled <- pool(ros_imp)$pooled  %>%
                          as_tibble()
    # Get terms
    ros_terms <- 
      full_join(
      summary(pool(ros_imp)) %>% 
        as_tibble() %>%
        rownames_to_column("row"), 
  
      confint.mipo(pool(ros_imp)) %>%
        as_tibble() %>%
        rownames_to_column("row") ) 
    

#
# Maximum canopy temperature  
#
# Fit model 
  canopy_imp <- with(imp_sc, suppressMessages(
                lme4::glmer(MaxC ~ RH + WindSpeed +  
                              FuelMoisture + tHa + 
                              (1|location/block/year/plot), 
                            family=Gamma(link = "log"), 
                            control=lme4::glmerControl(optimizer="bobyqa", 
                                                       optCtrl=list(maxfun=100000)) )) )
  
  canopy_imp_pooled <- pool(canopy_imp)$pooled  %>%
                            as_tibble()
  
  canopy_terms <- 
    full_join(
      summary(pool(canopy_imp)) %>% 
        as_tibble() %>%
        rownames_to_column("row"), 
      
      confint.mipo(pool(canopy_imp)) %>%
        as_tibble() %>%
        rownames_to_column("row") ) 

#
# Maximum soil surface temperature  
#
# Fit model 
  soil_imp <- with(imp_sc, suppressMessages(
                  lme4::glmer(log(SoilMaxC+1) ~ RH + WindSpeed +  
                      FuelMoisture + tHa + 
                      (1|location/block/year/plot), 
                    family=Gamma(link = "log"), 
                    control=lme4::glmerControl(optimizer="bobyqa", 
                                               optCtrl=list(maxfun=100000)) )) )

  soil_imp_pooled <- pool(soil_imp)$pooled  %>%
    as_tibble()
  
  soil_terms <- 
    full_join(
      summary(pool(soil_imp)) %>% 
        as_tibble() %>%
        rownames_to_column("row"), 
      
      confint.mipo(pool(soil_imp)) %>%
        as_tibble() %>%
        rownames_to_column("row") ) 
  
  
  response_CIs <-   
    bind_rows(
      mutate(soil_terms, response = 'Temp. at surface'), 
      mutate(canopy_terms, response = 'Temp. above surface'),
      mutate(ros_terms, response = "Rate of spread") 
    ) %>%
    as_tibble() %>%
    rename(lwr = `2.5 %`, upr = `97.5 %`)

# save(response_CIs, file="./r objects/response_CIs.Rdata")

response_CIs %>%
  filter(term != '(Intercept)') %>%
  mutate(term = recode(term, tHa = 'Fuel load', 
                       WindSpeed = 'Wind speed', 
                       RH = 'Relative humidity', 
                       FuelMoisture = 'Fuel moisture'))  %>%
  ggplot(aes(x = reorder(term, abs(estimate), max))) + theme_bw(16) + 
  geom_hline(yintercept = 0, color="black", linetype = 2) +
  geom_errorbar(aes(ymin = lwr, ymax = upr), 
                size = 1.1, width = 0.2, 
                color = "blue") +
  geom_point(aes(y = estimate), pch = 21, 
             stroke = 1.5, size = 4,
             color = "blue", fill="lightblue") +
  labs(x = '', 
       y = 'Regression coefficient with 95% CI') + 
  coord_flip(ylim=c(-1.9,1.9)) + 
  facet_wrap(~ response) + 
  theme(axis.text.y = element_text(color="black", size = 14), 
        strip.text = element_text(size = 14), 
        panel.grid.major.y = element_blank())
