
## Put all packages from ALL_PACAGES into the couchdb database

source("couch_functions.R")

allpkg <- read.dcf("ALL_PACKAGES")

res <- sapply(1:nrow(allpkg), function(i) {
  print(unname(allpkg[i, c("Package", "Version")]))
  js <- to_couch(allpkg[i,])
  res <- fromJSON(content(couch_add_docs(js)))$ok
  print(res)
  res
})

bad <- which(! sapply(res, function(x) is.logical(x) && x))
save(bad, file="badpackage.Rdata")

res2 <- sapply(bad, function(i) {
  print(unname(allpkg[i, c("Package", "Version")]))
  js <- to_couch(allpkg[i,])
  res <- fromJSON(content(couch_add_docs(js)))$ok
  print(res)
  res
})

bad2 <- bad[which(! sapply(res2, function(x) is.logical(x) && x))]
save(bad2, file="badpackage.Rdata")

res3 <- sapply(bad2, function(i) {
  print(unname(allpkg[i, c("Package", "Version")]))
  js <- to_couch(allpkg[i,])
  res <- fromJSON(content(couch_add_docs(js)))$ok
  print(res)
  res
})

bad3 <- bad2[which(! sapply(res3, function(x) is.logical(x) && x))]

