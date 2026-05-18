#' Run a curl request on a neo4j graph
#'
#' @param graph the neo4j connection
#' @param endpoint the endpoint for the request. To list all the available
#' endpoints:
#' `graphRequest(graph, endpoint="", customrequest="GET", postText="")$result`
#' @param customrequest the type of request: "POST" (default) or "GET"
#' @param postText the request body
#'
#' @return A list with the "header" and the "result" of the request (invisible)
#'
#' @seealso [startGraph()] and [cypher()]
#'
#' @export
#'
graphRequest <- function(
  graph,
  endpoint, #"transaction/commit"
  customrequest = c("POST", "GET"),
  postText
) {
  customrequest <- match.arg(customrequest)
  postfields <- jsonlite::toJSON(postText, auto_unbox = T)

  req <- httr2::request(paste0(graph$url, endpoint)) |>
    httr2::req_method(customrequest)
  req <- do.call(httr2::req_headers, c(list(req), graph$headers))
  if (length(graph$.opts) > 0) {
    req <- do.call(httr2::req_options, c(list(req), graph$.opts))
  }
  if (customrequest == "POST") {
    req <- httr2::req_body_raw(req, charToRaw(postfields))
  }
  resp <- req |>
    httr2::req_error(is_error = \(r) FALSE) |>
    httr2::req_perform()
  invisible(list(
    header = c(status = httr2::resp_status(resp)),
    result = jsonlite::fromJSON(
      httr2::resp_body_string(resp),
      simplifyVector = FALSE
    )
  ))
}
