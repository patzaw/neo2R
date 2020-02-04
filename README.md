# neo2R

The aim of the neo2R is to provide simple and low level connectors
for querying [neo4j graph databases](https://neo4j.com/).
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

```
devtools::install_github("patzaw/neo2R")
```

# Use

This package provides 4 functions:

  - `startGraph` to connect to a neo4j graph database
  - `graphRequest` to run a curl request on a neo4j graph
  - `cypher` to run a cypher query
  - `prepCql`to prepare a CQL query from a character vector
  
After installing neo4j (), `startGraph` is used to initialize the connection
from R.
If authentication has been disabled in neo4j by setting NEO4J.AUTH=none,
neither username nor password are required.

```
graph <- startGraph("localhost:7474")
```

