#' Imports a data.frame in the neo4j graph database
#'
#' @param graph the neo4j connection
#' @param cql the CQL query to be applied on each row of toImport.
#' Use the 'row' prefix to refer to the data.frame column.
#' @param toImport the data.frame to be imported as "row".
#' Use "row.FIELD" in the cql query to refer to one FIELD of the toImport
#' data.frame
#' @param periodicCommit use periodic commit when loading the data
#' (default: 1000).
#' @param ... further parameters for [cypher()]
#'
#' @seealso [cypher()]
#'
#' @export
#'
import_from_df <- function(
   graph, cql, toImport, periodicCommit=10000, ...
){
   if(!inherits(toImport, "data.frame")){
      stop("toImport must be a data.frame")
   }
   importPath <- graph$importPath
   stopifnot(
      !is.null(importPath),
      !is.na(importPath)
   )
   if(!file.exists(importPath)){
      stop(sprintf("Import path (%s) does not exist.", importPath))
   }
   tf <- tempfile(tmpdir=importPath)
   for(cn in colnames(toImport)){
      toImport[,cn] <- as.character(toImport[,cn])
   }
   pc <- c()
   if(is.numeric(periodicCommit) && length(periodicCommit)==1){
      pc <- sprintf("USING PERIODIC COMMIT %s", periodicCommit)
   }
   cql <- prepCql(c(
      pc,
      paste0(
         'LOAD CSV WITH HEADERS FROM "file:',
         ifelse(
            !is.null(importPath),
            file.path("", basename(tf)),
            tf
         ),
         '" AS row '# FIELDTERMINATOR "\\t"'
      ),
      cql
   ))
   if(nrow(toImport)<=1000){
      write.table(
         toImport,
         file=tf,
         sep=",", #"\t",
         quote=T,
         row.names=F, col.names=T
      )
      on.exit(file.remove(tf))
      toRet <- cypher(graph=graph, query=cql, ...)
      invisible(toRet)
   }else{
      write.table(
         toImport[c(1:1000), , drop=FALSE],
         file=tf,
         sep=",", #"\t",
         quote=T,
         row.names=F, col.names=T
      )
      on.exit(file.remove(tf))
      toRet <- cypher(graph=graph, query=cql, ...)
      cypher(graph=graph, query='CALL db.resampleOutdatedIndexes();')
      write.table(
         toImport[-c(1:1000), , drop=FALSE],
         file=tf,
         sep=",", #"\t",
         quote=T,
         row.names=F, col.names=T
      )
      toRet <- cypher(graph=graph, query=cql, ...)
      invisible(toRet)
   }
}
