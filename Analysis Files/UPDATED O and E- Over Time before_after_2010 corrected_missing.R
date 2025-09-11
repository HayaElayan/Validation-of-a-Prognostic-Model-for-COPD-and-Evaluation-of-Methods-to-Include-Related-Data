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


train_region_before2010 <- train_region[as.Date(train_region$copd_diagdate) < as.Date("2010-01-01"), ]
train_region_after2010 <-  train_region[as.Date(train_region$copd_diagdate) >= as.Date("2010-01-01"), ]

train_region_before2010 <- data_preproess(train_region_before2010)
train_region_after2010 <- data_preproess(train_region_after2010)

validation <- data_preproess(test_region)


source <- train_region_before2010
target <- train_region_after2010
all<-rbind(source,target)

##### Models

#reproduce kiddle model
rep_formula <- as.formula( "surv ~ age_diag_mean + age_diag_mean2+ bmi_mean+ bmi_mean2 +
  fev1pp_mean+ fev1pp_mean2 +gender+ fev1pp_miss +smoke_status_k+
  bmi_miss +alcohol+ atrial +diabetes+heart_fail+ ibd+ pvd+
  substance +ctd +stroke+ asthma+ cancer+ constip+depression+
  epilepsy+ ibs+ psychosis")

# Reproduced Kiddle model (2004-2012)
reproduced <- glm(rep_formula, data=all, family=binomial, x=TRUE, y=TRUE)

##### Checking O and E

# O in external validation dataset (2012-2014)
mean(validation$surv)
#0.7874759

# 1) Membership-based - propensity score weights with limiting weights up to 1
# create a weighted model to correct for shift with forgetting factor
source$isSource <- 1
target$isSource <- 0
train_data <- rbind(source, target)
train_data$ps_weights <- propensity_weighting_with_lambda(source, target)

weight_formula <- as.formula( "surv ~ age_diag_mean + age_diag_mean2+ bmi_mean+ bmi_mean2 +
  fev1pp_mean+ fev1pp_mean2 +gender+ fev1pp_miss +smoke_status_k+
  bmi_miss +alcohol+ atrial +diabetes+heart_fail+ ibd+ pvd+
  substance +ctd +stroke+ asthma+ cancer+ constip+depression+
  epilepsy+ ibs+ psychosis + isSource")

model_ps <- glm(weight_formula, data = train_data, weights = ps_weights, family = binomial)
validation$isSource <- 0
pr_val_ps<- predict(model_ps, type="response", newdata = validation)

#E
mean(pr_val_ps)
#0.7789351

#Difference
mean(validation$surv)-mean(pr_val_ps)
#0.008540808

# 2) Intercept recalibration: model developed on all (2004-2012) and updated using 2010-2012, externally validated in 2012-2014
target$lp <- predict(reproduced, newdata = target, type="link")
model_intercept <- glm(surv ~ offset(lp), data=target,family=binomial, x=T, y=T)
validation$lp <- predict(reproduced, newdata = validation, type="link")
pr_val_intercept <- predict(model_intercept, type="response", newdata = validation, offset = validation$lp)

#E
mean(pr_val_intercept)
#0.779019

#Difference
mean(validation$surv)-mean(pr_val_intercept)
#0.008456976

# 3) Intercept recalibration: model developed on source (2004-2010) and updated using 2010-2012, externally validated in 2012-2014
model_source <- glm(rep_formula, data=source, family=binomial, x=TRUE, y=TRUE)
target$lp_source <- predict(model_source, newdata = target, type="link")
model_intercept_source <- glm(surv ~ offset(lp_source), data=target,family=binomial, x=T, y=T)
validation$lp_source <- predict(model_source, newdata = validation, type="link")
pr_val_intercept_source <- predict(model_intercept_source, type="response", newdata = validation, offset = validation$lp)

#E
mean(pr_val_intercept_source)
#0.7790875

#Difference
mean(validation$surv)-mean(pr_val_intercept_source)
#0.008388442

# 4) Logistic recalibration: model developed on all (2004-2012) and updated using 2010-2012, externally validated in 2012-2014
model_logistic <- glm(surv ~ lp, data=target,family=binomial, x=T, y=T)
validation$lp_logistic <- predict(model_logistic, newdata = validation, type="link")
pr_val_logistic <- predict(model_logistic, type="response", newdata = validation, offset = validation$lp_logistic)

#E
mean(pr_val_logistic)
#0.7789981

#Difference
mean(validation$surv)-mean(pr_val_logistic)
#0.008477833

# 5) Logistic recalibration: model developed on all (2004-2012) and updated using 2010-2012, externally validated in 2012-2014
model_logistic_source <- glm(surv ~ lp_source, data=target,family=binomial, x=T, y=T)
validation$lp_logistic_source <- predict(model_logistic_source, newdata = validation, type="link")
pr_val_logistic_source <- predict(model_logistic_source, type="response", newdata = validation, offset = validation$lp_logistic_source)

#E
mean(pr_val_logistic_source)
#0.7790752

#Difference
mean(validation$surv)-mean(pr_val_logistic_source)
#0.008400739

# 6) Target only dataset (2010-2012), externally validated in 2012-2014
model_target <- glm(rep_formula, data=target, family=binomial)
pr_val_target_only <- predict(model_target, type="response", newdata = validation)

#E
mean(pr_val_target_only)
#0.778702

# Difference
mean(validation$surv)-mean(pr_val_target_only)
#0.008773942
