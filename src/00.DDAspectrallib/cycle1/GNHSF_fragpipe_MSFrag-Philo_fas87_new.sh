#!/bin/bash

########################
# need to check
# software dir
# work dir
# parameters
##########################

##########################
# ./fragpipe.sh >>log_`date +"%Y%m%d_%H%M%S"` 2>&1&
# tail -f log*
##########################
set -xe

# set path
fragpipePath=$1
rawtype=$2
dda_cycle1_RAM=$3
msfraggerPath="$fragpipePath/software/MSFragger-3.3/MSFragger-3.3.jar" # download from http://msfragger-upgrader.nesvilab.org/upgrader/
philosopherPath="$fragpipePath/software/philosopher4.0.0/philosopher"

#crystalcPath="CrystalC.jar" # download from https://github.com/Nesvilab/Crystal-C/releases/latest
#crystalcParameterPath="crystalc.params"
#ionquantPath="IonQuant.jar" # download from https://github.com/Nesvilab/IonQuant/releases/latest


# add decoys to fasta
$philosopherPath workspace --clean --nocheck
$philosopherPath workspace --init --nocheck
$philosopherPath database --custom *.fasta
$philosopherPath workspace --clean --nocheck

# set params
echo 'database_name = '`ls *.fasta.fas` >> fragger.params

# Work directory
# Specify paths of tools and files to be analyzed.
dataDirPath="."
fraggerParamsPath="./fragger.params"
fastaPath="*.fasta.fas"
decoyPrefix="rev_"

# Run MSFragger. Change the -Xmx value according to your computer's memory.
java -Xmx${dda_cycle1_RAM} -jar $msfraggerPath $fraggerParamsPath $dataDirPath/*.${rawtype}

# Initiate Philosopher workspace
$philosopherPath workspace --clean --nocheck
$philosopherPath workspace --init --nocheck

# input: fasta file
$philosopherPath database --annotate $fastaPath --prefix $decoyPrefix

# Pick one from the following three commands and comment the other two.
# input: *.pepXML generated by MSFragger; output: interact-*.pep.xml
$philosopherPath peptideprophet --decoyprobs --ppm --accmass --nonparam --expectscore --minprob 0 --decoy $decoyPrefix --database $fastaPath --output interact *.pepXML

# input: interact-*.pep.xml; output: combined.prot.xml
$philosopherPath proteinprophet --minprob 0 --maxppmdiff 2000000 --output combined ./interact-*.pep.xml

# Pick one from the following two commands and comment the other one.
# input: all interact-*.pep.xml, combined.prot.xml
$philosopherPath filter --sequential --razor --picked --ion 1 --pep 1 --pepProb 0 --prot 1 --protProb 0 --psm 1 --tag $decoyPrefix --pepxml ./ --protxml ./combined.prot.xml

# Make reports.
# output: ion.tsv, peptide.tsv, protein.tsv
$philosopherPath report
$philosopherPath workspace --clean --nocheck

rm -rf *.${rawtype}
rm -rf *.pepindex
rm -rf *.mgf
rm -rf *.pepXML
rm -rf *.pep.xml
rm -rf *.fasta.fas
