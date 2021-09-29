# 1.2
library(mlflow)
df <- mlflow_list_experiments()
# Optie 1
experiment_id <- df$experiment_id[1]
mlflow_get_experiment(experiment_id)
# Optie 2
experiment_name <- df$name[1]
mlflow_get_experiment(name = experiment_name)

# 1.3
experiment_name <- "/Shared/pietje_puk"
experiment_id <- mlflow_create_experiment(experiment_name)
cat("Experiment id:", experiment_id)
# Optie 1
mlflow_set_experiment(experiment_name)
# Optie 2
mlflow_set_experiment(experiment_id = experiment_id)

# 1.4
# Optie 1
run <- mlflow_start_run()
cat("Run id:", run$run_id)
# Optie 2
mlflow_start_run()
run <- mlflow_get_run()
cat("Run id:", run$run_id)

# 1.5
cat("Actieve run:", mlflow_get_run()$run_id)
mlflow_end_run()
# Onderstaande commando geeft nu een foutmelding, want er is geen actieve run meer
cat("Actieve run:", mlflow_get_run()$run_id)

# 1.6
mlflow_start_run()
mlflow_log_param("minsplit", 30)
mlflow_log_param("cp", 0.001)
# Check dat de parameters gelogd zijn in de actieve run
run <- mlflow_get_run()
run$run_id
run$params
mlflow_end_run()

# 1.7
mlflow_start_run()
mlflow_log_metric("accuracy", 0.95)
mlflow_log_metric("recall", 0.89)
mlflow_log_metric("precision", 0.97)
# Check dat de metrics gelogd zijn in de actieve run
run <- mlflow_get_run()
run$run_id
run$metrics
mlflow_end_run()

# Optionele oefening
mlflow_start_run()
linear_model <- lm(Sepal.Width ~ Sepal.Length, data = iris)
rmse <- sqrt(mean(linear_model$residuals^2))
mlflow_log_metric('rmse', rmse)
run <- mlflow_get_run()
run$metrics
mlflow_end_run()

# 1.8
mlflow_start_run()
writeLines(capture.output(sessionInfo()), "session_info.txt")
mlflow_log_artifact("session_info.txt")
mlflow_end_run()
file.remove("session_info.txt")

# 1.9
mlflow_start_run()
linear_model <- lm(Sepal.Width ~ Sepal.Length, iris)
predictor <- carrier::crate(
  function(x) stats::predict(model, newdata = x),
  model = linear_model
)
mlflow_log_model(predictor, "iris")
mlflow_end_run()
# Predictie maken
rm(linear_model)
new_obs <- data.frame(Sepal.Length = 5.4)
cat("Predictie:", predictor(new_obs))

# 1.11
library(rpart)
mlflow_start_run()
cp <- 0.05
maxdepth <- 3
mlflow_log_param('cp', cp)
mlflow_log_param('maxdepth', maxdepth)
tree <- rpart(
  Species ~ .,
  data = iris,
  method = "class",
  control = rpart.control(cp = cp, maxdepth = maxdepth)
)
predictor <- carrier::crate(
  function(x) {rpart:::predict.rpart(model, x, type = "class")},
  model = tree
)
mlflow_log_model(predictor, "model")
iris$Pred <- predictor(iris[, -5])
accuracy <- sum(iris$Species == iris$Pred) / nrow(iris)
mlflow_log_metric("accuracy", accuracy)
run <- mlflow_end_run()
# Verwijderen alle objecten, zodat je een goede test kunt doen
rm(cp, maxdepth, tree, predictor, accuracy)
# Voorspellingen doen voor ongeziene data
run_id <- run$run_id # Vul hier eventueel het run_id van je collega in
predictor <- mlflow_load_model(paste0("runs:/", run_id, "/model"))
new_obs <- data.frame(
  Sepal.Length = 5.4,
  Sepal.Width  = 3.5,
  Petal.Length = 1.4,
  Petal.Width  = 0.2
)
predictor(new_obs)

# 1.12
library(rpart)
with(mlflow_start_run(), {
  cp <- 0.05
  maxdepth <- 3
  mlflow_log_param('cp', cp)
  mlflow_log_param('maxdepth', maxdepth)
  tree <- rpart(
    Species ~ .,
    data = iris,
    method = "class",
    control = rpart.control(cp = cp, maxdepth = maxdepth)
  )
  predictor <- carrier::crate(
    function(x) {rpart:::predict.rpart(model, x, type = "class")},
    model = tree
  )
  mlflow_log_model(predictor, "model")
  iris$Pred <- predictor(iris[, -5])
  accuracy <- sum(iris$Species == iris$Pred) / nrow(iris)
  mlflow_log_metric("accuracy", accuracy)
})
