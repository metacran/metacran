
## Functions for couchdb connection and operations

## Some configuration

url <- "http://127.0.0.1:5984"
db <- "cran"
dep_fields <- c("Depends", "Imports", "Suggests", "Enhances", "LinkingTo")

library(jsonlite)
library(httr)

## To sort version numbers

`==.version` <- function(x, y) compareVersion(x, y) == 0
`>.version`  <- function(x, y) compareVersion(x, y) == 1
`[.version`  <- function(x, i) structure(unclass(x)[i], class="version")

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

set_encoding <- function(str) {
  if (! is.na(str["Encoding"])) {
    Encoding(str) <- str['Encoding']
  } else {
    Encoding(str) <- "latin1"
  }
  str
}

normalize_date <- function(date) {
  cmd <- paste("NODE_PATH=/usr/local/lib/node_modules/ node -e \"var moment=require('moment'); console.log(moment(process.argv[1]).format());\" ", "\"",
               date, "\"", sep="")
  system(cmd, intern=TRUE)
}

add_date <- function(rec) {
  dd <- if ("Date/Publication" %in% names(rec)) {
    rec[["Date/Publication"]]
  } else if ("Packaged" %in% names(rec)) {
    sub(";.*$", "", rec[["Packaged"]])
  } else {
    rec[["Date"]]
  }
  normalize_date(dd)
}

## Convert a DESCRIPTION record to JSON
## Usage: to_couch(allpkg[1,])

to_couch_version <- function(rec) {
  rec <- set_encoding(rec)
  rec <- na.omit(rec)
  rec <- as.list(rec)
  rec <- lapply(rec, unbox)
  for (f in intersect(names(rec), dep_fields)) {
    rec[[f]] <- parse_dep_field(rec[[f]])
  }
  rec$releases <- add_releases(rec, releases)
  rec$date <- unbox(add_date(rec))
  rec
}

## Add archival information to list
add_archived <- function(frec, archived) {
  pkg <- frec$name
  w <- which(archived$package == pkg)
  if (length(w) != 0) {
    frec$archived <- unbox(TRUE)
    frec$archived_date <- unbox(normalize_date(archived[w, "date"]))
    frec$archived_comment <- unbox(archived[w, "comment"])
    frec$timeline[["archived"]] <- frec$archived_date
  } else {
    frec$archived <- unbox(FALSE)
  }
  frec
}

## Add latest title
add_latest_title <- function(frec) {
  tit <- frec$versions[[frec[["latest"]]]]$Title
  tit
}

## Add timeline
add_timeline <- function(frec) {
  dates <- lapply(sapply(frec$versions, "[[", "date"), unbox)
  structure(dates, names=names(frec$versions))
}

to_couch_from_matrix <- function(pkg, recs, pretty=FALSE) {
  frec <- list()

  ## Simple fields, workaround for VR
  frec[["_id"]] <- unbox(pkg)
  frec[["name"]] <- unbox(pkg)

  ## Versions
  frec$versions <- lapply(1:nrow(recs), function(r) {
    to_couch_version(recs[r, ])
  })
  names(frec$versions) <- recs[, "Version"]

  ## Latest version
  origversions <- versions <- sapply(frec$versions, "[[", "Version")
  versions <- gsub("[^0-9]+", "-", versions)
  versions <- sub("^[^0-9]+", "", versions)
  class(versions) <- "version"
  frec[["latest"]] <- unbox(unclass(tail(sort(origversions), 1)))

  ## Latest title
  frec$title <- add_latest_title(frec)

  ## Timeline
  frec$timeline <- add_timeline(frec)
  
  ## Archived or not? Adds it to timeline as well
  frec <- add_archived(frec, archived)
  
  toJSON(frec, pretty=pretty)
}

to_couch <- function(all, pkg, pretty=FALSE) {
  recs <- all[which(all[,"Package"] == pkg | all[, "Bundle"] == pkg),,
              drop=FALSE]
  if (nrow(recs) == 0) { stop("No such package") }
  to_couch_from_matrix(pkg, recs, pretty=pretty)
}

couch_add_docs <- function(id, json) {
  rep <- PUT(paste0(url, "/", db, "/", id), body=json)
  rep
}

couch_add_releases <- function() {
  rel <- read.delim("releases.conf", skip=1, header=FALSE, 
                    stringsAsFactors=FALSE)
  rel <- rel[ -nrow(rel), ]
  for (i in 1:nrow(rel)) {
    id <- rel[i, 1]
    date <- normalize_date(rel[i,2])
    json <- toJSON(list("_id"=unbox(id), date=unbox(date), 
    	                type=unbox("release")))
    res <- PUT(paste0(url, "/", db, "/", id), body=json)
    print(res)
  }
}