# 4.1
library(mlflow)
library(rpart)

url <- "data/german_credit.csv"
german_credit <- read.csv(url, stringsAsFactors = TRUE) 

mlflow_set_experiment("/Shared/pietje_puk")

new_loan_applicant <- data.frame(
  duration = 48,
  credit_history = "delay in paying off in the past",
  purpose = "car (new)",
  amount = 10000,
  age = 18,
  housing = "for free"
)

with(mlflow_start_run(), {
  tree <- rpart(class ~ ., data = german_credit, method = "class")
  predictor <- carrier::crate(
    function(x) {as.character(rpart:::predict.rpart(model, x, type = "class"))},
    model = tree
  )
  mlflow_log_model(predictor, "model")
  mlflow_set_tag("result", "creditworthiness (Good/Bad)")
  run_id <- mlflow_get_run()$run_id
})

rm(url, tree, predictor)

predictor <-  mlflow_load_model(paste0("runs:/", run_id, "/model"))
cat(
  "Result: \n", 
  "Creditworthiness:", predictor(new_loan_applicant)
)

# 4.2
with(mlflow_start_run(), {
  tree <- rpart(class ~ ., data = german_credit, method = "class")
  predictor <- carrier::crate(
    function(x) {
      class <- as.character(rpart:::predict.rpart(model, x, type = "class"))
      prob <- rpart:::predict.rpart(model, x, type = "prob")[, "Bad"]
      list(
        creditworthiness = class, 
        probability_of_default = prob
      )
    },
    model = tree
  )
  mlflow_log_model(predictor, "model")
  mlflow_set_tag("result", "creditworthiness (Good/Bad)")
  mlflow_set_tag("result", "probability of default")
  run_id <- mlflow_get_run()$run_id
})


rm(tree, predictor)

predictor <-  mlflow_load_model(paste0("runs:/", run_id, "/model"))
pred <- predictor(new_loan_applicant)
cat(
  "Result: \n", 
  "Creditworthiness:", unlist(pred["creditworthiness"]), "\n",
  "Probability of default:", unlist(pred["probability_of_default"])
)

# 4.3
with(mlflow_start_run(), {
  tree <- rpart(class ~ ., data = german_credit, method = "class")
  predictor <- carrier::crate(
    function(x) {
      class <- as.character(rpart:::predict.rpart(model, x, type = "class"))
      prob <- rpart:::predict.rpart(model, x, type = "prob")[, "Bad"]
      decision <- ifelse(class == "Bad" & stats::runif(1) <= 0.20, "grant loan", "do not grant loan")
      list(
        creditworthiness = class, 
        probability_of_default = prob, 
        decision = decision
      )
    },
    model = tree
  )
  mlflow_log_model(predictor, "model")
  mlflow_set_tag("result", "creditworthiness (Good/Bad)")
  mlflow_set_tag("result", "probability of default")
  mlflow_set_tag("result", "decision")
  run_id <- mlflow_get_run()$run_id
})

rm(tree, predictor)

predictor <-  mlflow_load_model(paste0("runs:/", run_id, "/model"))
pred <- predictor(new_loan_applicant)
cat(
  "Result: \n", 
  "Creditworthiness:", unlist(pred["creditworthiness"]), "\n",
  "Probability of default:", unlist(pred["probability_of_default"]), "\n",
  "Decision:", unlist(pred["decision"])
)

# Het model classificeert de nieuwe aanvrager als niet kredietwaardig.
# Toch is in 20% van de gevallen het besluit om wel een lening te geven.
d <- sapply(1:100, function(x) predictor(new_loan_applicant)$decision)
table(d)

# 4.4
with(mlflow_start_run(), {
  tree <- rpart(class ~ ., data = german_credit, method = "class")
  predictor <- carrier::crate(
    function(x) {
      model <- partykit::as.party(model)
      class <- as.character(partykit:::predict.party(model, x, type = "response"))
      prob  <- partykit:::predict.party(model, x, type = "prob")[, "Bad"]
      decision <- ifelse(class == "Bad" & stats::runif(1) <= 0.20, "grant loan", "do not grant loan")
      rules <- partykit:::.list.rules.party(model)
      expl  <- rules[as.character(partykit:::predict.party(model, x, type = "node"))]    
      list(
        creditworthiness = class, 
        probability_of_default = prob, 
        decision = decision,
        explanation = expl
      )
    },
    model = tree
  )
  mlflow_log_model(predictor, "model")
  mlflow_set_tag("result", "creditworthiness (Good/Bad)")
  mlflow_set_tag("result", "probability of default")
  mlflow_set_tag("result", "decision")
  mlflow_set_tag("result", "explanation")
  run_id <- mlflow_get_run()$run_id
})

rm(tree, predictor)

predictor <-  mlflow_load_model(paste0("runs:/", run_id, "/model"))
pred <- predictor(new_loan_applicant)
cat(
  "Result: \n", 
  "Creditworthiness:", unlist(pred["creditworthiness"]), "\n",
  "Probability of default:", unlist(pred["probability_of_default"]), "\n",
  "Decision:", unlist(pred["decision"]), "\n",
  "Explanation:", unlist(pred["explanation"])
)

# 4.5
library(class)

with(mlflow_start_run(), {  
  nor_duration <- function(x) {(x - 4)/(72 - 4)}
  nor_amount <- function(x) {(x - 250)/(18424 - 250)}
  encode_housing <- function(x, c) {
    ifelse(x == c, 1, 0)
  }
  
  train <- data.frame(
    duration_norm = nor_duration(german_credit$duration),
    amount_norm = nor_amount(german_credit$amount),
    housing_own = encode_housing(german_credit$housing, "own"),
    housing_for_free = encode_housing(german_credit$housing, "for free"),
    housing_rent = encode_housing(german_credit$housing, "rent")
  )
  
  cl <- german_credit$class
  
  predictor <- carrier::crate(
    function(x) {
      x$duration_norm <- nor_duration(x$duration)
      x$amount_norm <- nor_amount(x$amount)
      x$housing_own <- encode_housing(x$housing, "own")
      x$housing_for_free <- encode_housing(x$housing, "for free")
      x$housing_rent <- encode_housing(x$housing, "rent")
      pred <- class::knn(
        train = train, 
        test = x[, c("duration_norm", "amount_norm", "housing_own", "housing_for_free", "housing_rent")],
        cl = cl,
        k = 5
      )
      as.character(pred)
    },
    train = train,
    cl = cl,
    nor_duration = nor_duration,
    nor_amount = nor_amount,
    encode_housing = encode_housing
  )  
  mlflow_log_model(predictor, "model")
  mlflow_set_tag("result", "creditworthiness (Good/Bad)")
  mlflow_set_tag("algorithm", "kNN")
  run_id <- mlflow_get_run()$run_id
})

rm(nor_duration, nor_amount, encode_housing, train, cl, predictor)

predictor <-  mlflow_load_model(paste0("runs:/", run_id, "/model"))
pred <- predictor(new_loan_applicant)
cat(
  "Result: \n", 
  "Creditworthiness:", pred
)
