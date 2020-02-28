###############################################################################@
#' Run a cypher query
#'
#' @param graph the neo4j connection
#' @param query the cypher query
#' @param parameters parameters for the cypher query.
#' @param result the way to return results. "row" will return a data frame
#' and "graph" will return a list of nodes, a list of relationships
#' and a list of paths (vectors of relationships identifiers).
#' @param arraysAsStrings if result="row" and arraysAsStrings is TRUE (default)
#' array from neo4j are converted to strings and array elements are
#' separated by eltSep.
#' @param eltSep if result="row" and arraysAsStrings is TRUE (default)
#' array from neo4j are converted to strings and array elementes are
#' separated by eltSep.
#'
#' @return the "result" of the query (invisible). See the "result" param.
#'
#' @seealso [multicypher()], [startGraph()], [prepCql()],
#' [readCql()] and [graphRequest()]
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
   endpoint <- graph$cypher_endpoint
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
      toRet <- process_row(results)
   }
   if(result=="graph"){
      d <- results$results[[1]]$data
      toRet <- process_graph(d)
   }
   invisible(toRet)
}

###############################################################################@
#' Run a multiple cypher queriers
#'
#' @param graph the neo4j connection
#' @param queries queries to submit. It can be either a character vector
#' for which each element corresponds to a cypher query. Or it can be
#' a list of lists with the following slots:
#' - **query** (mandatory): A single character corresponding to the cypher
#' query.
#' - **parameters** (optional): A set of parameters specific for
#' this query. If not provided, the *parameters* parameter of the function is
#' used  (see below).
#' - **result** (optional): The specific way to return the results of
#' this query. If not provided, the *result* parameter of the function is
#' used  (see below).
#' @param parameters default parameters for the cypher queries.
#' @param result default way to return results. "row" will return a data frame
#' and "graph" will return a list of nodes, a list of relationships
#' and a list of paths (vectors of relationships identifiers).
#' @param arraysAsStrings if result="row" and arraysAsStrings is TRUE (default)
#' array from neo4j are converted to strings and array elements are
#' separated by eltSep.
#' @param eltSep if result="row" and arraysAsStrings is TRUE (default)
#' array from neo4j are converted to strings and array elementes are
#' separated by eltSep.
#'
#' @return a list of "result" of the queries (invisible).
#' See the "result" param.
#'
#' @seealso [cypher()], [startGraph()], [prepCql()],
#' [readCql()] and [graphRequest()]
#'
#' @examples \dontrun{
#' result <- multicypher(
#'    graph,
#'    queries=list(
#'       q1="match (n) return n.value limit 5",
#'       q2=list(
#'          query="match (f {value:$val})-[r]->(t) return f, r, t limit 5",
#'          result="graph",
#'          parameters=list(val=100)
#'       )
#'    )
#' )
#' }
#'
#' @export
#'
multicypher <- function(
   graph,
   queries,
   parameters=NULL,
   result=c("row", "graph"),
   arraysAsStrings=TRUE,
   eltSep=" || "
){
   result = match.arg(result)
   endpoint <- graph$cypher_endpoint
   qnames <- names(queries)

   statements <- lapply(
      unname(queries),
      function(query){
         if(!is.character(query) && !is.list(query)){
            stop("Each query should be character or a list")
         }
         if(is.character(query)){
            toRet <- list(statement=query)
         }
         if(is.list(query)){
            if(!"query" %in% names(query)){
               stop('Parameterized query should have a "query" slot')
            }
            if(!is.character(query$query)){
               stop('The "query" slot should be a character')
            }
            toRet <- list(statement=query$query)
            if("result" %in% names(query)){
               if(!query$result %in% c("row", "graph")){
                  stop('The "result" slot should be "row" or "graph"')
               }
               toRet$resultDataContents <- list(query$result)
            }
            if(!is.null(query$parameters)){
               toRet$parameters <- query$parameters
            }
         }
         if(is.null(toRet$resultDataContents)){
            toRet$resultDataContents <- list(result)
         }
         if(is.null(toRet$parameters) && !is.null(parameters)){
            toRet$parameters <- parameters
         }
         return(toRet)
      }
   )
   postText <- list(statements=statements)

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

   toRet <- lapply(
      1:length(results$results),
      function(i){
         results <- results$results[[i]]
         if(statements[[i]]$resultDataContents=="row"){
            return(process_row(results))
         }
         if(statements[[i]]$resultDataContents=="graph"){
            return(process_graph(results$d))
         }
      }
   )
   names(toRet) <- qnames
   invisible(toRet)
}


###############################################################################@
## Helpers ----
process_row <- function(results){
   if(length(results$data)==0){
      toRet <- NULL
   }else{
      if(!is.null(names(results$data[[1]][[1]]))){
         warning(
            "Complex data from query ==> you should shift to 'graph' result."
         )
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
   return(toRet)
}

process_graph <- function(d){
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
