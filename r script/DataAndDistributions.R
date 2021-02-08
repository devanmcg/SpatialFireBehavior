pacman::p_load(tidyverse)

load(paste0(FilePath, "data/AnalysisData.Rdata"))

GGally::ggpairs(AnalysisData, columns = 9:17)

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
  ggplot(aes(x=MaxC)) + theme_bw(14) + 
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
  ggplot(aes(x=MaxC, y = ros, color=location)) + theme_bw(14) +
  geom_point(alpha=0.5)

ggplot(AnalysisData, aes(x=SoilMoisture, y=FuelMoisture, color=location)) +
  theme_bw(14) + 
  geom_smooth(method = 'lm') + 
  geom_point(alpha=0.5) +
  coord_cartesian(ylim = c(0,200))

AnalysisData %>% 
  ggplot(aes(x=dbC, y = ros, color=location)) + theme_bw(14) +
  geom_point(alpha=0.5)