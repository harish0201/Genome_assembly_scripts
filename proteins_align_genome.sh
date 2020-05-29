#uses mmseqs2 as a replacement to tblastn, commands are in reference to gemoma and various threads on mmseqs2
# target index needs to be built with the following command:
# mmseqs createdb genome.fasta target
# mmseqs createindex target tmp  --comp-bias-corr 0 --mask 0 --search-type 2

export PATH=$PATH:/apps/mmseqs/bin/
query=$(basename "$1" .fasta)
tmp=tmp_$(basename "$1" .fasta)
mmseqs createdb $1 $query
mmseqs search $query "$2" out_$query $tmp -e 0.0001 --threads 96 -s 8.5 -a --max-seqs 500 --orf-start-mode 1 --comp-bias-corr 0 --mask 0
output=$query.out.gemoma
mmseqs convertalis $query target out_$query $output --format-output "query,target,pident,alnlen,mismatch,gapopen,qstart,qend,tstart,tend,evalue,bits,empty,raw,nident,empty,empty,empty,qframe,tframe,qaln,taln,qlen,tlen"
echo "done"
