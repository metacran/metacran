
source("es_common.R")

## Get the new docs
new_docs_res <- get_new_docs()
new_docs <- new_docs_res$results
c_seq <- new_docs_res$last_seq

## Get number of reverse dependencies, for cran-devel
## This is not right, if we change older releases,
## but that does not happen too often, and it will
## be corrected eventually by another means
deps <- fromJSON(content(GET("http://crandb.r-pkg.org/-/deps/devel"),
                         as="text"))
deps <- unlist(deps)

rel <- get_versions()

## Update them
tmp <- sapply(new_docs, update_es_doc, deps=deps, vers=rel)

## Update the stamp
stop_for_status(PUT(paste0(URL, "/meta/meta/couch-seq"),
                    body=paste0(' { "value": ', c_seq, ' }'),
                    authenticate(user, pass, type="basic")))
