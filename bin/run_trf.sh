#!/usr/bin/env
#set -oeu pipefail
infile=$1
outfile=$2
workdir=$(dirname $infile)

# check for fastq format, convert to fasta if needed and use that as input to trf
ext=.${infile#*.}
if [ "$ext" == ".fq" ] || [ "$ext" == ".fastq" ]
then
    tmpfile=$(mktemp -p $workdir)
    cmd="seqkit fq2fa < $infile > $tmpfile" 
    echo $cmd
    time eval $cmd
    mv $tmpfile $infile # this will cause the original file, which ends in .fq, to be a fasta file. oh well
fi


trf_options="2 7 7 80 10 50 500"
infile=$(basename $infile)
outfile=$(basename $outfile)
expected_outfile=$infile.${trf_options// /.}.dat
trf_cmd="trf $infile $trf_options -d -h"
echo $trf_cmd
cd $workdir
time eval $trf_cmd
echo "trf cmd returned $?"
echo "===== ===== ===== ===== ===== ===== ===== ===== ===== "
cmd="python ../parse_trf_dat_format.py $expected_outfile $outfile"
echo $cmd
time eval $cmd

echo "============================================= End run_trf.sh ============================================="
date
