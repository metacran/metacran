
`==.version` <- function(x, y) compareVersion(x, y) == 0
`>.version`  <- function(x, y) compareVersion(x, y) == 1
`[.version`  <- function(x, i) structure(unclass(x)[i], class="version")

f <- file("stdin")
fv <- matrix(scan(f, what="", quiet=TRUE), ncol=2)
v <- structure(fv[,2], class="version")
write.table(fv[order(v), 2:1, drop=FALSE], row.names=FALSE, 
            col.names=FALSE, quote=FALSE)
