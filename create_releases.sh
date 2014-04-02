#!/bin/bash

BASE=/Users/csardi/cran
github="$BASE"/github

mkdir -p "$BASE"/releases

## Sometimes the separator is a tab, sometimes a space
## Sometimes there are more than one version records, 
## we use the latest

get_version() {
    grep "^Version:" | tr '\t' ' ' | cut -f2 -d":" | tr -d ' ' | tail -1
}

do_package_version() {
    local pkg="$1" ver="$2"
    (
	cd "$github/$pkg"
	commit=$(git log -1 "$ver" --format="format:%H" 2>/dev/null || 
	    false)
	if [ -z "$commit" ]; then return 0; fi
	pkgver=$(git show "$commit":DESCRIPTION 2>/dev/null | get_version ||
	    false)
	if [ -z "$pkgver" ]; then return 0; fi
	echo "$pkg": "$pkgver" >> "$BASE/releases/$ver"
    )
}

do_package() {    
    local pkg="$1"
    (
	cd "$github"/"$pkg"
	versions=$(git tag | grep "^R-")
	for ver in $versions; do do_package_version "$pkg" "$ver"; done
    )
}

create_releases() {
    (
	cd "$github"
	for pkg in *; do echo "$pkg"; do_package "$pkg"; done
    )
}

create_releases
