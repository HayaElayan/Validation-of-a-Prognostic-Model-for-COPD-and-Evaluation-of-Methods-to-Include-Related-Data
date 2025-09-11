propensity_weighting_with_lambda<- function(source, target){
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
  
  lambda <- find_lambda(source, target)
  print(lambda)
  weights_adjusted <- c(source$propensity_weight*lambda,target$propensity_weight)
  return(weights_adjusted)
}


find_lambda <- function(source, target){
  hyperparam_values <- c(seq(0, 1, by = 0.1), 0.05, 0.08, 0.15, 0.25, 0.03)
  mse_results <- numeric(length(hyperparam_values))
  
  for (i in seq_along(hyperparam_values)) {
    lambda <- hyperparam_values[i]
    
    
    folds <- custom_cv(source, target) 
    mse_values <- numeric(length(folds))
    
    for (j in seq_along(folds)) {
      train_source_indices <- folds[[j]]$train_source
      train_target_indices <- folds[[j]]$train_target
      test_indices <- folds[[j]]$test
      
      train_source_data <- source[train_source_indices, ] 
      train_target_data <- target[train_target_indices, ] 
      test_data <- target[test_indices, ] 
      
      source_target_weights <- propensity_weighting_x(train_source_data, train_target_data, lambda)
      
      result <- weighted_logistic_regression_x(train_source_data, train_target_data, test_data, weight = source_target_weights)
      mse_values[j] <- calculate_mse(true_labels = test_data$surv, pred_probs = result)
      
    }
    
    mse_results[i] <- mean(mse_values)
  }
  
  
  optimal_param <- hyperparam_values[which.min(mse_results)]
  return(optimal_param)
}


propensity_weighting_x<- function(source, target, lambda){
  temp <- rbind(source, target)
  
  weight_formula <- as.formula( "isSource ~ age_diag_mean + age_diag_mean2+ bmi_mean+ bmi_mean2 +
  fev1pp_mean+ fev1pp_mean2 +gender+ fev1pp_miss +smoke_status_k+
  bmi_miss +alcohol+ atrial +diabetes+heart_fail+ ibd+ pvd+
  substance +ctd +stroke+ asthma+ cancer+ constip+depression+
  epilepsy+ ibs+ psychosis")
  
  membership_model <- glm(weight_formula, data=temp, family = 'binomial')

  score <- predict(membership_model,type="response", newdata = source) #predict p(isSource=1|X)
  
  propensity_weight <-  (1 - score)/ score #p(p(isSource=0|X)/ p(isSource=1|X))

  propensity_weight <- propensity_weight*(nrow(source)/ nrow(target))
  
  propensity_weight[propensity_weight >= 1]= 1
  source$propensity_weight <- propensity_weight
  target$propensity_weight <- 1
  
  weights <- c(source$propensity_weight*lambda,target$propensity_weight )

  return(weights)
  
}




# Define custom cross-validation function
custom_cv <- function(source, target) {
  indices_source <- sample(rep(1:4, length.out = nrow(source)))
  indices_target <- sample(rep(1:4, length.out = nrow(target)))
  
  folds_list <- lapply(1:4, function(i) {
    train_source_indices <- which(indices_source != i)
    train_target_indices <- which(indices_target != i)
    test_indices <- which(indices_target == i)
    list(train_source = train_source_indices, train_target= train_target_indices, test = test_indices)
  })
  return(folds_list)
}


# Define function to calculate mean squared error
calculate_mse <- function(true_labels, pred_probs) {
  mse <- MLmetrics::MSE(y_pred = pred_probs, y_true = true_labels)
  return(mse)
}

weighted_logistic_regression_x <- function(source, target, test_data, weight) {
  train_data <- rbind(source, target)

  weight_formula <- as.formula( "surv ~ age_diag_mean + age_diag_mean2+ bmi_mean+ bmi_mean2 +
  fev1pp_mean+ fev1pp_mean2 +gender+ fev1pp_miss +smoke_status_k+
  bmi_miss +alcohol+ atrial +diabetes+heart_fail+ ibd+ pvd+
  substance +ctd +stroke+ asthma+ cancer+ constip+depression+
  epilepsy+ ibs+ psychosis + isSource")

  model <- glm(weight_formula, data = train_data, weights = weight, family = binomial)
  pred_probs <- predict(model, newdata = test_data, type = "response")
  return( pred_probs)
  
}




