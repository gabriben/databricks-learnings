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
