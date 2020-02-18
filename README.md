-   [neo2R](#neo2r)
-   [Installation](#installation)
    -   [From CRAN](#from-cran)
    -   [Dependencies](#dependencies)
    -   [Installation from github](#installation-from-github)
-   [Use](#use)
    -   [Running Neo4j](#running-neo4j)
    -   [Connect to Neo4j](#connect-to-neo4j)
    -   [Import from data.frame](#import-from-data.frame)
    -   [Query the Neo4j database](#query-the-neo4j-database)

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

From CRAN
---------

``` r
install.packages("neo2R")
```

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
set.seed(1)
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

    ## [1] 2253    2

``` r
print(head(df))
```

    ##      name    value
    ## 1   V 693 3.791603
    ## 2  N 2585 1.965486
    ## 3 L 72527 3.345461
    ## 4 Y 54240 2.372623
    ## 5  N 1436 1.500713
    ## 6 T 21434 3.592195

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
    ## $nodes$`2815978`
    ## $nodes$`2815978`$id
    ## [1] "2815978"
    ## 
    ## $nodes$`2815978`$labels
    ## $nodes$`2815978`$labels[[1]]
    ## [1] "TestNode"
    ## 
    ## 
    ## $nodes$`2815978`$properties
    ## $nodes$`2815978`$properties$name
    ## [1] "N 78274"
    ## 
    ## $nodes$`2815978`$properties$value
    ## [1] 8.064299
    ## 
    ## 
    ## 
    ## $nodes$`2826833`
    ## $nodes$`2826833`$id
    ## [1] "2826833"
    ## 
    ## $nodes$`2826833`$labels
    ## $nodes$`2826833`$labels[[1]]
    ## [1] "TestNode"
    ## 
    ## 
    ## $nodes$`2826833`$properties
    ## $nodes$`2826833`$properties$name
    ## [1] "E 18105"
    ## 
    ## $nodes$`2826833`$properties$value
    ## [1] 6.936337
    ## 
    ## 
    ## 
    ## $nodes$`2855952`
    ## $nodes$`2855952`$id
    ## [1] "2855952"
    ## 
    ## $nodes$`2855952`$labels
    ## $nodes$`2855952`$labels[[1]]
    ## [1] "TestNode"
    ## 
    ## 
    ## $nodes$`2855952`$properties
    ## $nodes$`2855952`$properties$name
    ## [1] "K 44901"
    ## 
    ## $nodes$`2855952`$properties$value
    ## [1] 11.67618
    ## 
    ## 
    ## 
    ## 
    ## $relationships
    ## $relationships$`664638`
    ## $relationships$`664638`$id
    ## [1] "664638"
    ## 
    ## $relationships$`664638`$type
    ## [1] "TestEdge"
    ## 
    ## $relationships$`664638`$startNode
    ## [1] "2871190"
    ## 
    ## $relationships$`664638`$endNode
    ## [1] "2826833"
    ## 
    ## $relationships$`664638`$properties
    ## $relationships$`664638`$properties$property
    ## [1] 1
    ## 
    ## 
    ## 
    ## $relationships$`597613`
    ## $relationships$`597613`$id
    ## [1] "597613"
    ## 
    ## $relationships$`597613`$type
    ## [1] "TestEdge"
    ## 
    ## $relationships$`597613`$startNode
    ## [1] "2815978"
    ## 
    ## $relationships$`597613`$endNode
    ## [1] "2796948"
    ## 
    ## $relationships$`597613`$properties
    ## $relationships$`597613`$properties$property
    ## [1] 4
    ## 
    ## 
    ## 
    ## $relationships$`637295`
    ## $relationships$`637295`$id
    ## [1] "637295"
    ## 
    ## $relationships$`637295`$type
    ## [1] "TestEdge"
    ## 
    ## $relationships$`637295`$startNode
    ## [1] "2826833"
    ## 
    ## $relationships$`637295`$endNode
    ## [1] "2855952"
    ## 
    ## $relationships$`637295`$properties
    ## $relationships$`637295`$properties$property
    ## [1] 5
    ## 
    ## 
    ## 
    ## 
    ## $paths
    ## $paths[[1]]
    ## [1] "664638" "597613" "637295" "624611" "641222"
    ## 
    ## $paths[[2]]
    ## [1] "611081" "596184" "684767" "666604" "645798"
    ## 
    ## $paths[[3]]
    ## [1] "600235" "685356" "654094" "651827" "630484"

``` r
print(table(unlist(lapply(net$paths, length))))
```

    ## 
    ##   5 
    ## 945
