pacman::p_load(tidyverse, vegan) 
source("https://raw.githubusercontent.com/devanmcg/IntroRangeR/master/11_IntroMultivariate/ordinationsGGplot.R")

# Fire behavior PCA 
  fb_d <- 
    imp_raw %>%
    select(MaxC, ros, SoilMaxC) 
  
  fb_pca <- rda(fb_d ~ 1, 'euc', scale = T)
  
  summary(fb_pca)$cont$importance 
  
  plot(fb_pca)
  ordispider(fb_pca, groups =imp_raw$location, label = T)
  text(fb_pca, "species")
  
  envfit(fb_pca ~ location, imp_raw, 
         choices = c(1:3), 
         strata = imp_raw$year, 
         199)
  envfit(fb_pca ~ MaxWindSpeed + AirTemp + dpC + RH + VPD + HDWI, 
         data = imp_raw, 
         choices = c(1:3), 
         strata = imp_raw$location)  

  
  # get ord data for ggplotting
  pca_gg <- gg_ordiplot(fb_pca, groups = imp_raw$location, 
                        plot=FALSE)
  
  pca_spp <- # species only; sites come later
    scores(fb_pca, display = "species") %>%
    as.data.frame %>%
    as_tibble(rownames="response")
  
  # Vectors 
  pca_v <- envfit(fb_pca ~ RH + VPD, imp_raw, 
                  choices = c(1:3), 
                  strata = imp_raw$location)
  pca_vd <- scores(pca_v,  "vectors") %>%
            as.data.frame %>% 
            round(3) %>%
            as_tibble(rownames="gradient") 
  
  pca_scores <- lst(species=pca_spp, 
                    vectors=pca_vd)
  pca_scores$spiders <-
    pca_gg$df_spiders %>% 
    rename(PC1 = x, PC2 = y) %>%
    as_tibble

  # gg plot
  
  ggplot() + theme_bw(16) + 
    labs(x="PC 1", 
         y="PC 2") + 
    geom_vline(xintercept = 0, lty=3, color="darkgrey") +
    geom_hline(yintercept = 0, lty=3, color="darkgrey") +
    geom_point(data=pca_scores$spiders, 
                        aes(x=PC1, y=PC2, 
                            shape=Group, 
                            colour=Group), 
                        size=2)  +   
    geom_segment(data=pca_scores$spiders, 
                 aes(x=cntr.x, y=cntr.y,
                     xend=PC1, yend=PC2, 
                     color=Group), 
                 size=1.2, 
                 alpha = 0.75) +
    geom_point(data=pca_scores$spiders, 
               aes(x=PC1, y=PC2, fill=Group), 
               colour="grey40", 
               pch=21, 
               size=3, 
               stroke=2, alpha = 0.75) +
    geom_label(data=pca_scores$spiders,
               aes(x=cntr.x,
                   y=cntr.y,
                   label=Group,
                   color=Group),
               fontface="bold", size=4,
               label.size = 0,
               label.r = unit(0.5, "lines")) +
    geom_segment(data=pca_scores$vectors, 
                 aes(x=0, y=0, 
                     xend=PC1*1.6, 
                     yend=PC2*1.6),
                 arrow=arrow(length = unit(0.03, "npc")),
                 lwd=1.5) +
    geom_text(data=pca_scores$vectors,
              aes(x=PC1*1.5, 
                  y=PC2*1.5, 
                  label=gradient), 
              nudge_x = 0.06, 
              nudge_y =-0.05, 
              size=6, fontface="bold") + 
    geom_label(data=pca_scores$species, 
                aes(x=PC1/3, 
                    y=PC2/2, 
                    label=response), 
                label.padding=unit(0.25,"lines"),
                label.size = 0.5, 
                fontface="bold", 
               color="darkred") +
    
    scale_color_manual(values = cbPal5[1:2]) + 
    scale_fill_manual(values = cbPal5[1:2])  +
    theme(panel.grid=element_blank(), 
          legend.position="none") 
    
  