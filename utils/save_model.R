function(m){

  crated_model <- carrier::crate(
    function(x) workflows:::predict.workflow(m, x),
    m
  )

  mlflow_save_model(crated_model, here::here("models"))
  mlflow_log_artifact(here::here("models", "crate.bin"))
}
