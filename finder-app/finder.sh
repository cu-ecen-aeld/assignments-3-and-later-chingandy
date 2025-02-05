#!/bin/sh

filesdir=$1 # Directory to search
searchstr=$2 # Word to count


if [ -z "$filesdir" ] || [ -z "$searchstr" ]; then
    echo "Usage: $0 <directory> <word>"
    exit 1
fi


# Check if filedir is a valid directory
if [ ! -d "$filesdir" ]; then
    echo "Error: $filesdir is not a directory or does not exist."
    exit 1
fi


# The number of files in the directory and all subdirectories 
num_of_files=$(find $filesdir -type f | wc -l)

# The number of matching lines found in respective files
num_of_matching_lines=$(grep -r $searchstr $filesdir | wc -l)

echo The number of files are $num_of_files and the number of matching lines are $num_of_matching_lines





