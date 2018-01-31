#' Prepare connection to neo4j database
#'
#' @param url the DB url
#' @param username the neo4j user name
#' @param password the neo4j user password
#'
#' @return a connection to the graph DB:
#' a list with the url and necessary headers
#'
#' @importFrom base64enc base64encode
#'
#' @export
#'
startGraph <- function(url, username, password){
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
      'Accept' = 'application/json; charset=UTF-8',
      'Content-Type' = 'application/json',
      'X-Stream' = TRUE,
      'Authorization' = paste(
         "Basic",
         base64encode(charToRaw(
            paste(username, password, sep=":")
         ))
      )
   )
   toRet <- list(
      url=url,
      headers=neo4jHeaders
   )
   return(toRet)
}
