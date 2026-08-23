# Run a curl request on a neo4j graph

Run a curl request on a neo4j graph

## Usage

``` r
graphRequest(graph, endpoint, customrequest = c("POST", "GET"), postText)
```

## Arguments

- graph:

  the neo4j connection

- endpoint:

  the endpoint for the request. To list all the available endpoints:
  `graphRequest(graph, endpoint="", customrequest="GET", postText="")$result`

- customrequest:

  the type of request: "POST" (default) or "GET"

- postText:

  the request body

## Value

A list with the "header" and the "result" of the request (invisible)

## See also

[`startGraph()`](https://patzaw.github.io/neo2R/reference/startGraph.md)
and [`cypher()`](https://patzaw.github.io/neo2R/reference/cypher.md)
