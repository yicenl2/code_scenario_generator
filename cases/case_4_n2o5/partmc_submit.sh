#!/bin/bash
#SBATCH --job-name=PartMCScenarioGen1
#SBATCH -n 101
#SBATCH -p sesempi 
#SBATCH --time=24:00:00
#SBATCH --mem-per-cpu=4000
# Email if failed run
#SBATCH --mail-type=FAIL
# Email when finished
#SBATCH --mail-type=END
# My email address
#SBATCH --mail-user=yicenl2@illinois.edu
export case=case_4_n2o5
export scenario_num_plus_1=101
#export SLURM_SUBMIT_DIR  = /data/keeling/a/yicenl2/d/project_n2o5/code_scenario_generator/cases/case_4_n2o5 
# The job script can create its own job-ID-unique directory 
# to run within.  In that case you'll need to create and populate that 
# directory with executables and inputs
mkdir -p /data/keeling/a/yicenl2/d/project_n2o5/scenario_libs/$SLURM_JOB_ID
cd /data/keeling/a/yicenl2/d/project_n2o5/scenario_libs/$SLURM_JOB_ID
export PMC_PATH=/data/keeling/a/yicenl2/d/project_n2o5/partmc
cp -r $PMC_PATH/build build
cp -r $PMC_PATH/src src
# Copy the scenario directory that holds all the inputs files
cp -r $SLURM_SUBMIT_DIR/scenarios .

# Copy things to run this job
# Need the scheduler and the joblist

cp $SLURM_SUBMIT_DIR/scheduler.x .
cp $SLURM_SUBMIT_DIR/joblist .

# Run the library. One core per job plus one for the master.
mpirun -np $scenario_num_plus_1 ./scheduler.x joblist /bin/bash -noexit -nostdout > log
