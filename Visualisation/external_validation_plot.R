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

#External validation csv file 
df<- read.csv("external_validation-before2010_after2010_corrected_missing.csv") 

df<- df[df$model_name != "Membership-based weighted model (weights limited to 1)" & df$model_name != "Naive Logistic-developed on full data" & df$model_name!= "Naive Logistic-developed on source only",]
df

df$model_name[df$model_name == "Membership-based weighted model (weights limited to 1 + Forgetting factor)"] <- "Membership-based recalibration"

df$model_name[df$model_name == "Naive Logistic-developed on target only"]<-"Target-only"
df$model_name[df$model_name == "Intercept recalibration-developed on source only"]<-"Intercept Recalibration-ancillary only"
df$model_name[df$model_name == "Intercept recalibration-developed on full data"]<-"Intercept Recalibration-all data" 
df$model_name[df$model_name == "Logistic recalibration-developed on full data"]<-"Logistic Recalibration-all data"
df$model_name[df$model_name == "Logistic recalibration-developed on source only"]<-"Logistic Recalibration-ancillary only"

df$model_name <- factor(df$model_name, levels = c("Membership-based recalibration",
                                                  "Intercept Recalibration-ancillary only",
                                                  "Intercept Recalibration-all data" ,
                                                  "Logistic Recalibration-ancillary only",
                                                  "Logistic Recalibration-all data",
                                                  "Target-only"
))






labels <- c('AUC', 'CITL', 'CSLOPE', 'BrierScore')
legends <- list()
figs <- list()
plots <- 0
aggs <- list()

scaleFUN <- function(x) sprintf("%.4f", x)

for(i in 1:4){
  data <- df#[df$Statistic==labels[i],]
  print(data)
  
  if(i==1){
    figs[[i]] <- ggplot(data, aes(y=model_name, x=AUC, colour=model_name, shape=model_name))  + geom_point(size=2) +theme(
      legend.position = 'bottom',
      legend.title = element_blank(),
      legend.text=element_text(size=8),
      axis.text.y=element_text(size=7), axis.text.x=element_text(size=7.5), axis.title.y=element_blank(), axis.title.x=element_text(size=8),
      panel.background = element_rect(fill = "white", color = "gray"),  # White background with black borders
      panel.grid.major = element_line(color = "gray", size = 0.07),  # Light gray grid lines
      panel.grid.minor = element_line(color = "gray", size = 0.07),  # Minor grid lines
      strip.background = element_blank() 
    ) + labs(x = labels[i]) +# scale_x_continuous(breaks = scales::pretty_breaks(n = 3)) 
     scale_x_continuous(breaks = c(0.79 , 0.8), limits = c(0.79, 0.8))
    
  }
  
  if(i==2){
    figs[[i]] <- ggplot(data, aes(y=model_name, x=CITL, colour=model_name, shape=model_name)) +
      geom_vline(xintercept = 0, linetype = "dashed", color = "black", linewidth = 0.25) + geom_point(size=2 )  +theme(
        legend.position='none'  , axis.ticks.y = element_blank(), axis.text.y =element_blank(), 
        axis.title.y=element_blank(),axis.text.x=element_text(size=7.5), axis.title.x=element_text(size=8),
        panel.background = element_rect(fill = "white", color = "gray"),  # White background with black borders
        panel.grid.major = element_line(color = "gray", size = 0.07),  # Light gray grid lines
        panel.grid.minor = element_line(color = "gray", size = 0.07),  # Minor grid lines
        strip.background = element_blank() 
      ) + labs(x = labels[i]) + #+scale_x_continuous(breaks = scales::pretty_breaks(n = 3)) 
    scale_x_continuous(breaks = c(0 , 0.03, 0.06, 0.09), limits = c(0, 0.09))
  }
  if(i==3){
    figs[[i]] <- ggplot(data, aes(y=model_name, x=CSLOPE, colour=model_name, shape=model_name))  + 
      geom_vline(xintercept = 1, linetype = "dashed", color = "black", linewidth = 0.25)  + 
      geom_point(size=2 ) +theme(
        legend.position='none'  , axis.ticks.y = element_blank(), axis.text.y =element_blank(), 
        axis.title.y=element_blank(), axis.text.x=element_text(size=7.5),axis.title.x=element_text(size=8),
        panel.background = element_rect(fill = "white", color = "gray"),  # White background with black borders
        panel.grid.major = element_line(color = "gray", size = 0.07),  # Light gray grid lines
        panel.grid.minor = element_line(color = "gray", size = 0.07),  # Minor grid lines
        strip.background = element_blank() 
      ) + labs(x = labels[i]) +#+scale_x_continuous(breaks = scales::pretty_breaks(n = 2)) 
      scale_x_continuous(breaks = c(0.98,0.99, 1), limits = c(0.98, 1))
    
    
  }
  if(i==4){
    figs[[i]] <- ggplot(data, aes(y=model_name, x=BrierScore, colour=model_name, shape=model_name))   + geom_point(size=2 )+
      theme( legend.position='none'  ,
             axis.ticks.y = element_blank(), axis.text.y =element_blank(), 
             axis.title.y=element_blank(), axis.text.x=element_text(size=7.5),axis.title.x=element_text(size=8),
             panel.background = element_rect(fill = "white", color = "gray"),  # White background with black borders
             panel.grid.major = element_line(color = "gray", size = 0.07),  # Light gray grid lines
             panel.grid.minor = element_line(color = "gray", size = 0.07),  # Minor grid lines
             strip.background = element_blank() 
      ) + labs(x = "Brier Score") + #+ scale_x_continuous(breaks = scales::pretty_breaks(n =2))
    scale_x_continuous(breaks = c(0.13 , 0.14), limits = c(0.13 , 0.14))
    
    
  }
  
  
}


filename<- "external_validation-before2010_after2010_corrected_missing.pdf"

pdf(filename, width =8, height = 3)
combined_plot <- annotate_figure(ggarrange(figs[[1]],figs[[2]], figs[[3]],  figs[[4]], 
                                           ncol = 4, nrow = 1, widths=c(1.9,0.98,0.95,0.95), legend='none'))

#combined_plot<- grid.arrange(combined_plot, get_legend(figs[[1]]), ncol = 1, heights = c(1, 0.1))
show(combined_plot)               
dev.off()                                         
