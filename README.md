
# `metacran` — Tooling around CRAN R packages

`metacran` is a collection of projects to allow better tooling
around CRAN R packages. It contains a number of projects.
The following ones are stably working and can be considered
beta software:

* [CRAN @ github](https://github.com/cran), read-only mirror of CRAN at github.
* [`crandb`](https://github.com/metacran/crandb),
  a database of CRAN R packages, with an HTTP API, and an
  R package to access it from R.
* [CRAN package search](https://github.com/metacran/search), 
  based on `crandb`. It is online at http://metacran.github.io/search.
* [`seer`](https://github.com/metacran/seer), R package
  to search for CRAN packages.
* [`r-builder`](https://github.com/metacran/r-builder)
  Scripts to use Travis or another CI to
  build and check R packages with various R versions, including
  R-devel.
* `cranlogs` A [database](https://github.com/metacran/cranlogs.app)
  and [R package](https://github.com/metacran/cranlogs) for daily R package
  download counts from the RStudio CRAN mirror.
* [`rversions`](https://github.com/metacran/rversions)
  An R package to query R versions and their
  release dates from the R project SVN repository.

`metacran` also contains some experimental packages and tools:

* [`spareserver`](https://github.com/metacran/spareserver)
  R package to fallback to another web server if the main one
  is not responding.
* [`cranny`](https://github.com/metacran/cranny)
  [`packer`](https://packer.io/) templates to build the metacran servers.
