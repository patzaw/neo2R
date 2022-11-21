#######################################################

#' Prepares a CQL query from a character vector
#'
#' @param ... character vectors with cQL commands
#'
#' @return A well formated CQL query
#'
#' @seealso [cypher()] and [readCql()]
#'
#' @examples prepCql(c(
#'  "MATCH (n)",
#'  "RETURN n"
#' ))
#'
#' @export
#'
prepCql <- function(...){
   cql <- paste(..., collapse=" ")
   return(paste(sub(";[[:blank:]]*$", "", cql), ";"))
}


#######################################################

#' Parse a CQL file and returned the prepared queries
#'
#' @param file the name of the file to be parsed
#'
#' @return A character vector of well formated CQL queries
#'
#' @seealso [cypher()] and [prepCql()]
#'
#' @export
#'
readCql <- function(file){
   rq <- readLines(file)
   rq <- sub("//.*", "", rq)
   rq <- rq[which(rq != "")]
   qend <- grep(";$", rq)
   qstart <- c(1, (qend[1:(length(qend))]+1)[-length(qend)])
   toRet <- apply(
      cbind(qstart, qend),
      1,
      function(x){
         prepCql(rq[x[1]:x[2]])
      }
   )
   return(toRet)
}
