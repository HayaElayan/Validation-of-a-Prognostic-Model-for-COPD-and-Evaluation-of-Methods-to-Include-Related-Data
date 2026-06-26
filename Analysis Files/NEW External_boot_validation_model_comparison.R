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




#Correcting for shift

#1- get propensity score weights with limiting weights up to 1, 2- create a weighted model to correct for shift 3- validate
ps_weights_limit1 <- propensity_weighting_limit1(source, target)
propensity_model_limit1 <- weighted_LR(source, target, ps_weights_limit1)

#1- get propensity score weights with limiting weights up to 1, 2- create a weighted model to correct for shift with forgetting factor 3- validate
ps_weights_lambda <- propensity_weighting_with_lambda(source, target)
propensity_model_lambda <- weighted_LR(source, target, ps_weights_lambda)



#intercept recalibration, develop the model on full data then recalibrate of target
int_calib_full_df <- intercept_calibration(source, target, "FULL", rep_formula)


#intercept recalibration, develop the model on source data then recalibrate of target
int_calib_source_only <- intercept_calibration(source, target, "source_only", rep_formula)


#logistic recalibration, develop the model on full data then recalibrate of target
logit_calib_full_df <- logistic_calibration(source, target, "FULL", rep_formula)


#logistic recalibration, develop the model on source data then recalibrate of target
logit_calib_source_only <- logistic_calibration(source, target, "source_only", rep_formula)


model_on_allData <- all_data_model(source, target, rep_formula)  

model_on_targetOnly <- glm(rep_formula, data=target, family=binomial)


Models <- c("Naive Logistic-developed on source only", 
            "Membership-based weighted model (weights limited to 1)",
            "Membership-based weighted model (weights limited to 1 + Forgetting factor)",
            "Intercept recalibration-developed on full data",
            "Intercept recalibration-developed on source only", 
            "Logistic recalibration-developed on full data",
            "Logistic recalibration-developed on source only",
            "Naive Logistic-developed on full data",
            "Naive Logistic-developed on target only"
)


external_boot <- function(val_data, MODELS_NAMES, model_region_source,
                          propensity_model_limit1, propensity_model_lambda,
                          int_calib_full_df, int_calib_source_only,
                          logit_calib_full_df, logit_calib_source_only,
                          model_on_allData, model_on_targetOnly){
  
  test_val_results_df <-  data.frame(matrix(ncol = 6, nrow = 0))
  names <- c('AUC', 'CITL', 'CSLOPE', 'BrierScore',"boot_round","model_name")
  colnames(test_val_results_df) <- names
  
  
  for (i in 1:200) {
    set.seed(231396*i)
    samp_index_val <- sample(1:nrow(val_data), nrow(val_data), rep=TRUE) # create a sampling index vector

    bs_samp_val <- val_data[samp_index_val,] # index the orignal dataset using the sampling vector to give the bs sample

    
    after2010_val_external <- validation_results(model_region_source, bs_samp_val)
    
    external_prop_Lim_val <- ps_validation_results(propensity_model_limit1, bs_samp_val) 
    external_prop_lambda_val <- ps_validation_results(propensity_model_lambda, bs_samp_val)
    
    external_int_full_val <- calibrated_model_validation_results(int_calib_full_df, bs_samp_val, "intercept_only")
    extrenal_int_source_val <- calibrated_model_validation_results(int_calib_source_only, bs_samp_val, "intercept_only")
    
    external_logistic_full_val <- calibrated_model_validation_results(logit_calib_full_df, bs_samp_val, "logistic")
    external_logistic_source_val <- calibrated_model_validation_results(logit_calib_source_only, bs_samp_val, "logistic")
    
    external_model_on_allData_val <- ps_validation_results(model_on_allData, bs_samp_val)
    
    external_model_on_targetOnly_val <- validation_results(model_on_targetOnly, bs_samp_val)
    
   
    
    
    new_rows_test <- rbind(
      after2010_val_external$val_results,
      external_prop_Lim_val$val_results,
      external_prop_lambda_val$val_results,
      external_int_full_val$val_results,
      extrenal_int_source_val$val_results,
      external_logistic_full_val$val_results,
      external_logistic_source_val$val_results,
      external_model_on_allData_val$val_results,
      external_model_on_targetOnly_val$val_results
    )
    
    new_rows_test$model_name  <- MODELS_NAMES
    new_rows_test$boot_round<- i

    test_val_results_df <- rbind(test_val_results_df, new_rows_test)
    
    print(i)
  }
  return(test_val_results_df)
}

external_boot_results<- external_boot(validation_region, Models, model_region_source,
                                      propensity_model_limit1, propensity_model_lambda,
                                      int_calib_full_df, int_calib_source_only,
                                      logit_calib_full_df, logit_calib_source_only,
                                      model_on_allData, model_on_targetOnly)
write.csv(external_boot_results, "external_boot_validation-before2010_after2010_corrected_missing.csv")


