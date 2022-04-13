PartMC-CESM Scenario Generator
=================

## Introduction

This repository is a supplementary to the manuscript **"Submicron Aerosol Mixing State Estimate at Global Scale with Machine Learning and Earth System Modeling"** for the submission to *Journal of Advances in Modeling Earth Systems*.

The purpose of this project is to using [**Latin hypercube sampling** (**LHS**)](https://en.wikipedia.org/wiki/Latin_hypercube_sampling) to create scenarios for **[Particle-resolved Monte Carlo (PartMC)](http://lagrange.mechse.illinois.edu/partmc/)** version 2.5.0.

We used NCSA-Blue Waters' computing environment as an example to demonstrate the key steps.

## **Prerequisite**

```bash
# Create your own conda/python environment
# For Blue Waters:
module load bwpy
pip install pyDOE datetime pandas xarray
```

## To use this repo:
### Step 1
```python
python 1_create_LHS_matrix.py
```
Here you need to type the total number of scenarios that you want to generate

### Step 2
```python
python 2_modify_dat_spec.py
```
Again, here you need to confrim the total number of scenarios that you want to deal with

### Step 3
```bash
cd Scheduler
ftn -o scheduler.x scheduler.F90
mv scheduler.x ..
### For keeling
mpif90 -o scheduler.x scheduler.F90
```
Create the scheduler.x

### Step 4
- modify **"partmc_schedulerx.pbs"**
```bash
cp src/partmc_schedulerx.pbs .
  - modify "#PBS -l nodes=1:ppn=32:xe"
export case=case1
export scenario_num_plus_1=6 
```

### Step 5
```bash
qsub partmc_schedulerx.pbs
qstat -u $USER
```

### Step 6
```bash
module load bwpy
```
```python
python s_bw_process.py job_id csv_name end_scenario
#python s_bw_process.py "10539590" "case_3_200" 199
```

## Cases Information    
***w/o sea salt***    
Action (within the case):<br>
1.modify "1_create_LHS_matrix" (RH_min, RH_max, Latitude_min, Latitude_max, and **ss** relevant copies)<br>
2.modify "gas_back.dat"<br>
3.modify "2_modify_dat_spec.py"  
```python
# assume there are no sea salt and DMS
util.modify_aero_emit_dist(directory, matrix, ss_option=None, dust_option=True)
util.modify_gas_emit(directory, matrix, DMS_option=None))
#util.modify_aero_emit_comp_ss1(directory, matrix)
#util.modify_aero_emit_comp_ss2(directory, matrix)
```
|                      | With sea salt          |  Without sea salt                  |
| -------------------- | -----------------------| -----------------------------------|
| **Latitude**         | [-89.999, 89.999]      |  [-69.999, 69.999]                 |
| **Relative humidty** | [0.4, 0.999]           |  [0.1, 0.999]                      |
| **DMS concentration (ppb)** (gas_back.dat)  |5.0E-01 |  No                         |
| **DMS emissions (mol m^{-2} s^{-1})** (gas_emit.dat)  |3.756E-11 |  No             |

***w/o dust***     
Action:<br>
1.modify "1_create_LHS_matrix" (RH_min, RH_max, Latitude_min, Latitude_max, and **dust** relevant copies)<br>
2.modify "2_modify_dat_spec.py"  

```python
# assume there are no dust, but sea salt
util.modify_aero_emit_dist(directory, matrix, ss_option=True, dust_option=None)
```
**Cases/Scenarios Distribution**

|                  | 2/3 with sea salt          |  1/3 without sea salt              |
| ---------------- | ---------------------------| -----------------------------------|
| **2/3 with dust**    | case_1 (4/9)           |  case_2 (2/9)                     |
| **1/3 without dust** | case_3 (2/9)           |  case_4 (1/9)                     |

## Acknowledgement

This research is part of the Blue Waters sustained-petascale computing project, which is supported by the National Science Foundation (awards OCI-0725070 and ACI-1238993) the State of Illinois, and as of December, 2019, the National Geospatial-Intelligence Agency. Blue Waters is a joint effort of the University of Illinois at Urbana-Champaign and its National Center for Supercomputing Applications.

