library(mlflow)
mlflow_create_experiment("/Shared/demo-experiment")
mlflow_set_experiment("/Shared/demo-experiment")

sapply(1:25, function(x)
{
  with(mlflow_start_run(), {
    mlflow_log_metric("recall",    runif(1, min=0.5, max=1))
    mlflow_log_metric("precision", runif(1, min=0.5, max=1))
  })
})
