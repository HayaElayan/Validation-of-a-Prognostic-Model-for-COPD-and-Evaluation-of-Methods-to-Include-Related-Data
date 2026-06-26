library(ggplot2)
library(wacolors)
library(tidyr)
library(dplyr)
library(stringr)
library(gridExtra)
library(cowplot)

#bootstrap apparent with calculated confidence interval csv file
result_df<- read.csv("bootstrap_external_validation_MoreRecentData.csv") #read.csv("bootstrap_apparent_ci.csv")##


result_df<- result_df[result_df$model_name != "Membership-based weighted model (weights limited to 1)"
                                & result_df$model_name != "Naive Logistic-developed on full data" 
                      & result_df$model_name != "Naive Logistic-developed on source only",]
result_df

result_df$model_name[result_df$model_name == "Membership-based weighted model (weights limited to 1 + Forgetting factor)"] <- "Membership-based recalibration"

result_df$model_name[result_df$model_name == "Naive Logistic-developed on target only"]<-"Target-only"
result_df$model_name[result_df$model_name == "Intercept recalibration-developed on source only"]<-"Intercept Recalibration-ancillary only"
result_df$model_name[result_df$model_name == "Intercept recalibration-developed on full data"]<-"Intercept Recalibration-all data" 
result_df$model_name[result_df$model_name == "Logistic recalibration-developed on full data"]<-"Logistic Recalibration-all data"
result_df$model_name[result_df$model_name == "Logistic recalibration-developed on source only"]<-"Logistic Recalibration-ancillary only"

result_df$model_name <- factor(result_df$model_name, levels = c("Membership-based recalibration",
                                                                          "Intercept Recalibration-ancillary only",
                                                                          "Intercept Recalibration-all data" ,
                                                                          "Logistic Recalibration-ancillary only",
                                                                          "Logistic Recalibration-all data",
                                                                          "Target-only"
))

labels <- c('AUC', 'CITL', 'CSLOPE', 'BrierScore')
labels2 <- c('AUC', 'CITL', 'CSLOPE', 'Brier Score')
legends <- list()
figs <- list()
plots <- 0


scaleFUN <- function(x) sprintf("%.4f", x)

for(i in 1:4){
  data <- result_df[result_df$statistics==labels[i],]
  print(data)
  
  if(i==1){
    figs[[i]] <- ggplot(data, aes(y=model_name, x=mean, colour=model_name, shape=model_name)) +        # ggplot2 plot with confidence intervals
      geom_errorbar(aes(xmin =lower_band, xmax =upper_band), width = 0
      )  + geom_point(size=2) +
      theme( axis.text.y = element_text(size = 7),
             axis.title.y = element_blank(),
             axis.title.x = element_text(size = 8),
             axis.text.x = element_text(size = 7.5),
             legend.position = 'none',  # Remove legend
             panel.background = element_rect(fill = "white", color = "gray"),  # White background with black borders
             panel.grid.major = element_line(color = "gray", size = 0.07),  # Light gray grid lines
             panel.grid.minor = element_line(color = "gray", size = 0.07),  # Minor grid lines
             strip.background = element_blank() 
      )+ labs(x= labels2[i], colour="model_name", shape="model_name"
      )+ scale_x_continuous(breaks = c(0.78 , 0.79,0.80), limits = c(0.78, 0.81))
  }
  if(i==2){
    figs[[i]] <-ggplot(data, aes(y=model_name, x=mean, colour=model_name, shape=model_name)) +  
      geom_vline(xintercept = 0, linetype = "dashed", color = "black", size = 0.25) + # ggplot2 plot with confidence intervals
      geom_errorbar(aes(xmin =lower_band, xmax =upper_band), width = 0
      )  + geom_point(size=2) +
      theme(     axis.ticks.y = element_blank(), axis.text.y =element_blank(),
                 axis.title.y = element_blank(),
                 axis.title.x = element_text(size = 8),
                 axis.text.x = element_text(size = 7),
                 legend.position = 'none',  # Remove legend
                 panel.background = element_rect(fill = "white", color = "gray"),  # White background with black borders
                 panel.grid.major = element_line(color = "gray", size = 0.07),  # Light gray grid lines
                 panel.grid.minor = element_line(color = "gray", size = 0.07),  # Minor grid lines
                 strip.background = element_blank() 
      )+ labs(x= labels2[i], colour="model_name", shape="model_name"
      )+ scale_x_continuous(breaks = c(0, 0.06 , 0.13), limits = c(0, 0.13))
      #scale_x_continuous(breaks = scales::pretty_breaks(n = 5)) #+ #
    
  }
  if(i==3){
    figs[[i]] <-ggplot(data, aes(y=model_name, x=mean, colour=model_name, shape=model_name)) +  
      geom_vline(xintercept = 1, linetype = "dashed", color = "black", size = 0.25) + # ggplot2 plot with confidence intervals
      geom_errorbar(aes(xmin =lower_band, xmax =upper_band), width = 0
      )  + geom_point(size=2) +
      theme(     axis.ticks.y = element_blank(), axis.text.y =element_blank(),
                 axis.title.y = element_blank(),
                 axis.title.x = element_text(size = 8),
                 axis.text.x = element_text(size = 7.5),
                 legend.position = 'none',  # Remove legend
                 panel.background = element_rect(fill = "white", color = "gray"),  # White background with black borders
                 panel.grid.major = element_line(color = "gray", size = 0.07),  # Light gray grid lines
                 panel.grid.minor = element_line(color = "gray", size = 0.07),  # Minor grid lines
                 strip.background = element_blank() 
      )+ labs(x= labels2[i], colour="model_name", shape="model_name"
      )+scale_x_continuous(breaks = c(0.93, 0.97, 1, 1.05), limits = c(0.93, 1.05))
  }
  if(i==4){
    figs[[i]] <-ggplot(data, aes(y=model_name, x=mean, colour=model_name, shape=model_name)) +        # ggplot2 plot with confidence intervals
      geom_errorbar(aes(xmin =lower_band, xmax =upper_band), width = 0
      )  + geom_point(size=2) +
      theme( 
        axis.ticks.y = element_blank(), axis.text.y =element_blank(),
        axis.title.y = element_blank(),
        axis.title.x = element_text(size = 8),
        axis.text.x = element_text(size = 7),
        legend.position = 'none',  # Remove legend
        panel.background = element_rect(fill = "white", color = "gray"),  # White background with black borders
        panel.grid.major = element_line(color = "gray", size = 0.07),  # Light gray grid lines
        panel.grid.minor = element_line(color = "gray", size = 0.07),  # Minor grid lines
        strip.background = element_blank() 
      )+ labs(x= labels2[i], colour="model_name", shape="model_name"
      )+scale_x_continuous(breaks = c(0.12, 0.13 , 0.14), limits = c(0.12, 0.14))
    
  }
  
}

filename<- "external_validation_withCI_exisiting_data.pdf"

pdf(filename, width =8, height = 3)

combined_plot <- grid.arrange(figs[[1]],figs[[2]], figs[[3]],  figs[[4]], ncol = 4, nrow = 1, widths=c(1.9,0.95,0.95,0.95)
)

show(combined_plot)               
dev.off()                                         




dev.off()