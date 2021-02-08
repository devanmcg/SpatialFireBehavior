load(paste0(FilePath, '/r objects/imp_sc.Rdata'))

imp_sc 
# RE.gam.var <- function(x) {
#   require(lme4)
  var.mod <- lme4::glmer(ros ~ (1|location:year) +
                         (1|location:pasture:year)
                         (1|location:pasture:plot:year), 
                         Gamma(link = "log"), 
                         data=imp_sc) 
  transect.var <- (attr(VarCorr(var.mod)$'transect.num:year',"stddev"))^2
  year.var <- (attr(VarCorr(var.mod)$'year',"stddev"))^2 
  var.results<-array(NA,c(1,2))
  colnames(var.results)<-c("transect.var","year.var")
  var.results[1,] <- round(c(transect.var, year.var), 4) 
  return(var.results)	
  # }
  
  imp_chr <-  imp_raw  %>% 
                mutate(across(location:array, as.character)) 
                
  var.mod <- lme4::glmer(ros ~ 1 + (1|pasture:plot:array:year) +
                                (1|pasture:plot:year) +
                                (1|location) , 
                         Gamma(link = "log"), 
                         data=imp_chr, 
                         control=lme4::glmerControl(optimizer="bobyqa", 
                                                    optCtrl=list(maxfun=100000)) ) 
  
  ros_var <- glmmADMB::glmmadmb(ros ~ 1 ,
                                 random = ~ (1|pasture:plot:array:year) +
                                            (1|pasture:plot:year) +
                                            (1|location),
                                 data=imp_sc,
                                 family="gamma",
                                 link="log") 
  attr(lme4::VarCorr(ros_var)$'location:year',"StdDev")
  
  lme4::VarCorr(ros_var)[3]  
  
  lme4::VarCorr(ros_var)  
  
  vc <- unlist(lme4::VarCorr(ros_var)) %>%
    as.data.frame( ) %>%
    rownames_to_column('scale')
    colnames(vc) <- c('array', 'plot', 'location')
  
  unique(imp_chr$plot)  
  
  var_mod <- lme4::glmer(ros ~ 1 + (1|FireCode:plot:array) +
                           (1|FireCode:plot)  , 
                         Gamma(link = "log"), 
                         data=imp_chr, 
                         control=lme4::glmerControl(optimizer="bobyqa", 
                                                    optCtrl=list(maxfun=100000)) )
  