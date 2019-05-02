# C2SNARK Transform #

This comparison experiments use the Pepper system to transform a subset of C program to sets of constraints that can be used for SNARK. 




## Examples ##

* Note, not all of the examples in `apps/` have been tested in this
  release.

Known working ones include:

`mm_pure_arith, pam_clustering, fannkuch, ptrchase_{benes,merkle},
mergesort_{benes,merkle}, boyer_occur_{benes,merkle}, kmpsearch,
kmpsearch_flat, rle_decode, rle_decode_flat, sparse_matvec,
sparse_matvec_flat.`

Most others should work as well, but may require porting the
verifier's input generation function from the main release.
