# Imports a data.frame in the neo4j graph database

This function only works with localhost Neo4j instances.

## Usage

``` r
import_from_df(graph, cql, toImport, periodicCommit = 1000, by = Inf, ...)
```

## Arguments

- graph:

  the neo4j connection

- cql:

  the CQL query to be applied on each row of toImport. Use the 'row'
  prefix to refer to the data.frame column.

- toImport:

  the data.frame to be imported as "row". Use "row.FIELD" in the cql
  query to refer to one FIELD of the toImport data.frame

- periodicCommit:

  use periodic commit when loading the data (default: 10000).

- by:

  number of rows to send by batch (default: Inf). Can be an alternative
  to periodic commit.

- ...:

  further parameters for
  [`cypher()`](https://patzaw.github.io/neo2R/reference/cypher.md)

## See also

[`cypher()`](https://patzaw.github.io/neo2R/reference/cypher.md)
