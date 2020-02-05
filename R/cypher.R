#' Run a cypher query
#'
#' @param graph the neo4j connection
#' @param query the cypher query
#' @param parameters parameters for the cypher query.
#' @param result the way to return results. "row" will return a data frame
#' and "graph" will return a list of nodes and a list of relationships.
#' @param arraysAsStrings if result="row" and arraysAsStrings is TRUE (default)
#' array from neo4j are converted to strings and array elements are
#' separated by eltSep.
#' @param eltSep if result="row" and arraysAsStrings is TRUE (default)
#' array from neo4j are converted to strings and array elementes are
#' separated by eltSep.
#'
#' @return the "result" of the query (invisible). See the "result" param.
#'
#' @seealso [startGraph()], [prepCql()], [readCql()] and [graphRequest()]
#'
#' @examples \dontrun{
#' # 2 identical queries
#' result <- cypher(
#'    graph=graph,
#'    query='match (n {value:$value}) return n',
#'    parameters=list(value="100"),
#'    result="graph"
#' )
#' result <- cypher(
#'    graph=graph,
#'    query='match (n {value:"100"}) return n',
#'    result="graph"
#' )
#' }
#'
#' @export
#'
cypher <- function(
   graph,
   query,
   parameters=NULL,
   result=c("row", "graph"),
   arraysAsStrings=TRUE,
   eltSep=" || "
){
   result=match.arg(result)
   endpoint <- "transaction/commit"
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
      endpoint=endpoint,
      customrequest="POST",
      postText=postText
   )$result
   errors <- results$errors
   if(length(errors)>0){
      devnull <- lapply(errors, lapply, message)
      stop("neo4j error")
   }
   if(result=="row"){
      results <- results$results[[1]]
      if(length(results$data)==0){
         toRet <- NULL
      }else{
         if(!is.null(names(results$data[[1]][[1]]))){
            warning("Complex data from query ==> you should shift to 'graph' result.")
         }
         columns <- do.call(c, results$columns)
         toRet <- do.call(rbind, lapply(results$data, function(x) x$row))
         toRet[sapply(toRet, is.null)] <- NA
         toRet <- data.frame(toRet, stringsAsFactors=FALSE)
         if(all(sapply(toRet, class) == "list")) {
            for(i in 1:ncol(toRet)) {
               if(max(unlist(sapply(toRet[[i]], length))) == 1) {
                  toRet[,i] <- unlist(toRet[,i])
               }else{
                  if(arraysAsStrings){
                     toRet[,i] <- unlist(lapply(
                        toRet[,i], paste, collapse=eltSep
                     ))
                  }
               }
            }
         }
         colnames(toRet) <- columns
      }
   }
   if(result=="graph"){
      d <- results$results[[1]]$data
      if(is.null(d) || length(d)==0){
         return(NULL)
      }
      nodes <- unique(do.call(c, lapply(d, function(x) x$graph$nodes)))
      names(nodes) <- unlist(lapply(nodes, function(n) n$id))
      relationships <- unique(do.call(c, lapply(d, function(x) x$graph$relationships)))
      names(relationships) <- unlist(lapply(relationships, function(n) n$id))
      p <- lapply(
         d,
         function(x)
            unique(unlist(lapply(x$graph$relationships, function(y) y$id)))
      )
      p <- p[which(!unlist(lapply(p, is.null)))]
      toRet <- list(nodes=nodes, relationships=relationships, paths=p)
   }
   invisible(toRet)
}
