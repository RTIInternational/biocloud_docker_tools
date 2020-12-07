#!/usr/local/bin/Rscript

# Arguments
# --file-gds <GDS FILE>
# --variant-id-field <VARIANT ID FIELD IN GDS FILE>
# --chunk-size <N>
# --out-prefix <OUTPUT FILE PREFIX>

library(gdsfmt)
library(data.table)
library(R.utils)

args <- commandArgs(asValue = TRUE)
cat("Arguments:\n")
str(args)

# Retrieve variant IDs from GDS file
geno = openfn.gds(toString(args["file-gds"]))
node=index.gdsn(geno, toString(args["variant-id-field"]))
snpIds = read.gdsn(node)
closefn.gds(geno)

# Split into chunks and write variant lists
chunks = split(snpIds, ceiling(seq_along(snpIds)/strtoi(args["chunk-size"])))
for (chunk in 1:(length(chunks))) {
    strChunk = formatC(chunk, width = 10, format = "d", flag = "0")
    fwrite(
        chunks[chunk],
        file = paste0(toString(args["out-prefix"]), "_", strChunk, ".txt"),
        col.names = FALSE
    )
}
