
library(jsonlite)
library(httr)

db <- "http://rpkg.igraph.org"
repo <- "git@github.com:cran/cran.github.io.git"

if (!file.exists("_build")) {
  cmd <- paste("git clone --branch source --depth 1", repo, "_build")
  system(cmd)

  setwd("_build")
  cmd <- paste("git clone --branch master", repo, "_site")
  system(cmd)
} else {
  setwd("_build")
}

setwd("scripts")

commandArgs <- function(...) "devel"

cat("Package list for devel... ")
source("update_alpha.R")
cat("DONE\n")

cat("Most depended upon for devel... ")
source("update_topdeps.R")
cat("DONE\n")

cat("Latest packages... ")
source("update_recent.R")
cat("DONE\n")

rel <- get_versions()

for (myrel in rel) {  
  commandArgs <- function(...) myrel

  cat("Creating skeleton list for", myrel, "...")
  source("add_alpha_skeleton.R")
  cat("DONE\n")
  
  cat("Package list for", myrel, "...")
  source("update_alpha.R")
  cat("DONE\n")

  cat("Most depended upon for", myrel, "...")
  source("update_topdeps.R")
  cat("DONE\n")  
}
