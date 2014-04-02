#! /bin/bash -e

## Get archival dates for packages
## A package is archived if it is in /Archive, but not in 
## the main directory

BASE=/Users/csardi/cran
CRAN="$BASE"/CRAN/contrib
github="$BASE"/github
output="ARCHIVED"

if [ -f "$output" ]; then
    echo "Output file exists"
    exit 1
fi

tmp1=$(mktemp -t cran)
tmp2=$(mktemp -t cran)

ls "$CRAN"/Archive | grep -v README | sort > "$tmp1"
ls "$CRAN" | grep ".tar.gz$" | sed 's/_.*.tar.gz$//' | sort > "$tmp2"

archived=$(comm -2 -3 "$tmp1" "$tmp2")
rm -f "$tmp1" "$tmp2"

## Now we need to look up when they were archived.
## We also save the comment with the reason for archival,
## if available. In PACKAGES.in there are only ~230 comments
## about archivals, so it might be tough to find out the date.
## If there is nothing else, we take the date of the file
## of the last version in /Archive

tmp1=$(mktemp -t cran)
date_pattern="[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]"

Rscript get_comment.R "$CRAN/PACKAGES.in" > "$tmp1"

parse_comment() {
    local comment="$1"
    if echo "$comment" | grep -q "$date_pattern"; then
	echo "$comment" | sed 's/^.*\('$date_pattern'\).*$/\1/'
	return 0
    fi
    return 1
}

## Just get the latest date
check_last_date() {
    local pkg="$1"
    last=$(stat -f "%m" CRAN/contrib/Archive/${pkg}/${pkg}* | 
	sort -nr | head -1)
    date -r "$last" +%Y-%m-%d
}

do_package() {
    local pkg="$1"
    comment=$(grep "^${pkg}:" "$tmp1" | cut -f2- -d: | sed 's/"/\\"/g' )
    when=$(parse_comment "$comment" || check_last_date "$pkg")
    echo \""$pkg"\" \""$when"\" \""$comment"\"
}

for pkg in $archived; do 
    echo "$pkg"
    do_package $pkg >> "$output"
done

rm -f "$tmp1"
