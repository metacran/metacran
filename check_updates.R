
args <- commandArgs(trailingOnly=TRUE)
if (length(args) != 2 || !file.exists(args[1]) || !file.exists(args[2])) {
  stop("Invalid argument(s), need PACKAGES files")
}

old <- read.dcf(args[1])[, c("Package", "Version")]
new <- read.dcf(args[2])[, c("Package", "Version")]

newpkg <- setdiff(new[, "Package"], old[, "Package"])
midx <- match(new[, "Package"], old[, "Package"])
updpkg <- na.omit(new[, "Package"][new[, "Version"] !=
                                   old[, "Version"][midx]])
write.table(data.frame(c(newpkg, updpkg)), row.names=FALSE,
            col.names=FALSE, quote=FALSE)

