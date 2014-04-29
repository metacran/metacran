
library(httr)
library(jsonlite)

## Initialize the ElasticSearch database
## Each R version will be in a separate index,
## this makes it easy to search them individually.

## This also means that versions that are not part of
## any R/CRAN release are not searched at all.

URL <- "http://rpkg.igraph.org:9200"
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
  url <- "http://rpkg.igraph.org"
  vv <- content(GET(paste0(url, "/-/releases")), as="text")
  js <- fromJSON(vv)
  js$version
}
releases <- get_versions()

## Create indexes, and 'package' types
for (rel in c(releases, "devel")) {
  ind <- sub("${version}", rel, index, fixed=TRUE)
  stop_for_status(DELETE(paste0(URL, "/", ind),
                         authenticate(user, pass, type="basic")))
  stop_for_status(PUT(paste0(URL, "/", ind), body=mapping,
                      authenticate(user, pass, type="basic")))
}

## For each release, add packages
for (rel in c("devel", releases)) {
  print(rel)
  if (rel == "devel") {
    url <- "http://rpkg.igraph.org/-/latest"
  } else {
    url <- paste0("http://rpkg.igraph.org/-/releasepkgs/", rel)
  }  
  pkgs <- fromJSON(content(GET(url), as="text"))
  pkgs <- rev(pkgs)
  pkgs <- rev(pkgs[!duplicated(names(pkgs))])
  deps <- fromJSON(content(GET(paste0("http://rpkg.igraph.org/-/deps/",
                                      rel)), as="text"))
  deps <- unlist(deps)
  ind <- sub("${version}", rel, index, fixed=TRUE)
  es_add_docs(ind, pkgs, deps)
}

## Example CouchDB document:
## 
## {
##     "_id": "igraph",
##     "_rev": "2-94483ef15a3707e7d065671382a16d45",
##     "name": "igraph",
##     "versions": {
##         "0.1.1": {
##             "Package": "igraph",
##             "Title": "IGraph class",
##             "Version": "0.1.1",
##             "Date": "Januar 25, 2005",
##             "Author": "Gabor Csardi <csardi@rmki.kfki.hu>",
##             "Maintainer": "Gabor Csardi <csardi@rmki.kfki.hu>",
##             "Description": "Routines for simple graphs.",
##             "License": "GPL version 2 or later (June, 1991)",
##             "Packaged": "Tue Feb 28 14:17:08 2006; csardi",
##             "URL": "http://cneurocvs.rmki.kfki.hu/igraph",
##             "date": "2006-02-28T14:17:08-05:00"
##         },
##         "0.6": {
##             "Package": "igraph",
##             "Title": "Network analysis and visualization",
##             "Version": "0.6",
##             "Date": "Jun 11, 2012",
##             "Author": "Gabor Csardi <csardi.gabor@gmail.com>",
##             "Maintainer": "Gabor Csardi <csardi.gabor@gmail.com>",
##             "Description": "Routines for simple graphs and network analysis. igraph\ncan handle large graphs very well and provides functions for\ngenerating random and regular graphs, graph visualization,\ncentrality indices and much more.",
##             "License": "GPL (>= 2)",
##             "Depends": {
##                 "stats": "*"
##             },
##             "Suggests": {
##                 "igraphdata": "*",
##                 "stats4": "*",
##                 "rgl": "*",
##                 "tcltk": "*",
##                 "graph": "*",
##                 "Matrix": "*",
##                 "ape": "*"
##             },
##             "Packaged": "2012-06-14 13:43:29 UTC; gaborcsardi",
##             "Repository": "CRAN",
##             "Date/Publication": "2012-06-14 20:21:10",
##             "URL": "http://igraph.sourceforge.net",
##             "SystemRequirements": "gmp, libxml2",
##             "date": "2012-06-14T20:21:10-04:00"
##         },
##         "0.7.1": {
##             "Package": "igraph",
##             "Version": "0.7.1",
##             "Date": "2014-04-22",
##             "Title": "Network analysis and visualization",
##             "Author": "See AUTHORS file.",
##             "Maintainer": "Gabor Csardi <csardi.gabor@gmail.com>",
##             "Description": "Routines for simple graphs and network analysis. igraph can\nhandle large graphs very well and provides functions for generating random\nand regular graphs, graph visualization, centrality indices and much more.",
##             "Depends": {
##                 "methods": "*"
##             },
##             "Imports": {
##                 "Matrix": "*"
##             },
##             "Suggests": {
##                 "igraphdata": "*",
##                 "stats4": "*",
##                 "rgl": "*",
##                 "tcltk": "*",
##                 "graph": "*",
##                 "ape": "*"
##             },
##             "License": "GPL (>= 2)",
##             "URL": "http://igraph.org",
##             "SystemRequirements": "gmp, libxml2",
##             "BugReports": "https://github.com/igraph/igraph/issues",
##             "Packaged": "2014-04-22 18:00:26 UTC; gaborcsardi",
##             "NeedsCompilation": "yes",
##             "Repository": "CRAN",
##             "Date/Publication": "2014-04-22 23:08:29",
##             "releases": [
##             ],
##            "date": "2014-04-22T23:08:29-04:00"
##        }
##    },
##    "latest": "0.7.1",
##    "title": "Network analysis and visualization",
##    "timeline": {
##        "0.1.1": "2006-02-28T14:17:08-05:00",
##        "0.6": "2012-06-14T20:21:10-04:00",
##        "0.7.1": "2014-04-22T23:08:29-04:00"
##    },
##    "archived": false
## }
