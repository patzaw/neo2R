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
   ## Process URL and guess protocol ----
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
      sub("[/]db.*$", "", url)
   )
   ## Set general header ----
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
   ## Find neo4j version and database name ----
   conStatus <- graphRequest(toRet, "", "GET", "")
   if(is.na(conStatus$header["status"]) || conStatus$header["status"]!="200"){
      print(conStatus$header)
      stop("Cannot connect to the Neo4j database")
   }
   if("neo4j_version" %in% names(conStatus$result)){
      toRet$version=unlist(strsplit(
         conStatus$result$neo4j_version, split="[.]"
      ))
   }else{
      if(is.na(database)){
         database <- "data"
      }
      conStatus <- graphRequest(toRet, sprintf("/db/%s/", database), "GET", "")
      if(
         is.na(conStatus$header["status"]) || conStatus$header["status"]!="200"
      ){
         print(conStatus$header)
         stop("Cannot connect to the Neo4j database")
      }
      if("neo4j_version" %in% names(conStatus$result)){
         toRet$version=unlist(strsplit(
            conStatus$result$neo4j_version, split="[.]"
         ))
      }else{
         stop("Unknown version of neo4j")
      }
   }
   if(!toRet$version[1] %in% c("3", "4")){
      print(toRet["version"])
      stop("Only version 3 and 4 of Neo4j are supported")
   }
   ## Define cypher transaction endpoint ----
   if(toRet$version[1]=="3"){
      toRet$database=ifelse(is.na(database), "data", database)
      toRet$cypher_endpoint <- sprintf(
         "/db/%s/transaction/commit", toRet$database
      )
   }
   if(toRet$version[1]=="4"){
      toRet$database <- ifelse(is.na(database), "neo4j", database)
      toRet$cypher_endpoint <- sprintf("/db/%s/tx/commit", toRet$database)
   }
   ## Final connection check ----
   cypher(toRet, "match (n) return n limit 1", result="graph")
   return(toRet)
}
