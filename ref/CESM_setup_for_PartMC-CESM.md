# CESM setup for PartMC-CESM

[TOC]

## Bash commands

We use `cesm2.1.1` as an example 

```bash
cd ~/cesm/cime/scripts
# create a new case
./create_newcase --case ~/cases/F09_2011 --compset FHIST --res f09_f09_mg17 --project UIUC0021
#./create_newcase --case ~/cases/F19_2011 --compset FHIST --res f19_f19_mg17 --project UIUC0021 --run-unsupported

# setup case
cd ~/cases/F09_2011
# cd ~/cases/F19_2011
./case.setup

./xmlchange STOP_N=1,STOP_OPTION=nmonths
./xmlchange RESUBMIT=24
./xmlchange RUN_STARTDATE=2011-01-01

./xmlchange PROJECT=UIUC0021
./xmlchange --subgroup case.run JOB_QUEUE=regular
./xmlchange --subgroup case.st_archive JOB_QUEUE=regular
./xmlchange --subgroup case.run JOB_WALLCLOCK_TIME=6:00:00
./xmlchange --subgroup case.st_archive JOB_WALLCLOCK_TIME=1:00:00

# see detail of "user_nl_cam" below
vi user_nl_cam

# build the case
qcmd -A UIUC0021 -q regular -- ./case.build
# submit the case
./case.submit
```

## user_nl_cam

```bash
! Users should add all user specific namelist changes below in the form of
! namelist_var = new_namelist_value
nhtfrq=0,-3
mfilt=1,8
fincl2='T:I','RELHUM:I','SZA:I','SOAG_SRF:I','DMS_SRF:I','H2SO4_SRF:I','O3:I','H2O2_SRF:I','SO2_SRF:I','bc_a1_SRF:I','bc_a4_SRF:I','dst_a1_SRF:I','dst_a2_SRF:I','dst_a3_SRF:I','ncl_a1_SRF:I','ncl_a2_SRF:I','ncl_a3_SRF:I','pom_a1_SRF:I','pom_a4_SRF:I','so4_a1_SRF:I','so4_a2_SRF:I','so4_a3_SRF:I','soa_a1_SRF:I','soa_a2_SRF:I'
```

