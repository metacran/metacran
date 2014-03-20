## Unofficial read-only mirror of CRAN R packages on github

The benefits being:
- Easy access to the source code, including diffs between versions.
- Easy forking and maintaining patched versions of packages.
- Watching new versions of packages
- Easy installation of old package versions via `install_github` from
  the `devtools` package. (Although this is already possible with
  the `install_version` function of the same package.)

## The machinery

We keep a local mirror of CRAN source packages. A couple of times a
day we rsync the mirror and compare the old and new `PACKAGES` files.
We add all new versions of the packages that were updated or
introduced in the new `PACKAGES` file. Simple, huh?

## Some details

Every package is in its own repository. Each new package version
generates a new commit to the package repository, with the version
number in the commit message. There is also a tag for each commit, the
tag is simply the version number.

Author dates and committer dates are set to the date in the
DESCRIPTION file.

## cran.github.io

This is in the works.

It will be a website including some info about the packages. Updated
every time one of the repositories are updated.

The idea is to have a static website, with searching supported by some
client-side search engine, or google custom search.

It is not completely clear what would be on the website, though. Maybe
one page per package, and some summary pages. Although the package
pages can also be on individual websites,
http://cran.github.io/<package>.

Some ideas about useful content:
- List of new packages. This is already on cranberries, though.
- Documentation for each package, already on inside-r.
- NEWS files.
- Some search engine that can search in `DESCRIPTION` files.
- Some search engine that searches in the package contents (?).
- Some search engine that searches in functions and data sets
  (there are already several websites like this....)


