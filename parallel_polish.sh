#Assumes pacbio data  with subread bams,
#Requisites: pbmm2, pbindex, samtools, parallel and split_assembly.py from this repo (this is for pacbio)
#Requisites: pilon, bwa, sambamba, samblaster, parallel and split_assembly.py from this repo (this is for illumina based reads)

########################## PACBIO POLISHING #####################
#create a list of subread bams with location. cd into the directory with bams and do ls $PWD/*subreads.bam > bam.fofn
#change number of threads as reqd: -j => threads for alignments -J for sorting the alignments (note these are for pbmm2; -j for parallel is number of jobs)

pbmm2 align genome.fasta bam.fofn aligned.bam --sort -j 96 -J 96
mkdir sequences bams polishes
cd sequences
ln -s ../genome.fasta .
python split_assembly.py genome.fasta > /dev/null
unlink genome.fasta
for i in *fa; do echo "samtools faidx "$i""; done | parallel -j100
cd ..
for i in sequences/*.fa; do echo "samtools view -Sbo bams/$(basename "$i" .fa).bam aligned.bam $(basename "$i" .fa)"; done | parallel -j100
cd bams
for i in *fa; do echo "samtools index "$i""; done | parallel -j100 &
for i in *fa; do echo "pbindex "$i""; done | parallel -j100
cd ..
#this is where the polishing begins
nohup sh -c 'for i in sequences/*.fa; do echo "echo "$i" && arrow -x 5 -r "$i" -o polishes/$(basename "$i" .fa).vcf -o polishes/$(basename "$i" .fa).fastq -j 10 bams/$(basename "$i" .fa).bam"; done | parallel -j15'
for i in *vcf; do echo "bgzip "$i""; done | parallel -j100
cat *.fastq > ../arrow_polish.fastq
########################## ###################### #####################

########################## ILLUMINA POLISHING #####################
#assumes reads have the suffix: _R*.clean.fq.gz, if not use rename command: eg file1.R1.fq.gz; using rename you can do rename .R1.fq.gz _R1.clean.fq.gz *, to change all files in the directory
#change parallel -j(*) to whatever number of jobs you want to have. BWA, sambamba uses 24 threads here
#$1=folder with reads (fastq) files); $2=genome fasta; $3=output_directory
bwa index $2
mkdir -p "$3"/sorted "$1"/tmp  && for i in "$1"/*_R1.clean.fq.gz; do echo "bwa mem -t 24 -R '@RG\tID:$(basename "$i" _R1.clean.fq.gz)\tSM:$(basename "$i" _R1.clean.fq.gz)\tLB:$(basename "$i" _R1.clean.fq.gz)' "$2" "$i" "$1"/$(basename "$i" _R1.clean.fq.gz)_R2.clean.fq.gz | samblaster --excludeDups --addMateTags -o /dev/stdout |sambamba view -S /dev/stdin -f bam -t 24 -o /dev/stdout | sambamba sort -m 3GB --tmpdir="$1"tmp -o "$3"/sorted/$(basename "$i" _R1.clean.fq.gz).sorted.bam -l 9 -t 24 /dev/stdin"; done | parallel -j2
cd sorted
mkdir sequences bams polishes
cd sequences
ln -s ../../genome.fasta .
python split_assembly.py genome.fasta > /dev/null
unlink genome.fasta
for i in *fa; do echo "samtools faidx "$i""; done | parallel -j100
cd ..
for i in sequences/*.fa; do echo "samtools view -Sbo bams/$(basename "$i" .fa).bam aligned.bam $(basename "$i" .fa)"; done | parallel -j100
cd bams
for i in *fa; do echo "samtools index "$i""; done | parallel -j100
cd ..
#this is where the polishing begins
nohup sh -c 'for i in sequences/*.fa; do echo "echo "$i" && java -Xmx10g pilon.jar --threads 5 --fix all --genome "$i" --bam bams/$(basename "$i" .fa).bam --outdir polishes -o $(basename "$i" .fa) --vcf --tracks --changes --tracks"; done | parallel -j15'
for i in *vcf *changes; do echo "bgzip "$i""; done | parallel -j100
cat *.fasta > ../pilon.fasta
########################## ###################### #####################
