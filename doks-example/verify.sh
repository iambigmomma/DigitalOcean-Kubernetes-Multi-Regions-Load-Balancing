#!/bin/bash
export URL="$1"
for x in {1..10}; 
    do echo "== request $x" ; 
    curl -L ${URL} | grep title >> result.txt ; 
done
cat result.txt
rm result.txt
