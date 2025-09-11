library(ggplot2)
library(wacolors)
library(tidyr)
library(dplyr)
library(stringr)
library(gridExtra)
library(cowplot)
require(plyr)
library(stringr)
library(ggplot2)
library("ggpubr")
library(gridExtra)
library(viridis)
library(plotly)
library(scales)
library(wacolors)
library(ggthemes)

#apparent optimsim adjusted results csv file
df<- read.csv("issue_fixed_results/fixed_results/apparent_optadjust_val-all_vs_region7-corrected_missing_TimeRegion.csv") 

df<- df[df$Model_name != "Membership-based weighted model (weights limited to 1)" & df$Model_name != "Naive Logistic-developed on full data recalibrated",]
df

df$Model_name[df$Model_name == "Membership-based weighted model (weights limited to 1 + Forgetting factor)"] <- "Membership-based recalibration"

df$Model_name[df$Model_name == "Naive Logistic-developed on target only"]<-"Target-only"
df$Model_name[df$Model_name == "Intercept recalibration-developed on source only"]<-"Intercept Recalibration-ancillary only"
df$Model_name[df$Model_name == "Intercept recalibration-developed on full data"]<-"Intercept Recalibration-all data" 
df$Model_name[df$Model_name == "Logistic recalibration-developed on full data"]<-"Logistic Recalibration-all data"
df$Model_name[df$Model_name == "Logistic recalibration-developed on source only"]<-"Logistic Recalibration-ancillary only"

df$Model_name <- factor(df$Model_name, levels = c("Membership-based recalibration",
                                                                          "Intercept Recalibration-ancillary only",
                                                                          "Intercept Recalibration-all data" ,
                                                                          "Logistic Recalibration-ancillary only",
                                                                          "Logistic Recalibration-all data",
                                                                          "Target-only"
))




library(reshape2)
df <-
  (melt(df, id.vars = c(
    "Model_name", "Statistic"
  )))

df$variable <- mapvalues(df$variable, 
                         from=c("apparent", "Optimisim_Adjusted"), 
                         to=c(
                           "Optimism-Unadjusted (apparent)","Optimism-Adjusted"
                         ))



labels <- c('AUC', 'CITL', 'CSLOPE', 'BrierScore')
legends <- list()
figs <- list()
plots <- 0
aggs <- list()

scaleFUN <- function(x) sprintf("%.4f", x)

for(i in 1:4){
  data <- df[df$Statistic==labels[i],]
  print(data)
  
  if(i==1){
    figs[[i]] <- ggplot(data, aes(y=Model_name, x=value, colour=variable, shape=variable))  + geom_point(size=2) +theme(
      legend.position = 'bottom',
      legend.title = element_blank(),
      legend.text=element_text(size=8),
      axis.text.y=element_text(size=7), axis.text.x=element_text(size=7.5), axis.title.y=element_blank(), axis.title.x=element_text(size=8),
      panel.background = element_rect(fill = "white", color = "gray"),  # White background with black borders
      panel.grid.major = element_line(color = "gray", size = 0.07),  # Light gray grid lines
      panel.grid.minor = element_line(color = "gray", size = 0.07),  # Minor grid lines
      strip.background = element_blank() 
    ) + labs(x = labels[i]) +scale_x_continuous(breaks = c( 0.78, 0.80 , 0, 0.82), limits = c(0.78 , 0.82))
    #+ scale_x_continuous(breaks = scales::pretty_breaks(n = 3)) 

  }
  
  if(i==2){
    figs[[i]] <- ggplot(data, aes(y=Model_name, x=value, colour=variable, shape=variable)) +
      geom_vline(xintercept = 0, linetype = "dashed", color = "black", linewidth = 0.25) + geom_point(size=2 )  +theme(
        legend.position='none'  , axis.ticks.y = element_blank(), axis.text.y =element_blank(), 
        axis.title.y=element_blank(),axis.text.x=element_text(size=7.5), axis.title.x=element_text(size=8),
        panel.background = element_rect(fill = "white", color = "gray"),  # White background with black borders
        panel.grid.major = element_line(color = "gray", size = 0.07),  # Light gray grid lines
        panel.grid.minor = element_line(color = "gray", size = 0.07),  # Minor grid lines
        strip.background = element_blank() 
      ) + labs(x = labels[i])+scale_x_continuous(breaks = c(-0.01, 0 , 0.01), limits = c(-0.01, 0.01)) #+scale_x_continuous(breaks = scales::pretty_breaks(n = 2)) 
  }
  if(i==3){
    figs[[i]] <- ggplot(data, aes(y=Model_name, x=value, colour=variable, shape=variable))  + 
      geom_vline(xintercept = 1, linetype = "dashed", color = "black", linewidth = 0.25)  + 
      geom_point(size=2 ) +theme(
        legend.position='none'  , axis.ticks.y = element_blank(), axis.text.y =element_blank(), 
        axis.title.y=element_blank(), axis.text.x=element_text(size=7.5),axis.title.x=element_text(size=8),
        panel.background = element_rect(fill = "white", color = "gray"),  # White background with black borders
        panel.grid.major = element_line(color = "gray", size = 0.07),  # Light gray grid lines
        panel.grid.minor = element_line(color = "gray", size = 0.07),  # Minor grid lines
        strip.background = element_blank() 
      ) + labs(x = labels[i])+ #scale_x_continuous(breaks = scales::pretty_breaks(n = 4)) 
    scale_x_continuous(breaks = c(0.8, 0.9, 1), limits = c(0.8, 1.01))
    
    
  }
  if(i==4){
    figs[[i]] <- ggplot(data, aes(y=Model_name, x=value, colour=variable, shape=variable))   + geom_point(size=2 )+
      theme( legend.position='none'  ,
             axis.ticks.y = element_blank(), axis.text.y =element_blank(), 
             axis.title.y=element_blank(), axis.text.x=element_text(size=7.5),axis.title.x=element_text(size=8),
             panel.background = element_rect(fill = "white", color = "gray"),  # White background with black borders
             panel.grid.major = element_line(color = "gray", size = 0.07),  # Light gray grid lines
             panel.grid.minor = element_line(color = "gray", size = 0.07),  # Minor grid lines
             strip.background = element_blank() 
      ) + labs(x = "Brier Score") +#+ scale_x_continuous(breaks = scales::pretty_breaks(n = 3))
      scale_x_continuous(breaks = c(0.11,0.12, 0.13), limits = c(0.11 , 0.13))
    
    
  }
  

}


filename<- "adjusted_unadjusted_results-all_vs_region7-corrected_missing_TimeRegion.pdf"
pdf(filename, width =8, height = 3)
combined_plot <- annotate_figure(ggarrange(figs[[1]],figs[[2]], figs[[3]],  figs[[4]], 
                              ncol = 4, nrow = 1, widths=c(1.9,0.98,0.95,0.95), legend='none'))

combined_plot<- grid.arrange(combined_plot, get_legend(figs[[1]]), ncol = 1, heights = c(1, 0.1))
show(combined_plot)               
dev.off()                                         
