#bootstrap validation results

original_validation_results <- function(pr_val, lp_val, validation){
  
  val_results <- matrix(nrow = 1,ncol = 4)
  colnames(val_results) <- c('AUC', 'CITL', 'CSLOPE', 'BrierScore') 
  
  
  # calculate performance of the  model in the validation sample
  val_cstat_model <- roc(surv ~ pr_val,data=validation)
  val_results[1,1] <- val_cstat_model$auc
  
  brierScore <- mean((pr_val- validation$surv)^2)
  val_results[1,4] <- brierScore
  
  val_citl_model <- glm(surv ~ offset(lp_val),family=binomial, data=validation)
  val_results[1,2] <- summary(val_citl_model)$coefficients[1,1]
  
  val_cslope_model <- glm(surv ~ lp_val,family=binomial(link='logit'), data=validation)
  val_results[1,3] <- summary(val_cslope_model)$coefficients[2,1]
  val_results<- as.data.frame(val_results)
  return(val_results)
}
validation_results <- function(model, validation){
  
  val_results <- matrix(nrow = 1,ncol = 4)
  colnames(val_results) <- c('AUC', 'CITL', 'CSLOPE', 'BrierScore') 
  
  
  pr_val <- predict(model, type="response", newdata = validation) # predict probabilities 
  lp_val <- predict(model, newdata = validation , type="link") # predict lp type=link
  
  # calculate performance of the  model in the validation sample
  val_cstat_model <- roc(surv ~ pr_val,data=validation)
  val_results[1,1] <- val_cstat_model$auc
  
  brierScore <- mean((pr_val- validation$surv)^2)
  val_results[1,4] <- brierScore
  
  val_citl_model <- glm(surv ~ offset(lp_val),family=binomial, data=validation)
  val_results[1,2] <- summary(val_citl_model)$coefficients[1,1]
  
  val_cslope_model <- glm(surv ~ lp_val,family=binomial(link='logit'), data=validation)
  val_results[1,3] <- summary(val_cslope_model)$coefficients[2,1]
  
  return(list(val_results = as.data.frame(val_results), preds = pr_val))
}

ps_validation_results <- function(model, validation){
  
  val_results <- matrix(nrow = 1,ncol = 4)
  colnames(val_results) <- c('AUC', 'CITL', 'CSLOPE', 'BrierScore') 
  
  validation$isSource <- 0
  pr_val <- predict(model, type="response", newdata = validation) # predict probabilities 
  lp_val <- predict(model, newdata = validation , type="link") # predict lp type=link
  
  # calculate performance of the  model in the validation sample
  val_cstat_model <- roc(surv ~ pr_val,data=validation)
  val_results[1,1] <- val_cstat_model$auc
  
  brierScore <- mean((pr_val- validation$surv)^2)
  val_results[1,4] <- brierScore
  
  val_citl_model <- glm(surv ~ offset(lp_val),family=binomial, data=validation)
  val_results[1,2] <- summary(val_citl_model)$coefficients[1,1]
  
  val_cslope_model <- glm(surv ~ lp_val,family=binomial(link='logit'), data=validation)
  val_results[1,3] <- summary(val_cslope_model)$coefficients[2,1]
  
  return(list(val_results = as.data.frame(val_results), preds = pr_val))
}



