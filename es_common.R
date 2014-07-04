
URL <- "http://search.r-pkg.org:9200"
index <- "cran-${version}"
user_pw <- readLines("es_user.txt")[1]
user <- strsplit(user_pw, ":")[[1]][1]
pass <- strsplit(user_pw, ":")[[1]][2]

dep_fields <- c("Depends", "Imports", "Suggests", "Enhances", "LinkingTo")

concat_dep_field <- function(field) {
  nm <- names(field)
  field <- sub("*", "", field, fixed=TRUE)
  field <- sub("^(..*)$", " (\\1)", field)
  paste0(nm, field, collapse=", ")
}

es_format <- function(pkg, deps) {
  pkg$releases <- NULL
  if (tolower(pkg$date) == "invalid date") { pkg$date <- NULL }
  if (pkg$Package %in% names(deps)) {
    pkg$revdeps <- deps[[pkg$Package]]+1
  } else {
    pkg$revdeps <- 1
  }
  non_dep <- setdiff(names(pkg), dep_fields)
  for (df in intersect(names(pkg), dep_fields)) {
    pkg[[df]] <- concat_dep_field(pkg[[df]])
  }  
  pkg <- lapply(pkg, unbox)
  js <- gsub("\\n", " ", toJSON(pkg), fixed=TRUE)
  gsub('\\\\[^"]', " ", js)
}

es_add_docs <- function(index, packages, deps, chunk_size=30) {
  chunks <- split(packages, ceiling(seq_along(packages)/chunk_size))
  for (chunk in chunks) {
    jpkgs <- sapply(chunk, es_format, deps=deps)
    heads <- paste0('{ "create": { "_id": "',
                    unname(sapply(chunk, "[[", "Package")),
                    '" } }')
    body <- paste0(paste(heads, jpkgs, sep="\n", collapse="\n"), "\n")
    res <- PUT(paste0(URL, "/", index, "/package/_bulk"),
               body=body, authenticate(user, pass, type="basic"))
    stat <- sapply(lapply(fromJSON(content(res, as="text"),
                                   simplifyVector=FALSE)$items, "[[",
                          "create"), "[[", "status")
    if (any(stat != 201)) { stop("Error") }
  }
}
library(httr)
library(jsonlite)

URL <- "http://search.r-pkg.org:9200"
index <- "cran-${version}"
user_pw <- readLines("es_user.txt")[1]
user <- strsplit(user_pw, ":")[[1]][1]
pass <- strsplit(user_pw, ":")[[1]][2]

mapping <- '{
  "mappings": {
    "package": {
      "properties": {
        "Package": {
          "type": "string",
          "index": "not_analyzed"
        },
        "Title": {
          "type": "string",
          "analyzer": "english"
        },
        "Version": {
          "type": "string",
          "index": "not_analyzed"
        },
        "Author": {
          "type": "string"
        },
        "Maintainer": {
          "type": "string"
        },
        "Description": {
          "type": "string",
          "analyzer": "english"
        },
        "License": {
          "type": "string",
          "index": "not_analyzed"
        },
        "URL": {
          "type": "string",
          "analyzer": "simple"
        },
        "BugReports": {
          "type": "string",
          "analyzer": "simple"
        },
        "date": {
          "type": "date"
        },
        "Date": {
          "type": "string"
        }
      }
    }
  }
}
'

dep_fields <- c("Depends", "Imports", "Suggests", "Enhances", "LinkingTo")

concat_dep_field <- function(field) {
  nm <- names(field)
  field <- sub("*", "", field, fixed=TRUE)
  field <- sub("^(..*)$", " (\\1)", field)
  paste0(nm, field, collapse=", ")
}

es_format <- function(pkg, deps) {
  pkg$releases <- NULL
  if (tolower(pkg$date) == "invalid date") { pkg$date <- NULL }
  if (pkg$Package %in% names(deps)) {
    pkg$revdeps <- deps[[pkg$Package]]+1
  } else {
    pkg$revdeps <- 1
  }
  non_dep <- setdiff(names(pkg), dep_fields)
  for (df in intersect(names(pkg), dep_fields)) {
    pkg[[df]] <- concat_dep_field(pkg[[df]])
  }  
  pkg <- lapply(pkg, unbox)
  js <- gsub("\\n", " ", toJSON(pkg), fixed=TRUE)
  gsub('\\\\[^"]', " ", js)
}

es_add_docs <- function(index, packages, deps, chunk_size=30) {
  chunks <- split(packages, ceiling(seq_along(packages)/chunk_size))
  for (chunk in chunks) {
    jpkgs <- sapply(chunk, es_format, deps=deps)
    heads <- paste0('{ "create": { "_id": "',
                    unname(sapply(chunk, "[[", "Package")),
                    '" } }')
    body <- paste0(paste(heads, jpkgs, sep="\n", collapse="\n"), "\n")
    res <- PUT(paste0(URL, "/", index, "/package/_bulk"),
               body=body, authenticate(user, pass, type="basic"))
    stat <- sapply(lapply(fromJSON(content(res, as="text"),
                                   simplifyVector=FALSE)$items, "[[",
                          "create"), "[[", "status")
    if (any(stat != 201)) { stop("Error") }
  }
}

## Supported releases
get_versions <- function() {
  url <- "http://db.r-pkg.org"
  vv <- content(GET(paste0(url, "/-/releases")), as="text")
  js <- fromJSON(vv)
  js$version
}

last_coach_update <- function() {
  url <- "http://107.170.126.171/cran/_changes?limit=1&descending=true"
  res <- fromJSON(content(GET(url), as="text"), simplifyVector=FALSE)
  res$last_seq
}

last_es_update <- function() {
  url <- paste0(URL, "/meta/meta/couch-seq")
  res <- fromJSON(content(GET(url), as="text"), simplifyVector=FALSE)
  res$`_source`$value
}

get_new_docs <- function(from=last_es_update()) {
  url <- paste0("http://107.170.126.171",
                "/cran/_changes?last-event-id=", from, "&include_docs=true")
  fromJSON(content(GET(url), as="text"), simplifyVector=FALSE)
}

update_es_doc_version_for_release <- function(pkg, json, rel) {
  index <- paste0("cran-", rel)
  stop_for_status(PUT(paste0(URL, "/", index, "/package/", pkg),
                      body=json, authenticate(user, pass, type="basic")))
}

update_es_doc <- function(doc, deps, vers) {
  doc <- doc$doc
  pkg <- doc[["_id"]]
  print(pkg)
  
  ## Design document
  if (substr(pkg, 1, 1) == "_") { return() }

  ## Non-package document, releases are not handled yet
  if (!is.null(doc[["type"]]) && doc[["type"]] != "package") { return() }

  ## Update versions
  for (ver in doc$versions) {
    if (length(ver$releases) != 0) {
      json <- es_format(ver, deps=deps)
      for (rel in ver$releases) {
        update_es_doc_version_for_release(pkg, json, rel)
      }
    }
  }

  ## Remove from versions
  rels <- unique(unlist(lapply(doc$versions, "[[", "releases")))
  del_rels <- setdiff(vers, rels)
  body <- paste0('{ "delete": { "_index": "', del_rels, '",',
                 ' "_type": "package", "_id": "', pkg, '" } }\n',
                 collapse="")
  POST(paste0(URL, "/", "_bulk"), body=body,
      authenticate(user, pass, type="basic"))

  ## Update cran-devel
  json <- es_format(doc$versions[[doc$latest]], deps)
  update_es_doc_version_for_release(pkg, json, "devel")

  invisible()
}
