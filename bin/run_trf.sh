#!/usr/bin/env bash
#set -euo pipefail
infile=$1
outfile=$2
workdir=$(dirname $infile)

# check for fastq format, convert to fasta if needed and use that as input to trf
ext=.${infile##*.} # extract the last part of the file name delimited by a '.'
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
set +e
time eval $trf_cmd 
retval=$?
set -e
echo "trf cmd returned $retval"
echo "===== ===== ===== ===== ===== ===== ===== ===== ===== "
cmd="parse_trf_dat_format.py $expected_outfile $outfile"
echo $cmd
time eval $cmd

echo "============================================= End run_trf.sh ============================================="
date
