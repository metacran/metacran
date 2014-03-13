#! /bin/bash

export PATH=/usr/local/bin:$PATH

if [[ $# -eq 0 ]] ; then
    echo 'Package not specified.'
    exit 1
fi

pkg=$1

if [ ! -d "$pkg" ]; then
    echo Package directory does not exist
    exit 2
fi

cd $pkg
foo=$(git log --reverse --pretty=oneline | cut -f1 -d" ")
ver=$(git log --reverse --pretty=oneline | sed 's/.*version[ ]*//')
correctver=$(echo $foo $ver | Rscript ../sortvers.R | cut -d" " -f1)
if [ "$ver" != "$correctver" ]; then
    echo ${pkg}
#    echo $ver
#    echo $correctver
fi
cd ..
