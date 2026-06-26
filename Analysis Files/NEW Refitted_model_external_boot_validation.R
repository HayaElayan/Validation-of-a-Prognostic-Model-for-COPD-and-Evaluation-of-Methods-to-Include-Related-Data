#setwd("")

library(MLmetrics)
library(haven)
library(pROC)
library(DescTools)
library(dplyr)
############################ Over time ##################################
set.seed(386)
source("FUNCTIONS_BOOTSTRAP.R")
source("LAMBDA.R")
external_boot <- function(val_data, MODEL_NAME, model){
  
  test_val_results_df <-  data.frame(matrix(ncol = 6, nrow = 0))
  names <- c('AUC', 'CITL', 'CSLOPE', 'BrierScore',"boot_round","model_name")
  colnames(test_val_results_df) <- names
  
  
  for (i in 1:200) {
    set.seed(231396*i)
    samp_index_val <- sample(1:nrow(val_data), nrow(val_data), rep=TRUE) # create a sampling index vector
    
    bs_samp_val <- val_data[samp_index_val,] # index the orignal dataset using the sampling vector to give the bs sample
    
    val_external <- validation_results(model, bs_samp_val)$val_results
    
    
    val_external$model_name  <- MODEL_NAME
    val_external$boot_round<- i
    test_val_results_df <- rbind(test_val_results_df, val_external)
    
    print(i)
  }
  return(test_val_results_df)
}

#Read data
train <-read_dta("kiddle_data_before_missing.dta")
test <-read_dta("kiddle_validation_data_before_missing.dta")
kiddle_coef <- read.csv("reported_stats.csv")
practice <- read_dta("practice.dta")


data_preproess <- function(df){
  # Loop over each variable
  for (var in  c("bmi", "fev1pp")) {
    # Create a missing indicator variable
    df[[paste0(var, "_miss")]] <- as.numeric(is.na(df[[var]]))
    
    # Compute the median
    median_value <- median(df[[var]], na.rm = TRUE)
    
    # Replace missing values with the median
    df[[var]][is.na(df[[var]])] <- median_value
  }
  #Replace missingness in smoking
  
  df$smoke_status_k[is.na(df$smoke_status_k)] <- sample(df$smoke_status_k[!is.na(df$smoke_status_k)], 
                                                        sum(is.na(df$smoke_status_k)))
  
  
  
  # Loop over each variable
  for (var in  c("age_diag", "bmi", "fev1pp")) {
    
    # Compute the mean
    mean_value <- mean(df[[var]], na.rm = TRUE)
    
    # Create mean-centered variable
    df[[paste0(var, "_mean")]] <- df[[var]] - mean_value
    
    # Create quadratic term
    df[[paste0(var, "_mean2")]] <- df[[paste0(var, "_mean")]]^2
  }
  
  
  df$smoke_status_k <- factor(df$smoke_status_k)
  df$smoke_status_k <- relevel(df$smoke_status_k, ref = 3)
  df$surv <- 1-df$dead5  
  df$gender <- factor(df$gender)
  df$gender <- relevel(df$gender, ref = 1)
  
  df$gender2 <-ifelse(df$gender==2, 1, 0)
  df$smoke1 <-ifelse(df$smoke_status_k==1, 1, 0)
  df$smoke2 <-ifelse(df$smoke_status_k==2, 1, 0)
  
  return(df)
}   



train_region<- merge(train, practice, pracid=pracid)

test_region<- merge(test, practice, pracid=pracid)


train_region_before2010 <- train_region[as.Date(train_region$copd_diagdate) < as.Date("2010-01-01"), ]
train_region_after2010 <-  train_region[as.Date(train_region$copd_diagdate) >= as.Date("2010-01-01"), ]

train_region_before2010 <- data_preproess(train_region_before2010)
train_region_after2010 <- data_preproess(train_region_after2010)

validation_region <- data_preproess(test_region)


source <- train_region_before2010
target <- train_region_after2010


