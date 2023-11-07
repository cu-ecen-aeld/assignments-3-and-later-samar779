#!/bin/bash

if [ $# -ne 2 ]; then
	echo "ERROR: Two arguments are required."
fi

writefile=$1
writestr=$2

if [ -z "$writefile" ]; then
	echo "error: writefile argument is not specified"
	exit 1
fi
if [ -z "$writestr" ]; then
	echo "error: writestr argument is not specified"
	exit 1
fi
mkdir -p $(dirname $writefile)
	if [ $? -ne 0 ]; then
		echo "ERROR: failed to create the directory"
		exit 1
	fi
echo "$writestr" >> "$writefile"
if [ $? -ne 0 ]; then
		echo "ERROR: failed to create the file"
		exit 1
else
echo "file created $writefile"
fi

