#!/bin/bash

if [ $# -ne 2 ]; then
	echo "ERROR: Two arguments are required."
	exit 1
fi

### Arguments ###
filesdir=$1
searchstr=$2
count=0
#### check if filesdir exists and is a directory
if [ ! -d "$filesdir" ]; then
	echo "ERROR: $filesdir is not a directory."
	exit 1
fi

count=$(find "$filesdir" -type f | wc -l)

matchcount=$(grep -r "$searchstr" "$filesdir" | wc -l)

echo "The number of files are $count  and the number of matching lines are $matchcount"
