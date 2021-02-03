pacman::p_load(tidyverse)

source("./r script/LoadingCompiledData.R")

AnalysisData <- 
  DataCombined %>%
    filter( ros <= 40, 
            tempC >= 40) %>%
      mutate(FuelMoisture = ifelse(FuelMoisture >= 0, 
                                    FuelMoisture, NA), 
             FuelMoisture = FuelMoisture * 100)
  
GGally::ggpairs(AnalysisData, columns = 8:19)

# Distribution

AnalysisData %>% 
  ggplot(aes(x=ros)) + theme_bw(14) + 
  geom_histogram(aes(y=..density..),      
                 binwidth=0.5,
                 colour="black", 
                 fill="lightgreen") +
  geom_density(alpha=0.2, 
               fill="#FF6666") 

AnalysisData %>% 
  ggplot(aes(x=tempC)) + theme_bw(14) + 
  geom_histogram(aes(y=..density..),      
                 binwidth=10,
                 colour="black", 
                 fill="lightgreen") +
  geom_density(alpha=0.2, 
               fill="#FF6666") 

AnalysisData %>% 
  ggplot(aes(x=SoilMaxC)) + theme_bw(14) + 
  geom_histogram(aes(y=..density..),      
                 binwidth=10,
                 colour="black", 
                 fill="lightgreen") +
  geom_density(alpha=0.2, 
               fill="#FF6666") 

AnalysisData %>% 
  ggplot(aes(x=tempC, y = ros, color=location)) + theme_bw(14) +
    geom_point(alpha=0.5)

  ggplot(AnalysisData, aes(x=SoilMoisture, y=FuelMoisture, color=location)) + 
    geom_smooth(method = 'lm') + 
    geom_point(alpha=0.5) +
    coord_cartesian(ylim = c(0,200))
  
  AnalysisData %>% 
    ggplot(aes(x=dbC, y = ros, color=location)) + theme_bw(14) +
    geom_point(alpha=0.5)

# MICE regression 

pacman::p_load(mice, broom.mixed)

  # View pattern of missing data
    AnalysisData %>%
        md.pattern() 

  # Calculate imputed datasets
    imp <- AnalysisData %>% 
                mutate_at(vars(plot, array), as.character) %>%
                mutate_at(vars(tempC:SoilMaxC), ~as.numeric(scale(., center=F))) %>%
                select(-SoilMoisture, -dpF) %>%
                 mice(m=100, seed = 23109, print=F)
#
# Rate of spread
#   
  # Fit model 
    ros_all <- with(imp, suppressMessages(
                              lme4::glmer(ros ~ RH + mean_mph + 
                                         FuelMoisture + LAI + 
                                      (1|location/block/year/plot), 
                                 family=Gamma(link = "log"), 
                                 control=lme4::glmerControl(optimizer="bobyqa", 
                                                        optCtrl=list(maxfun=100000)) )) )
 ros_terms <-   
    summary(pool(ros_all)) %>%
      mutate_at(vars(estimate:p.value), ~round(., 2)) %>%
   select(term, statistic, df, p.value, estimate) %>%
    bind_cols(confint.mipo(pool(ros_all)) %>%
                as_tibble() %>%
                round(2) ) %>%
      arrange(desc(abs(estimate)))

#
# Maximum canopy temperature  
#
 # Fit model 
   temp_all <- with(imp, suppressMessages(
               lme4::glmer(tempC ~ RH + mean_mph +  
                             FuelMoisture + LAI + 
                             (1|location/block/year/plot), 
                           family=Gamma(link = "log"), 
                           control=lme4::glmerControl(optimizer="bobyqa", 
                                                      optCtrl=list(maxfun=100000)) )) )
   temp_terms <-   
     summary(pool(temp_all)) %>%
     mutate_at(vars(estimate:p.value), ~round(., 2)) %>%
     select(term, statistic, df, p.value, estimate) %>%
     bind_cols(confint.mipo(pool(temp_all)) %>%
                 as_tibble() %>%
                 round(2) ) %>%
     arrange(desc(abs(estimate)))
   
#
# Maximum soil surface temperature  
#
   # Fit model 
   soil_all <- with(imp, suppressMessages(
     lme4::glmer(SoilMaxC ~ RH + mean_mph +  
                   FuelMoisture + LAI + 
                   (1|location/block/year/plot), 
                 family=Gamma(link = "log"), 
                 control=lme4::glmerControl(optimizer="bobyqa", 
                                            optCtrl=list(maxfun=100000)) )) )
   soil_terms <-   
     summary(pool(soil_all)) %>%
     mutate_at(vars(estimate:p.value), ~round(., 2)) %>%
     select(term, statistic, df, p.value, estimate) %>%
     bind_cols(confint.mipo(pool(soil_all)) %>%
                 as_tibble() %>%
                 round(2) ) %>%
     arrange(desc(abs(estimate)))
 
response_CIs <-   
        bind_rows(
          mutate(soil_terms, response = 'Temp. at surface'), 
          mutate(temp_terms, response = 'Temp. above surface'),
          mutate(ros_terms, response = "Rate of spread") 
          )

# save(response_CIs, file="./r objects/response_CIs.Rdata")

response_CIs %>%
  filter(term != '(Intercept)') %>%
  as_tibble() %>%
  mutate(term = recode(term, LAI = 'Fuel load', 
                             mean_mph = 'Wind speed', 
                             RH = 'Relative humidity', 
                             FuelMoisture = 'Fuel moisture'))  %>%
  ggplot(aes(x = reorder(term, abs(estimate), max))) + theme_bw(16) + 
    geom_hline(yintercept = 0, color="black", linetype = 2) +
    geom_errorbar(aes(ymin = `2.5 %`, ymax = `97.5 %`), 
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
  
    