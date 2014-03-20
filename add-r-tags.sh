#! /bin/sh

## Releases taken from CRAN, e.g. http://cran.rstudio.com/src/base/R-2/
## Dates taken from the R-announce mailing list announcements, search from
## http://blog.gmane.org/gmane.comp.lang.r.announce
## This is after 2.13.2. Before that google search, and the R-user list:
## http://blog.gmane.org/gmane.comp.lang.r.general

read -r -d '' RELEASES <<'---'
3.0.3	2014-03-06
3.0.2	2013-09-25
3.0.1	2013-05-16
3.0.0	2013-04-03
2.15.3	2013-03-01
2.15.2	2012-10-26
2.15.1	2012-06-22
2.15.0	2012-03-30
2.14.2	2012-02-29
2.14.1	2011-12-22
2.14.0	2011-10-31
2.13.2	2011-09-30
2.13.1	2011-07-08
2.13.0	2011-04-13
2.12.2	2011-02-25
2.12.1	2010-12-16
2.12.0	2010-10-15
2.11.1	2010-05-31
2.11.0	2010-04-22
2.10.1	2009-12-14
2.10.0	2009-10-26
2.9.2	2009-08-24
2.9.1	2009-06-26
2.9.0	2009-04-17
2.8.1	2008-12-22
2.8.0	2008-10-20
2.7.2	2008-08-25
2.7.1	2008-06-23
2.7.0	2008-04-22
2.6.2	2008-02-08
2.6.1	2007-11-26
2.6.0	2007-10-03
2.5.1	2007-06-28
2.5.0	2007-04-24
2.4.1	2006-12-18
2.4.0	2006-10-03
2.3.1	2006-06-01
2.3.0	2006-04-24
2.2.1	2005-12-20
2.2.0	2005-10-06
2.1.1	2005-06-20
2.1.0	2005-04-18
2.0.1	2004-11-15
2.0.0	2004-10-04
---

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

