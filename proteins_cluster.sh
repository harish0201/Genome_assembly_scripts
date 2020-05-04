#Requires mmseqs2; get it here: https://github.com/soedinglab/MMseqs2
#Requires concatenated protein set from multiple species
#Requires seqtk;
#Requires seqkit;
#$3 and $4 are the query coverage and seq-id respectively
export PATH=$PATH:"$1"
seqtk seq -m 10 "$2" > "$2".tmp.fa
mmseqs createdb "$2".tmp.fa proteins_mmseqs
mmseqs cluster --cov-mode 1 -c "$3" --min-seq-id "$4" proteins_mmseqs cluster $PWD
mmseqs result2flat proteins_mmseqs proteins_mmseqs cluster cluster_out --use-fasta-header
grep "^>" cluster_out | sed 's/>//g' | seqtk subseq "$2".tmp.fa - > uniq_proteins.fasta
mkdir proteins && mv "$2" uniq_proteins.fasta proteins
rm -rf proteins_mmseqs* latest cluster* [0-9][0-9][0-9]*
echo "done"
