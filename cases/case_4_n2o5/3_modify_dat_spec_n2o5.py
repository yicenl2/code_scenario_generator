import numpy as np
import datetime
import util_n2o5

total_scenario = int(input("Please confirm the total number of scenarios:\n"))
#total_scenario = 5
print("The total number of scenarios is:", total_scenario)

# %%
oldtime=datetime.datetime.now()
for scenario_num in range(total_scenario):
    directory = "./scenarios/scenario_" +  str(scenario_num).zfill(4)
    matrix = np.loadtxt(directory+"/matrix_"+str(scenario_num).zfill(4)+".txt")
    print("*******************")
    print("Start scenario",str(scenario_num).zfill(4))
    print("Load matrix:",directory+"/matrix_"+str(scenario_num).zfill(4)+".txt")
       
    util_n2o5.make_spec_restart(directory, scenario_num, matrix)
    print("Completed scenario",str(scenario_num).zfill(4))
    print("\n")
    
newtime=datetime.datetime.now() 
print("The runtime is:",newtime-oldtime)

# %% write joblist script

N_SCENARIOS = total_scenario 
LIB_DIR = "scenarios/"
SCENARIO_PREFIX = "scenario"

joblist = open("joblist", 'w')
for ii in range(N_SCENARIOS):
   dir = "%s%s_%04i" %(LIB_DIR, SCENARIO_PREFIX, ii)
   script = '1_run.sh'
   joblist.write("%s %s\n" % (dir, script))
joblist.close()
