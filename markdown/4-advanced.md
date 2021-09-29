## Advanced topics

### 4.1 German credit data

In de volgende oefeningen ga je aan de slag met een subset van de [German credit data](https://archive.ics.uci.edu/ml/datasets/statlog+(german+credit+data)) dataset. Het gaat om de gegevens van personen die een lening hebben bij een bank. Het doel is om een model te trainen dat of de aanvrager van een nieuwe lening wel kredietwaardig is.

Je kunt de geprepareerde dataset inlezen met onderstaande code.

```
url <- "data/german_credit.csv"
german_credit <- read.csv(url, stringsAsFactors = TRUE) 
head(german_credit)
```
Met deze dataset kun je bijvoorbeeld een decision tree trainen.

```
with(mlflow_start_run(), {
  tree <- rpart(class ~ ., data = german_credit, method = "class")
  predictor <- carrier::crate(
    function(x) {as.character(rpart:::predict.rpart(model, x, type = "class"))},
    model = tree
  )
  mlflow_log_model(predictor, "model")
  mlflow_set_tag("result", "creditworthiness (Good/Bad)")
})
```

Vergeet niet om aan het begin van de R sessie het default experiment te initialiseren, en om de packages te laden. Anders geeft bovenstaande code een foutmelding. 

#### Oefening
1. Train een model voor het voorspellen van de kredietwaardigheid van een aanvrager en log dit model in MLflow.
2. Herstart de R sessie.
4. Laad het model en maak een voorspelling voor onderstaande nieuwe aanvrager.
```
new_loan_applicant <- data.frame(
  duration = 48,
  credit_history = "delay in paying off in the past",
  purpose = "car (new)",
  amount = 10000,
  age = 18,
  housing = "for free"
)
```

### 4.2 Voorspelfunctie uitbreiden

Stel dat je niet alleen een classificatie, maar ook een kans op wanbetaling wilt. Dan moet je de voorspelfunctie uitbreiden.

```
with(mlflow_start_run(), {
  tree <- rpart(class ~ ., data = german_credit, method = "class")
  predictor <- carrier::crate(
    function(x) {
      class <- as.character(rpart:::predict.rpart(model, x, type = "class"))
      prob <- rpart:::predict.rpart(model, x, type = "prob")[, "Bad"]
      list(creditworthiness = class, probability_of_default = prob)
    },
    model = tree
  )
  mlflow_log_model(predictor, "model")
  mlflow_set_tag("result", "creditworthiness (Good/Bad)")
  mlflow_set_tag("result", "probability of default")
})
```

### 4.3 Voorspelling overrulen

Om er zeker van te zijn dat het model ook in de toekomst goed blijft presteren, moet je gegevens verzamelen voor het hertrainen. Het is natuurlijk belangrijk dat deze gegevens representatief zijn. Stel dat de bank er daarom voor kiest om in 20% van de gevallen de voorspelling van het model te negeren en t&oacute;ch een lening te verstrekken. 
(Vanuit bedrijfseconomisch perspectief misschien niet zo slim, maar wel fijn voor de datascientist!)

#### Oefening:
1. Breid de voorspelfunctie uit, zodat het model niet alleen een classificatie en kans retourneert, maar ook een beslissing (wel of geen lening verlenen). Een aanvrager die geclassificeerd wordt als kredietwaardig, krijgt sowieso een lening. In 1 op de 5 gevallen krijgt een aanvrager die niet kredietwaardig is toch een lening. Onderstaande code kan je misschien op weg helpen.

```
decision <- ifelse(class == "Bad" & stats::runif(1) <= 0.20, "grant loan", "do not grant loan")
```
2. Geef voor de nieuwe aanvrager uit de vorige oefening 100 keer een voorspelling.
3. Verifieer dat het model in 20% van de gevallen een niet kredietwaardige aanvrager t&oacute;ch een lening geeft, omdat de voorspelling van het model 'overruled' wordt.

### 4.4 Uitleg toevoegen 

Om zo transparant mogelijk te zijn, is het goed om ook een uitleg toe te voegen aan het resultaat van het model. Met functies uit {partykit} is dat mogelijk.

```
with(mlflow_start_run(), {
  tree <- rpart(formula = class ~ ., data = german_credit, method = "class") 
  predictor <- carrier::crate(
    function(x) {
      model <- partykit::as.party(model)
      class <- as.character(partykit:::predict.party(model, x, type = "response"))
      prob  <- partykit:::predict.party(model, x, type = "prob")[, "Bad"]
      rules <- partykit:::.list.rules.party(model)
      expl  <- rules[as.character(partykit:::predict.party(model, x, type = "node"))]
      list(creditworthiness = class, probability_of_default = prob, explanation = expl)           
  }, 
    model = tree
  )
  mlflow_log_model(predictor, "model")
  mlflow_set_tag("result", "creditworthiness (Good/Bad)")
  mlflow_set_tag("result", "probability of default")
  mlflow_set_tag("result", "explanation")
})
```

#### Oefening:
Probeer bovenstaande voorspelfunctie uit voor de nieuwe klant die je eerder hebt aangemaakt. De uitleg die het model geeft, kan misschien qua opmaak beter. Maar het is wel duidelijk welke regels het model heeft toegepast om tot een voorspelling voor een specifieke aanvrager te komen.

### 4.5 Preprocessing stappen toevoegen

Stel dat de bank een k-nearest neighbors algoritme wil gaan gebruiken voor het bepalen van kredietwaardigheid. Om het simpel te houden, worden alleen de numerieke voorspellende variabelen meegenomen. Het is verstandig om deze variabelen te normaliseren, zodat ze een waarde krijgen tussen 0 en 1.

#### Oefening:
[Min-max normalisatie](https://www.codecademy.com/articles/normalization) is een veelgebruikte methode voor normaliseren. Bepaal daarom het minimum en maximum voor de numerieke variabelen in de dataset.

Nu heb je alle informatie die nodig is om de voorspelfunctie aan te passen.

```
library(class)

with(mlflow_start_run(), {  
  nor_duration <- function(x) {(x - 4)/(72 - 4)}
  nor_amount <- function(x) {(x - 250)/(18424 - 250)}
  
  train <- data.frame(
    duration_norm = nor_duration(german_credit$duration),
    amount_norm = nor_amount(german_credit$amount)
  )

  cl <- german_credit$class

  predictor <- carrier::crate(
    function(x) {
      x$duration_norm <- nor_duration(x$duration)
      x$amount_norm <- nor_amount(x$amount)
      pred <- class::knn(
        train = train, 
        test = x[, c("duration_norm", "amount_norm")],
        cl = cl,
        k = 5
      )
      as.character(pred)
    },
    train = train,
    cl = cl,
    nor_duration = nor_duration,
    nor_amount = nor_amount
  )  
  mlflow_log_model(predictor, "model")
  mlflow_set_tag("result", "creditworthiness (Good/Bad)")
  mlflow_set_tag("algorithm", "kNN")
})
```

#### Oefening:
Breid bovenstaande code uit, zodat ook de voorspellende variabele `housing` wordt meegenomen. Het is een categorische variabele die drie verschillende waarden kan hebben. Pas daarom in de preprocessing fase [one-hot encoding](https://machinelearningmastery.com/why-one-hot-encode-data-in-machine-learning/) toe.
