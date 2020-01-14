#!/usr/bin/env bash

export INPUT_FILE="$1"
export OUTPUT_FILE="${1%.*}.R"

rm -f $OUTPUT_FILE

Rscript -e "library(knitr); purl(\"$INPUT_FILE\", output = \"$OUTPUT_FILE\", documentation = 2)"
