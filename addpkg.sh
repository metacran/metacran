#!/bin/sh

## TODO: 
## - github disconnects

if [[ $# -eq 0 ]] ; then
    echo 'Package not specified.'
    exit 1
fi

pkg=$1

CRAN=/Users/csardi/cran/CRAN/contrib
github=/Users/csardi/cran/github

export PATH=/usr/local/bin:$PATH
export LC_CTYPE=C 
export LANG=C

test_date() {
    local date=$1 td=`mktemp -d -t XXXXXX-rpkg`
    local res=$(
	cd "$td"
	git init . >/dev/null
	touch a
	git add a >/dev/null
	local res2="0"
	git commit -q -m test --date="$date" >/dev/null 2>/dev/null || false
	res2=$?
	cd ..
	rm -rf "$td"
	echo $res2 )
    if [ "$res" = "0" ]; then return 0; else return 1; fi
}

get_date() {
    date=$(grep "^Date:" DESCRIPTION | sed 's/[^:]*:[ ]*//' |
	tr '-' '.')
    if [ -z "$date" ]; then
	date=$(grep "^Packaged:" DESCRIPTION | sed 's/[^:]*:[ ]*//' |
	    sed 's/;.*$//')
    fi
    date="$date 00:00:00 +0000"
    if ! test_date "$date"; then
	date=$(git log -1 --format="%aD" 2>/dev/null || true)
	if [ -z "$date" ]; then
	    date="1977-08-08 00:00:00 +0000"
	fi
    fi
}

get_author() {
    author=$(grep "^Maintainer:" DESCRIPTION | sed 's/[^:]*:[ ]*//')
    if [ -z "$author" -o "$author" = "ORPHANED" ]; then
	author=$(grep "^X-CRAN-Original-Maintainer:" DESCRIPTION | 
	    sed 's/[^:]*:[ ]*//')
    fi
    if [ -z "$author" ]; then
	author=$(grep "^Author:" DESCRIPTION | sed 's/[^:]*:[ ]*//')
    fi
    if echo ${author} | grep -q '^<'; then
	author="$(echo $author | sed 's/^<\([^@]*\)@.*$/\1/') $author"
    fi
    if echo ${author} | grep -q '[^ ]<'; then
	author=$(echo $author | sed 's/</ </')
    fi
    if echo ${author} | grep -q -v '<'; then
	author=$(echo $author | sed 's/[(]/</' | sed 's/[)]/>/')
    fi
    if echo ${author} | grep -q -v '<'; then
	author=$(echo $author | sed 's/[ ]\([^ ]*@[^ ]*\)/ <\1>/')
    fi
    if [ -z "$author" ] || echo "$author" | grep -q -v '@'; then
	author="Unknown author <unknown@unknown>"
    fi
}

get_desc() {
    desc=$(grep "^Title:" DESCRIPTION  | sed 's/[^:]*:[ ]*//')
}

get_homepage() {
    homepage=$(grep "^URL:" DESCRIPTION | sed 's/[^:]*:[ ]*//')
}

get_token() {
    token=$(grep -A 1 github.com  ~/.config/hub  | grep oauth_token |
	sed 's/^[^:]*:[ ]*//')
}

github() {
    local data=$1 url=$2 method=$3
    get_token
    curl --request "${method}" --data "${data}" \
	"https://api.github.com/${url}?access_token=${token}"
}

update_desc() {
    local name=$1 desc=$2 homepage=$3
    get_token
    data="{ \"name\": \"${name}\", \"description\": \"${desc}\", \"homepage\": \"${homepage}\" } "
    github "${data}" "repos/cran/${name}" "PATCH"
}

remove_dotgit() {
    if [ "$1" == "." ]; then exit 3; fi
    find $1 -name .git -exec rm -rf \{\} \;
}

untar_it() {
    local file="$1"
    local real=$(echo "$1" | sed 's/_.*$//')
    local td=`mktemp -d -t XXXXXXXX-rpkg`
    (
        cp $file "$td"
	cd "$td"
	tar xzf *
        rm $file
	mv `ls` "$real"
    )
    mv "${td}/${real}" .
    rm -rf "$td"
}

get_versions() {
    local files versions ov

    # Old versions
    if [ -d ${CRAN}/Archive/${pkg} ]; then
       files=( $(find ${CRAN}/Archive/${pkg} -type f -name "*.tar.gz") )
    else   
       files=()
    fi

    # Latest version
    files=( "${files[@]}" $(ls ${CRAN}/${pkg}_*) )

    versions=( $(echo "${files[@]}"  | tr ' ' '\n' | sed 's/.tar.gz$//' |
                 sed 's/^.*_//') )

    rest=$(echo "${files[@]}" "${versions[@]}" | Rscript sortvers.R)

    first=( $(echo "$rest" | head -1) )
}

check_pkg_dir() {
    (
	if [ ! -d "$pkg" ]; then return 1; fi
    	cd $pkg
    	if [ ! -d .git ]; then return 2; fi
    	if ! git log 2>/dev/null >/dev/null; then return 3; fi
    	return 0
     )
}

add_if_new() {
     local pkg=$1 file=$2 ver=$3
     if (cd ${pkg}; git log --format=oneline | sed 's/^.*version[ ]*//' | \
	    grep -qFx "$ver"); then 
         echo "$ver exists"
         if [ "$adding" == 1 ]; then 
             echo "$pkg version number error" ; exit 25; 
         fi
         return 0 
     fi
     adding=1
     echo "adding $ver"
     (
       mv ${pkg}/.git ./${pkg}-git
       rm -rf ${pkg} ${pkg}*.tar.gz    
       cp ${file} .
       untar_it "${pkg}_*.tar.gz"
       remove_dotgit "${pkg}"
       mv ./${pkg}-git ${pkg}/.git
       cd ${pkg}
       git status
       git add -A .
       git status
       get_date
       get_author
       if git tag | grep -q "^${ver}"'$'; then ver="${ver}-dup"; fi
       GIT_COMMITTER_DATE="$date" git commit --allow-empty \
          -m "version $ver" --date "$date" --author "$author"
       git tag "$ver" || true
       cd ..
       rm ${pkg}_*.tar.gz
     )
}

####################################################
# Main program starts here

get_versions

set -e

cd ${github}

echo "======= $pkg"

new_package=0
if ! check_pkg_dir; then 
    # Copy over first version
    new_package=1
    rm -rf ${pkg} ${pkg}*.tar.gz
    cp ${first[1]} .
    untar_it "${pkg}_*.tar.gz"
    remove_dotgit "${pkg}"
    cd ${pkg}

    # Init repo with first version
    git init .
    git add -A .
    get_date
    get_author
    GIT_COMMITTER_DATE="$date" git commit -m "version ${first[0]}" \
        --date "$date" --author "$author"
    git tag ${first[0]}
    cd ..
    rm ${pkg}_*.tar.gz
fi

# And add the rest, if any
if [ ! -z "$rest" ]; then    
    while read -r line; do
	ver=$(echo $line | cut -d" " -f1)
	file=$(echo $line | cut -d" " -f2)
	add_if_new "$pkg" "$file" "$ver"
    done <<< "$rest"
fi

# And put the whole stuff on github
if [ "$new_package" == "1" ]; then
  (
  cd ${pkg}
  get_desc
  get_homepage
  hub create cran/${pkg} -d "$desc" -h "$homepage"
  github " { \"name\": \"${pkg}\", \"has_issues\": false, \"has_wiki\": false }" \
    "repos/cran/${pkg}" "PATCH"
  )
fi

if [ "$adding" == "1" -o "$new_package" == "1" ]; then
   (
    cd ${pkg} 
    git push origin master
    git push --tags
   )
fi
