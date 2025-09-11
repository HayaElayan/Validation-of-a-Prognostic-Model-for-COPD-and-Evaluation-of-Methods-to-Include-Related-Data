###########################Region 7 -> London region

set.seed(386)

#setwd("")
source("FUNCTIONS_BOOTSTRAP.R")
source("LAMBDA.R")
library(MLmetrics)
library(haven)
library(pROC)
library(DescTools)
library(dplyr)

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
train_region1 <- train_region[train_region$region==7,]

train_region_all <- data_preproess(train_region_all)
train_region1 <- data_preproess(train_region1)


validation_region_all <- test_region[test_region$region!=7,]
validation_region1 <- test_region[test_region$region==7,]

validation_region_all <- data_preproess(validation_region_all)
validation_region1 <- data_preproess(validation_region1)


source <- train_region_all
target <- validation_region1


##### Models

rep_formula <- as.formula( "surv ~ age_diag_mean + age_diag_mean2+ bmi_mean+ bmi_mean2 +
  fev1pp_mean+ fev1pp_mean2 +gender+ fev1pp_miss +smoke_status_k+
  bmi_miss +alcohol+ atrial +diabetes+heart_fail+ ibd+ pvd+
  substance +ctd +stroke+ asthma+ cancer+ constip+depression+
  epilepsy+ ibs+ psychosis")


##### Checking O and E

# O in external validation dataset (2012-2014/ region 7)
mean(target$surv)
#0.8069705

# Reproduced Kiddle model
model_full <- glm(rep_formula, data=source, family=binomial)

# E = reproduced Kiddle model (2012-2014/ region 7)
pr_val <- predict(model_full, type="response", newdata = target)
mean(pr_val)
#0.7486846

# Difference
mean(target$surv)-mean(pr_val)
#0.05828591 
