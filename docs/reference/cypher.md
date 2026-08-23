# Run a cypher query

Run a cypher query

## Usage

``` r
cypher(
  graph,
  query,
  parameters = NULL,
  result = c("row", "graph", "source"),
  arraysAsStrings = TRUE,
  eltSep = " || "
)
```

## Arguments

- graph:

  the neo4j connection

- query:

  the cypher query

- parameters:

  parameters for the cypher query.

- result:

  the way to return results. "row" will return a data frame and "graph"
  will return a list of nodes, a list of relationships and a list of
  paths (vectors of relationships identifiers). 'source' will return the
  results as returned by neo4j (Caution: The format is inconsistent
  between the two versions of the API).

- arraysAsStrings:

  if result="row" and arraysAsStrings is TRUE (default) array from neo4j
  are converted to strings and array elements are separated by eltSep.

- eltSep:

  if result="row" and arraysAsStrings is TRUE (default) array from neo4j
  are converted to strings and array elementes are separated by eltSep.

## Value

The "result" of the query (invisible). See the "result" param.

## See also

[`multicypher()`](https://patzaw.github.io/neo2R/reference/multicypher.md),
[`startGraph()`](https://patzaw.github.io/neo2R/reference/startGraph.md),
[`prepCql()`](https://patzaw.github.io/neo2R/reference/prepCql.md),
[`readCql()`](https://patzaw.github.io/neo2R/reference/readCql.md) and
[`graphRequest()`](https://patzaw.github.io/neo2R/reference/graphRequest.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# 2 identical queries
result <- cypher(
   graph=graph,
   query='match (n {value:$value}) return n',
   parameters=list(value="100"),
   result="graph"
)
result <- cypher(
   graph=graph,
   query='match (n {value:"100"}) return n',
   result="graph"
)
} # }
```
