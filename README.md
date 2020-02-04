# neo2R

The aim of the neo2R is to provide simple and low level connectors
for querying [Neo4j graph databases](https://neo4j.com/).
The objects returned by the query functions are either lists or data.frames
with very few post-processing.
It allows fast processing of queries returning many records.
And it let the user handle post-processing according to the data model
and his needs.
It has been developed to support the BED package (https://github.com/patzaw/BED,
https://f1000research.com/articles/7-195/v3 ).
Other packages such as RNeo4j (https://github.com/nicolewhite/RNeo4j) or
neo4R (https://github.com/neo4j-rstats/neo4r) provide connectors to neo4j
databases with additional features.

# Installation

## Dependencies

The following R packages available on CRAN are required:

    - base64enc
    - jsonlite
    - RCurl
    
They can be easily installed with the `install.packages()` function.

## Installation from github

```r
devtools::install_github("patzaw/neo2R")
```

# Use

## Running Neo4j

You can download and install Neo4j according to
the [documentation](https://neo4j.com/docs/getting-started/current/get-started-with-neo4j/#_installing_neo4j).
You can also run it
in a [docker container](https://neo4j.com/docs/operations-manual/current/docker/).

```sh
#!/bin/sh

## Chose a name for your container
export CONTAINER=neo4j_cont

## Chose Neo4j version
export NJ_VERSION=3.5.14

## Ports
export NJ_HTTP_PORT=7474
export NJ_BOLT_PORT=7687

## Change the location of the Neo4j directory
export NJ_HOME=~/neo4j_home
mkdir -p $NJ_HOME

## Import and data directory
export NJ_IMPORT=$NJ_HOME/neo4jImport
mkdir -p $NJ_IMPORT
export NJ_DATA=$NJ_HOME/neo4jData
if test -e $NJ_DATA; then
   echo "$NJ_DATA directory exists ==> abort - Remove it before proceeding" >&2
   exit
fi
mkdir -p $NJ_DATA

docker run -d \
	--name $CONTAINER \
	--publish=$NJ_HTTP_PORT:7474 \
	--publish=$NJ_BOLT_PORT:7687 \
	--env=NEO4J_dbms_memory_heap_initial__size=4G \
	--env=NEO4J_dbms_memory_heap_max__size=4G \
	--env=NEO4J_dbms_memory_pagecache_size=2G \
	--env=NEO4J_dbms_query__cache__size=0 \
  --env=NEO4J_cypher_min__replan__interval=100000000ms \
  --env=NEO4J_cypher_statistics__divergence__threshold=1 \
	--env=NEO4J_AUTH=none \
	--env=NEO4J_dbms_directories_import=import \
	--volume $NJ_IMPORT:/var/lib/neo4j/import \
	--volume $NJ_DATA/data:/data \
	neo4j:$NJ_VERSION
```

## Connect to Neo4j

After installing [neo4j](https://neo4j.com/),
`startGraph` is used to initialize the connection from R.
If authentication has been disabled in neo4j by setting NEO4J.AUTH=none,
neither username nor password are required.
If you're connecting to a local instance of Neo4j and import directory has
been defined in the configuration, you can specify it in order to allow
import from data.frames.

```r
graph <- startGraph(
  "localhost:7474",
  importPath="~/neo4j_home/neo4jImport"
)
```

## Import from data.frame

If you're connecting to a local instance of Neo4j and import directory has
been defined (see above), you can import data from data.frames.
Use the 'row' prefix to refer to the data.frame column.

```r
#########################################
## Nodes
## Define a label for the node to import
label <- 'NodeType'
## Define node properties in a data.frame
nodes <- data.frame(
  "name"=c("a", "b", "c", "d", "e", "f"),
  "value"=1:6,
  stringsAsFactors=FALSE
)
import_from_df(
  graph=graph,
  cql=sprintf(
     'MERGE (n:%s {name:row.name, value:toInteger(row.value)})',
     label
  ),
  toImport=nodes
)

#########################################
## Edges
## Define a label for the node to import
label <- 'EdgeType'
## Define node properties in a data.frame
edges <- data.frame(
  "from"=c("a", "b", "c"),
  "to"=c("d", "e", "f"),
  "property"=(1:3)*10,
  stringsAsFactors=FALSE
)
import_from_df(
   graph=graph,
   cql=prepCql(
      'MATCH (f:NodeType {name:row.from})',
      'MATCH (t:NodeType {name:row.to})',
      sprintf('MERGE (f)-[r:%s {property:toInteger(row.property)}]->(t)', label)
   ),
   toImport=edges
)
```

## Query the Neo4j database

You can query the Neo4j graph database using the `cypher()` function.
Depending on the query, the function can return data in a a data.frame
(by setting `result="row"`) or in a list with nodes, relationships and paths
returned by the query (by setting `result="graph"`)

```r
df <- cypher(
   graph,
   prepCql(
      'MATCH (n:NodeType) WHERE n.value < 2',
      'RETURN n.name as name, n.value as value'
   )
)
net <- cypher(
   graph,
   prepCql(
      'MATCH (f:NodeType)-[r:EdgeType]->(t:NodeType) WHERE f.value < 2',
      'RETURN f, t, r'
   ),
   result="graph"
)
```

