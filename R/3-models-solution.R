# 3.4

library(httr)

key <- Sys.getenv("DATABRICKS_TOKEN")
base_url <- Sys.getenv("DATABRICKS_HOST")
path <- "/model/tech-summit-wine-model/Production/invocations"
body <- list(
  list(
    alcohol = 12.8, 
    chlorides = 0.029, 
    `citric acid` = 0.48, 
    density = 0.98, 
    `fixed acidity` = 6.2, 
    `free sulfur dioxide` = 29, 
    pH = 3.33, 
    `residual sugar` = 1.2, 
    sulphates = 0.39, 
    `total sulfur dioxide` = 75, 
    `volatile acidity` = 0.66
  ),
  list(
    alcohol = 9.4, 
    chlorides = 0.076, 
    `citric acid` = 0.00, 
    density = 0.9978, 
    `fixed acidity` = 7.4, 
    `free sulfur dioxide` = 11, 
    pH = 3.51, 
    `residual sugar` = 1.9, 
    sulphates = 0.56, 
    `total sulfur dioxide` = 34, 
    `volatile acidity` = 0.700
  )
)

pred <- content(
  httr::POST(
    url <- modify_url(base_url, path = path, scheme = "https"),
    body = jsonlite::toJSON(list(body), auto_unbox = TRUE), 
    add_headers(Authorization = paste("Bearer", key)), 
    content_type_json()
  )
)
pred
