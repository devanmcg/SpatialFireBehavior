pacman::p_load(tidyverse, lubridate)

FilePath = getwd()

  AllData <-  
    read_csv(paste0(FilePath, "data/fromMZ/CompiledData2.csv")) %>%
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
  
# Calculate Hot-Dry-Windy Index
  DataMeans <- 
    DataMeans %>%
      mutate(e  = 6.11 * (10 ^ ( (7.5 * dpC)/ (237.3 + dpC) ) ), 
             es = 6.11 * (10 ^ ( (7.5 * AirTemp)/ (237.3 + AirTemp) ) ), 
             VPD = es - e) %>%
      select(-e, -es)


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
  
  
# Combine, filter, and convert data into final tibble for analysis 

  AnalysisData  <- 
    full_join(DataMeans, ROS) %>%
    left_join(SoilTemp) %>%
    filter( ros <= 40, 
            MaxC >= 40) %>%
    rename(FuelMoisture = FMC, 
           SoilMaxC = SoilC) %>%
    mutate(FuelMoisture = ifelse(FuelMoisture >= 0, 
                                 FuelMoisture, NA), 
           tHa = KgHa/1000) %>%
    separate(FireCode, into = c("location", "block", "pasture", 
                                "patch", "year"), 
             remove = F) %>%
    select(-KgHa)

# save(AnalysisData, file = paste0(FilePath, "/data/AnalysisData.Rdata"))
