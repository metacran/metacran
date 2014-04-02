#! /bin/sh

## Releases taken from CRAN, e.g. http://cran.rstudio.com/src/base/R-2/
## Dates taken from the R-announce mailing list announcements, search from
## http://blog.gmane.org/gmane.comp.lang.r.announce
## This is after 2.13.2. Before that google search, and the R-user list:
## http://blog.gmane.org/gmane.comp.lang.r.general

. releases.conf

if [[ $# -eq 0 ]] ; then
    echo 'Package not specified.'
    exit 1
fi

pkg=$1

CRAN=/Users/csardi/cran/CRAN/contrib
github=/Users/csardi/cran/github

add_tag() {
    local ver="$1" date="$2"
    commit=$(git log -1 --before "$date" --format="%H")
    if [ -z "$commit" ]; then return 0; fi
    git tag "R-${ver}" "$commit"
}

if [ ! -d "${github}/${pkg}" ]; then
     echo "Package directory ${github}/${pkg} does not exist"
     exit 2
fi

cd "${github}/${pkg}"

while read -r line; do
     ver=$(echo $line | cut -d" " -f1)
     date=$(echo $line | cut -d" " -f2)      
     add_tag "$ver" "$date"
done <<< "$RELEASES"

