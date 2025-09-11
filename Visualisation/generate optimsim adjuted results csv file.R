
optimism_df <- data.frame(matrix(ncol = 4, nrow = 0))
names <- c("apparent","Optimisim_Adjusted","Statistic","Model_name")
colnames(optimism_df) <- names

#internal validation csv file
app_df <- read.csv("internal_validation12-14-all_vs_region1_corrected_missing_TimeRegion.csv")

#bootstrap_apparent_validation_results csv file
boost_apparent<- read.csv("bootstrap_apparent_validation_results-all_vs_region1_corrected_missing_TimeRegion.csv")

#bootstrap test validation_results csv file
boot_test <- read.csv("bootstrap_test_validation_results-all_vs_region1_corrected_missing_TimeRegion.csv")

app_df <- app_df[app_df$model_name != "Naive Logistic-developed on source only",]

get_opts <- function(app_df, boost_apparent, boot_test){ 
  mets <- c('AUC', 'CITL', 'CSLOPE', 'BrierScore')
  for(met in mets){
    app <- boost_apparent[, grepl(met, colnames(boost_apparent)), drop = FALSE]
    test <- boot_test[, grepl(met, colnames(boot_test)), drop = FALSE]
    opt <- app - test
    
    app_val <- app_df[, grepl(met, colnames(app_df)), drop = FALSE][[1]]
    
    print(opt[[1]])
    diff_opt <-   app_val - mean(opt[[1]])
    optimism_df[nrow(optimism_df) + 1,] <<- list(app_val, diff_opt, met, app_df$model_name)
  }
}

lapply(unique(app_df$model_name), function(model_name) {
  # Filter df by the current model name
  boost_apparent_subset <- boost_apparent[boost_apparent$model_name == model_name, ]
  boot_test_subset <- boot_test[boot_test$model_name == model_name, ]
  app_df_subset <- app_df[app_df$model_name == model_name, ]
  
  # Apply get_opts to the subset
  get_opts(app_df_subset, boost_apparent_subset, boot_test_subset)
})


write.csv(optimism_df, "apparent_optadjust_val-all_vs_region1-corrected_missing_TimeRegion.csv", row.names = FALSE)



