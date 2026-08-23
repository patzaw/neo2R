# Changelog

## Version 3.1.2

- Vignettes and package website with {pkgdown}

## Version 3.1.1

CRAN release: 2026-08-05

- Fix Import with neo4j \>= 2025

## Version 3.1.0

- Improvement of neo4j result processing

  - API v2: paths handled correctly
  - new possible value for the `result` parameter: `"source"`. With this
    value the `cypher` and `multicypher` functions return the result as
    returned by neo4j API. Caution: The format is inconsistent between
    the two versions of the API.

## Version 3.0.0

CRAN release: 2026-05-18

- Use the ‘httr2’ package instead of the ‘httr’ package.

- Add support for the Neo4j Query API v2 (`/db/{database}/query/v2`),
  required for Neo4j Aura and available on self-managed Neo4j \>= 5.19.
  [`startGraph()`](https://patzaw.github.io/neo2R/reference/startGraph.md)
  gains an `api` parameter (`"auto"`, `"tx"`, `"v2"`); Aura URLs
  (`*.databases.neo4j.io`) are detected automatically and default to
  `"v2"`. Self-managed instances continue to use the legacy
  Transactional HTTP API (`"tx"`) unless `api = "v2"` is set explicitly.
  Note: with `api = "v2"`, graph nodes expose `elementId` (a string)
  instead of the integer `id` returned by the legacy API.

## Version 2.4.2

CRAN release: 2024-01-18

- Support periodic commit for Neo4j version 5 (thanks to
  [gregleleu](https://github.com/gregleleu))

- Support connection to the “system” database in Neo4j version 5 for
  admin tasks

## Version 2.4.1

CRAN release: 2023-02-16

- Bug fix in
  [`import_from_df()`](https://patzaw.github.io/neo2R/reference/import_from_df.md)
  when importing a data.frame with one column

## Version 2.4.0

- Add the possibility to add additional headers to the graph requests.
- New contributor: <https://github.com/eusebiu>

## Version 2.3.0

- Use the ‘httr’ package instead of the ‘RCurl’ package.

## Version 2.2.0

- Support Neo4j version 5

## Version 2.1.1

CRAN release: 2022-04-15

- [`graphRequest()`](https://patzaw.github.io/neo2R/reference/graphRequest.md)
  supports the .opts parameter of `RCurl::curlPerform()`.

## Version 2.1.0

CRAN release: 2020-03-28

- Implementation of the
  [`multicypher()`](https://patzaw.github.io/neo2R/reference/multicypher.md)
  function which can be used to send multiple queries together to the
  neo4j database

## Version 2.0.2

- Better handling of NA values when importing data.frames
- Supporting tibbles when importing

## Version 2.0.0 (On CRAN)

CRAN release: 2020-02-17

- Support Neo4j 4
- Import data from data.frames to localhost Neo4j instance only
