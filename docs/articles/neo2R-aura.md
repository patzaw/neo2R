# Getting Started with neo2R and Neo4j Aura

## Introduction

Graph databases excel at storing and traversing highly connected data
used for recommendation engines, fraud detection, knowledge graphs, and
social networks. **Neo4j** is one of the most widely used graph
databases, and with **Neo4j Aura**, its managed cloud service, you can
spin up a production-grade instance without any infrastructure overhead.

The [neo2R](https://cran.r-project.org/package=neo2R) package provides a
seamless interface for querying Neo4j from R. Version 3.0.0 introduced
two important improvements:

1.  **Unified connection model** — a single
    [`startGraph()`](https://patzaw.github.io/neo2R/reference/startGraph.md)
    call handles both self-hosted Neo4j instances
    (`http://localhost:7474`) and cloud Neo4j Aura instances
    (`https://<id>.databases.neo4j.io`)
2.  **httr2 backend** — migrated from the deprecated `httr` package to
    [`httr2`](https://httr2.r-lib.org/), providing reliable retries and
    clean error handling

This vignette demonstrates how to connect to Neo4j Aura, explore the
Movie Recommendations dataset, and visualize networks using neo2R.

## Prerequisites

The core functionality of neo2R requires only the package itself. Some
examples in this vignette use {dplyr} and {visNetwork} packages for data
manipulation and visualization:

``` r

# Optional packages used in examples
# install.packages(c("dplyr", "visNetwork"))
library(dplyr)
library(visNetwork)
```

## Connecting to Neo4j Aura

### Create and Connect to an Aura Instance

Neo4j provides a **free Aura Free** tier (up to 200k nodes / 400k
relationships).

Create a free instance at <https://console.neo4j.io> and get your
connection details.

Connect to your instance with
[`startGraph()`](https://patzaw.github.io/neo2R/reference/startGraph.md).
neo2R automatically detects Aura URLs (those ending with
`.databases.neo4j.io`) and selects the [Query API
v2](https://neo4j.com/docs/query-api/current/) — no extra configuration
is needed:

``` r

library(neo2R)

my_aura <- startGraph(
  url = "https://<INSTANCEID>.databases.neo4j.io",
  database = "INSTANCEID",
  username = "INSTANCEID",
  password = "INSTANCEPASSWORD"
  # api = "v2" is set automatically for *.databases.neo4j.io URLs
)
```

### The Movie Recommendations Dataset

Neo4j provides [example
datasets](https://neo4j.com/docs/getting-started/appendix/example-data/).
The Movie Recommendations dataset is a classic example available on a
demo server:

``` r

library(neo2R)

graph <- startGraph(
  url = "https://demo.neo4jlabs.com:7473",
  database = "recommendations",
  username = "recommendations",
  password = "recommendations"
)
```

## Exploring the Database Schema

The Movie database contains nodes representing movies, people (actors
and directors), genres, and users, connected by relationships that
capture who acted in which movies, who directed them, their genres, and
user ratings.

Let’s first connect to the demo database and examine its structure:

### Node and Relationship Types

The Movie Recommendations database includes the following node labels
and relationship types:

#### Node Labels

| Node label | Key properties          |
|------------|-------------------------|
| Movie      | title, released, imdbId |
| Genre      | name                    |
| Person     | name, born, imdbId      |
| User       | name                    |

#### Relationship Types

| Relationship type | Key properties    |
|-------------------|-------------------|
| IN_GENRE          |                   |
| ACTED_IN          | role              |
| DIRECTED          |                   |
| RATED             | rating, timestamp |

### Counting Database Elements

Let’s count the number of each node label and relationship type
(filtering out technical nodes):

``` r

# Node types and counts
node_counts <- cypher(
  graph,
  "
  MATCH (n)
  RETURN labels(n) AS label, count(n) AS n
  ORDER BY n DESC
  "
)

# Filter out technical nodes
node_counts_filtered <- node_counts[
  node_counts$label != "_Bloom_Perspective_" &
    node_counts$label != "_Bloom_Scene_" &
    node_counts$label != "",
]
print(node_counts_filtered)
#>                         label     n
#> 1             Actor || Person 14956
#> 2                       Movie  9125
#> 3          Director || Person  3604
#> 4                        User   671
#> 5 Actor || Director || Person   487
#> 6                       Genre    20

# Relationship types and counts
rel_counts <- cypher(
  graph,
  "
  MATCH ()-[r]->()
  RETURN type(r) AS type, count(r) AS n
  ORDER BY n DESC
  "
)

# Filter out technical relationships
rel_counts_filtered <- rel_counts[rel_counts$type != "_Bloom_HAS_SCENE_", ]
print(rel_counts_filtered)
#>       type      n
#> 1    RATED 100004
#> 2 ACTED_IN  35910
#> 3 IN_GENRE  20340
#> 4 DIRECTED  10007
```

## Querying with Cypher

### Top Prolific Actors

Find the actors who have appeared in the most movies:

``` r

top_actors <- cypher(
  graph,
  "
  MATCH (p:Person)-[:ACTED_IN]->(m:Movie)
  RETURN p.name AS actor, count(m) AS movies
  ORDER BY movies DESC
  LIMIT 10
  "
)
print(top_actors)
#>                actor movies
#> 1     Robert De Niro     56
#> 2       Bruce Willis     49
#> 3  Samuel L. Jackson     45
#> 4       Nicolas Cage     45
#> 5      Michael Caine     40
#> 6     Clint Eastwood     40
#> 7          Tom Hanks     38
#> 8        John Cusack     38
#> 9     Morgan Freeman     38
#> 10      Gene Hackman     38
```

### Movies and Their Directors

Retrieve movies with their release years and directors:

``` r

movies_directors <- cypher(
  graph,
  "
  MATCH (d:Person)-[:DIRECTED]->(m:Movie)
  RETURN m.title AS movie, m.released AS released, d.name AS director
  ORDER BY m.released IS NOT NULL DESC, m.released DESC
  LIMIT 10
  "
)
print(movies_directors)
#>            movie   released           director
#> 1         Solace 2016-09-02      Afonso Poyart
#> 2        Ben-hur 2016-08-12  Timur Bekmambetov
#> 3         Rustom 2016-08-12  Tinu Suresh Desai
#> 4   Mohenjo Daro 2016-08-12 Ashutosh Gowariker
#> 5  Suicide Squad 2016-08-05         David Ayer
#> 6  Shin Godzilla 2016-07-29       Hideaki Anno
#> 7  Shin Godzilla 2016-07-29     Shinji Higuchi
#> 8   Jason Bourne 2016-07-29    Paul Greengrass
#> 9    Star Trek 3 2016-07-22         Justin Lin
#> 10  Ghostbusters 2016-07-15          Paul Feig
```

### Parameterized Queries

neo2R supports **named parameters**, keeping queries safe from injection
and easy to reuse:

``` r

# Find all co-stars of a given actor
co_stars <- cypher(
  graph,
  "
  MATCH (a:Person {name: $actor})-[:ACTED_IN]->(m:Movie)<-[:ACTED_IN]-(co:Person)
  RETURN DISTINCT co.name AS co_star, m.title AS shared_movie
  ORDER BY co_star
  LIMIT 10
  ",
  parameters = list(actor = "Tom Hanks")
)
print(co_stars)
#>               co_star         shared_movie
#> 1         Adrian Zmed       Bachelor Party
#> 2   Alexander Godunov       Money Pit, The
#> 3           Amy Adams Charlie Wilson's War
#> 4  Annie Rose Buckley     Saving Mr. Banks
#> 5       Audrey Tautou   Da Vinci Code, The
#> 6        Ayelet Zurer      Angels & Demons
#> 7        Barkhad Abdi     Captain Phillips
#> 8  Barkhad Abdirahman     Captain Phillips
#> 9        Barry Pepper  Saving Private Ryan
#> 10        Bill Paxton            Apollo 13
```

## Graph Result Format

The [`cypher()`](https://patzaw.github.io/neo2R/reference/cypher.md)
function can return results in different formats. By default, it returns
a data frame with rows. For queries that return nodes, relationships,
and paths, use `result = "graph"`:

``` r

# Graph result: co-actors of Tom Hanks
co_actors <- cypher(
  graph,
  'MATCH p=(tom:Person {name:"Tom Hanks"})-[mt:ACTED_IN]->
          (m:Movie)<-[mca:ACTED_IN]-(coActor:Person)
    RETURN p',
  result = "graph"
)

# The result contains nodes, relationships and paths
lengths(co_actors)
#>         nodes relationships         paths 
#>           144           152           114

# Extract node names from the first few nodes
node_names <- co_actors$nodes |>
  head() |>
  lapply(function(n) {
    if (!is.null(n$properties$name)) {
      n$properties$name
    } else if (!is.null(n$properties$title)) {
      n$properties$title
    } else {
      NA_character_
    }
  })
print(node_names)
#> $`4:6636a433-9f85-4f47-b4a7-e2cd79149f79:14838`
#> [1] "Tom Hanks"
#> 
#> $`4:6636a433-9f85-4f47-b4a7-e2cd79149f79:3233`
#> [1] "Punchline"
#> 
#> $`4:6636a433-9f85-4f47-b4a7-e2cd79149f79:13683`
#> [1] "Sally Field"
#> 
#> $`4:6636a433-9f85-4f47-b4a7-e2cd79149f79:13148`
#> [1] "Mark Rydell"
#> 
#> $`4:6636a433-9f85-4f47-b4a7-e2cd79149f79:15641`
#> [1] "John Goodman"
#> 
#> $`4:6636a433-9f85-4f47-b4a7-e2cd79149f79:4436`
#> [1] "Catch Me If You Can"
```

## Network Visualization with visNetwork

The real power of a graph database becomes apparent when you visualize
the graph. This section shows how to pull Tom Hanks’s ego network and
render it with **visNetwork**. This example uses the `dplyr` and
`visNetwork` packages.

### Step 1: Fetch Nodes and Edges

``` r

hub <- "Tom Hanks"
nodes_raw <- cypher(
  graph,
  "
  MATCH (hub:Person {name: $hub})-[hr:ACTED_IN]->(m:Movie)
  <-[cr:ACTED_IN]-(co:Person)
  RETURN hub.name AS hub, hr.role AS hub_role,
  m.title AS movie, m.released AS year,
  co.name AS co, cr.role AS co_role
  ",
  parameters = list(hub = hub)
) |> 
  as_tibble()

print(nodes_raw)
#> # A tibble: 114 × 6
#>    hub       hub_role      movie               year       co             co_role
#>    <chr>     <chr>         <chr>               <chr>      <chr>          <chr>  
#>  1 Tom Hanks Steven Gold   Punchline           1988-10-07 Sally Field    Lilah …
#>  2 Tom Hanks Steven Gold   Punchline           1988-10-07 Mark Rydell    Romeo  
#>  3 Tom Hanks Steven Gold   Punchline           1988-10-07 John Goodman   John K…
#>  4 Tom Hanks Carl Hanratty Catch Me If You Can 2002-12-25 Martin Sheen   Roger …
#>  5 Tom Hanks Carl Hanratty Catch Me If You Can 2002-12-25 Leonardo DiCa… Frank …
#>  6 Tom Hanks Carl Hanratty Catch Me If You Can 2002-12-25 Christopher W… Frank …
#>  7 Tom Hanks Pep Streebeck Dragnet             1987-06-26 Dan Aykroyd    Sgt. J…
#>  8 Tom Hanks Pep Streebeck Dragnet             1987-06-26 Harry Morgan   Captai…
#>  9 Tom Hanks Pep Streebeck Dragnet             1987-06-26 Christopher P… Revere…
#> 10 Tom Hanks Walt Disney   Saving Mr. Banks    2013-12-20 Colin Farrell  Traver…
#> # ℹ 104 more rows
```

### Step 2: Shape Data for visNetwork

visNetwork expects two data frames: `nodes` (with columns `id`, `label`,
`group`, etc.) and `edges` (with columns `from`, `to`, etc.).

``` r

nodes <- bind_rows(
  nodes_raw |>
    distinct(
      id = hub,
      group = "Hub"
    ),
  nodes_raw |>
    distinct(
      id = co,
      group = "Co-star"
    ),
  nodes_raw |>
    distinct(
      id = movie,
      group = "Movie",
      year
    )
) |>
  distinct() |>
  mutate(
    title = sprintf(
      '<b>%s</b>: %s%s',
      group,
      id,
      ifelse(!is.na(year), sprintf(" (%s)", year), "")
    ),
    shape = ifelse(group == "Movie", "dot", "star"),
    size = ifelse(group == "Hub", 30, 18)
  ) |>
  arrange(id)

edges <- bind_rows(
  nodes_raw |>
    distinct(
      from = hub,
      to = movie,
      role = hub_role
    ),
  nodes_raw |>
    distinct(
      from = co,
      to = movie,
      role = co_role
    )
) |>
  mutate(
    title = sprintf('<b>Role</b>: %s', role),
    arrows = "to"
  )

print(nodes)
#> # A tibble: 144 × 6
#>    id                 group   year       title                       shape  size
#>    <chr>              <chr>   <chr>      <chr>                       <chr> <dbl>
#>  1 'burbs, The        Movie   1989-02-17 <b>Movie</b>: 'burbs, The … dot      18
#>  2 Adrian Zmed        Co-star NA         <b>Co-star</b>: Adrian Zmed star     18
#>  3 Alexander Godunov  Co-star NA         <b>Co-star</b>: Alexander … star     18
#>  4 Amy Adams          Co-star NA         <b>Co-star</b>: Amy Adams   star     18
#>  5 Angels & Demons    Movie   2009-05-15 <b>Movie</b>: Angels & Dem… dot      18
#>  6 Annie Rose Buckley Co-star NA         <b>Co-star</b>: Annie Rose… star     18
#>  7 Apollo 13          Movie   1995-06-30 <b>Movie</b>: Apollo 13 (1… dot      18
#>  8 Audrey Tautou      Co-star NA         <b>Co-star</b>: Audrey Tau… star     18
#>  9 Ayelet Zurer       Co-star NA         <b>Co-star</b>: Ayelet Zur… star     18
#> 10 Bachelor Party     Movie   1984-06-29 <b>Movie</b>: Bachelor Par… dot      18
#> # ℹ 134 more rows
print(edges)
#> # A tibble: 152 × 5
#>    from      to                         role                        title arrows
#>    <chr>     <chr>                      <chr>                       <chr> <chr> 
#>  1 Tom Hanks Punchline                  "Steven Gold"               "<b>… to    
#>  2 Tom Hanks Catch Me If You Can        "Carl Hanratty"             "<b>… to    
#>  3 Tom Hanks Dragnet                    "Pep Streebeck"             "<b>… to    
#>  4 Tom Hanks Saving Mr. Banks           "Walt Disney"               "<b>… to    
#>  5 Tom Hanks Bachelor Party             "Rick Gassko"               "<b>… to    
#>  6 Tom Hanks Volunteers                 "Lawrence Whatley Bourne I… "<b>… to    
#>  7 Tom Hanks Man with One Red Shoe, The "Richard Harlan Drew"       "<b>… to    
#>  8 Tom Hanks Splash                     "Allen Bauer"               "<b>… to    
#>  9 Tom Hanks Big                        "Joshua \"Josh\" Baskin"    "<b>… to    
#> 10 Tom Hanks Nothing in Common          "David Basner"              "<b>… to    
#> # ℹ 142 more rows
```

### Step 3: Draw the Network

``` r

visNetwork(nodes, edges) |>
  visGroups(
    groupname = "Hub",
    color = list(
      background = "#3B82F6",
      border = "#1D4ED8",
      highlight = "#93C5FD"
    )
  ) |>
  visGroups(
    groupname = "Movie",
    color = list(
      background = "#F97316",
      border = "#C2410C",
      highlight = "#FED7AA"
    ),
    shape = "square"
  ) |>
  visGroups(
    groupname = "Co-star",
    color = list(
      background = "#6B7280",
      border = "#374151",
      highlight = "#D1D5DB"
    )
  ) |>
  visEdges(
    color = list(color = "#CBD5E1", highlight = "#3B82F6"),
    width = 1.5
  ) |>
  visOptions(
    highlightNearest = list(enabled = TRUE, degree = 1, hover = TRUE),
    nodesIdSelection = TRUE
  ) |>
  visLayout(randomSeed = 42) |>
  visPhysics(
    solver = "forceAtlas2Based",
    forceAtlas2Based = list(
      gravitationalConstant = -60,
      springLength = 120,
      springConstant = 0.04
    )
  ) |>
  visLegend(position = "right", main = "Node type")
```

Hover over any node to see its label. Use the **Select by id** dropdown
or click a node to highlight movies shared with Tom Hanks.

### Further Reading

- [Neo4j Aura console](https://console.neo4j.io) — create your free
  instance
- [Neo4j Cypher
  reference](https://neo4j.com/docs/cypher-manual/current/) — query
  language docs
- [visNetwork
  documentation](https://datastorm-open.github.io/visNetwork/) —
  interactive network visualization
