boot_external <- read.csv("external_boot_validation-before2010_after2010_corrected_missing.csv") 


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
lapply(unique(boot_external$model_name), function(model_name) {
  # Filter df by the current model name
  subset <- boot_external[boot_external$model_name == model_name, ]
  # Apply get_opts to the subset
  get_ci(subset)
})
write.csv(all_mets, "bootstrap_external_validation_MoreRecentData.csv", row.names = FALSE)
