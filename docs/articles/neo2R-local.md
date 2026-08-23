# Using neo2R with Local Neo4j Instances

## Introduction

This vignette demonstrates how to connect to a local Neo4j instance and
import data from data frames.

## Connecting to Local Neo4j

After installing [Neo4j](https://neo4j.com/), use
[`startGraph()`](https://patzaw.github.io/neo2R/reference/startGraph.md)
to initialize the connection from R. If authentication has been disabled
in Neo4j by setting `NEO4J_AUTH=none`, neither username nor password are
required.

If you’re connecting to a local instance of Neo4j and an import
directory has been defined in the configuration, you can specify it in
order to allow import from data frames.

``` r

library(neo2R)

graph <- startGraph(
  "https://localhost:7473",
  username = "neo4j",
  password = "donttrustusers",
  importPath = "~/neo4j_home/neo4jImport",
  .opts = list(ssl_verifypeer = 0)
)
```

## Importing Data from Data Frames

If you’re connected to a local instance of Neo4j and an import directory
has been defined (see above), you can import data from data frames. Use
the `row` prefix to refer to the data frame column.

``` r

# Create an index to speed-up MERGE
if (as.integer(graph$version[[1]]) >= 5) {
   try(cypher(graph, 'CREATE INDEX FOR (n:TestNode) ON (n.name)'), silent = TRUE)
} else {
   try(cypher(graph, 'CREATE INDEX ON :TestNode(name)'), silent = TRUE)
}
#> Neo.ClientError.Schema.EquivalentSchemaRuleAlreadyExists
#> An equivalent index already exists, 'Index( id=3, name='index_e8759119', type='RANGE', schema=(:TestNode {name}), indexProvider='range-1.0' )'.

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
```

## Querying the Neo4j Database

You can query the Neo4j graph database using the
[`cypher()`](https://patzaw.github.io/neo2R/reference/cypher.md)
function. Depending on the query, the function can return data in a data
frame (by setting `result = "row"`) or in a list with nodes,
relationships and paths returned by the query by setting
`result = "graph"`.

``` r

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
#> [1] 2253    2
print(head(df))
#>      name    value
#> 1  N 2585 1.965486
#> 2 L 72527 3.345461
#> 3 Y 54240 2.372623
#> 4  N 1436 1.500713
#> 5 T 21434 3.592195
#> 6 M 91787 2.504475

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
#> [[1]]
#> [1] 386   2
#> 
#> [[2]]
#> [1] 954   2
#> 
#> [[3]]
#> [1] 2253    2

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
#> $nodes
#> $nodes$`4:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:7`
#> $nodes$`4:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:7`$elementId
#> [1] "4:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:7"
#> 
#> $nodes$`4:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:7`$labels
#> $nodes$`4:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:7`$labels[[1]]
#> [1] "TestNode"
#> 
#> 
#> $nodes$`4:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:7`$properties
#> $nodes$`4:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:7`$properties$name
#> [1] "N 2585"
#> 
#> $nodes$`4:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:7`$properties$value
#> [1] 1.965486
#> 
#> 
#> 
#> $nodes$`4:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:97347`
#> $nodes$`4:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:97347`$elementId
#> [1] "4:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:97347"
#> 
#> $nodes$`4:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:97347`$labels
#> $nodes$`4:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:97347`$labels[[1]]
#> [1] "TestNode"
#> 
#> 
#> $nodes$`4:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:97347`$properties
#> $nodes$`4:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:97347`$properties$name
#> [1] "V 30913"
#> 
#> $nodes$`4:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:97347`$properties$value
#> [1] 10.389
#> 
#> 
#> 
#> $nodes$`4:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:13440`
#> $nodes$`4:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:13440`$elementId
#> [1] "4:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:13440"
#> 
#> $nodes$`4:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:13440`$labels
#> $nodes$`4:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:13440`$labels[[1]]
#> [1] "TestNode"
#> 
#> 
#> $nodes$`4:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:13440`$properties
#> $nodes$`4:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:13440`$properties$name
#> [1] "Z 33864"
#> 
#> $nodes$`4:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:13440`$properties$value
#> [1] 5.65467
#> 
#> 
#> 
#> 
#> $relationships
#> $relationships$`5:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:93543`
#> $relationships$`5:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:93543`$elementId
#> [1] "5:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:93543"
#> 
#> $relationships$`5:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:93543`$startNodeElementId
#> [1] "4:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:7"
#> 
#> $relationships$`5:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:93543`$endNodeElementId
#> [1] "4:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:97347"
#> 
#> $relationships$`5:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:93543`$type
#> [1] "TestEdge"
#> 
#> $relationships$`5:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:93543`$properties
#> $relationships$`5:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:93543`$properties$property
#> [1] 8
#> 
#> 
#> 
#> $relationships$`5:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:31423`
#> $relationships$`5:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:31423`$elementId
#> [1] "5:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:31423"
#> 
#> $relationships$`5:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:31423`$startNodeElementId
#> [1] "4:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:97347"
#> 
#> $relationships$`5:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:31423`$endNodeElementId
#> [1] "4:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:13440"
#> 
#> $relationships$`5:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:31423`$type
#> [1] "TestEdge"
#> 
#> $relationships$`5:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:31423`$properties
#> $relationships$`5:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:31423`$properties$property
#> [1] 0
#> 
#> 
#> 
#> $relationships$`5:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:470`
#> $relationships$`5:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:470`$elementId
#> [1] "5:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:470"
#> 
#> $relationships$`5:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:470`$startNodeElementId
#> [1] "4:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:13440"
#> 
#> $relationships$`5:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:470`$endNodeElementId
#> [1] "4:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:79444"
#> 
#> $relationships$`5:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:470`$type
#> [1] "TestEdge"
#> 
#> $relationships$`5:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:470`$properties
#> $relationships$`5:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:470`$properties$property
#> [1] 10
#> 
#> 
#> 
#> 
#> $paths
#> $paths[[1]]
#> [1] "5:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:93543"
#> [2] "5:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:31423"
#> [3] "5:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:470"  
#> [4] "5:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:7553" 
#> [5] "5:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:94678"
#> 
#> $paths[[2]]
#> [1] "5:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:93543"
#> [2] "5:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:31423"
#> [3] "5:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:470"  
#> [4] "5:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:7553" 
#> [5] "5:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:98608"
#> 
#> $paths[[3]]
#> [1] "5:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:93543"
#> [2] "5:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:31423"
#> [3] "5:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:69425"
#> [4] "5:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:71263"
#> [5] "5:189c469e-6afa-4d4f-b15c-f46d0ff5d9b4:58428"
print(table(unlist(lapply(net$paths, length))))
#> 
#>   5 
#> 945
```

### Further Reading

- [Neo4j Cypher
  reference](https://neo4j.com/docs/cypher-manual/current/) — query
  language docs
