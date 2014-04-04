
## Put all packages from ALL_PACAGES into the couchdb database

source("couch_functions.R")

allpkg <- read.dcf("ALL_PACKAGES")

##################################################################
## Need some cleanup first

## Remove exact duplicates
allpkg <- allpkg[!duplicated(allpkg), ]

## Duplicate versions, but other data is not the same:
pp <- allpkg[,"Package"]
pp[is.na(pp)] <- allpkg[,"Bundle"][is.na(pp)]
badbad <- pp[which(duplicated(paste(pp, allpkg[, "Version"], sep=":")))]
badbad
# [1] "MetabolAnalyze" "SciViews"       "evora"          "pcalg"
# [5] "pwr"

## Handle them by hand
to_del <- c()

## MetabolAnalyze: only Date/Publication is different, keep earlier
to_del <- c(to_del, which(pp == "MetabolAnalyze" &
                          allpkg[, "Date/Publication"] ==
                          "2012-08-29 14:22:54"))
## SciViews: One Bundle, one Package, keep Package
to_del <- c(to_del, which(pp=="SciViews" & allpkg[, "Version"] == "0.9-5" &
                          is.na(allpkg[, "Package"])))

## evora: NeedsCompilation is different: NA/no, keep no
to_del <- c(to_del, which(pp == "evora" &
                          is.na(allpkg[, "NeedsCompilation"])))

## pcalg: Keep later, accoring to R-Forge revision and time stamp
to_del <- c(to_del, which(pp == "pcalg" &
                          allpkg[, "Repository/R-Forge/Revision"] == "239"))
## pwr: Updated DESCRIPTION to remove latin1 character from name,
##      and added Date/Publication field as well
##      we keep the later record, but with the old publication date
to_del <- c(to_del, which(pp == "pwr" & allpkg[, "Version"] == "1.1.1" &
                          is.na(allpkg[, "Repository"])))
allpkg[pp=="pwr" & allpkg[, "Version"] == "1.1.1",
       c("Date", "Date/Publication")][2,] <-
  c("2007-01-31", "2007-01-31 00:00:00")

if (length(to_del) != 0) { allpkg <- allpkg[-to_del, ] }

## The VR bundle has spaces in its name, we just replace this with "VR"
pkgs <- unique(na.omit(c(allpkg[, c("Package", "Bundle")])))
vr <- grep(" ", pkgs, value=TRUE)
vr
# [1] "VR: contains MASS class nnet spatial"
pp <- allpkg[,"Package"]
pp[is.na(pp)] <- allpkg[,"Bundle"][is.na(pp)]
allpkg[pp==vr, "Title"] <- vr
allpkg[pp==vr, "Package"] <- "VR"

##################################################################

pkgs <- unique(na.omit(c(allpkg[, c("Package", "Bundle")])))

res <- lapply(pkgs, function(p) {
  print(p)
  js <- to_couch(allpkg, p)
  res <- fromJSON(content(couch_add_docs(p, js)))
  print(res)
  res
})


