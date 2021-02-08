pacman::p_load(tidyverse)

# Load imputed dataset 
  load(paste0(getwd(), '/r objects/imp_d.Rdata'))

  
# Mixed-effect regression models 
#
# Rate of spread
#   
  # Fit model 
    ros_all <- with(imp.d, suppressMessages(
      lme4::glmer(ros ~ RH + MaxWindSpeed + 
                    FuelMoisture + LAI + 
                    (1|location/block/year/plot), 
                  family=Gamma(link = "log"), 
                  control=lme4::glmerControl(optimizer="bobyqa", 
                                             optCtrl=list(maxfun=100000)) )) )
    
  # Get terms
    ros_terms <- 
      suppressWarnings(confint(ros_all,method="boot",nsim=199)) %>%
      as.data.frame %>%
      rownames_to_column("term") %>%
      slice(6:10) %>%
      rename(lwr = `2.5 %`, upr = `97.5 %`) %>%
      full_join(
        lme4::fixef(ros_all) %>%
          as.data.frame() %>% 
          rownames_to_column("term") %>%
          rename(estimate = '.') ) 


#
# Maximum canopy temperature  
#
# Fit model 
temp_all <- with(imp.d, suppressMessages(
  lme4::glmer(MaxC ~ RH + MaxWindSpeed +  
                FuelMoisture + LAI + 
                (1|location/block/year/plot), 
              family=Gamma(link = "log"), 
              control=lme4::glmerControl(optimizer="bobyqa", 
                                         optCtrl=list(maxfun=100000)) )) )
temp_terms <-   
  suppressWarnings(confint(temp_all,method="boot",nsim=199)) %>%
  as.data.frame %>%
  rownames_to_column("term") %>%
  slice(6:10) %>%
  rename(lwr = `2.5 %`, upr = `97.5 %`) %>%
  full_join(
    lme4::fixef(temp_all) %>%
      as.data.frame() %>% 
      rownames_to_column("term") %>%
      rename(estimate = '.') ) 

#
# Maximum soil surface temperature  
#
# Fit model 
soil_glmer <- with(imp_d, suppressMessages(
                lme4::glmer(SoilMaxC ~ RH + MaxWindSpeed +  
                    FuelMoisture + LAI + 
                    (1|location/block/year/plot), 
                  family=Gamma(link = "log"), 
                  control=lme4::glmerControl(optimizer="bobyqa", 
                                             optCtrl=list(maxfun=100000)) )) )

soil_terms <-   
  suppressWarnings(confint(soil_glmer,method="boot",nsim=199)) %>%
  as.data.frame %>%
  rownames_to_column("term") %>%
  slice(6:10) %>%
  rename(lwr = `2.5 %`, upr = `97.5 %`) %>%
  full_join(
    lme4::fixef(soil_glmer) %>%
      as.data.frame() %>% 
      rownames_to_column("term") %>%
      rename(estimate = '.') ) ; beepr::beep()


response_CIs <-   
  bind_rows(
    mutate(soil_terms, response = 'Temp. at surface'), 
    mutate(temp_terms, response = 'Temp. above surface'),
    mutate(ros_terms, response = "Rate of spread") 
  ) %>%
  as_tibble() 

# save(response_CIs, file="./r objects/response_CIs.Rdata")

response_CIs %>%
  filter(term != '(Intercept)') %>%
  mutate(term = recode(term, LAI = 'Fuel load', 
                       MaxWindSpeed = 'Wind speed', 
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