calibrated_model_validation_results <- function(model, validation, type){
  
  val_results <- matrix(nrow = 1,ncol = 4)
  colnames(val_results) <- c('AUC', 'CITL', 'CSLOPE', 'BrierScore')
  pr_val <- nrow(validation)
  lp_val <- nrow(validation)
  
  validation$lp <- predict(model$source_model, newdata = validation, type = "link")
  #print(table(validation$Y, validation$lp))
  
  if(type=='intercept_only'){
    print("intercept_only")
    pr_val <- predict(model$calibrated_model, type="response", newdata = validation, offset = validation$lp) # predict probabilities 
    lp_val <- predict(model$calibrated_model, newdata = validation, offset = validation$lp ) # predict lp type=link
    #print(lp_val)
  }else{
    print("logistic")
    pr_val <- predict(model$calibrated_model, type="response", newdata = validation, lp = validation$lp) # predict probabilities 
    lp_val <- predict(model$calibrated_model, newdata = validation, lp = validation$lp ) # predict lp type=link
  }
  
  
  # calculate performance of the  model in the validation sample
  val_cstat_model <- roc(surv ~ pr_val,data=validation)
  val_results[1,1] <- val_cstat_model$auc
  
  brierScore <- mean((pr_val - validation$surv)^2)
  val_results[1,4] <- brierScore
  
  
  val_citl_model <- glm(surv ~ offset(lp_val),family=binomial, data=validation)
  val_results[1,2] <- summary(val_citl_model)$coefficients[1,1]
  
  val_cslope_model <- glm(surv ~ lp_val,family=binomial(link='logit'), data=validation)
  val_results[1,3] <- summary(val_cslope_model)$coefficients[2,1]
  
  return(list(val_results = as.data.frame(val_results), preds = pr_val))
}


