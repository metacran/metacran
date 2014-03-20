
old <- read.dcf("PACKAGES.old")[, c("Package", "Version")]
new <- read.dcf("PACKAGES.new")[, c("Package", "Version")]

newpkg <- setdiff(new[, "Package"], old[, "Package"])
midx <- match(new[, "Package"], old[, "Package"])
updpkg <- na.omit(new[, "Package"][new[, "Version"] !=
                                   old[, "Version"][midx]])
write.table(data.frame(c(newpkg, updpkg)), row.names=FALSE,
            col.names=FALSE, quote=FALSE)

