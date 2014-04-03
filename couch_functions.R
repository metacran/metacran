
## Functions for couchdb connection and operations

## Some configuration

url <- "http://127.0.0.1:5984"
db <- "cran"
dep_fields <- c("Depends", "Imports", "Suggests", "Enhances", "LinkingTo")

library(jsonlite)
library(httr)

## Parse releases
parse_releases <- function(reldir) {
  rf <- list.files(reldir, full.names=TRUE)
  rl <- lapply(rf, function(x) {
    r1 <- read.table(x, sep=":", stringsAsFactors=FALSE, strip.white=TRUE)
    cbind(r1, rversion=sub("^R-", "", basename(x)))
  })
  res <- do.call(rbind, rl)
  colnames(res) <- c("package", "version", "rversion")
  res
}

releases <- parse_releases("releases")

## Get data about archived packages
parse_archived <- function(arch) {
  res <- read.table(arch, stringsAsFactors=FALSE)
  colnames(res) <- c("package", "date", "comment")
  res
}

archived <- parse_archived("ARCHIVED")

## Trim whitespace from beginning and end

trim <- function (x) gsub("^\\s+|\\s+$", "", x)

## Convert a dependency field to a nested array
## that will be eventually converted to JSON

parse_dep_field <- function(str) {
  sstr <- strsplit(str, ",")[[1]]
  pkgs <- sub("[ ]?[(].*[)].*$", "", sstr)
  vers <- gsub("^[^(]*[(]?|[)].*$", "", sstr)
  vers[vers==""] <- "*"
  vers <- lapply(as.list(vers), unbox)  
  names(vers) <- trim(pkgs)
  vers
}

## Add releases to list

add_releases <- function(rec, releases) {
  pkg <- rec$Package
  version <- rec$Version
  if (is.null(pkg)) { pkg <- rec$Bundle }
  if (is.null(pkg)) {
    character()
  } else {
    w <- which(releases$package == pkg & releases$version == version)
    releases$rversion[w]
  }
}

## Add archival information to list
add_archived <- function(rec, archived) {
  pkg <- rec$Package
  version <- rec$Version
  if (is.null(pkg)) { pkg <- rec$Bundle }
  if (is.null(pkg) || !pkg %in% archived$package) {
    NULL
  } else {
    w <- which(archived$package == pkg)
    list(archived=unbox(TRUE), date=unbox(archived[w, "date"]),
         comment=unbox(archived[w, "comment"]))
  }
}

set_encoding <- function(str) {
  if (! is.na(str["Encoding"])) {
    Encoding(str) <- str['Encoding']
  } else {
    Encoding(str) <- "latin1"
  }
  str
}

## Convert a DESCRIPTION record to JSON
## Usage: to_couch(allpkg[1,])

to_couch <- function(rec, pretty=FALSE) {
  rec <- set_encoding(rec)
  rec <- na.omit(rec)
  rec <- as.list(rec)
  rec <- lapply(rec, unbox)
  for (f in intersect(names(rec), dep_fields)) {
    rec[[f]] <- parse_dep_field(rec[[f]])
  }
  rec$releases <- add_releases(rec, releases)
  rec$archived <- add_archived(rec, archived)
  toJSON(rec, pretty=pretty)
}

couch_add_docs <- function(json) {
  id <- fromJSON(content(GET(paste0(url, "/_uuids"))))$uuids
  rep <- PUT(paste0(url, "/", db, "/", id), body=json)
  rep
}
