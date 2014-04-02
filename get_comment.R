
args <- commandArgs(trailingOnly=TRUE)
if (length(args) != 1 || !file.exists(args[1])) {
  stop("Invalid argument, need PACKAGES.in file")
}

tab <- read.dcf(args[1])
tab <- tab[, c("Package", "X-CRAN-Comment")]
tab[is.na(tab)] <- ""

write.table(tab, row.names=FALSE, col.names=FALSE, sep=":", quote=FALSE)
