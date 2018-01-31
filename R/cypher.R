#' Run a cypher query
#'
#' @param graph the neo4j connection
#' @param query the cypher query
#' @param parameters parameters for the cypher query. Cannot be used in MATCH
#' @param result the way to return results. "row" will return a data frame
#' and "graph" will return a list of nodes and a list of relationships.
#'
#' @return the "result" of the query (invisible). See the "result" param.
#'
#' @examples \dontrun{
#' # 2 identical queries
#' result <- cypher(
#'    graph=graph,
#'    query='match (n {value:$value}) return n',
#'    parameters=list(value="100")
#'    result="graph"
#' )
#' result <- cypher(
#'    graph=graph,
#'    query='match (n {value:"100"}) return n',
#'    result="graph"
#' )
#' }
#'
#' @importFrom jsonlite toJSON fromJSON
#' @importFrom RCurl basicTextGatherer basicHeaderGatherer curlPerform
#'
#' @export
#'
cypher <- function(graph, query, parameters=NULL, result=c("row", "graph")){
   result=match.arg(result)
   postText <- list(
      statements=list(list(
         statement=query,
         resultDataContents=list(result)
      ))
   )
   if(!is.null(parameters)){
      postText$statements[[1]]$parameters <- parameters
   }
   results <- graphRequest(
      graph=graph,
      endpoint="transaction/commit",
      customrequest="POST",
      postText=postText
   )$result
   errors <- results$errors
   if(length(errors)>0){
      devnull <- lapply(errors, lapply, message)
      stop("neo4j error")
   }
   if(result=="row"){
      if(length(results$results[[1]]$data)==0){
         toRet <- NULL
      }else{
         if(!is.null(names(results$results[[1]]$data[[1]]$row[[1]]))){
            warning("Complex data from query ==> you should shift to 'graph' result.")
         }
         columns <- do.call(c, results$results[[1]]$columns)
         toRet <- list()
         for(i in 1:length(columns)){
            toAdd <- do.call(c, lapply(
               results$results[[1]]$data,
               function(d){
                  r <- unlist(d$row[[i]])
                  if(length(r)!=1){
                     paste(r, collapse=" || ")
                  }else{
                     r
                  }
               }
            ))
            toRet <- c(
               toRet,
               list(toAdd)
            )
         }
         toRet <- as.data.frame(toRet, stringsAsFactors=FALSE)
         colnames(toRet) <- columns
      }
   }
   if(result=="graph"){
      d <- results$results[[1]]$data
      nodes <- unique(do.call(c, lapply(d, function(x) x$graph$nodes)))
      names(nodes) <- unlist(lapply(nodes, function(n) n$id))
      relationships <- unique(do.call(c, lapply(d, function(x) x$graph$relationships)))
      names(relationships) <- unlist(lapply(relationships, function(n) n$id))
      p <- lapply(d, function(x) unlist(lapply(x$graph$relationships, function(y) y$id)))
      toRet <- list(nodes=nodes, relationships=relationships, paths=p)
   }
   invisible(toRet)
}
