#' Prepare connection to neo4j database
#'
#' @param url the DB url
#' @param database the name of the database. If NA (default) it will use "data"
#' with versions 3.. of Neo4j and "neo4j" with versions 4..
#' @param username the neo4j user name
#' (default: NA; works only if authentication has been disabled in neo4j by
#' setting NEO4J.AUTH=none)
#' @param password the neo4j user password
#' (default: NA; works only if authentication has been disabled in neo4j by
#' setting NEO4J.AUTH=none)
#' @param importPath path to the import directory
#' (default: NA => no import directory). Import only works with local neo4j
#' instance.
#' @param .opts a named list identifying the curl
#' options for the handle (see [httr2::req_options()] and curl option names
#' for a complete list of available options;
#' for example: `.opts = list(ssl_verifypeer = 0)`). Moreover, this parameter
#' can be used to pass additional headers to the graph requests as
#' "extendedHeaders": it is useful, for example, for OAuth access
#' delegation (see details).
#' @param check check the connection before returning it (default: TRUE).
#' Set to false when connection to the "system" database
#' @param api the HTTP API to use: `"tx"` for the legacy Transactional Cypher
#' HTTP API (default for self-managed instances), `"v2"` for the Neo4j Query
#' API v2 (required for Aura, available on self-managed Neo4j >= 5.19), or
#' `"auto"` (default) to detect automatically — Aura URLs
#' (*.databases.neo4j.io) select `"v2"`, all others select `"tx"`.
#'
#'
#' @details The "ssl.verifypeer" logical option available in the RCurl package
#' used in former versions of neo2R (<= 2.2.0) is
#' not recognized by [httr2::req_options()].
#' However, for backward compatibility, if it is used, it is translated into
#' the "ssl_verifypeer" integer curl option with a warning message.
#'
#' Headers in `.opts$extendedHeaders` are added to, or overwrite,
#' the default Neo4j headers.
#' If there is a `.opts$extendedHeaders[["Authorization"]]` value, the
#' default Neo4j "Authorization" header (user credentials) is provided
#' automaticaly as "X-Authorization". This mechanism is used for OAuth access
#' delegation.
#'
#' @return A connection to the graph DB:
#' a list with the url and necessary headers
#'
#' @export
#'
startGraph <- function(
  url,
  database = NA,
  username = NA,
  password = NA,
  importPath = NA,
  .opts = list(),
  check = TRUE,
  api = c("auto", "tx", "v2")
) {
  api <- match.arg(api)

  if ("ssl.verifypeer" %in% names(.opts)) {
    .opts$ssl_verifypeer <- as.integer(.opts$ssl.verifypeer)
    .opts$ssl.verifypeer <- NULL
    warning(
      "'ssl.verifypeer' option has been automatically converted into ",
      "'ssl_verifypeer' integer curl option. ",
      "You should use the 'ssl_verifypeer' integer option ",
      "to avoid this warning."
    )
  }

  ## Process URL and guess protocol ----
  protocol <- grep("^https://", url)
  if (length(protocol) == 1) {
    protocol = "https://"
    url <- sub("^https://", "", url)
  } else {
    protocol <- "http://"
    url <- sub("^http://", "", url)
  }
  url <- paste0(
    protocol,
    sub("[/]db.*$", "", url)
  )
  ## Set general header ----
  neo4jHeaders <- list(
    'Accept' = 'application/json; charset=UTF-8;',
    'Content-Type' = 'application/json',
    'X-Stream' = TRUE,
    'Authorization' = paste(
      "Basic",
      jsonlite::base64_enc(paste(username, password, sep = ":"))
    )
  )

  ## Append other headers - swap Authorization headers for OAuth ----
  extendedHeaders <- .opts$extendedHeaders
  .opts$extendedHeaders <- NULL
  if (!is.null(extendedHeaders[["Authorization"]])) {
    temp_auth <- neo4jHeaders[["Authorization"]]
    neo4jHeaders[["Authorization"]] <- extendedHeaders[["Authorization"]]
    neo4jHeaders[["X-Authorization"]] <- temp_auth
    extendedHeaders <- extendedHeaders[setdiff(
      names(extendedHeaders),
      "Authorization"
    )]
  }
  overw <- intersect(names(extendedHeaders), names(neo4jHeaders))
  if (length(overw) > 0) {
    warning(
      "The following default headers are overwritten by user values: ",
      paste(overw, sep = ", ")
    )
    neo4jHeaders <- neo4jHeaders[setdiff(
      names(neo4jHeaders),
      names(extendedHeaders)
    )]
  }
  neo4jHeaders <- c(neo4jHeaders, extendedHeaders)

  toRet <- list(
    url = url,
    headers = neo4jHeaders,
    importPath = importPath,
    .opts = .opts
  )
  ## Find neo4j version and database name ----
  conStatus <- graphRequest(toRet, "", "GET", "")
  if (
    is.na(conStatus$header["status"]) || conStatus$header["status"] != "200"
  ) {
    print(conStatus$header)
    stop("Cannot connect to the Neo4j database")
  }
  if ("neo4j_version" %in% names(conStatus$result)) {
    toRet$version = unlist(strsplit(
      conStatus$result$neo4j_version,
      split = "[.]"
    ))
  } else {
    if (is.na(database)) {
      database <- "data"
    }
    conStatus <- graphRequest(toRet, sprintf("/db/%s/", database), "GET", "")
    if (
      is.na(conStatus$header["status"]) || conStatus$header["status"] != "200"
    ) {
      print(conStatus$header)
      stop("Cannot connect to the Neo4j database")
    }
    if ("neo4j_version" %in% names(conStatus$result)) {
      toRet$version = unlist(strsplit(
        conStatus$result$neo4j_version,
        split = "[.]"
      ))
    } else {
      stop("Unknown version of neo4j")
    }
  }
  .v1 <- suppressWarnings(as.integer(toRet$version[1]))
  .year_based <- !is.na(.v1) && .v1 >= 2025
  if (!toRet$version[1] %in% c("3", "4", "5") && !.year_based) {
    print(toRet["version"])
    stop(
      "Only Neo4j versions 3, 4, 5 and year-based versions ",
      "(>= 2025) are supported"
    )
  }
  ## Define database name ----
  if (toRet$version[1] == "3") {
    toRet$database <- ifelse(is.na(database), "data", database)
  }
  if (toRet$version[1] %in% c("4", "5") || .year_based) {
    toRet$database <- ifelse(is.na(database), "neo4j", database)
  }
  ## Determine API ----
  if (api == "auto") {
    api <- if (
      grepl("\\.databases\\.neo4j\\.io", toRet$url, ignore.case = TRUE) ||
        .year_based
    ) {
      "v2"
    } else {
      "tx"
    }
  }
  toRet$api <- api
  ## Define cypher endpoint ----
  if (api == "v2") {
    toRet$cypher_endpoint <- sprintf("/db/%s/query/v2", toRet$database)
  } else {
    if (toRet$version[1] == "3") {
      toRet$cypher_endpoint <- sprintf(
        "/db/%s/transaction/commit",
        toRet$database
      )
    }
    if (toRet$version[1] %in% c("4", "5") || .year_based) {
      toRet$cypher_endpoint <- sprintf("/db/%s/tx/commit", toRet$database)
    }
  }
  ## Final connection check ----
  if (check) {
    cypher(toRet, "match (n) return n limit 1", result = "graph")
  }
  return(toRet)
}
