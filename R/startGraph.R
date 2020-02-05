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
#'
#' @return a connection to the graph DB:
#' a list with the url and necessary headers
#'
#' @export
#'
startGraph <- function(
   url, database=NA, username=NA, password=NA, importPath=NA
){
   protocol <- grep("^https://", url)
   if(length(protocol)==1){
      protocol="https://"
      url <- sub("^https://", "", url)
   }else{
      protocol <- "http://"
      url <- sub("^http://", "", url)
   }
   url <- paste0(
      protocol,
      sub("[/]*db[/]data[/]*$", "", url),
      "/db/data/"
   )
   neo4jHeaders <- list(
      'Accept' = 'application/json; charset=UTF-8;',
      'Content-Type' = 'application/json',
      'X-Stream' = TRUE,
      'Authorization' = paste(
         "Basic",
         base64enc::base64encode(charToRaw(
            paste(username, password, sep=":")
         ))
      )
   )
   toRet <- list(
      url=url,
      headers=neo4jHeaders,
      importPath=importPath
   )
   return(toRet)
}
