
args <- commandArgs(trailingOnly=TRUE)
if (length(args) != 2 || !file.exists(args[1]) || !file.exists(args[2])) {
  stop("Invalid argument(s), need PACKAGES files")
}

old <- read.dcf(args[1])[, "Package"]
new <- read.dcf(args[2])[, "Package"]

write(setdiff(old, new), file="")
