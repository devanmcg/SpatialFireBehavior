pacman::p_load(tidyverse, lubridate)

# wd_fp = "C:/Users/devan/GitHubProjects/SpatialFireBehavior/" # home PC

wd_fp = getwd() # machine-independent?

# Pull data from .csv created from MZ's compiled Excel file (tab = All)

  AllData <-  
    read_csv(paste0(wd_fp, "/data/fromMZ/CompiledData2.csv")) %>%
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
               AirTemp, RH, dpC, MaxWindSpeed, 
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
    
  
# Calculate ROS 

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
    mutate( theta_rad = atan((2*c - b - a) / (sqrt(3)*(b - a))), 
            ros = case_when(
              a == b ~ (sqrt(3) / 2) / (c - a) , 
              a != b ~  (D*cos(theta_rad) / (b - a) ) 
            )) %>%
    select(-a, -b, -c, -theta_rad)
  
# Combine data into final tibble for analysis 
  
  CompData <- full_join(DataMeans, ROS) %>%
                left_join(SoilTemp)
  
  
