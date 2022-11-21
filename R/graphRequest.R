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
   customrequest=c("POST", "GET"),
   postText
){
   customrequest <- match.arg(customrequest)
   postfields <- jsonlite::toJSON(postText, auto_unbox = T)

   if(customrequest=="POST"){
      toRet <- httr::POST(
         url=paste0(graph$url, endpoint),
         body=postfields,
         do.call(httr::add_headers, graph$headers),
         config=do.call(httr::config, graph$.opts)
      )
   }
   if(customrequest=="GET"){
      toRet <- httr::GET(
         url=paste0(graph$url, endpoint),
         body=postfields,
         do.call(httr::add_headers, graph$headers),
         config=do.call(httr::config, graph$.opts)
      )
   }
   invisible(list(
      header=toRet$all_headers[[1]],
      result=jsonlite::fromJSON(rawToChar(toRet$content), simplifyVector=FALSE)
   ))
}
