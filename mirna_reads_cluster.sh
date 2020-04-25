#requires mmseqs; get it from here: https://github.com/soedinglab/MMseqs2
#requires seqkit; get it from here: https://github.com/shenwei356/seqkit
#requires seqtk; get it from here: https://github.com/lh3/seqtk
export PATH=$PATH:"$1"

#filter the data for sequences between 
seqkit seq -m 18 -M 30 "$2" > tmp.fa
mmseqs createdb tmp.fa mirna_mmseqs
mmseqs cluster --cov-mode 1 -c 0.5 --min-seq-id 0.5 mirna_mmseqs cluster $PWD
mmseqs result2flat mirna_mmseqs mirna_mmseqs cluster cluster_out --use-fasta-header
grep "^>" cluster_out | sed 's/>//g' | seqtk subseq "$2" - > uniq_mirna.fasta
mkdir mirna && mv "$2" uniq_mirna.fasta mirna
rm -rf mirna_mmseqs* latest cluster* [0-9][0-9][0-9]* tmp.fa
echo "done"
