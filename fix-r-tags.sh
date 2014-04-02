#! /bin/bash

## Remove tags from packages that were already archived at 
## the time of the release

. releases.conf

CRAN=/Users/csardi/cran/CRAN/contrib
github=/Users/csardi/cran/github

fix_tag() {
    local pkg="$1" tag="$2"
    (
	cd "$github/$pkg"

	ver=$(echo $tag | sed "s/^R-//")
	rel=$(echo "$RELEASES" | grep "$ver")
	rel_date=$(echo $rel | cut -d" " -f2 | tr -d '-')

	arch_date=$(grep "\"$pkg\"" "$github"/../ARCHIVED |
	    cut -f2 -d" " | tr -d '"-')
	
	if [ "$rel_date" -ge "$arch_date" ]; then
	    git tag -d "$tag"
	    git push origin ":refs/tags/$tag"
	fi
    )	
}

fix_all_tags_pkg() {
    local pkg="$1"
    (
	cd "$github/.."
	if ! grep -q "\"$pkg\"" ARCHIVED; then return 0; fi
	echo "$pkg"
	cd "$github/$pkg"
	tags=$(git tag | grep "^R-")
	for tag in $tags; do fix_tag "$pkg" "$tag"; done
    )
}

fix_all_tags() {
    (
	cd "$github"
	for pkg in *; do fix_all_tags_pkg "$pkg"; done
    )

}

fix_all_tags
