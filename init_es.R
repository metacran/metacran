
## Initialize the ElasticSearch database
## Each R version will be in a separate index,
## this makes it easy to search them individually.

## This also means that versions that are not part of
## any R/CRAN release are not searched at all.

source("es_common.R")

## This is where we are in the couchdb database
## Ideally CouchDB should be read-only while we
## are doing this

c_seq <- last_coach_update()

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
    url <- "http://crandb.r-pkg.org/-/latest"
  } else {
    url <- paste0("http://crandb.r-pkg.org/-/releasepkgs/", rel)
  }  
  pkgs <- fromJSON(content(GET(url), as="text"))
  pkgs <- rev(pkgs)
  pkgs <- rev(pkgs[!duplicated(names(pkgs))])
  deps <- fromJSON(content(GET(paste0("http://crandb.r-pkg.org/-/deps/",
                                      rel)), as="text"))
  deps <- unlist(deps)
  ind <- sub("${version}", rel, index, fixed=TRUE)
  es_add_docs(ind, pkgs, deps)
}

## Add couchdb-ES stamp
stop_for_status(PUT(paste0(URL, "/meta/meta/couch-seq"),
                    body=paste0(' { "value": ', c_seq, ' }'),
                    authenticate(user, pass, type="basic")))

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
