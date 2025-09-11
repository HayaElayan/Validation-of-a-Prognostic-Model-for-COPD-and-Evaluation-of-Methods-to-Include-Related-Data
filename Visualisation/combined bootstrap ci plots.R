library(ggplot2)
library(wacolors)
library(tidyr)
library(dplyr)
library(stringr)
library(gridExtra)
library(cowplot)

#bootstrap apparent with calculated confidence interval csv file
boost_apparent<- read.csv("boot_apparent_ci_before2010_after2010_corrected_missing.csv") #read.csv("bootstrap_apparent_ci.csv")##

#bootstrap test with calculated confidence interval csv file
boost_test<- read.csv("boot_test_ci_before2010_after2010_corrected_missing.csv") #read.csv("bootstrap_apparent_ci.csv")##


boost_apparent<- boost_apparent[boost_apparent$model_name != "Membership-based weighted model (weights limited to 1)"
                                & boost_apparent$model_name != "Naive Logistic-developed on full data recalibrated",]
boost_apparent

boost_apparent$model_name[boost_apparent$model_name == "Membership-based weighted model (weights limited to 1 + Forgetting factor)"] <- "Membership-based recalibration"

boost_apparent$model_name[boost_apparent$model_name == "Naive Logistic-developed on target only"]<-"Target-only"
boost_apparent$model_name[boost_apparent$model_name == "Intercept recalibration-developed on source only"]<-"Intercept Recalibration-ancillary only"
boost_apparent$model_name[boost_apparent$model_name == "Intercept recalibration-developed on full data"]<-"Intercept Recalibration-all data" 
boost_apparent$model_name[boost_apparent$model_name == "Logistic recalibration-developed on full data"]<-"Logistic Recalibration-all data"
boost_apparent$model_name[boost_apparent$model_name == "Logistic recalibration-developed on source only"]<-"Logistic Recalibration-ancillary only"

boost_apparent$model_name <- factor(boost_apparent$model_name, levels = c("Membership-based recalibration",
                                                                          "Intercept Recalibration-ancillary only",
                                                                          "Intercept Recalibration-all data" ,
                                                                          "Logistic Recalibration-ancillary only",
                                                                          "Logistic Recalibration-all data",
                                                                          "Target-only"
))

labels <- c('AUC', 'CITL', 'CSLOPE', 'BrierScore')
labels2 <- c('Apparent AUC', 'Apparent CITL', 'Apparent CSLOPE', 'Apparent Brier Score')
legends <- list()
figs <- list()
plots <- 0


scaleFUN <- function(x) sprintf("%.4f", x)

for(i in 1:4){
  data <- boost_apparent[boost_apparent$statistics==labels[i],]
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
      )+ scale_x_continuous(breaks = scales::pretty_breaks(n = 2))
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
      )+scale_x_continuous(breaks = c(-0.001, 0 , 0.001), limits = c(-0.001, 0.001)) #+ scale_x_continuous(breaks = scales::pretty_breaks(n = 2)) 
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
      )+ scale_x_continuous(breaks = scales::pretty_breaks(n = 4))
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
      )+ scale_x_continuous(breaks = scales::pretty_breaks(n = 2))#+ scale_x_continuous(breaks = c(0.0020, 0.0021 , 0.0022), limits = c(0.0020, 0.0022))
    
    }
  
}


combined_plot <- grid.arrange(figs[[1]],figs[[2]], figs[[3]],  figs[[4]], ncol = 4, nrow = 1, widths=c(1.9,0.95,0.95,0.95)
)





boost_test<- boost_test[boost_test$model_name != "Membership-based weighted model (weights limited to 1)"
                                & boost_test$model_name != "Naive Logistic-developed on full data recalibrated",]
boost_test

boost_test$model_name[boost_test$model_name == "Membership-based weighted model (weights limited to 1 + Forgetting factor)"] <- "Membership-based recalibration"

boost_test$model_name[boost_test$model_name == "Naive Logistic-developed on target only"]<-"Target-only"
boost_test$model_name[boost_test$model_name == "Intercept recalibration-developed on source only"]<-"Intercept Recalibration-ancillary only"
boost_test$model_name[boost_test$model_name == "Intercept recalibration-developed on full data"]<-"Intercept Recalibration-all data" 
boost_test$model_name[boost_test$model_name == "Logistic recalibration-developed on full data"]<-"Logistic Recalibration-all data"
boost_test$model_name[boost_test$model_name == "Logistic recalibration-developed on source only"]<-"Logistic Recalibration-ancillary only"

boost_test$model_name <- factor(boost_test$model_name, levels = c("Membership-based recalibration",
                                                                          "Intercept Recalibration-ancillary only",
                                                                          "Intercept Recalibration-all data" ,
                                                                          "Logistic Recalibration-ancillary only",
                                                                          "Logistic Recalibration-all data",
                                                                          "Target-only"
))

labels <- c('AUC', 'CITL', 'CSLOPE', 'BrierScore')
labels2 <- c('Test AUC', 'Test CITL', 'Test CSLOPE', 'Test Brier Score')
legends <- list()
figs <- list()
plots <- 0


scaleFUN <- function(x) sprintf("%.4f", x)

for(i in 1:4){
  data <- boost_test[boost_test$statistics==labels[i],]
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
      )+ #scale_x_continuous(breaks = scales::pretty_breaks(n = 2))
      scale_x_continuous(breaks = c(0.795, 0.8), limits = c(0.795, 0.8))
  }
  if(i==2){
    figs[[i]] <-ggplot(data, aes(y=model_name, x=mean, colour=model_name, shape=model_name)) +  
      geom_vline(xintercept = 0, linetype = "dashed", color = "black", size = 0.25) + # ggplot2 plot with confidence intervals
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
      )+ #scale_x_continuous(breaks = scales::pretty_breaks(n = 3))
      scale_x_continuous(breaks = c(-0.05, 0, 0.05), limits = c(-0.05, 0.05))
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
      )+ scale_x_continuous(breaks = scales::pretty_breaks(n = 4))
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
      )+  scale_x_continuous(breaks = scales::pretty_breaks(n = 3))#+
     # scale_x_continuous(breaks = c(0.1250, 0.1255, 0.1260), limits = c(0.1250, 0.1260))
    #scale_x_continuous(breaks = c(0.12, 0.13, 0.14), limits = c(0.1186, 0.1215))
 
  }
  
}

#filename<- "bootstrap_apparent_ci.pdf"


combined_plot2 <- grid.arrange(figs[[1]],figs[[2]], figs[[3]],  figs[[4]], ncol = 4, nrow = 1, widths=c(1.9,0.95,0.95,0.95)
)


filename<- "bootstrap_CI-before2010_after2010_corrected_missing.pdf"

pdf(filename, width =8, height = 4.5)
combined_plot3 <- grid.arrange(combined_plot, combined_plot2, ncol = 1, nrow = 2)

dev.off()


