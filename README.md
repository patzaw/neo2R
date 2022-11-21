README
================

- <a href="#neo2r" id="toc-neo2r">neo2R</a>
- <a href="#installation" id="toc-installation">Installation</a>
  - <a href="#from-cran" id="toc-from-cran">From CRAN</a>
  - <a href="#dependencies" id="toc-dependencies">Dependencies</a>
  - <a href="#installation-from-github"
    id="toc-installation-from-github">Installation from github</a>
- <a href="#use" id="toc-use">Use</a>
  - <a href="#running-neo4j" id="toc-running-neo4j">Running Neo4j</a>
  - <a href="#connect-to-neo4j" id="toc-connect-to-neo4j">Connect to
    Neo4j</a>
  - <a href="#import-from-dataframe" id="toc-import-from-dataframe">Import
    from data.frame</a>
  - <a href="#query-the-neo4j-database"
    id="toc-query-the-neo4j-database">Query the Neo4j database</a>

<!----------------------------------------------------------------------------->
<!----------------------------------------------------------------------------->

# neo2R

[![CRAN_Status_Badge](http://www.r-pkg.org/badges/version/neo2R)](https://cran.r-project.org/package=neo2R)
[![](http://cranlogs.r-pkg.org/badges/neo2R)](https://cran.r-project.org/package=neo2R)

The aim of the neo2R is to provide simple and low level connectors for
querying [Neo4j graph databases](https://neo4j.com/). The objects
returned by the query functions are either lists or data.frames with
very few post-processing. It allows fast processing of queries returning
many records. And it let the user handle post-processing according to
the data model and his needs. It has been developed to support the BED
package (<https://github.com/patzaw/BED>,
<https://f1000research.com/articles/7-195/v3> ). Other packages such as
RNeo4j (<https://github.com/nicolewhite/RNeo4j>) or neo4R
(<https://github.com/neo4j-rstats/neo4r>) provide connectors to neo4j
databases with additional features.

<!----------------------------------------------------------------------------->
<!----------------------------------------------------------------------------->

# Installation

## From CRAN

``` r
install.packages("neo2R")
```

<!------------------------->

## Dependencies

The following R packages available on CRAN are required:

- [base64enc](https://CRAN.R-project.org/package=base64enc): Tools for
  base64 encoding
- [jsonlite](https://CRAN.R-project.org/package=jsonlite): A Simple and
  Robust JSON Parser and Generator for R
- [httr](https://CRAN.R-project.org/package=httr): Tools for Working
  with URLs and HTTP
- [utils](https://CRAN.R-project.org/package=utils): The R Utils Package

<!------------------------->

## Installation from github

``` r
devtools::install_github("patzaw/neo2R")
```

<!----------------------------------------------------------------------------->
<!----------------------------------------------------------------------------->

# Use

<!------------------------->

## Running Neo4j

You can download and install Neo4j according to the
[documentation](https://neo4j.com/docs/getting-started/current/get-started-with-neo4j/#_installing_neo4j).
You can also run it in a [docker
container](https://neo4j.com/docs/operations-manual/current/docker/). It
takes a few seconds to start.

The following chunks show how to instantaite a docker container running
either version 3 or version 4 (only those 2 are supported by neo2R) of
Neo4j. The main differences between the 2 calls are related to the apoc
library and SSL configuration.

### Neo4j 3.x

``` sh
#!/bin/sh

#################################
## CONFIG according to your needs
#################################

export CONTAINER=neo4j_cont

export NJ_VERSION=3.5.30

## Ports
export NJ_HTTP_PORT=7474
export NJ_HTTPS_PORT=7473
export NJ_BOLT_PORT=7687

## Change the location of the Neo4j directory
export NJ_HOME=~/neo4j_home

## Authorization
NJ_AUTH=neo4j/1234 # set to 'none' if you want to disable authorization

## APOC download
export NJ_APOC=https://github.com/neo4j-contrib/neo4j-apoc-procedures/releases/download/3.5.0.15/apoc-3.5.0.15-all.jar

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

## SSL
export NJ_SSL=${NJ_HOME}/ssl
mkdir -p ${NJ_SSL}/client_policy
mkdir -p ${NJ_SSL}/client_policy/revoked
mkdir -p ${NJ_SSL}/client_policy/trusted
openssl req -subj "/CN=localhost" -new -newkey rsa:2048 -days 365 -nodes -x509 -keyout ${NJ_SSL}/client_policy/private.key -out ${NJ_SSL}/client_policy/public.crt
chmod -R a+rwx ${NJ_SSL}

## Neo4j plugins: APOC
export NJ_PLUGINS=$NJ_HOME/neo4jPlugins
mkdir -p $NJ_PLUGINS
cd $NJ_PLUGINS
wget --no-check-certificate $NJ_APOC
cd -

docker run -d \
   --name $CONTAINER \
   --publish=$NJ_HTTP_PORT:7474 \
    --publish=$NJ_HTTPS_PORT:7473 \
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
    --volume=$NJ_SSL:/ssl \
    --env=NEO4J_https_ssl__policy=client_policy \
    --env=NEO4J_dbms_ssl_policy_client__policy_base__directory=/ssl/client_policy \
    --env=NEO4J_dbms_ssl_policy_client__policy_client__auth=NONE \
    --env=NEO4J_dbms_ssl_policy_client__policy_trust__all=true \
    neo4j:$NJ_VERSION

sleep 15
sudo chmod a+rwx $NJ_IMPORT
    
```

### Neo4j 4.x

``` sh
#!/bin/sh

#################################
## CONFIG according to your needs
#################################

export CONTAINER=neo4j_cont

export NJ_VERSION=4.4.5

## Ports
export NJ_HTTP_PORT=7474
export NJ_HTTPS_PORT=7473
export NJ_BOLT_PORT=7687

## Change the location of the Neo4j directory
export NJ_HOME=~/neo4j_home

## Authorization
NJ_AUTH=neo4j/1234 # set to 'none' if you want to disable authorization

## APOC download
export NJ_APOC=https://github.com/neo4j-contrib/neo4j-apoc-procedures/releases/download/4.4.0.3/apoc-4.4.0.3-all.jar

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

## SSL
export NJ_SSL=${NJ_HOME}/ssl
mkdir -p ${NJ_SSL}/https
mkdir -p ${NJ_SSL}/https/revoked
mkdir -p ${NJ_SSL}/https/trusted
openssl req -subj "/CN=localhost" -new -newkey rsa:2048 -days 365 -nodes -x509 -keyout ${NJ_SSL}/https/private.key -out ${NJ_SSL}/https/public.crt
chmod -R a+rwx ${NJ_SSL}

## Neo4j plugins: APOC
export NJ_PLUGINS=$NJ_HOME/neo4jPlugins
mkdir -p $NJ_PLUGINS
cd $NJ_PLUGINS
wget --no-check-certificate $NJ_APOC
cd -

docker run -d \
   --name $CONTAINER \
   --publish=$NJ_HTTP_PORT:7474 \
    --publish=$NJ_HTTPS_PORT:7473 \
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
    --volume=$NJ_SSL:/ssl \
    --env=NEO4J_dbms_connector_https_enabled=true \
   --env=NEO4J_dbms_ssl_policy_https_enabled=true \
    --env=NEO4J_dbms_ssl_policy_https_base__directory=/ssl/https \
   --env=NEO4J_dbms_ssl_policy_https_private__key=private.key \
   --env=NEO4J_dbms_ssl_policy_https_public__certificate=public.crt \
    --env=NEO4J_dbms_ssl_policy_https_client__auth=NONE \
    --env=NEO4J_dbms_ssl_policy_https_trust__all=true \
    neo4j:$NJ_VERSION

sleep 15
sudo chmod a+rwx $NJ_IMPORT
    
```

### Neo4j 5.x

``` sh
#!/bin/sh

#################################
## CONFIG according to your needs
#################################

export CONTAINER=neo4j_cont

export NJ_VERSION=5.1.0

## Ports
export NJ_HTTP_PORT=7474
export NJ_HTTPS_PORT=7473
export NJ_BOLT_PORT=7687

## Change the location of the Neo4j directory
export NJ_HOME=~/neo4j_home

## Authorization
NJ_AUTH=neo4j/1234 # set to 'none' if you want to disable authorization

## APOC download
export NJ_APOC=https://github.com/neo4j/apoc/releases/download/5.1.0/apoc-5.1.0-core.jar

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

## SSL
export NJ_SSL=${NJ_HOME}/ssl
mkdir -p ${NJ_SSL}/https
mkdir -p ${NJ_SSL}/https/revoked
mkdir -p ${NJ_SSL}/https/trusted
openssl req -subj "/CN=localhost" -new -newkey rsa:2048 -days 365 -nodes -x509 -keyout ${NJ_SSL}/https/private.key -out ${NJ_SSL}/https/public.crt
cp ${NJ_SSL}/https/public.crt ${NJ_SSL}/https/trusted
chmod -R a+rwx ${NJ_SSL}

## Neo4j plugins: APOC
export NJ_PLUGINS=$NJ_HOME/neo4jPlugins
mkdir -p $NJ_PLUGINS
cd $NJ_PLUGINS
wget --no-check-certificate $NJ_APOC
cd -

docker run -d \
   --name $CONTAINER \
   --publish=$NJ_HTTP_PORT:7474 \
   --publish=$NJ_HTTPS_PORT:7473 \
   --publish=$NJ_BOLT_PORT:7687 \
   --env=NEO4J_dbms_memory_heap_initial__size=2G \
   --env=NEO4J_dbms_memory_heap_max__size=2G \
   --env=NEO4J_dbms_memory_pagecache_size=1G \
   --env=NEO4J_dbms_query__cache__size=0 \
   --env=NEO4J_cypher_min__replan__interval=100000000ms \
   --env=NEO4J_cypher_statistics__divergence__threshold=1 \
   --env=NEO4J_dbms_security_procedures_unrestricted=apoc.\\\* \
   --env=NEO4J_dbms_directories_import=import \
   --env=NEO4J_AUTH=$NJ_AUTH \
   --volume=$NJ_IMPORT:/var/lib/neo4j/import \
   --volume=$NJ_DATA/data:/data \
   --volume=$NJ_PLUGINS:/plugins \
   --volume=$NJ_SSL:/ssl \
   --env=NEO4J_server_https_enabled=true \
   --env=NEO4J_dbms_ssl_policy_https_enabled=true \
   --env=NEO4J_dbms_ssl_policy_https_base__directory=/ssl/https \
   --env=NEO4J_dbms_ssl_policy_https_private__key=private.key \
   --env=NEO4J_dbms_ssl_policy_https_public__certificate=public.crt \
   --env=NEO4J_dbms_ssl_policy_https_client__auth=NONE \
   --env=NEO4J_dbms_ssl_policy_https_trust__all=true \
   neo4j:$NJ_VERSION

sleep 15
sudo chmod a+rwx $NJ_IMPORT
    
```

<!------------------------->

## Connect to Neo4j

After installing [neo4j](https://neo4j.com/), `startGraph` is used to
initialize the connection from R. If authentication has been disabled in
neo4j by setting NEO4J.AUTH=none, neither username nor password are
required. If you’re connecting to a local instance of Neo4j and import
directory has been defined in the configuration, you can specify it in
order to allow import from data.frames.

``` r
library(neo2R)
graph <- startGraph(
  "https://localhost:7473",
  username="neo4j", password="1234",
  importPath="~/neo4j_home/neo4jImport",
  .opts = list(ssl_verifypeer=0)
)
```

<!------------------------->

## Import from data.frame

If you’re connected to a local instance of Neo4j and import directory
has been defined (see above), you can import data from data.frames. Use
the ‘row’ prefix to refer to the data.frame column.

``` r
#########################################
## Nodes
## Create an index to speed-up MERGE
if(graph$version[[1]]=="5"){
   try(cypher(graph, 'CREATE INDEX FOR (n:TestNode) ON (n.name)'), silent=TRUE)
}else{
   try(cypher(graph, 'CREATE INDEX ON :TestNode(name)'), silent=TRUE)
}
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

## Query the Neo4j database

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
    ## 1  N 2585 1.965486
    ## 2 L 72527 3.345461
    ## 3 Y 54240 2.372623
    ## 4  N 1436 1.500713
    ## 5 T 21434 3.592195
    ## 6 M 91787 2.504475

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
    ## $nodes$`97347`
    ## $nodes$`97347`$id
    ## [1] "97347"
    ## 
    ## $nodes$`97347`$elementId
    ## [1] "4:8010ab4c-4837-401f-ba10-0f1353e7192c:97347"
    ## 
    ## $nodes$`97347`$labels
    ## $nodes$`97347`$labels[[1]]
    ## [1] "TestNode"
    ## 
    ## 
    ## $nodes$`97347`$properties
    ## $nodes$`97347`$properties$name
    ## [1] "V 30913"
    ## 
    ## $nodes$`97347`$properties$value
    ## [1] 10.389
    ## 
    ## 
    ## 
    ## $nodes$`7`
    ## $nodes$`7`$id
    ## [1] "7"
    ## 
    ## $nodes$`7`$elementId
    ## [1] "4:8010ab4c-4837-401f-ba10-0f1353e7192c:7"
    ## 
    ## $nodes$`7`$labels
    ## $nodes$`7`$labels[[1]]
    ## [1] "TestNode"
    ## 
    ## 
    ## $nodes$`7`$properties
    ## $nodes$`7`$properties$name
    ## [1] "N 2585"
    ## 
    ## $nodes$`7`$properties$value
    ## [1] 1.965486
    ## 
    ## 
    ## 
    ## $nodes$`39159`
    ## $nodes$`39159`$id
    ## [1] "39159"
    ## 
    ## $nodes$`39159`$elementId
    ## [1] "4:8010ab4c-4837-401f-ba10-0f1353e7192c:39159"
    ## 
    ## $nodes$`39159`$labels
    ## $nodes$`39159`$labels[[1]]
    ## [1] "TestNode"
    ## 
    ## 
    ## $nodes$`39159`$properties
    ## $nodes$`39159`$properties$name
    ## [1] "L 31296"
    ## 
    ## $nodes$`39159`$properties$value
    ## [1] 14.95749
    ## 
    ## 
    ## 
    ## 
    ## $relationships
    ## $relationships$`23876`
    ## $relationships$`23876`$id
    ## [1] "23876"
    ## 
    ## $relationships$`23876`$elementId
    ## [1] "5:8010ab4c-4837-401f-ba10-0f1353e7192c:23876"
    ## 
    ## $relationships$`23876`$type
    ## [1] "TestEdge"
    ## 
    ## $relationships$`23876`$startNode
    ## [1] "39159"
    ## 
    ## $relationships$`23876`$startNodeElementId
    ## [1] "4:8010ab4c-4837-401f-ba10-0f1353e7192c:39159"
    ## 
    ## $relationships$`23876`$endNode
    ## [1] "45711"
    ## 
    ## $relationships$`23876`$endNodeElementId
    ## [1] "4:8010ab4c-4837-401f-ba10-0f1353e7192c:45711"
    ## 
    ## $relationships$`23876`$properties
    ## $relationships$`23876`$properties$property
    ## [1] 3
    ## 
    ## 
    ## 
    ## $relationships$`93543`
    ## $relationships$`93543`$id
    ## [1] "93543"
    ## 
    ## $relationships$`93543`$elementId
    ## [1] "5:8010ab4c-4837-401f-ba10-0f1353e7192c:93543"
    ## 
    ## $relationships$`93543`$type
    ## [1] "TestEdge"
    ## 
    ## $relationships$`93543`$startNode
    ## [1] "7"
    ## 
    ## $relationships$`93543`$startNodeElementId
    ## [1] "4:8010ab4c-4837-401f-ba10-0f1353e7192c:7"
    ## 
    ## $relationships$`93543`$endNode
    ## [1] "97347"
    ## 
    ## $relationships$`93543`$endNodeElementId
    ## [1] "4:8010ab4c-4837-401f-ba10-0f1353e7192c:97347"
    ## 
    ## $relationships$`93543`$properties
    ## $relationships$`93543`$properties$property
    ## [1] 8
    ## 
    ## 
    ## 
    ## $relationships$`24488`
    ## $relationships$`24488`$id
    ## [1] "24488"
    ## 
    ## $relationships$`24488`$elementId
    ## [1] "5:8010ab4c-4837-401f-ba10-0f1353e7192c:24488"
    ## 
    ## $relationships$`24488`$type
    ## [1] "TestEdge"
    ## 
    ## $relationships$`24488`$startNode
    ## [1] "93854"
    ## 
    ## $relationships$`24488`$startNodeElementId
    ## [1] "4:8010ab4c-4837-401f-ba10-0f1353e7192c:93854"
    ## 
    ## $relationships$`24488`$endNode
    ## [1] "39159"
    ## 
    ## $relationships$`24488`$endNodeElementId
    ## [1] "4:8010ab4c-4837-401f-ba10-0f1353e7192c:39159"
    ## 
    ## $relationships$`24488`$properties
    ## $relationships$`24488`$properties$property
    ## [1] 8
    ## 
    ## 
    ## 
    ## 
    ## $paths
    ## $paths[[1]]
    ## [1] "23876" "93543" "24488" "46044" "6560" 
    ## 
    ## $paths[[2]]
    ## [1] "7553"  "94678" "470"   "93543" "31423"
    ## 
    ## $paths[[3]]
    ## [1] "7553"  "470"   "93543" "31423" "98608"

``` r
print(table(unlist(lapply(net$paths, length))))
```

    ## 
    ##   5 
    ## 945
