###########################Region 7 -> London region


#setwd("")
source("FUNCTIONS_BOOTSTRAP.R")
source("LAMBDA.R")
library(MLmetrics)
library(haven)
library(pROC)
library(DescTools)
library(dplyr)

set.seed(386)

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

print("source sample size")
print(nrow(source))

print("target sample size")
print(nrow(target))



#reproduce kiddle model
rep_formula <- as.formula( "surv ~ age_diag_mean + age_diag_mean2+ bmi_mean+ bmi_mean2 +
  fev1pp_mean+ fev1pp_mean2 +gender+ fev1pp_miss +smoke_status_k+
  bmi_miss +alcohol+ atrial +diabetes+heart_fail+ ibd+ pvd+
  substance +ctd +stroke+ asthma+ cancer+ constip+depression+
  epilepsy+ ibs+ psychosis")

model_region_source <- glm(rep_formula, data=train_region_all, family=binomial)

#validate reproduced kiddle model on more recent data external validation
region7_val_train <- validation_results(model_region_source, target)


#Correcting for shift

#1- get propensity score weights with limiting weights up to 1, 2- create a weighted model to correct for shift 3- validate
ps_weights_limit1 <- propensity_weighting_limit1(source, target)
propensity_model_limit1 <- weighted_LR(source, target, ps_weights_limit1)
internal_prop_Lim_val <- ps_validation_results(propensity_model_limit1, target) #validated on target from kiddle development data 2004-2012

#1- get propensity score weights with limiting weights up to 1, 2- create a weighted model to correct for shift with forgetting factor 3- validate
ps_weights_lambda <- propensity_weighting_with_lambda(source, target)
propensity_model_lambda <- weighted_LR(source, target, ps_weights_lambda)
internal_prop_lambda_val <- ps_validation_results(propensity_model_lambda, target)



#intercept recalibration, develop the model on full data then recalibrate of target
int_calib_full_df <- intercept_calibration(source, target, "FULL", rep_formula)
internal_int_full_val <- calibrated_model_validation_results(int_calib_full_df, target, "intercept_only")


#intercept recalibration, develop the model on source data then recalibrate of target
int_calib_source_only <- intercept_calibration(source, target, "source_only", rep_formula)
internal_int_source_val <- calibrated_model_validation_results(int_calib_source_only, target, "intercept_only")


#logistic recalibration, develop the model on full data then recalibrate of target
logit_calib_full_df <- logistic_calibration(source, target, "FULL", rep_formula)
internal_logistic_full_val <- calibrated_model_validation_results(logit_calib_full_df, target, "logistic")


#logistic recalibration, develop the model on source data then recalibrate of target
logit_calib_source_only <- logistic_calibration(source, target, "source_only", rep_formula)
internal_logistic_source_val <- calibrated_model_validation_results(logit_calib_source_only, target, "logistic")


model_on_allData <- all_data_model(source, target, rep_formula)  
internal_model_on_allData_val <- ps_validation_results(model_on_allData, target)

model_on_targetOnly <- glm(rep_formula, data=target, family=binomial)
internal_model_on_targetOnly_val <- validation_results(model_on_targetOnly, target)


Models <- c("Naive Logistic-developed on source only", 
            "Membership-based weighted model (weights limited to 1)",
            "Membership-based weighted model (weights limited to 1 + Forgetting factor)",
            "Intercept recalibration-developed on full data",
            "Intercept recalibration-developed on source only", 
            "Logistic recalibration-developed on full data",
            "Logistic recalibration-developed on source only",
            "Naive Logistic-developed on full data recalibrated",
            "Naive Logistic-developed on target only"
)




internal_val_results_df <- rbind(
  region7_val_train$val_results,
  internal_prop_Lim_val$val_results,
  internal_prop_lambda_val$val_results,
  internal_int_full_val$val_results,
  internal_int_source_val$val_results,
  internal_logistic_full_val$val_results,
  internal_logistic_source_val$val_results,
  internal_model_on_allData_val$val_results,
  internal_model_on_targetOnly_val$val_results
)

internal_val_results_df$model_name <- Models

write.csv(internal_val_results_df, "internal_validation12-14-all_vs_region7_corrected_missing_TimeRegion.csv")



boot_results<- manual_boot(source, target, 200, rep_formula)

write.csv(boot_results$apparent, "bootstrap_apparent_validation_results-all_vs_region7_corrected_missing_TimeRegion.csv")
write.csv(boot_results$test, "bootstrap_test_validation_results-all_vs_region7_corrected_missing_TimeRegion.csv")