propensity_weighting_limit1<- function(source, target){
  source$isSource <- 1
  target$isSource <- 0
  temp <- rbind(source, target)
  
  weight_formula <- as.formula( "isSource ~ age_diag_mean + age_diag_mean2+ bmi_mean+ bmi_mean2 +
  fev1pp_mean+ fev1pp_mean2 +gender+ fev1pp_miss +smoke_status_k+
  bmi_miss +alcohol+ atrial +diabetes+heart_fail+ ibd+ pvd+
  substance +ctd +stroke+ asthma+ cancer+ constip+depression+
  epilepsy+ ibs+ psychosis")
  
  membership_model <- glm(weight_formula, data=temp, family = 'binomial')
  #print(membership_model)
  score <- predict(membership_model,type="response", newdata = source) #predict p(isSource=1|X)
  
  propensity_weight <-  (1 - score)/ score #p(p(isSource=0|X)/ p(isSource=1|X))
  #print(propensity_weight)
  
  propensity_weight <- propensity_weight*(nrow(source)/ nrow(target))
  
  propensity_weight[propensity_weight >= 1]= 1
  source$propensity_weight <- propensity_weight
  target$propensity_weight <- 1
  
  weights <- c(source$propensity_weight, target$propensity_weight )
  return(weights)
}

propensity_weighting_no_limit<- function(source, target){
  source$isSource <- 1
  target$isSource <- 0
  temp <- rbind(source, target)
  
  weight_formula <- as.formula( "isSource ~ age_diag_mean + age_diag_mean2+ bmi_mean+ bmi_mean2 +
  fev1pp_mean+ fev1pp_mean2 +gender+ fev1pp_miss +smoke_status_k+
  bmi_miss +alcohol+ atrial +diabetes+heart_fail+ ibd+ pvd+
  substance +ctd +stroke+ asthma+ cancer+ constip+depression+
  epilepsy+ ibs+ psychosis")
  
  membership_model <- glm(weight_formula, data=temp, family = 'binomial')
  #print(membership_model)
  score <- predict(membership_model,type="response", newdata = source) #predict p(isSource=1|X)
  
  propensity_weight <-  (1 - score)/ score #p(p(isSource=0|X)/ p(isSource=1|X))
  #print(propensity_weight)
  
  propensity_weight <- propensity_weight*(nrow(source)/ nrow(target))
  
  #propensity_weight[propensity_weight >= 1]= 1
  source$propensity_weight <- propensity_weight
  target$propensity_weight <- 1
  
  weights <- c(source$propensity_weight, target$propensity_weight )
  return(weights)
}



weighted_LR <- function(source, target, ps_weights) {
  source$isSource <- 1
  target$isSource <- 0
  train_data <- rbind(source, target)
  
  weight_formula <- as.formula( "surv ~ age_diag_mean + age_diag_mean2+ bmi_mean+ bmi_mean2 +
  fev1pp_mean+ fev1pp_mean2 +gender+ fev1pp_miss +smoke_status_k+
  bmi_miss +alcohol+ atrial +diabetes+heart_fail+ ibd+ pvd+
  substance +ctd +stroke+ asthma+ cancer+ constip+depression+
  epilepsy+ ibs+ psychosis + isSource")
  
  model <- glm(weight_formula, data = train_data, weights = ps_weights, family = binomial)
  #print(summary(model))
  return( model)
  
}




intercept_calibration <- function(source, target, dev_on, d_formula) {
  if(dev_on=='FULL'){
    train_data <- rbind(source, target) 
    print("full")
  }else{
    train_data <- source
    print("source")
  }
  
  source_model <- glm(d_formula, data=train_data, family = 'binomial', x=TRUE, y=TRUE)
  
  target$lp <- predict(source_model, newdata=target) #get Lp of source model on target data
  calibrated_model <- glm(surv~offset(lp), data=target, family='binomial',x=T, y=T)#update intercept only
  
  
  return(list(calibrated_model=calibrated_model, source_model=source_model))
  
}


logistic_calibration <-function(source, target, dev_on, d_formula) {
  if(dev_on=='FULL'){
    print("full")
    train_data <- rbind(source, target )
  }else{
    print("source")
    train_data <-source
  }
  
  source_model <- glm(d_formula, data=train_data, family = 'binomial', x=TRUE, y=TRUE)
  
  target$lp <- predict(source_model, newdata=target) #get Lp of source model on target data
  calibrated_model <- glm(surv~lp, data=target, family='binomial',x=T, y=T)#update all model's coeff
  
  return(list(calibrated_model=calibrated_model, source_model=source_model))
} 


all_data_model <- function(source, target, dev_formula){
  source$isSource <- 1
  target$isSource <- 0
  train_data <- rbind(source, target)
  
  model <- glm(dev_formula, data = train_data, family = binomial)
  return(model)
}



manual_boot <- function(source, target,samples, dev_formula){
  val_results_df <- data.frame(matrix(ncol = 6, nrow = 0))
  test_val_results_df <-  data.frame(matrix(ncol = 6, nrow = 0))
  names <- c('AUC', 'CITL', 'CSLOPE', 'BrierScore',"boot_round","model_name")
  colnames(val_results_df) <- names
  colnames(test_val_results_df) <- names
  
  
  for (i in 1:samples) {
    set.seed(231396*i)
    samp_index_source <- sample(1:nrow(source), nrow(source), rep=TRUE) # create a sampling index vector
    samp_index_target <- sample(1:nrow(target), nrow(target), rep=TRUE) # create a sampling index vector
    
    bs_samp_source <- source[samp_index_source,] # index the orignal dataset using the sampling vector to give the bs sample
    bs_samp_target <- target[samp_index_target,]
    
    
    #1- get propensity score weights with limiting weights up to 1, 2- create a weighted model to correct for shift 3- validate
    ps_weights_limit1 <- propensity_weighting_limit1(bs_samp_source, bs_samp_target)
    propensity_model_limit1 <- weighted_LR(bs_samp_source, bs_samp_target, ps_weights_limit1)
    apparent_boot_prop_Lim_val <- ps_validation_results(propensity_model_limit1, bs_samp_target)
    test_prop_Lim_val <- ps_validation_results(propensity_model_limit1, target)
    
    
    #1- get propensity score weights with limiting weights up to 1, 2- create a weighted model to correct for shift with forgetting factor 3- validate
    ps_weights_lambda <- propensity_weighting_with_lambda(bs_samp_source, bs_samp_target)
    propensity_model_lambda <- weighted_LR(bs_samp_source, bs_samp_target, ps_weights_lambda)
    apparent_boot_prop_lambda_val <- ps_validation_results(propensity_model_lambda, bs_samp_target)
    test_prop_lambda_val <- ps_validation_results(propensity_model_lambda, target)
    
    
    
    #intercept recalibration, develop the model on full data then recalibrate of target
    int_calib_full_df <- intercept_calibration(bs_samp_source, bs_samp_target, "FULL", dev_formula)
    apparent_boot_int_full_val <- calibrated_model_validation_results(int_calib_full_df, bs_samp_target, "intercept_only")
    test_int_full_val <- calibrated_model_validation_results(int_calib_full_df, target, "intercept_only")
    
    #intercept recalibration, develop the model on source data then recalibrate of target
    int_calib_source_only <- intercept_calibration(bs_samp_source, bs_samp_target, "source_only", dev_formula)
    apparent_boot_int_source_val <- calibrated_model_validation_results(int_calib_source_only, bs_samp_target, "intercept_only")
    test_int_source_val <- calibrated_model_validation_results(int_calib_source_only, target, "intercept_only")
    
    
    #logistic recalibration, develop the model on full data then recalibrate of target
    logit_calib_full_df <- logistic_calibration(bs_samp_source, bs_samp_target, "FULL", dev_formula)
    apparent_boot_logistic_full_val <- calibrated_model_validation_results(logit_calib_full_df, bs_samp_target, "logistic")
    test_logistic_full_val <- calibrated_model_validation_results(logit_calib_full_df, target, "logistic")
    
    #logistic recalibration, develop the model on source data then recalibrate of target
    logit_calib_source_only <- logistic_calibration(bs_samp_source, bs_samp_target, "source_only", dev_formula)
    apparent_boot_logistic_source_val <- calibrated_model_validation_results(logit_calib_source_only, bs_samp_target, "logistic")
    test_logistic_source_val <- calibrated_model_validation_results(logit_calib_source_only, target, "logistic")
    
    
    model_on_allData <- all_data_model(bs_samp_source, bs_samp_target, dev_formula)  
    apparent_boot_model_on_allData_val <- ps_validation_results(model_on_allData, bs_samp_target)
    test_model_on_allData_val <- ps_validation_results(model_on_allData, target)
    
    
    model_on_targetOnly <- glm(dev_formula, data=bs_samp_target, family=binomial)
    apparent_boot_model_on_targetOnly_val <- validation_results(model_on_targetOnly, bs_samp_target)
    test_model_on_targetOnly_val <- validation_results(model_on_targetOnly, target)
    
    
    new_rows_app <- rbind(
      apparent_boot_prop_Lim_val$val_results,
      apparent_boot_prop_lambda_val$val_results,
      apparent_boot_int_full_val$val_results,
      apparent_boot_int_source_val$val_results,
      apparent_boot_logistic_full_val$val_results,
      apparent_boot_logistic_source_val$val_results,
      apparent_boot_model_on_allData_val$val_results,
      apparent_boot_model_on_targetOnly_val$val_results
    )
    
    MODELS_NAMES <- c("Membership-based weighted model (weights limited to 1)",
                      "Membership-based weighted model (weights limited to 1 + Forgetting factor)",
                      "Intercept recalibration-developed on full data",
                      "Intercept recalibration-developed on source only", 
                      "Logistic recalibration-developed on full data",
                      "Logistic recalibration-developed on source only",
                      "Naive Logistic-developed on full data recalibrated",
                      "Naive Logistic-developed on target only"
    )
    new_rows_app$model_name <- MODELS_NAMES
    
    new_rows_app$boot_round <- i
    new_rows_app$metric_type <- "boot_apparent" 
    
    val_results_df <- rbind(val_results_df, new_rows_app)
    
    new_rows_test <- rbind(
      test_prop_Lim_val$val_results,
      test_prop_lambda_val$val_results,
      test_int_full_val$val_results,
      test_int_source_val$val_results,
      test_logistic_full_val$val_results,
      test_logistic_source_val$val_results,
      test_model_on_allData_val$val_results,
      test_model_on_targetOnly_val$val_results
    )
    
    new_rows_test$model_name  <- MODELS_NAMES
    new_rows_test$boot_round<- i
    new_rows_test$metric_type  <- "boot_test" 
    
    test_val_results_df <- rbind(test_val_results_df, new_rows_test)
    
    print(i)
  }
  return(list(apparent = val_results_df, test= test_val_results_df))
}




