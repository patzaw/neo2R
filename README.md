# neo2R

This R package provides simple connectors for querying neo4j graph databases.
It provides simple low level functions.
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
