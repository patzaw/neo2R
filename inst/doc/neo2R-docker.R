## ----include = FALSE---------------------------------------------------------------------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  fig.path = "man/figures/README-",
  echo = TRUE
)

## ----eval=FALSE--------------------------------------------------------------------------------------------------------------------------
# library(neo2R)
# 
# # First connect with default credentials
# system <- startGraph(
#   "https://localhost:7473",
#   database = "system",
#   check = FALSE,
#   username = "neo4j",
#   password = "neo4j",
#   importPath = "~/neo4j_home/neo4jImport",
#   .opts = list(ssl_verifypeer = 0)
# )
# 
# # Change the password
# cypher(
#   system,
#   "ALTER CURRENT USER SET PASSWORD FROM 'neo4j' TO 'donttrustusers'"
# )

