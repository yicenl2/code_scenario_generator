import xarray as xr
import pandas as pd
import numpy as np
import gc
import time
import sys
from tqdm import tqdm


"""
# How to run this code? For scenario 0000 to 0029

python extract_mixing_state.py train_0 29
"""


def multi_scenarios(job_id, sc_number_start, sc_number_end, time_length):
    vari_ls = []
    p1 = "/data/keeling/a/zzheng25/d/partmc-simulations/"
    p2 = ".bw/scenarios/scenario_"
    p3 = "/out/urban_plume_mixing_state_new.nc"
    
    for i in tqdm(range(sc_number_start, sc_number_end+1)):
        sc_id = "%04i" %i  #define the file number
        print("scenario id:", sc_id)
        
        # get mixing state metrics
        msm_nc = xr.open_dataset(p1+job_id+p2+sc_id+p3)
        msm = msm_nc[['chi_hyg','chi_opt1','chi_opt2',
                      'chi_opt3','chi_abd']].to_dataframe().reset_index()
        
        vari_ls.append(msm)
        
        del msm_nc, msm
        gc.collect()
        
    # concat the df from different scenarios    
    df_final = pd.concat(vari_ls).reset_index(drop=True) 
    
    return df_final
    
job_id = sys.argv[1]
csv_name = sys.argv[2]
sc_number_start_type = int(sys.argv[3])
sc_number_end_type = int(sys.argv[4])
df = multi_scenarios(job_id, sc_number_start=sc_number_start_type, sc_number_end=sc_number_end_type, time_length=25)
df.to_csv("/data/keeling/a/zzheng25/d/partmc-mam4/mixing_state_indices_from_PartMC/"+csv_name+".csv",index=False)
