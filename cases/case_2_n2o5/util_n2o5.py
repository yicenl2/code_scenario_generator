# %%
import numpy as np
import math
# %% Subfunction
# %% Make spec file
def make_spec_restart(directory, scenario_num, matrix):
    f=open(directory+"/urban_plume_restart.spec", "r+")
    flist=f.readlines()   
   
    # modify the matrix here
    flist[32] = "do_n2o5_hydrolysis " + "yes" + "          # whether to do n2o5 hydrolysis (yes/no) \n"
    print("do_n2o5_hydrolysis " + "yes")    

    flist[33] = "n2o5_hydrolysis " + "particle" + "            # which n2o5 hydrolysis treatment \n"
    print("n2o5_hydrolysis " + "particle")    

    f=open(directory+"/urban_plume_restart.spec", "w+")
    f.writelines(flist)
    f.close()

