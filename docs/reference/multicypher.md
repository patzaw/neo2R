# Run a multiple cypher queriers

Run a multiple cypher queriers

## Usage

``` r
multicypher(
  graph,
  queries,
  parameters = NULL,
  result = c("row", "graph", "source"),
  arraysAsStrings = TRUE,
  eltSep = " || "
)
```

## Arguments

- graph:

  the neo4j connection

- queries:

  queries to submit. It can be either a character vector for which each
  element corresponds to a cypher query. Or it can be a list of lists
  with the following slots:

  - **query** (mandatory): A single character corresponding to the
    cypher query.

  - **parameters** (optional): A set of parameters specific for this
    query. If not provided, the *parameters* parameter of the function
    is used (see below).

  - **result** (optional): The specific way to return the results of
    this query. If not provided, the *result* parameter of the function
    is used (see below).

- parameters:

  default parameters for the cypher queries.

- result:

  default way to return results. "row" will return a data frame and
  "graph" will return a list of nodes, a list of relationships and a
  list of paths (vectors of relationships identifiers). 'source' will
  return the results as returned by neo4j (Caution: The format is
  inconsistent between the two versions of the API).

- arraysAsStrings:

  if result="row" and arraysAsStrings is TRUE (default) array from neo4j
  are converted to strings and array elements are separated by eltSep.

- eltSep:

  if result="row" and arraysAsStrings is TRUE (default) array from neo4j
  are converted to strings and array elementes are separated by eltSep.

## Value

A list of "result" of the queries (invisible). See the "result" param.

## See also

[`cypher()`](https://patzaw.github.io/neo2R/reference/cypher.md),
[`startGraph()`](https://patzaw.github.io/neo2R/reference/startGraph.md),
[`prepCql()`](https://patzaw.github.io/neo2R/reference/prepCql.md),
[`readCql()`](https://patzaw.github.io/neo2R/reference/readCql.md) and
[`graphRequest()`](https://patzaw.github.io/neo2R/reference/graphRequest.md)

## Examples

``` r
if (FALSE) { # \dontrun{
result <- multicypher(
   graph,
   queries=list(
      q1="match (n) return n.value limit 5",
      q2=list(
         query="match (f {value:$val})-[r]->(t) return f, r, t limit 5",
         result="graph",
         parameters=list(val=100)
      )
   )
)
} # }
```
