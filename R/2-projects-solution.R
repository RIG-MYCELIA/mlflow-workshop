# 3.2 
# Zie het bestand project/MLproject

# 3.3
# Zie het bestand project/train.R

# 3.4
library(mlflow)

experiments <- mlflow_list_experiments()
my_experiment <- experiments[experiments$name == "/Shared/pietje_puk", "experiment_id"]
  
mlflow_run(
  uri = ".", 
  experiment_id = my_experiment, 
  parameters = list(cp = 0.01, maxdepth = 20), 
  no_conda = TRUE
)

# 3.5
library(mlflow)
mlflow_run(
  uri = "https://github.com/friesewoudloper/mlflow-example", 
  experiment_id = my_experiment,  
  parameters = list(cp = 0.02, maxdepth = 13), 
  no_conda = TRUE
)

# 3.6
# Zie het bestand project/cluster-spec.json
mlflow_run(
  uri = "https://github.com/friesewoudloper/mlflow-example", 
  experiment_id = my_experiment,  
  parameters = list(cp = 0.02, maxdepth = 13),
  backend = "databricks",
  backend_config = "cluster-spec.json"
)