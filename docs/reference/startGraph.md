# Prepare connection to neo4j database

Prepare connection to neo4j database

## Usage

``` r
startGraph(
  url,
  database = NA,
  username = NA,
  password = NA,
  importPath = NA,
  .opts = list(),
  check = TRUE,
  api = c("auto", "tx", "v2"),
  cypher_version = c("auto", "")
)
```

## Arguments

- url:

  the DB url

- database:

  the name of the database. If NA (default) it will use "data" with
  versions 3.. of Neo4j and "neo4j" with versions 4..

- username:

  the neo4j user name (default: NA; works only if authentication has
  been disabled in neo4j by setting NEO4J.AUTH=none)

- password:

  the neo4j user password (default: NA; works only if authentication has
  been disabled in neo4j by setting NEO4J.AUTH=none)

- importPath:

  path to the import directory (default: NA =\> no import directory).
  Import only works with local neo4j instance.

- .opts:

  a named list identifying the curl options for the handle (see
  [`httr2::req_options()`](https://httr2.r-lib.org/reference/req_options.html)
  and curl option names for a complete list of available options; for
  example: `.opts = list(ssl_verifypeer = 0)`). Moreover, this parameter
  can be used to pass additional headers to the graph requests as
  "extendedHeaders": it is useful, for example, for OAuth access
  delegation (see details).

- check:

  check the connection before returning it (default: TRUE). Set to false
  when connection to the "system" database

- api:

  the HTTP API to use: `"tx"` for the legacy Transactional Cypher HTTP
  API (default for self-managed instances), `"v2"` for the Neo4j Query
  API v2 (required for Aura, available on self-managed Neo4j \>= 5.19),
  or `"auto"` (default) to detect automatically — Aura URLs
  (\*.databases.neo4j.io) select `"v2"`, all others select `"tx"`.

- cypher_version:

  The version of the cypher language used by the database. Should be
  `""` for neo4j version \<= 5.

## Value

A connection to the graph DB: a list with the url and necessary headers

## Details

The "ssl.verifypeer" logical option available in the RCurl package used
in former versions of neo2R (\<= 2.2.0) is not recognized by
[`httr2::req_options()`](https://httr2.r-lib.org/reference/req_options.html).
However, for backward compatibility, if it is used, it is translated
into the "ssl_verifypeer" integer curl option with a warning message.

Headers in `.opts$extendedHeaders` are added to, or overwrite, the
default Neo4j headers. If there is a
`.opts$extendedHeaders[["Authorization"]]` value, the default Neo4j
"Authorization" header (user credentials) is provided automaticaly as
"X-Authorization". This mechanism is used for OAuth access delegation.
