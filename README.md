README
================

- [neo2R](#neo2r)
- [Installation](#installation)
  - [From CRAN](#from-cran)
  - [Dependencies](#dependencies)
  - [Installation from github](#installation-from-github)
- [Use](#use)
  - [Running Neo4j](#running-neo4j)
  - [Connect to Neo4j](#connect-to-neo4j)
  - [Import from data.frame](#import-from-dataframe)
  - [Query the Neo4j database](#query-the-neo4j-database)

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
NJ_AUTH=neo4j/donttrustusers # set to 'none' if you want to disable authorization

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
   --env=NEO4J_dbms_memory_heap_initial__size=2G \
   --env=NEO4J_dbms_memory_heap_max__size=2G \
   --env=NEO4J_dbms_memory_pagecache_size=1G \
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

export NJ_VERSION=4.4.26

## Ports
export NJ_HTTP_PORT=7474
export NJ_HTTPS_PORT=7473
export NJ_BOLT_PORT=7687

## Change the location of the Neo4j directory
export NJ_HOME=~/neo4j_home

## Authorization
NJ_AUTH=neo4j/donttrustusers # set to 'none' if you want to disable authorization

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
   --env=NEO4J_dbms_memory_heap_initial__size=2G \
   --env=NEO4J_dbms_memory_heap_max__size=2G \
   --env=NEO4J_dbms_memory_pagecache_size=1G \
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

### Neo4j 5.x (\>= 5.12)

In recent version of Neo4j, it is not possible to instantiate the docker
image with a specific user name and password. The password needs to be
changed after Neo4j starts. Nevertheless, it’s still possible to
instanciate the image without any credentials with the following
`docker run` parameter: `--env NEO4J_AUTH=none`

``` sh
#!/bin/sh

#################################
## CONFIG according to your needs
#################################

export CONTAINER=neo4j_cont

export NJ_VERSION=5.12.0

## Ports
export NJ_HTTP_PORT=7474
export NJ_HTTPS_PORT=7473
export NJ_BOLT_PORT=7687

## Change the location of the Neo4j directory
export NJ_HOME=~/neo4j_home

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

## Add ` --env NEO4J_AUTH=none ` if you don't want to setup credentials
docker run -d \
   --name $CONTAINER \
   --publish=$NJ_HTTP_PORT:7474 \
   --publish=$NJ_HTTPS_PORT:7473 \
   --publish=$NJ_BOLT_PORT:7687 \
   --env=NEO4J_server_memory_heap_initial__size=2G \
   --env=NEO4J_server_memory_heap_max__size=2G \
   --env=NEO4J_server_memory_pagecache_size=1G \
   --env=NEO4J_server_db_query__cache__size=0 \
   --env=NEO4J_dbms_cypher_min__replan__interval=100000000ms \
   --env=NEO4J_dbms_cypher_statistics__divergence__threshold=1 \
   --env=NEO4J_dbms_security_procedures_unrestricted=apoc.\\\* \
   --env=NEO4J_server_directories_import=import\
   --volume=$NJ_IMPORT:/var/lib/neo4j/import \
   --volume=$NJ_DATA/data:/data \
   --volume=$NJ_LOGS:/var/lib/neo4j/logs \
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

If you did not disable credentials (with `--env NEO4J_AUTH=none`),
you’ll need to first change the user password before being able to
connect to the graph database. The following chunk shows how to do it
with neo2R.

``` r
library(neo2R)
system <- startGraph(
  "https://localhost:7473", database="system", check=FALSE,
  username="neo4j", password="neo4j",
  importPath="~/neo4j_home/neo4jImport",
  .opts = list(ssl_verifypeer=0)
)
cypher(
   system,
   "ALTER CURRENT USER SET PASSWORD FROM 'neo4j' TO 'donttrustusers'"
)
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
  username="neo4j", password="donttrustusers",
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
## Multiple queries can be sent at once
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
```

    ## [[1]]
    ## [1] 386   2
    ## 
    ## [[2]]
    ## [1] 954   2
    ## 
    ## [[3]]
    ## [1] 2253    2

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
    ## $nodes$`79444`
    ## $nodes$`79444`$id
    ## [1] "79444"
    ## 
    ## $nodes$`79444`$elementId
    ## [1] "4:a81e761d-c0d7-49c5-af6f-5cb5130fdbc1:79444"
    ## 
    ## $nodes$`79444`$labels
    ## $nodes$`79444`$labels[[1]]
    ## [1] "TestNode"
    ## 
    ## 
    ## $nodes$`79444`$properties
    ## $nodes$`79444`$properties$name
    ## [1] "S 99155"
    ## 
    ## $nodes$`79444`$properties$value
    ## [1] 9.658103
    ## 
    ## 
    ## 
    ## $nodes$`97347`
    ## $nodes$`97347`$id
    ## [1] "97347"
    ## 
    ## $nodes$`97347`$elementId
    ## [1] "4:a81e761d-c0d7-49c5-af6f-5cb5130fdbc1:97347"
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
    ## [1] "4:a81e761d-c0d7-49c5-af6f-5cb5130fdbc1:7"
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
    ## 
    ## $relationships
    ## $relationships$`7553`
    ## $relationships$`7553`$id
    ## [1] "7553"
    ## 
    ## $relationships$`7553`$elementId
    ## [1] "5:a81e761d-c0d7-49c5-af6f-5cb5130fdbc1:7553"
    ## 
    ## $relationships$`7553`$type
    ## [1] "TestEdge"
    ## 
    ## $relationships$`7553`$startNode
    ## [1] "79444"
    ## 
    ## $relationships$`7553`$startNodeElementId
    ## [1] "4:a81e761d-c0d7-49c5-af6f-5cb5130fdbc1:79444"
    ## 
    ## $relationships$`7553`$endNode
    ## [1] "20186"
    ## 
    ## $relationships$`7553`$endNodeElementId
    ## [1] "4:a81e761d-c0d7-49c5-af6f-5cb5130fdbc1:20186"
    ## 
    ## $relationships$`7553`$properties
    ## $relationships$`7553`$properties$property
    ## [1] 8
    ## 
    ## 
    ## 
    ## $relationships$`94678`
    ## $relationships$`94678`$id
    ## [1] "94678"
    ## 
    ## $relationships$`94678`$elementId
    ## [1] "5:a81e761d-c0d7-49c5-af6f-5cb5130fdbc1:94678"
    ## 
    ## $relationships$`94678`$type
    ## [1] "TestEdge"
    ## 
    ## $relationships$`94678`$startNode
    ## [1] "20186"
    ## 
    ## $relationships$`94678`$startNodeElementId
    ## [1] "4:a81e761d-c0d7-49c5-af6f-5cb5130fdbc1:20186"
    ## 
    ## $relationships$`94678`$endNode
    ## [1] "7311"
    ## 
    ## $relationships$`94678`$endNodeElementId
    ## [1] "4:a81e761d-c0d7-49c5-af6f-5cb5130fdbc1:7311"
    ## 
    ## $relationships$`94678`$properties
    ## $relationships$`94678`$properties$property
    ## [1] 3
    ## 
    ## 
    ## 
    ## $relationships$`470`
    ## $relationships$`470`$id
    ## [1] "470"
    ## 
    ## $relationships$`470`$elementId
    ## [1] "5:a81e761d-c0d7-49c5-af6f-5cb5130fdbc1:470"
    ## 
    ## $relationships$`470`$type
    ## [1] "TestEdge"
    ## 
    ## $relationships$`470`$startNode
    ## [1] "13440"
    ## 
    ## $relationships$`470`$startNodeElementId
    ## [1] "4:a81e761d-c0d7-49c5-af6f-5cb5130fdbc1:13440"
    ## 
    ## $relationships$`470`$endNode
    ## [1] "79444"
    ## 
    ## $relationships$`470`$endNodeElementId
    ## [1] "4:a81e761d-c0d7-49c5-af6f-5cb5130fdbc1:79444"
    ## 
    ## $relationships$`470`$properties
    ## $relationships$`470`$properties$property
    ## [1] 10
    ## 
    ## 
    ## 
    ## 
    ## $paths
    ## $paths[[1]]
    ## [1] "7553"  "94678" "470"   "93543" "31423"
    ## 
    ## $paths[[2]]
    ## [1] "7553"  "470"   "93543" "31423" "98608"
    ## 
    ## $paths[[3]]
    ## [1] "69425" "93543" "58428" "31423" "71263"

``` r
print(table(unlist(lapply(net$paths, length))))
```

    ## 
    ##   5 
    ## 945
