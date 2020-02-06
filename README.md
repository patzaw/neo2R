<!----------------------------------------------------------------------------->
<!----------------------------------------------------------------------------->
neo2R
=====

The aim of the neo2R is to provide simple and low level connectors for
querying [Neo4j graph databases](https://neo4j.com/). The objects
returned by the query functions are either lists or data.frames with
very few post-processing. It allows fast processing of queries returning
many records. And it let the user handle post-processing according to
the data model and his needs. It has been developed to support the BED
package
(<a href="https://github.com/patzaw/BED" class="uri">https://github.com/patzaw/BED</a>,
<a href="https://f1000research.com/articles/7-195/v3" class="uri">https://f1000research.com/articles/7-195/v3</a>
). Other packages such as RNeo4j
(<a href="https://github.com/nicolewhite/RNeo4j" class="uri">https://github.com/nicolewhite/RNeo4j</a>)
or neo4R
(<a href="https://github.com/neo4j-rstats/neo4r" class="uri">https://github.com/neo4j-rstats/neo4r</a>)
provide connectors to neo4j databases with additional features.

<!----------------------------------------------------------------------------->
<!----------------------------------------------------------------------------->
Installation
============

<!------------------------->
Dependencies
------------

The following R packages available on CRAN are required:

    - base64enc
    - jsonlite
    - RCurl

They can be easily installed with the `install.packages()` function.

<!------------------------->
Installation from github
------------------------

``` r
devtools::install_github("patzaw/neo2R")
```

<!----------------------------------------------------------------------------->
<!----------------------------------------------------------------------------->
Use
===

<!------------------------->
Running Neo4j
-------------

You can download and install Neo4j according to the
[documentation](https://neo4j.com/docs/getting-started/current/get-started-with-neo4j/#_installing_neo4j).
You can also run it in a [docker
container](https://neo4j.com/docs/operations-manual/current/docker/). It
takes a few seconds to start.

``` sh
#!/bin/sh

#################################
## CONFIG according to your needs
#################################

export CONTAINER=neo4j_cont

## Chose Neo4j version (Only versions 3 and 4 are supported)
export NJ_VERSION=4.0.0
# export NJ_VERSION=3.5.14

## Ports
export NJ_HTTP_PORT=7475
export NJ_BOLT_PORT=7688

## Change the location of the Neo4j directory
export NJ_HOME=~/neo4j_home

## Authorization
NJ_AUTH=neo4j/1234 # set to 'none' if you want to disable authorization

## APOC download
export NJ_APOC=https://github.com/neo4j-contrib/neo4j-apoc-procedures/releases/download/4.0.0.2/apoc-4.0.0.2-all.jar
# export NJ_APOC=https://github.com/neo4j-contrib/neo4j-apoc-procedures/releases/download/3.5.0.7/apoc-3.5.0.7-all.jar

#################################
## RUN
#################################

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
## Neo4j plugins: APOC
export NJ_PLUGINS=$NJ_HOME/neo4jPlugins
mkdir -p $NJ_PLUGINS
cd $NJ_PLUGINS
wget --no-check-certificate $NJ_APOC
cd -

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
   --env=NEO4J_dbms_security_procedures_unrestricted=apoc.\\\* \
   --env=NEO4J_dbms_directories_import=import \
   --env NEO4J_AUTH=$NJ_AUTH \
   --volume $NJ_IMPORT:/var/lib/neo4j/import \
   --volume $NJ_DATA/data:/data \
    --volume $NJ_PLUGINS:/plugins \
    neo4j:$NJ_VERSION
    
```

<!------------------------->
Connect to Neo4j
----------------

After installing [neo4j](https://neo4j.com/), `startGraph` is used to
initialize the connection from R. If authentication has been disabled in
neo4j by setting NEO4J.AUTH=none, neither username nor password are
required. If you’re connecting to a local instance of Neo4j and import
directory has been defined in the configuration, you can specify it in
order to allow import from data.frames.

``` r
library(neo2R)
graph <- startGraph(
  "localhost:7475",
  username="neo4j", password="1234",
  importPath="~/neo4j_home/neo4jImport"
)
```

<!------------------------->
Import from data.frame
----------------------

If you’re connected to a local instance of Neo4j and import directory
has been defined (see above), you can import data from data.frames. Use
the ‘row’ prefix to refer to the data.frame column.

``` r
#########################################
## Nodes
## Create an index to speed-up MERGE
try(cypher(graph, 'CREATE INDEX ON :TestNode(name)'))
## Define node properties in a data.frame
nn <- 100000
nodes <- data.frame(
   "name"=paste(
      sample(LETTERS, nn, replace=TRUE),
      sample.int(nn, nn, replace=FALSE)
   ),
   "value"=rnorm(nn, 10, 3),
   stringsAsFactors=FALSE
)
import_from_df(
  graph=graph,
  cql='MERGE (n:TestNode {name:row.name, value:toFloat(row.value)})',
  toImport=nodes
)

#########################################
## Edges
## Define node properties in a data.frame
ne <- 100000
edges <- data.frame(
  "from"=sample(nodes$name, ne, replace=TRUE),
  "to"=sample(nodes$name, ne, replace=TRUE),
  "property"=round(runif(ne)*10),
  stringsAsFactors=FALSE
)
import_from_df(
   graph=graph,
   cql=prepCql(
      'MATCH (f:TestNode {name:row.from})',
      'MATCH (t:TestNode {name:row.to})',
      'MERGE (f)-[r:TestEdge {property:toInteger(row.property)}]->(t)'
   ),
   toImport=edges
)
```

<!------------------------->
Query the Neo4j database
------------------------

You can query the Neo4j graph database using the `cypher()` function.
Depending on the query, the function can return data in a a data.frame
(by setting `result="row"`) or in a list with nodes, relationships and
paths returned by the query (by setting `result="graph"`)

``` r
## Get TestNode with value smaller than 4.
## According to the normal distribution we expect 2.5% of the total
## number of nodes ==> ~2500 nodes
df <- cypher(
   graph,
   prepCql(
      'MATCH (n:TestNode) WHERE n.value <= 4',
      'RETURN n.name as name, n.value as value'
   )
)
print(dim(df))
```

    ## [1] 2195    2

``` r
print(head(df))
```

    ##      name    value
    ## 1 J 82813 2.758757
    ## 2 S 45631 2.515531
    ## 3 R 36882 3.392146
    ## 4  J 8940 3.450308
    ## 5 L 37977 1.419235
    ## 6 Y 97217 3.223701

``` r
## Get all paths of length 5 starting from a subset of nodes 
net <- cypher(
   graph,
   prepCql(
      'MATCH p=(f:TestNode)-[:TestEdge*5..5]->(t:TestNode) WHERE f.value < 3',
      'RETURN p'
   ),
   result="graph"
)
print(lapply(net, head, 3))
```

    ## $nodes
    ## $nodes$`98980`
    ## $nodes$`98980`$id
    ## [1] "98980"
    ## 
    ## $nodes$`98980`$labels
    ## $nodes$`98980`$labels[[1]]
    ## [1] "TestNode"
    ## 
    ## 
    ## $nodes$`98980`$properties
    ## $nodes$`98980`$properties$name
    ## [1] "M 64216"
    ## 
    ## $nodes$`98980`$properties$value
    ## [1] 13.25553
    ## 
    ## 
    ## 
    ## $nodes$`48070`
    ## $nodes$`48070`$id
    ## [1] "48070"
    ## 
    ## $nodes$`48070`$labels
    ## $nodes$`48070`$labels[[1]]
    ## [1] "TestNode"
    ## 
    ## 
    ## $nodes$`48070`$properties
    ## $nodes$`48070`$properties$name
    ## [1] "W 27492"
    ## 
    ## $nodes$`48070`$properties$value
    ## [1] 0.5488439
    ## 
    ## 
    ## 
    ## $nodes$`57495`
    ## $nodes$`57495`$id
    ## [1] "57495"
    ## 
    ## $nodes$`57495`$labels
    ## $nodes$`57495`$labels[[1]]
    ## [1] "TestNode"
    ## 
    ## 
    ## $nodes$`57495`$properties
    ## $nodes$`57495`$properties$name
    ## [1] "I 4741"
    ## 
    ## $nodes$`57495`$properties$value
    ## [1] 10.95175
    ## 
    ## 
    ## 
    ## 
    ## $relationships
    ## $relationships$`25316`
    ## $relationships$`25316`$id
    ## [1] "25316"
    ## 
    ## $relationships$`25316`$type
    ## [1] "TestEdge"
    ## 
    ## $relationships$`25316`$startNode
    ## [1] "16475"
    ## 
    ## $relationships$`25316`$endNode
    ## [1] "42200"
    ## 
    ## $relationships$`25316`$properties
    ## $relationships$`25316`$properties$property
    ## [1] 2
    ## 
    ## 
    ## 
    ## $relationships$`86517`
    ## $relationships$`86517`$id
    ## [1] "86517"
    ## 
    ## $relationships$`86517`$type
    ## [1] "TestEdge"
    ## 
    ## $relationships$`86517`$startNode
    ## [1] "42200"
    ## 
    ## $relationships$`86517`$endNode
    ## [1] "57495"
    ## 
    ## $relationships$`86517`$properties
    ## $relationships$`86517`$properties$property
    ## [1] 1
    ## 
    ## 
    ## 
    ## $relationships$`98582`
    ## $relationships$`98582`$id
    ## [1] "98582"
    ## 
    ## $relationships$`98582`$type
    ## [1] "TestEdge"
    ## 
    ## $relationships$`98582`$startNode
    ## [1] "48070"
    ## 
    ## $relationships$`98582`$endNode
    ## [1] "16475"
    ## 
    ## $relationships$`98582`$properties
    ## $relationships$`98582`$properties$property
    ## [1] 1
    ## 
    ## 
    ## 
    ## 
    ## $paths
    ## $paths[[1]]
    ## [1] "25316" "86517" "98582" "40087" "9243" 
    ## 
    ## $paths[[2]]
    ## [1] "41649" "60677" "58668" "96700" "98703"
    ## 
    ## $paths[[3]]
    ## [1] "59314" "76901" "19639" "59817" "62299"

``` r
print(table(unlist(lapply(net$paths, length))))
```

    ## 
    ##   5 
    ## 865
