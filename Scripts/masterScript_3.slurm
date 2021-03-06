#!/bin/bash

        #Helikar Lab, University of Nebraska, Lincoln  copyright 2016
        #Developed by Greyson Biegert and Akram Mohammed
        #GPL-3.0

#SBATCH --time=23:00:00         # Run time in hh:mm:ss
#SBATCH --mem=60000             # Minimum memory required per CPU (in megabytes)
#SBATCH --job-name=MasterScript3
#SBATCH --error=/home/general/data/CancerDiscover/Outputs/job.%J.err
#SBATCH --output=/home/general/data/CancerDiscover/Outputs/job.%J.out

start=$(date +%s)
#this script constitutes the third leg of the pipeline, from feature selection outputs to model training and testing.
cd /home/general/data/CancerDiscover/Scripts

#making chunk files by parsing the output files from feature selection
perl chunkMaker.pl &
wait

#selecting thresholds of the ranked list of features
bash thresholdSelector_pc.bash &
wait

#removal of empty files
bash emptyFileRemover.bash &
wait

#Matching lists of ranked features with associated data (expressionSet matricies)
perl trainThresholdMaker.pl &
wait

#removal of empty files
bash emptyFileRemover.bash &
wait

#Splitting the data and head sections
perl processingBeforeTransposing2.pl &
wait

#Head section completion
perl preprocessingContinued2.pl &

#Data matrix transposition
perl transposer2.pl &
wait

#Addition of class variables
perl sampleNumberClassPaster2.pl &
wait

#each piece of the arrf is compiled into single file, with the correct orientation
perl concatenationTRAIN2.pl &
wait

#data partitioning
perl dataPartitioning2.pl Configuration.txt &
wait

#model training
sbatch trainModels.slurm &
wait

#model testing
sbatch testModels.slurm &
wait

#Results Summarization
bash resultsSummaryMaker.bash &
wait

#this script resets the DataFiles directory, placing data from the recently run experiment(s) in the CompletedExperiments directory followed by a timestamp and creating a new DataFiles directory
bash cleanSlate.bash

end=$(date +%s)
runTime=$((end-start))
echo $runTime>../Logs/runTime_ms3SLURM.txt
