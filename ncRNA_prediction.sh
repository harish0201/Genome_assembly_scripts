#Requires: cmscan/infernal toolkit, cmpressed RFAM database, parallel, samtools, split-assembly.py in this repo

#split and index the genome:
mkdir split_genome && cd split_genome
ln -s "$1" genome.fasta
python2.7 split-assembly.py genome.fasta > /dev/null
unlink genome.fasta
for i in *.fa; do echo "samtools index "$i""; done | parallel -j100
for i in *.fa; do echo "cmscan -Z $(awk '{$x=$2*2/10^9; print $x}' "$i".fai) --cut_ga --rfam --nohmmonly --tblout $(basename "$i" .fa).tblout --fmt 2 --clanin Rfam.clanin Rfam.cm "$i" >
$(basename "$i" .fa).cmscan"; done | parallel -j30
cd .. && echo "done"
