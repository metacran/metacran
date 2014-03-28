#!/bin/bash

# Need to store info about all updates of all packages

# We can actually use a format similar to PACKAGES,
# but we would include a little more info, and all
# versions of all packages. The simplest thing is jut to 
# put together all DESCRIPTION files.

github=/Users/csardi/cran/github
packages=/Users/csardi/cran/ALL_PACKAGES

# Fixes:
#  - Replace \newline with a space character. Not strictly neeeded, but 
#    looks better.
#  - Replace empty lines within DESCRIPTION with an indented dot.
#    This is needed since empty lines separate records.
#  - Replace non-indented continuation lines.

fix_desc() {
    perl -CSAD -pe 's/\\newline/ /g;'                           \
	-pe 's/^[\t ]*$/  ./;'                                  \
	-pe 's/^models,/  models,/;'                            \
	-pe 's/^Confidence Intervals/  Confidence Intervals/;'
}

# Slight glitch: we ignore packages without 
# a DESCRIPTION file. There isn't too many of them, though,
# and they are all very old.

do_version() {
    (
	local pkg="$1" ver="$2"
	cd "$github/$pkg"
	desc=$( { git show "$ver":DESCRIPTION || false; } | fix_desc)
	{ echo -E "$desc"; echo; } >> "$packages"
    )
}

do_package() {
    (
	local pkg="$1"
	cd "$github/$pkg"
	vers=$(git log --reverse --format="format:%H")
	for ver in $vers; do do_version "$pkg" "$ver"; done
    )
}

rm -f "$packages"

cd "$github"
for i in *; do echo "$i" ; do_package "$i"; done
