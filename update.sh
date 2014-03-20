#!/bin/sh -ex

CRAN=/Users/csardi/cran/CRAN
github=/Users/csardi/cran/github

cd ${github}/..

cp PACKAGES.old PACKAGES.old.1
cp "${CRAN}"/contrib/PACKAGES PACKAGES.old
rsync -rtlzv --delete cran.r-project.org::CRAN/src/contrib ${CRAN}
cp "${CRAN}"/contrib/PACKAGES PACKAGES.new

to_update=$(Rscript check_updates.R)

for i in `echo $to_update`; do ./addpkg.sh "${i}"; done
