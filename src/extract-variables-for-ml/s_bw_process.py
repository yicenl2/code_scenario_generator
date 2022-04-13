import xarray as xr
import pandas as pd
import numpy as np
import gc
import time
import sys

# extract the aero mixing state from the partmc processed output
def get_aero_data(job_id, sc_id):
    p1 = "/u/sciteam/zheng1/scratch/"
    p2 = ".bw/scenarios/scenario_"
    p3 = "/out/urban_plume_variables_s.nc"
    aero_nc = xr.open_dataset(p1+job_id+p2+sc_id+p3)
    aero_df = aero_nc[["tot_so4_conc", "tot_no3_conc", "tot_cl_conc", "tot_nh4_conc", "tot_msa_conc",
        "tot_aro1_conc", "tot_aro2_conc", "tot_alk1_conc", "tot_ole1_conc", "tot_api1_conc",
        "tot_api2_conc", "tot_lim1_conc", "tot_lim2_conc", "tot_co3_conc", "tot_na_conc",
        "tot_ca_conc", "tot_oin_conc", "tot_oc_conc", "tot_bc_conc", "tot_h2o_conc"]].to_dataframe().reset_index()
    
    aero_df["Mass_so4"] = aero_df["tot_so4_conc"]
    aero_df["Mass_bc"] = aero_df["tot_bc_conc"]
    aero_df["Mass_ncl"] = aero_df["tot_na_conc"]+aero_df["tot_cl_conc"]
    #aero_df["Mass_ncl"] = aero_df["tot_na_conc"]+aero_df["tot_cl_conc"]+aero_df["tot_so4_conc"]
    aero_df["Mass_dst"] = aero_df["tot_oin_conc"]
    aero_df["Mass_pom"] = aero_df["tot_oc_conc"]
    aero_df["Mass_soa"] = aero_df["tot_aro1_conc"]+aero_df["tot_aro2_conc"]+aero_df["tot_alk1_conc"]+aero_df["tot_ole1_conc"]+aero_df["tot_api1_conc"]+aero_df["tot_api2_conc"]+aero_df["tot_lim1_conc"]+aero_df["tot_lim2_conc"]
    
    return aero_df[["Mass_so4", "Mass_bc", "Mass_ncl", "Mass_dst", "Mass_pom",
                    "Mass_soa", "time"]]

# extract the environmental variables and gas species from partmc raw output
def single_scenario(job_id, sc_id, time_length):
    p1 = "/u/sciteam/zheng1/scratch/"
    p2 = ".bw/scenarios/scenario_"
    p3 = "/out/urban_plume_0001_"
    
    # define the lists
    time_ls = []
    rh_ls = []
    gas_ls = []
    temperature_ls = []
    sza_ls = []
    lat_ls = []
    
    file_ls = []
    sc_ls = []
    # define the flag for gas species
    gas_name_flag = True

    for i in range(1,1+time_length):
        file = "%08i" %i  #define the file number
        print(p1+job_id+p2+sc_id+p3+file+".nc")
        ds = xr.open_dataset(p1+job_id+p2+sc_id+p3+file+".nc")
        
        sc_ls.append(sc_id)
        file_ls.append(file)
        
        time_ls.append(np.array(ds["time"]))
        rh_ls.append(np.array(ds["relative_humidity"]))
        temperature_ls.append(np.array(ds["temperature"]))
        sza_ls.append(np.array(ds["solar_zenith_angle"]))
        lat_ls.append(np.array(ds["latitude"]))
        gas_ls.append(ds.gas_mixing_ratio.to_pandas())

        if gas_name_flag:
            gas_names_ls = ds.gas_species.names.split(",")
            gas_name_flag = False

        del ds
        gc.collect()

    df = pd.concat(gas_ls,axis=1).transpose().reset_index().drop(['index'],axis=1)
    df.columns = gas_names_ls
    
    df["sc_id"] = sc_ls
    df["time_id"] = file_ls
    df["time"] = np.array(time_ls)
    df["RELHUM"] = rh_ls
    df["T"] = temperature_ls
    df["SZA"] = sza_ls
    df["lat"] = lat_ls

    
    df["SOAG_SRF"] = (df["ARO1"]+df["ARO2"]+df["ALK1"]+df["OLE1"]+df["API1"]+df["API2"]+df["LIM1"]+df["LIM2"])*1e-9
    df["DMS_SRF"] =  df["DMS"] * 1e-9 
    df["H2SO4_SRF"] =  df["H2SO4"] * 1e-9 
    df["H2O2_SRF"] = df["H2O2"] * 1e-9  
    df["SO2_SRF"] = df["SO2"] * 1e-9 
    df["O3_SRF"] = df["O3"] * 1e-9

    
    df_final = df[["sc_id", "time_id", "time",
                   "SOAG_SRF", "DMS_SRF", "H2SO4_SRF", "O3_SRF", "H2O2_SRF", "SO2_SRF", 
                   "T", "RELHUM", "SZA", "lat"]]
    
    return df_final

def multi_scenarios(job_id, sc_number_start, sc_number_end, time_length):
    vari_ls = []
    p1 = "/u/sciteam/zheng1/scratch/"
    p2 = ".bw/scenarios/scenario_"
    p3 = "/out/urban_plume_mixing_state_s.nc"
    
    for i in range(sc_number_start, sc_number_end+1):
        sc_id = "%04i" %i  #define the file number
        print("scenario id:", sc_id)
        
        # get mixing state metrics
        msm_nc = xr.open_dataset(p1+job_id+p2+sc_id+p3)
        msm = msm_nc[['chi_hyg','chi_opt1','chi_opt2','chi_abd']].to_dataframe().reset_index()
        
        # get environmental and gas variables
        gas_env = single_scenario(job_id, sc_id, time_length)
        print("\n")
        
        # get aero variables
        aero = get_aero_data(job_id, sc_id)
        
        # merge environmental, gas, and mixing state metrics within scenario
        gas_env_msm = pd.merge(gas_env, msm, how = "left", on = "time")
        gas_env_msm_aero = pd.merge(gas_env_msm, aero, how = "left", on = "time")
        
        vari_ls.append(gas_env_msm_aero)
        
        del msm_nc, msm, gas_env, aero, gas_env_msm, gas_env_msm_aero
        gc.collect()
        
    # concat the df from different scenarios    
    df_final = pd.concat(vari_ls).reset_index() 
    
    return df_final.drop("index", axis=1)
    
job_id = sys.argv[1]
csv_name = sys.argv[2]
sc_number_end_type = int(sys.argv[3])
df = multi_scenarios(job_id, sc_number_start=0, sc_number_end=sc_number_end_type, time_length=25)
df.to_csv("/u/sciteam/zheng1/scratch/"+csv_name+".csv",index=False)


# how to use:
# python s_bw_process.py job_id csv_name end_scenario
# for example
# python s_bw_process.py "10539590" "case_3_200" 199
