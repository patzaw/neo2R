# Version 2.3.0

- Use the 'httr' package instead of the 'RCurl' package.

# Version 2.2.0

- Support Neo4j version 5

# Version 2.1.1

- `graphRequest()` supports the .opts parameter of `RCurl::curlPerform()`.

# Version 2.1.0

- Implementation of the `multicypher()` function which can be used to send
multiple queries together to the neo4j database

# Version 2.0.2

- Better handling of NA values when importing data.frames
- Supporting tibbles when importing

# Version 2.0.0 (On CRAN)

- Support Neo4j 4
- Import data from data.frames to localhost Neo4j instance only
