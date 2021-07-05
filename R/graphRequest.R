#' Run a curl request on a neo4j graph
#'
#' @param graph the neo4j connection
#' @param endpoint the endpoint for the request. To list all the available
#' endpoints:
#' `graphRequest(graph, endpoint="", customrequest="GET", postText="")$result`
#' @param customrequest the type of request: "POST" (default) or "GET"
#' @param postText the request body
#'
#' @return a list with the "header" and the "result" of the request (invisible)
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

   if (customrequest== "GET")
   {
       res <- GET(url = paste0(graph$url, endpoint),
                 config=graph$headers,
                 body = postfields)
   }
   else if (customrequest== "POST")
   {
      res <- POST(url = paste0(graph$url, endpoint),
                 config=graph$headers,
                 body = postfields)
   }
   
   res.content = httr::content(res, as='text', encoding='UTF-8')
   
   invisible(list(
      header=headers(res),
      status_code=status_code(res),
      result=jsonlite::fromJSON(res.content, simplifyVector=FALSE)
   ))
}
