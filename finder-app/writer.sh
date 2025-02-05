#!/bin/sh

writefile=$1
writestr=$2

if [ -z $writefile ] || [ -z $writestr ]; then 
    echo "Usage: $0 <write-file-path> <text-string>"
    exit 1
fi

# Extract the directory path from the file path
writedir=$(dirname "$writefile")

# Create the directory if it does not exist
mkdir -p "$writedir"

# Write the string to the file, overwriting if it exists
echo "$writestr" > "$writefile"

# Check if the file was created successfully
if [ $? -ne 0 ]; then
    echo "Error: Could not create file $writefile."
    exit 1
fi
