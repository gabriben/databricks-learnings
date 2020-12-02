# Load packages ======================================================================================================

suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(tidymodels))
suppressPackageStartupMessages(library(mlflow))
suppressPackageStartupMessages(library(here))

# Set Environment ======================================================================================================

#MLFlow specific
Sys.setenv(MLFLOW_CONDA_HOME = "/databricks/conda")
Sys.setenv(DATABRICKS_TOKEN = my_token)
Sys.setenv(DATABRICKS_HOST = "https://dbc-4c80bcdb-419d.cloud.databricks.com")

s3_bucket <- "ci-data-apps/data/"

# Set MLFlow tags ======================================================================================================

#Example tags
time_scale = "hour"
target_group_string <- "25-54 jaar"
ratings_type <- "tvGRP"
start_date <- "2008-01-01"
end_date <- "2019-12-31"
mode <- "regression"
model_name <- "rand_forest"
engine <- "ranger"


# Set up MLFLow experiment ======================================================================================================

install_mlflow()
mlflow_set_tracking_uri('databricks')
mlflow_set_experiment(experiment_name = paste0(here:"/mlflow_demo"))

# Define MLFlow functions =================================================================================================

log_workflow_parameters <- function(workflow) {

  spec <- workflows::pull_workflow_spec(workflow)
  parameter_names <- names(spec$args)
  parameter_values <- lapply(spec$args, rlang::get_expr)

  for (i in seq_along(spec$args)) {
    parameter_name <- parameter_names[[i]]
    parameter_value <- parameter_values[[i]]
    if (!is.null(parameter_value)) {

      mlflow_log_param(parameter_name, parameter_value)
    }
  }
  workflow
}

log_tags <- function() {

  mlflow_set_tag("time_scale", time_scale)
  mlflow_set_tag("target_group_string", target_group_string)
  mlflow_set_tag("ratings_type", ratings_type)
  mlflow_set_tag("start_date", start_date)
  mlflow_set_tag("end_date", end_date)
  mlflow_set_tag("model_name", model_name)
  mlflow_set_tag("engine", engine)
  mlflow_set_tag("mode", mode)

}
# Load data ============================================================================================================

train_temp <- s3readRDS("data.rds", bucket = s3_bucket)

# Set formula =================================================================================================

form <- as.formula(paste0("ratings ~ ", formula_features))

# Set model =================================================================================================

if(model_name == "boost_tree"){

  # XGBoost model specification
  model <- boost_tree(
    trees = tune(),
    min_n = tune(),
    mtry = tune()
  ) %>%
    set_engine(engine) %>%
    set_mode(mode)

  # grid specification
  params <- parameters(
    mtry(range = c(70, 105)),
    trees(range = c(1, 500)),
    min_n(range = c(25, 40))) %>%
    update(
      mtry = finalize(mtry(), data))


  grid <- grid_max_entropy(
    params,
    size = 12)

}

# Set workflow =================================================================================================

tv_workflow <-
  workflows::workflow() %>%
  add_model(tv_model) %>%
  add_formula(form)

# Set rolling origin =================================================================================================

skip <- data %>%
  select(year, month) %>%
  unique() %>%
  count() -13

roll_rs <- train_temp %>%
  sliding_period(
    date_time,
    time_scale,
    lookback = Inf,
    skip = as.numeric(skip)
  )

# Run workflow  =================================================================================================

tv_grid_results <-
  tv_workflow %>%
  tune_grid(
    resamples = roll_rs,
    metrics   = metric_set(mae, mape, rmse, rsq),
    grid      =  tv_grid
  )

tv_grid_results_agg <-
  bind_rows(tv_grid_results$.metrics) %>%
  group_by(across(!.estimate)) %>%
  summarise(mean = mean(.estimate),
            std_err = sd(.estimate)/sqrt(length(.estimate)),
            n = length(.estimate))

tv_grid_results_agg

mods = unique(tv_grid_results_agg$.config)

for(mod in mods){

  result <-
    tv_grid_results_agg %>%
    filter(.config == mod)

  with(mlflow_start_run(), {

    # Log tags
    log_tags()

    # Log metrics
    pmap(list(result$.metric, result$mean),  mlflow_log_metric)

    # Log hyperparameters
    hyperparameters <-
      tv_grid_results_agg %>%
      filter(.config == mod) %>%
      filter(.metric == 'mape')

    fitted_tv_model <-
      tv_workflow %>%
      finalize_workflow(hyperparameters) %>%
      fit(train_temp) %>%
      log_workflow_parameters()

    # Log model
    crated_model <- carrier::crate(
      function(x) workflows:::predict.workflow(fitted_tv_model, x),
      fitted_tv_model = fitted_tv_model
    )

    mlflow_save_model(crated_model, here::here("models"))
    mlflow_log_artifact(here::here("models", "crate.bin"))

  })

}
