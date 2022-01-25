pacman::p_load(tidyverse, readr, mice, broom.mixed, vegan, lubridate)
# Additional script available via GitHub
source('https://raw.githubusercontent.com/cran/mice/master/R/mipo.R')
#
##
### D A T A   P R E P A R A T I O N
##
# Load raw data directly from GitHub
fp = 'https://raw.githubusercontent.com/devanmcg/SpatialFireBehavior/main'
#
# Data wrangling
#
AllData <-  
  read_csv(paste0(fp, "/data/fromMZ/CompiledData2.csv")) %>%
  filter(location != "OAK") %>%
  mutate(date = as.Date(date, format = "%m/%d/%Y"),
         L = str_remove(location, "REC"), 
         B = str_sub(block, 1,3), 
         Ps = str_replace(pasture, "[.]", ""), 
         Ps = str_sub(Ps, 1,2), 
         patch = str_replace(patch, "[.]", ""),
         y = format(date, "%y")) %>%
  unite("FireCode", c(L,B,Ps,patch,y), sep=".") %>%
  mutate(time = str_remove(MaxTempTime, "[.]+[0-9]"))%>%
  unite(timestamp, c(date, time), sep = " ") %>%
  mutate(timestamp = as.POSIXct(timestamp, format = "%Y-%m-%d %H:%M:%S")) %>%
  select(FireCode, timestamp, plot, array, TC, MaxC, 
         AirTemp, RH, dpC, WindSpeed, 
         LAI, FMC, KgHa) 
# Isolate soil surface temperature (TC 4)
SoilTemp <-
  filter(AllData, TC == 4) %>%
  select(FireCode, plot, array, MaxC) %>%
  rename(SoilC = MaxC)
# Summarize array-level data 
DataMeans <- 
  AllData %>%
  filter(TC %in% c('1', '2', '3')) %>% 
  select(-timestamp) %>%
  pivot_longer(cols = c(MaxC:KgHa), 
               names_to = "var",
               values_to = "value") %>%
  group_by(FireCode, plot, array, var) %>%
  summarize(Mean = mean(value) ) %>%
  ungroup() %>%
  pivot_wider(names_from = var, 
              values_from = Mean) 
# Calculate Vapor Pressure Deficit
DataMeans <- 
  DataMeans %>%
  mutate(e  = 6.11*(10^((7.5*dpC)/(237.3+dpC))), 
         es = 6.11*(10^((7.5*AirTemp)/(237.3+AirTemp))), 
         VPD = es - e) %>%
  select(-e, -es)
# Calculate rate of spread by arrival time of flame front at sensors 
D = 1   # Distance between thermocouples (m)
ROS <- 
  AllData %>%
  filter(TC %in% c('1', '2', '3')) %>%
  mutate(timestamp = format(timestamp, "%H:%M:%S"), 
         ArrivalTime = seconds(hms(timestamp)) ) %>%
  select(FireCode, plot, array, ArrivalTime) %>%
  group_by(FireCode, plot, array) %>%
  arrange(ArrivalTime, .by_group = TRUE) %>% 
  mutate(position = order(order(ArrivalTime, decreasing=FALSE)), 
         position = recode(position, "1"="a", "2"="b", "3"="c"), 
         ArrivalTime = as.numeric(ArrivalTime) /60 ) %>%
  spread(position, ArrivalTime)  %>%
  ungroup %>% 
  # Apply equations from Simard et al. (1984)
  mutate( theta_rad = atan((2*c - b - a) / (sqrt(3)*(b - a))), 
          ros = case_when(
            a == b ~ (sqrt(3) / 2) / (c - a) , 
            a != b ~  (D*cos(theta_rad) / (b - a) ) 
          )) %>%
  select(-a, -b, -c, -theta_rad)
#
# Create final tibble for analysis 
#
AnalysisData  <- 
  full_join(DataMeans, ROS) %>%
  left_join(SoilTemp) %>%
  filter( ros <= 40,       # remove outliers
          MaxC >= 40) %>%  # ditto
  rename(FuelMoisture = FMC, 
         SoilMaxC = SoilC) %>%
  mutate(FuelMoisture = ifelse(FuelMoisture >= 0, 
                               FuelMoisture, NA), 
         FuelMoisture = FuelMoisture * 100) %>%
  separate(FireCode, into = c("location", "block", "pasture", 
                              "patch", "year"), 
           remove = F)