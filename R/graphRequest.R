#' Run a curl request on a neo4j graph
#'
#' @param graph the neo4j connection
#' @param endpoint the endpoint for the request. To list all the available
#' endpoints:
#' \code{graphRequest(graph, endpoint="", customrequest="GET", postText="")$result}
#' @param customrequest the type of request: "POST" (default) or "GET"
#' @param postText the request body
#'
#' @return a list with the "header" and the "result" of the request (invisible)
#'
#' @export
#'
graphRequest <- function(
   graph,
   endpoint, #"transaction/commit"
   customrequest=c("POST", "GET"),
   postText
){
   customrequest <- match.arg(customrequest)
   postfields <- jsonlite::toJSON(postText, auto_unbox = T)
   tg = RCurl::basicTextGatherer()
   hg = RCurl::basicHeaderGatherer()
   RCurl::curlPerform(
      url = paste0(graph$url, endpoint),
      httpheader=graph$headers,
      customrequest = customrequest,
      writefunction = tg$update,
      headerfunction = hg$update,
      postfields=postfields,
      .encoding="UTF-8"
   )
   invisible(list(
      header=hg$value(),
      result=jsonlite::fromJSON(tg$value(), simplifyVector=FALSE)
   ))
}
