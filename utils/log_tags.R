log_tags <- function(setups) {
  
  for(s in setups){
  mlflow_set_tag(s["name"], s["variable"])
  }
  
}