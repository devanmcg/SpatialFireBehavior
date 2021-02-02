
 
# Importing and converting data
hrec.FT.shp <- rgdal::readOGR(dsn="C:/Users/devan.mcgranahan/GoogleDrive/QGIS/HREC/sampling/FireBehavior",
                     layer="FireTowerPlacements")
 
 hrec.FT.shp@data$id <- rownames(hrec.FT.shp@data)
    hrec.FT.df <- broom::tidy(hrec.FT.shp, region="id")
    hrec.FT.df <- plyr::rename(hrec.FT.df, c("coords.x1"="lon", 
                                             "coords.x2"="lat")) 
    hrec.FT.df$PastureRep <- tolower(hrec.FT.df$PastureRep)
    hrec.FT.df$Livestock <- tolower(hrec.FT.df$Livestock)
    # save(hrec.FT.df, file="./r objects/hrec.FT.df.Rdata")
    
# Plot tower locations for datasheet
 pacman::p_load(ggplot2)
 source("C:/Users/devan.mcgranahan/GoogleDrive/code snippets/ggplot themes/theme_map2.R")
 load("C:/Users/devan.mcgranahan/GoogleDrive/QGIS/HREC/r objects/hrec.patches.df.Rdata")
 load("C:/Users/devan.mcgranahan/GoogleDrive/Research/Projects/SpatialFireBehavior/r objects/hrec.FT.df.Rdata")
 
 hett.FT.gg <- ggplot()  + theme_map2() +coord_quickmap() +
    geom_polygon(data=hrec.patches.df, aes(x=long, y=lat, 
                                         group=group, fill=status2017), 
               color="black", size=0.25, 
               show.legend=FALSE) +
   geom_point(data=hrec.FT.df, aes(x=lon, y=lat), 
               show.legend=FALSE) + 
  scale_fill_manual(values= c("lightgrey", "white"))+ 
   facet_wrap(~PastureRep, 
                     scales="free", ncol=1)
   
 hett.FT.gg +
   geom_text(data=hrec.patches.df, aes(x=long, y=lat, label=Patch))
  geom_point(data=res, aes(x=lon, y=lat))
  
  vegan::envfit(X=hrec.patches.df[13:14], P=hrec.patches.df$Patch)
  
  patch.cen <- vegan::envfit(c(hrec.patches.df$long, hrec.patches.df$lat) ~ Patch, hrec.patches.df)
  
  
 