
AnalysisData %>%
  select(location, tempC, ros, SoilMaxC) %>%
  pivot_longer(names_to = "response", 
               values_to = "value", 
               -location) %>%
  mutate(location = recode(location, 
                           CG = "Streeter", 
                           H = "Hettinger"), 
         response = recode(response, 
                           tempC = "Max canopy temp (C)", 
                           ros = "Rate of spread (m/s)", 
                           SoilMaxC = "Max soil surface temp (C)")) %>%
  ggplot() + theme_bw(16) +
  geom_boxplot(aes(x=location, y = value, fill=location), 
               size = 1)  + 
  labs(y = '', 
       x = 'Research station') + 
  facet_wrap(~response, scales = "free_y") +
  scale_fill_viridis_d(option='plasma', guide = F, alpha = 0.5) + 
  theme(panel.grid.major.x = element_blank(), 
        axis.text.x = element_text(color='black'), 
        strip.background = element_rect(fill = 'lightblue')) 
