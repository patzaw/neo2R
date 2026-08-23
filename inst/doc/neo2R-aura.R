## ----include = FALSE---------------------------------------------------------------------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  fig.path = "man/figures/README-",
  echo = TRUE
)

## ----eval = FALSE------------------------------------------------------------------------------------------------------------------------
# # Optional packages used in examples
# # install.packages(c("dplyr", "visNetwork"))
# library(dplyr)
# library(visNetwork)

## ----include = FALSE---------------------------------------------------------------------------------------------------------------------
# Load required packages - suppress messages for cleaner output
suppressPackageStartupMessages({
  library(neo2R)
  library(dplyr)
  library(visNetwork)
})

## ----eval = FALSE------------------------------------------------------------------------------------------------------------------------
# library(neo2R)
# 
# my_aura <- startGraph(
#   url = "https://<INSTANCEID>.databases.neo4j.io",
#   database = "INSTANCEID",
#   username = "INSTANCEID",
#   password = "INSTANCEPASSWORD"
#   # api = "v2" is set automatically for *.databases.neo4j.io URLs
# )

## ----eval = FALSE------------------------------------------------------------------------------------------------------------------------
# library(neo2R)
# 
# graph <- startGraph(
#   url = "https://demo.neo4jlabs.com:7473",
#   database = "recommendations",
#   username = "recommendations",
#   password = "recommendations"
# )

## ----include = FALSE---------------------------------------------------------------------------------------------------------------------
library(neo2R)

graph <- tryCatch(
  {
    startGraph(
      url = "https://demo.neo4jlabs.com:7473",
      database = "recommendations",
      username = "recommendations",
      password = "recommendations"
    )
  },
  error = function(e) NULL
)

# Check if connection succeeded
if (is.null(graph)) {
  message(
    "Could not connect to demo database. Examples will show code but not execute."
  )
  should_run <- FALSE
} else {
  should_run <- TRUE
}

## ----eval = should_run-------------------------------------------------------------------------------------------------------------------
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

## ----eval = should_run-------------------------------------------------------------------------------------------------------------------
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

## ----eval = should_run-------------------------------------------------------------------------------------------------------------------
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

## ----eval = should_run-------------------------------------------------------------------------------------------------------------------
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

## ----eval = should_run-------------------------------------------------------------------------------------------------------------------
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

## ----eval = should_run-------------------------------------------------------------------------------------------------------------------
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

## ----eval = should_run-------------------------------------------------------------------------------------------------------------------
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
print(edges)

## ----eval = should_run, fig.height = 8, fig.width = 10-----------------------------------------------------------------------------------
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

