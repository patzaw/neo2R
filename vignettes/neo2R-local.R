## ----include = FALSE---------------------------------------------------------------------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  fig.path = "man/figures/README-",
  echo = TRUE
)

## ----setup, include = FALSE--------------------------------------------------------------------------------------------------------------
# Check if we're running as pgodard and if the graph is accessible and empty
library(neo2R)

# Only run executable code if we're pgodard
is_pgodard <- identical(Sys.getenv("USER"), "pgodard")

# Try to connect to the local graph
if (is_pgodard) {
  graph <- tryCatch({
    startGraph(
      "https://localhost:7473",
      username = "neo4j",
      password = "donttrustusers",
      importPath = "~/neo4j_home/neo4jImport",
      .opts = list(ssl_verifypeer = 0)
    )
  }, error = function(e) NULL)
  
  # Check if graph is accessible
  should_run <- !is.null(graph)
} else {
  should_run <- FALSE
}

## ----eval = should_run-------------------------------------------------------------------------------------------------------------------
library(neo2R)

graph <- startGraph(
  "https://localhost:7473",
  username = "neo4j",
  password = "donttrustusers",
  importPath = "~/neo4j_home/neo4jImport",
  .opts = list(ssl_verifypeer = 0)
)

## ----eval = should_run-------------------------------------------------------------------------------------------------------------------
# Create an index to speed-up MERGE
if (as.integer(graph$version[[1]]) >= 5) {
   try(cypher(graph, 'CREATE INDEX FOR (n:TestNode) ON (n.name)'), silent = TRUE)
} else {
   try(cypher(graph, 'CREATE INDEX ON :TestNode(name)'), silent = TRUE)
}

# Define node properties in a data frame
set.seed(1)
nn <- 100000
nodes <- data.frame(
   "name" = paste(
      sample(LETTERS, nn, replace = TRUE),
      sample.int(nn, nn, replace = FALSE)
   ),
   "value" = rnorm(nn, 10, 3),
   stringsAsFactors = FALSE
)

# Import nodes
import_from_df(
  graph = graph,
  cql = 'MERGE (n:TestNode {name: row.name, value: toFloat(row.value)})',
  toImport = nodes
)

# Define edge properties in a data frame
ne <- 100000
edges <- data.frame(
  "from" = sample(nodes$name, ne, replace = TRUE),
  "to" = sample(nodes$name, ne, replace = TRUE),
  "property" = round(runif(ne) * 10),
  stringsAsFactors = FALSE
)

# Import edges
import_from_df(
   graph = graph,
   cql = prepCql(
      'MATCH (f:TestNode {name: row.from})',
      'MATCH (t:TestNode {name: row.to})',
      'MERGE (f)-[r:TestEdge {property: toInteger(row.property)}]->(t)'
   ),
   toImport = edges
)

## ----eval = should_run-------------------------------------------------------------------------------------------------------------------
# Get TestNode with value smaller than 4
# According to the normal distribution we expect 2.5% of the total
# number of nodes ==> ~2500 nodes
df <- cypher(
   graph,
   prepCql(
      'MATCH (n:TestNode) WHERE n.value <= 4',
      'RETURN n.name as name, n.value as value'
   )
)
print(dim(df))
print(head(df))

# Multiple queries can be sent at once
dfl <- multicypher(
   graph,
   sprintf(
      paste(
         'MATCH (n:TestNode) WHERE n.value <= %s',
         'RETURN n.name as name, n.value as value'
      ),
      2:4
   )
)
print(lapply(dfl, dim))

# Get all paths of length 5 starting from a subset of nodes 
net <- cypher(
   graph,
   prepCql(
      'MATCH p=(f:TestNode)-[:TestEdge*5..5]->(t:TestNode) WHERE f.value < 3',
      'RETURN p'
   ),
   result = "graph"
)
print(lapply(net, head, 3))
print(table(unlist(lapply(net$paths, length))))