#reproduce kiddle model
rep_formula <- as.formula( "surv ~ age_diag_mean + age_diag_mean2+ bmi_mean+ bmi_mean2 +
  fev1pp_mean+ fev1pp_mean2 +gender+ fev1pp_miss +smoke_status_k+
  bmi_miss +alcohol+ atrial +diabetes+heart_fail+ ibd+ pvd+
  substance +ctd +stroke+ asthma+ cancer+ constip+depression+
  epilepsy+ ibs+ psychosis")

model_region_source <- glm(rep_formula, data=train_region_before2010, family=binomial)

external_boot_results<- external_boot(validation_region, "Naive Logistic-developed on source only", model_region_source)
write.csv(external_boot_results, "external_boot_validation-OverTime-refitted_only.csv")


rm(list = ls())
#####################Region 1 -> Noth East region ########################### 

set.seed(386)
source("FUNCTIONS_BOOTSTRAP.R")
source("LAMBDA.R")

external_boot <- function(val_data, MODEL_NAME, model){
  
  test_val_results_df <-  data.frame(matrix(ncol = 6, nrow = 0))
  names <- c('AUC', 'CITL', 'CSLOPE', 'BrierScore',"boot_round","model_name")
  colnames(test_val_results_df) <- names
  
  
  for (i in 1:200) {
    set.seed(231396*i)
    samp_index_val <- sample(1:nrow(val_data), nrow(val_data), rep=TRUE) # create a sampling index vector
    
    bs_samp_val <- val_data[samp_index_val,] # index the orignal dataset using the sampling vector to give the bs sample
    
    val_external <- validation_results(model, bs_samp_val)$val_results
    
    
    val_external$model_name  <- MODEL_NAME
    val_external$boot_round<- i
    test_val_results_df <- rbind(test_val_results_df, val_external)
    
    print(i)
  }
  return(test_val_results_df)
}


#Read data
train <-read_dta("kiddle_data_before_missing.dta")
test <-read_dta("kiddle_validation_data_before_missing.dta")
kiddle_coef <- read.csv("reported_stats.csv")
practice <- read_dta("practice.dta")


data_preproess <- function(df){
  # Loop over each variable
  for (var in  c("bmi", "fev1pp")) {
    # Create a missing indicator variable
    df[[paste0(var, "_miss")]] <- as.numeric(is.na(df[[var]]))
    
    # Compute the median
    median_value <- median(df[[var]], na.rm = TRUE)
    
    # Replace missing values with the median
    df[[var]][is.na(df[[var]])] <- median_value
  }
  #Replace missingness in smoking
  
  df$smoke_status_k[is.na(df$smoke_status_k)] <- sample(df$smoke_status_k[!is.na(df$smoke_status_k)], 
                                                        sum(is.na(df$smoke_status_k)))
  
  
  
  # Loop over each variable
  for (var in  c("age_diag", "bmi", "fev1pp")) {
    
    # Compute the mean
    mean_value <- mean(df[[var]], na.rm = TRUE)
    
    # Create mean-centered variable
    df[[paste0(var, "_mean")]] <- df[[var]] - mean_value
    
    # Create quadratic term
    df[[paste0(var, "_mean2")]] <- df[[paste0(var, "_mean")]]^2
  }
  
  
  df$smoke_status_k <- factor(df$smoke_status_k)
  df$smoke_status_k <- relevel(df$smoke_status_k, ref = 3)
  df$surv <- 1-df$dead5  
  df$gender <- factor(df$gender)
  df$gender <- relevel(df$gender, ref = 1)
  
  df$gender2 <-ifelse(df$gender==2, 1, 0)
  df$smoke1 <-ifelse(df$smoke_status_k==1, 1, 0)
  df$smoke2 <-ifelse(df$smoke_status_k==2, 1, 0)
  
  return(df)
}  



train_region<- merge(train, practice, pracid=pracid)

test_region<- merge(test, practice, pracid=pracid)


train_region_all <- train_region[train_region$region!=1,]
train_region1 <- train_region[train_region$region==1,]

train_region_all <- data_preproess(train_region_all)
train_region1 <- data_preproess(train_region1)


validation_region_all <- test_region[test_region$region!=1,]
validation_region1 <- test_region[test_region$region==1,]

validation_region_all <- data_preproess(validation_region_all)
validation_region1 <- data_preproess(validation_region1)


source <- train_region_all
target <- validation_region1

#reproduce kiddle model
rep_formula <- as.formula( "surv ~ age_diag_mean + age_diag_mean2+ bmi_mean+ bmi_mean2 +
  fev1pp_mean+ fev1pp_mean2 +gender+ fev1pp_miss +smoke_status_k+
  bmi_miss +alcohol+ atrial +diabetes+heart_fail+ ibd+ pvd+
  substance +ctd +stroke+ asthma+ cancer+ constip+depression+
  epilepsy+ ibs+ psychosis")

model_region_source <- glm(rep_formula, data=train_region_all, family=binomial)

#validate reproduced kiddle model on more recent data external validation
#region1_val_train <- validation_results(model_region_source, target)

external_boot_results<- external_boot(target, "Naive Logistic-developed on source only", model_region_source)
write.csv(external_boot_results, "external_boot_validation-Region1NorthEast-refitted_only.csv")

rm(list = ls())

########################### Region 7 -> London region ########################### 

set.seed(386)
source("FUNCTIONS_BOOTSTRAP.R")
source("LAMBDA.R")

external_boot <- function(val_data, MODEL_NAME, model){
  
  test_val_results_df <-  data.frame(matrix(ncol = 6, nrow = 0))
  names <- c('AUC', 'CITL', 'CSLOPE', 'BrierScore',"boot_round","model_name")
  colnames(test_val_results_df) <- names
  
  
  for (i in 1:200) {
    set.seed(231396*i)
    samp_index_val <- sample(1:nrow(val_data), nrow(val_data), rep=TRUE) # create a sampling index vector
    
    bs_samp_val <- val_data[samp_index_val,] # index the orignal dataset using the sampling vector to give the bs sample
    
    val_external <- validation_results(model, bs_samp_val)$val_results
    
    
    val_external$model_name  <- MODEL_NAME
    val_external$boot_round<- i
    test_val_results_df <- rbind(test_val_results_df, val_external)
    
    print(i)
  }
  return(test_val_results_df)
}

#Read data
train <-read_dta("kiddle_data_before_missing.dta")
test <-read_dta("kiddle_validation_data_before_missing.dta")
kiddle_coef <- read.csv("reported_stats.csv")
practice <- read_dta("practice.dta")

data_preproess <- function(df){
  # Loop over each variable
  for (var in  c("bmi", "fev1pp")) {
    # Create a missing indicator variable
    df[[paste0(var, "_miss")]] <- as.numeric(is.na(df[[var]]))
    
    # Compute the median
    median_value <- median(df[[var]], na.rm = TRUE)
    
    # Replace missing values with the median
    df[[var]][is.na(df[[var]])] <- median_value
  }
  #Replace missingness in smoking
  
  df$smoke_status_k[is.na(df$smoke_status_k)] <- sample(df$smoke_status_k[!is.na(df$smoke_status_k)], 
                                                        sum(is.na(df$smoke_status_k)))
  
  
  
  # Loop over each variable
  for (var in  c("age_diag", "bmi", "fev1pp")) {
    
    # Compute the mean
    mean_value <- mean(df[[var]], na.rm = TRUE)
    
    # Create mean-centered variable
    df[[paste0(var, "_mean")]] <- df[[var]] - mean_value
    
    # Create quadratic term
    df[[paste0(var, "_mean2")]] <- df[[paste0(var, "_mean")]]^2
  }
  
  
  df$smoke_status_k <- factor(df$smoke_status_k)
  df$smoke_status_k <- relevel(df$smoke_status_k, ref = 3)
  df$surv <- 1-df$dead5  
  df$gender <- factor(df$gender)
  df$gender <- relevel(df$gender, ref = 1)
  
  df$gender2 <-ifelse(df$gender==2, 1, 0)
  df$smoke1 <-ifelse(df$smoke_status_k==1, 1, 0)
  df$smoke2 <-ifelse(df$smoke_status_k==2, 1, 0)
  
  return(df)
}   



train_region<- merge(train, practice, pracid=pracid)
test_region<- merge(test, practice, pracid=pracid)


train_region_all <- train_region[train_region$region!=7,]
train_region7 <- train_region[train_region$region==7,]


train_region_all <- data_preproess(train_region_all)
train_region7 <- data_preproess(train_region7)


validation_region_all <- test_region[test_region$region!=7,]
validation_region7 <- test_region[test_region$region==7,]

validation_region_all <- data_preproess(validation_region_all)
validation_region7 <- data_preproess(validation_region7)

source <- train_region_all
target <- validation_region7


#reproduce kiddle model
rep_formula <- as.formula( "surv ~ age_diag_mean + age_diag_mean2+ bmi_mean+ bmi_mean2 +
  fev1pp_mean+ fev1pp_mean2 +gender+ fev1pp_miss +smoke_status_k+
  bmi_miss +alcohol+ atrial +diabetes+heart_fail+ ibd+ pvd+
  substance +ctd +stroke+ asthma+ cancer+ constip+depression+
  epilepsy+ ibs+ psychosis")

model_region_source <- glm(rep_formula, data=train_region_all, family=binomial)

external_boot_results<- external_boot(target, "Naive Logistic-developed on source only", model_region_source)
write.csv(external_boot_results, "external_boot_validation-Region7London-refitted_only.csv")

