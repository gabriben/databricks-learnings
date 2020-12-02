MLFlow_setup <- function(token, db_host, exp_path) {

  suppressPackageStartupMessages(library(mlflow))

  Sys.setenv(MLFLOW_CONDA_HOME = "/databricks/conda")
  Sys.setenv(DATABRICKS_TOKEN = token)
  Sys.setenv(DATABRICKS_HOST = db_host)

  install_mlflow()
  mlflow_set_tracking_uri('databricks')
  mlflow_set_experiment(experiment_name = paste0(exp_path))

}


  
