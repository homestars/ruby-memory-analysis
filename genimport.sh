#!/bin/sh
heapFiles=`ls ./heap_files/*.csv`
for file in $heapFiles; do
  table=space_objects
  echo "$file" | grep -q '\.refs\.csv$' && table=space_object_references

  echo "\\COPY $table (`head -n1 $file`) FROM '$file' WITH (FORMAT CSV, HEADER);"
done
echo "VACUUM ANALYZE;"
