external_boot <- read.csv("external_boot_validation-OverTime-refitted_only.csv") 

all_mets <- data.frame(matrix(ncol = 4, nrow = 0))
names <- c("mean","lower_band","upper_band", "statistics")
colnames(all_mets) <- names

get_ci <- function(df){ 
  mets <- c('AUC', 'CITL', 'CSLOPE', 'BrierScore')
  for(met in mets){
    df2 <- sort(df[[met]])
    all_mets[nrow(all_mets) + 1,] <<- list(mean = round(mean(df2),3), lower_band= round(df2[5],3), upper_band = round(df2[195],3), met)
  }
}

get_ci(external_boot)
all_mets

rm(list = ls())
##########################

external_boot <- read.csv("external_boot_validation-Region1NorthEast-refitted_only.csv") 

all_mets <- data.frame(matrix(ncol = 4, nrow = 0))
names <- c("mean","lower_band","upper_band", "statistics")
colnames(all_mets) <- names

get_ci <- function(df){ 
  mets <- c('AUC', 'CITL', 'CSLOPE', 'BrierScore')
  for(met in mets){
    df2 <- sort(df[[met]])
    all_mets[nrow(all_mets) + 1,] <<- list(mean = round(mean(df2),3), lower_band= round(df2[5],3), upper_band = round(df2[195],3), met)
  }
}

get_ci(external_boot)
all_mets

rm(list = ls())
##########################

external_boot <- read.csv("external_boot_validation-Region7London-refitted_only.csv") 

all_mets <- data.frame(matrix(ncol = 4, nrow = 0))
names <- c("mean","lower_band","upper_band", "statistics")
colnames(all_mets) <- names

get_ci <- function(df){ 
  mets <- c('AUC', 'CITL', 'CSLOPE', 'BrierScore')
  for(met in mets){
    df2 <- sort(df[[met]])
    all_mets[nrow(all_mets) + 1,] <<- list(mean = round(mean(df2),3), lower_band= round(df2[5],3), upper_band = round(df2[195],3), met)
  }
}

get_ci(external_boot)
all_mets

