# Zie https://archive.ics.uci.edu/ml/datasets/Statlog+(German+Credit+Data)

library(dplyr)
url <- "http://archive.ics.uci.edu/ml/machine-learning-databases/statlog/german/german.data"
german_credit <- read.table(url)
german_credit <- german_credit[, c(2, 3, 4, 5, 13, 15, 21)]
colnames(german_credit) <- c("duration", "credit_history", "purpose", "amount", "age", "housing", "class")
german_credit %>% 
  mutate(
    purpose = case_when(
      purpose == "A40" ~ "car (new)",
      purpose == "A41" ~ "car (used)",
      purpose == "A42" ~ "furniture/equipment",
      purpose == "A43" ~ "radio/television",
      purpose == "A44" ~ "domestic appliances",
      purpose == "A45" ~ "repairs",
      purpose == "A46" ~ "education",
      purpose == "A47" ~ "vacation", 
      purpose == "A48" ~ "retraining",
      purpose == "A49" ~ "business",
      purpose == "A410" ~ "others"
    ),
    housing = case_when(
      housing == "A151" ~ "rent",
      housing == "A152" ~ "own",
      housing == "A153" ~ "for free"
    ),
    credit_history = case_when(
      credit_history == "A30" ~ "no credits taken/ all credits paid back duly",
      credit_history == "A31" ~ "all credits at this bank paid back duly",
      credit_history == "A32" ~ "existing credits paid back duly till now",
      credit_history == "A33" ~ "delay in paying off in the past",
      credit_history == "A34" ~ "critical account/ other credits existing (not at this bank)"
    ),
    class = case_when(
      class == 1 ~ "Good",
      class == 2 ~ "Bad"
    )
  ) %>%
  write.csv("german_credit.csv", row.names = FALSE)
rm(url, german_credit)
