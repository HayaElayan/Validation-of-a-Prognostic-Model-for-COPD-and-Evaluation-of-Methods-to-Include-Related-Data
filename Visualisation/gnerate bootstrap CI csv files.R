########## bootstrap test validation results csv file
boot_test <- read.csv("bootstrap_test_validation_results-all_vs_region7_corrected_missing_TimeRegion.csv") 


all_mets <- data.frame(matrix(ncol = 5, nrow = 0))
names <- c("mean","lower_band","upper_band", "statistics","model_name")
colnames(all_mets) <- names

get_ci <- function(df){ 
  mets <- c('AUC', 'CITL', 'CSLOPE', 'BrierScore')
  for(met in mets){
    df2 <- sort(df[[met]])
    all_mets[nrow(all_mets) + 1,] <<- list(mean = mean(df2), lower_band= df2[5], upper_band = df2[195], met, unique(df$model_name))
  }
}

boot_ci <- data.frame()
lapply(unique(boot_test$model_name), function(model_name) {
  # Filter df by the current model name
  boost_apparent_subset <- boot_test[boot_test$model_name == model_name, ]
  # Apply get_opts to the subset
  get_ci(boost_apparent_subset)
})
write.csv(all_mets, "bootstrap_test_validation_results-all_vs_region7_corrected_missing_TimeRegion.csv", row.names = FALSE)





######### bootstrap apparent validation results csv file
boot_app <- read.csv("bootstrap_apparent_validation_results-all_vs_region7_corrected_missing_TimeRegion.csv") 


all_mets <- data.frame(matrix(ncol = 5, nrow = 0))
names <- c("mean","lower_band","upper_band", "statistics","model_name")
colnames(all_mets) <- names

get_ci <- function(df){ 
  mets <- c('AUC', 'CITL', 'CSLOPE', 'BrierScore')
  for(met in mets){
    df2 <- sort(df[[met]])
    all_mets[nrow(all_mets) + 1,] <<- list(mean = mean(df2), lower_band= df2[5], upper_band = df2[195], met, unique(df$model_name))
  }
}

boot_ci <- data.frame()
lapply(unique(boot_app$model_name), function(model_name) {
  # Filter df by the current model name
  boost_apparent_subset <- boot_app[boot_app$model_name == model_name, ]
  # Apply get_opts to the subset
  get_ci(boost_apparent_subset)
})
write.csv(all_mets, "bootstrap_app_validation_results-all_vs_region7_corrected_missing_TimeRegion.csv", row.names = FALSE)




