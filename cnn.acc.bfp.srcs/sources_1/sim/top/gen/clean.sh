#!/bin/bash

# clean up gen directory

file_to_remove=(csrc output.txt simv simv.daidir ucli.key)

for (( i=0; i<${#file_to_remove[*]}; i++ )); do
  file="${file_to_remove[i]}"
  if [[ -e $file ]]; then
    rm -rf $file
    echo "$file removed"
  fi
done

echo "directory clean"

