! Processing script for Zhonghua 

!> file
!> Read NetCDF output files and process them.

program s_process_scenario_library

  use pmc_output
  use pmc_stats

  character(len=PMC_MAX_FILENAME_LEN), parameter :: prefix &
       = "out/urban_plume"

  character(len=PMC_MAX_FILENAME_LEN) :: in_filename, out_filename
  
  type(aero_data_t) :: aero_data
  type(aero_state_t) :: aero_state, aero_state_old
  type(env_state_t) :: env_state
  type(gas_state_t) :: gas_state
  type(gas_data_t) :: gas_data
  integer :: ncid, index, i_index, n_index, n_repeat, i_part, n_part, &
         i_sample, i_size, repeat, i_repeat
		 
  character(len=PMC_UUID_LEN) :: uuid

  !!!!!!!!!!!!!!!!The aerosol species !!!!!!!!!!!!!!!
  real(kind=dp) :: time, del_t, density, & 
       tot_so4_conc, tot_no3_conc, tot_cl_conc, &
       tot_nh4_conc, tot_msa_conc, tot_aro1_conc, &
       tot_aro2_conc, tot_alk1_conc, tot_ole1_conc, &
       tot_api1_conc, tot_api2_conc, tot_lim1_conc, &
       tot_lim2_conc, tot_co3_conc, tot_na_conc, &
       tot_ca_conc, tot_oin_conc, tot_oc_conc, &
       tot_bc_conc, tot_h2o_conc
  
  !!!!!!!!!!!!!!!!The mixing state metrics !!!!!!!!!!!!!!!
  real(kind=dp) :: d_alpha, d_gamma, chi

  !!!!!!!!!!!!!!!!The aerosol species !!!!!!!!!!!!!!!
  real(kind=dp), allocatable :: times(:), num_concs(:), &
       so4_masses(:), no3_masses(:), cl_masses(:), &
       nh4_masses(:), msa_masses(:), aro1_masses(:), &
       aro2_masses(:), alk1_masses(:), ole1_masses(:), &
       api1_masses(:), api2_masses(:), lim1_masses(:), &
       lim2_masses(:), co3_masses(:), na_masses(:), &
       ca_masses(:), oin_masses(:), oc_masses(:), &
       bc_masses(:), h2o_masses(:), &
	   dry_diameters_ref(:)

  !!!!!!!!!!!!!!!!The aerosol species !!!!!!!!!!!!!!!
  type(stats_1d_t) :: stats_chi, stats_den, & 
       stats_tot_so4_conc, stats_tot_no3_conc, stats_tot_cl_conc, &
       stats_tot_nh4_conc, stats_tot_msa_conc, stats_tot_aro1_conc, &
       stats_tot_aro2_conc, stats_tot_alk1_conc, stats_tot_ole1_conc, &
       stats_tot_api1_conc, stats_tot_api2_conc, stats_tot_lim1_conc, &
       stats_tot_lim2_conc, stats_tot_co3_conc, stats_tot_na_conc, &
       stats_tot_ca_conc, stats_tot_oin_conc, stats_tot_oc_conc, &
       stats_tot_bc_conc, stats_tot_h2o_conc
  
  character(len=100) :: var_name


  call pmc_mpi_init()
 
  call input_n_files(prefix, n_repeat, n_index)

  if (allocated(times)) deallocate(times)
  allocate(times(n_index))

  do i_index = 1,n_index
      do i_repeat = 1,n_repeat
      !write(*,*) i_index, prefix
      call make_filename(in_filename, prefix, ".nc", i_index, i_repeat)
      
	  write(*,*) "Processing " // trim(in_filename)
      
		      
	  call input_state(in_filename, index, time, del_t, repeat, &
	       uuid, aero_data=aero_data, aero_state=aero_state_old, &
	       gas_data=gas_data, gas_state=gas_state, env_state=env_state)
      
	  !!! New aero_state
	  dry_diameters_ref = aero_state_dry_diameters(aero_state_old, aero_data)
      call aero_state_zero(aero_state)
      call aero_state_copy_weight(aero_state_old, aero_state)
      do i_part = 1,size(dry_diameters_ref)
         if (dry_diameters_ref(i_part)<=1.0d-6) then
           call aero_state_add_particle(aero_state, &
                aero_state_old%apa%particle(i_part),aero_data)
         end if
      end do	   
		   
      !!!! Time
      times(i_index) = time
      
      !!!  Density
      density = env_state_air_den(env_state)
      call stats_1d_add_entry(stats_den,density,i_index)

      !!!  Number concentration
      num_concs = aero_state_num_concs(aero_state, aero_data)

      !!!  1. SO4
      so4_masses = aero_state_masses(aero_state, aero_data, &
           include=(/"SO4"/))
      tot_so4_conc = sum(so4_masses*num_concs)
      call stats_1d_add_entry(stats_tot_so4_conc, tot_so4_conc, i_index)


      !!!  2. NO3
      no3_masses = aero_state_masses(aero_state, aero_data, &
           include=(/"NO3"/))
      tot_no3_conc = sum(no3_masses*num_concs)
      call stats_1d_add_entry(stats_tot_no3_conc, tot_no3_conc, i_index)

      !!!  3. Cl
      cl_masses = aero_state_masses(aero_state, aero_data, &
           include=(/"Cl"/))
      tot_cl_conc = sum(cl_masses*num_concs)
      call stats_1d_add_entry(stats_tot_cl_conc, tot_cl_conc, i_index)

      !!!  4. NH4
      nh4_masses = aero_state_masses(aero_state, aero_data, &
           include=(/"NH4"/))
      tot_nh4_conc = sum(nh4_masses*num_concs)
      call stats_1d_add_entry(stats_tot_nh4_conc, tot_nh4_conc, i_index)

      !!!  5. MSA
      msa_masses = aero_state_masses(aero_state, aero_data, &
           include=(/"MSA"/))
      tot_msa_conc = sum(msa_masses*num_concs)
      call stats_1d_add_entry(stats_tot_msa_conc, tot_msa_conc, i_index)

      !!!  6. ARO1
      aro1_masses = aero_state_masses(aero_state, aero_data, &
           include=(/"ARO1"/))
      tot_aro1_conc = sum(aro1_masses*num_concs)
      call stats_1d_add_entry(stats_tot_aro1_conc, tot_aro1_conc, i_index)

      !!!  7. ARO2
      aro2_masses = aero_state_masses(aero_state, aero_data, &
           include=(/"ARO2"/))
      tot_aro2_conc = sum(aro2_masses*num_concs)
      call stats_1d_add_entry(stats_tot_aro2_conc, tot_aro2_conc, i_index)

      !!!  8. ALK1
      alk1_masses = aero_state_masses(aero_state, aero_data, &
           include=(/"ALK1"/))
      tot_alk1_conc = sum(alk1_masses*num_concs)
      call stats_1d_add_entry(stats_tot_alk1_conc, tot_alk1_conc, i_index)

      !!!  9. OLE1
      ole1_masses = aero_state_masses(aero_state, aero_data, &
           include=(/"OLE1"/))
      tot_ole1_conc = sum(ole1_masses*num_concs)
      call stats_1d_add_entry(stats_tot_ole1_conc, tot_ole1_conc, i_index)

      !!!  10. API1
      api1_masses = aero_state_masses(aero_state, aero_data, &
           include=(/"API1"/))
      tot_api1_conc = sum(api1_masses*num_concs)
      call stats_1d_add_entry(stats_tot_api1_conc, tot_api1_conc, i_index)

      !!!  11. API2
      api2_masses = aero_state_masses(aero_state, aero_data, &
           include=(/"API2"/))
      tot_api2_conc = sum(api2_masses*num_concs)
      call stats_1d_add_entry(stats_tot_api2_conc, tot_api2_conc, i_index)

      !!!  12. LIM1
      lim1_masses = aero_state_masses(aero_state, aero_data, &
           include=(/"LIM1"/))
      tot_lim1_conc = sum(lim1_masses*num_concs)
      call stats_1d_add_entry(stats_tot_lim1_conc, tot_lim1_conc, i_index)

      !!!  13. LIM2
      lim2_masses = aero_state_masses(aero_state, aero_data, &
           include=(/"LIM2"/))
      tot_lim2_conc = sum(lim2_masses*num_concs)
      call stats_1d_add_entry(stats_tot_lim2_conc, tot_lim2_conc, i_index)

      !!!  14. CO3
      co3_masses = aero_state_masses(aero_state, aero_data, &
           include=(/"CO3"/))
      tot_co3_conc = sum(co3_masses*num_concs)
      call stats_1d_add_entry(stats_tot_co3_conc, tot_co3_conc, i_index)

      !!!  15. Na
      na_masses = aero_state_masses(aero_state, aero_data, &
           include=(/"Na"/))
      tot_na_conc = sum(na_masses*num_concs)
      call stats_1d_add_entry(stats_tot_na_conc, tot_na_conc, i_index)

      !!!  16. Ca
      ca_masses = aero_state_masses(aero_state, aero_data, &
           include=(/"Ca"/))
      tot_ca_conc = sum(ca_masses*num_concs)
      call stats_1d_add_entry(stats_tot_ca_conc, tot_ca_conc, i_index)

      !!!  17. OIN
      oin_masses = aero_state_masses(aero_state, aero_data, &
           include=(/"OIN"/))
      tot_oin_conc = sum(oin_masses*num_concs)
      call stats_1d_add_entry(stats_tot_oin_conc, tot_oin_conc, i_index)

      !!!  18. OC
      oc_masses = aero_state_masses(aero_state, aero_data, &
           include=(/"OC"/))
      tot_oc_conc = sum(oc_masses*num_concs)
      call stats_1d_add_entry(stats_tot_oc_conc, tot_oc_conc, i_index)

      !!!  19. BC
      bc_masses = aero_state_masses(aero_state, aero_data, &
           include=(/"BC"/))
      tot_bc_conc = sum(bc_masses*num_concs)
      call stats_1d_add_entry(stats_tot_bc_conc, tot_bc_conc, i_index)

      !!!  20. H2O
      h2o_masses = aero_state_masses(aero_state, aero_data, &
           include=(/"H2O"/))
      tot_h2o_conc = sum(h2o_masses*num_concs)
      call stats_1d_add_entry(stats_tot_h2o_conc, tot_h2o_conc, i_index)


      !> Read in mixing state variables
      call aero_state_mixing_state_metrics(aero_state, aero_data, &
           d_alpha, d_gamma, chi, exclude=(/"H2O"/), group=(/"BC ", "OC ", "OIN"/))
      call stats_1d_add_entry(stats_chi, chi, i_index)
      end do
  end do
    

  !> Output all variables in netcdf format
  call make_filename(out_filename, prefix, "_variables.nc")
  write(*,*) "Writing " // trim(out_filename)
  call pmc_nc_open_write(out_filename, ncid)
  call pmc_nc_write_info(ncid, uuid, "variables")
  call pmc_nc_write_real_1d(ncid, times, "time", dim_name="time", unit="s")

  call stats_1d_output_netcdf(stats_chi, ncid, 'chi', &
         dim_name="time", unit="1")
  call stats_1d_output_netcdf(stats_den, ncid, "density", &
         dim_name="time", unit="kg m^-3")

  call stats_1d_output_netcdf(stats_tot_so4_conc, ncid, 'tot_so4_conc', &
         dim_name="time", unit="kg m^-3")
  call stats_1d_output_netcdf(stats_tot_no3_conc, ncid, 'tot_no3_conc', &
         dim_name="time", unit="kg m^-3")
  call stats_1d_output_netcdf(stats_tot_cl_conc, ncid, 'tot_cl_conc', &
         dim_name="time", unit="kg m^-3")
  call stats_1d_output_netcdf(stats_tot_nh4_conc, ncid, 'tot_nh4_conc', &
         dim_name="time", unit="kg m^-3")
  call stats_1d_output_netcdf(stats_tot_msa_conc, ncid, 'tot_msa_conc', &
         dim_name="time", unit="kg m^-3")
  call stats_1d_output_netcdf(stats_tot_aro1_conc, ncid, 'tot_aro1_conc', &
         dim_name="time", unit="kg m^-3")
  call stats_1d_output_netcdf(stats_tot_aro2_conc, ncid, 'tot_aro2_conc', &
         dim_name="time", unit="kg m^-3")
  call stats_1d_output_netcdf(stats_tot_alk1_conc, ncid, 'tot_alk1_conc', &
         dim_name="time", unit="kg m^-3")
  call stats_1d_output_netcdf(stats_tot_ole1_conc, ncid, 'tot_ole1_conc', &
         dim_name="time", unit="kg m^-3")
  call stats_1d_output_netcdf(stats_tot_api1_conc, ncid, 'tot_api1_conc', &
         dim_name="time", unit="kg m^-3")
  call stats_1d_output_netcdf(stats_tot_api2_conc, ncid, 'tot_api2_conc', &
         dim_name="time", unit="kg m^-3")
  call stats_1d_output_netcdf(stats_tot_lim1_conc, ncid, 'tot_lim1_conc', &
         dim_name="time", unit="kg m^-3")
  call stats_1d_output_netcdf(stats_tot_lim2_conc, ncid, 'tot_lim2_conc', &
         dim_name="time", unit="kg m^-3")
  call stats_1d_output_netcdf(stats_tot_co3_conc, ncid, 'tot_co3_conc', &
         dim_name="time", unit="kg m^-3")
  call stats_1d_output_netcdf(stats_tot_na_conc, ncid, 'tot_na_conc', &
         dim_name="time", unit="kg m^-3")
  call stats_1d_output_netcdf(stats_tot_ca_conc, ncid, 'tot_ca_conc', &
         dim_name="time", unit="kg m^-3")
  call stats_1d_output_netcdf(stats_tot_oin_conc, ncid, 'tot_oin_conc', &
         dim_name="time", unit="kg m^-3")
  call stats_1d_output_netcdf(stats_tot_oc_conc, ncid, 'tot_oc_conc', &
         dim_name="time", unit="kg m^-3")
  call stats_1d_output_netcdf(stats_tot_bc_conc, ncid, 'tot_bc_conc', &
         dim_name="time", unit="kg m^-3")
  call stats_1d_output_netcdf(stats_tot_h2o_conc, ncid, 'tot_h2o_conc', &
         dim_name="time", unit="kg m^-3")

  call pmc_nc_close(ncid)

  call stats_1d_clear(stats_chi)
  call stats_1d_clear(stats_den)
  call stats_1d_clear(stats_tot_so4_conc)
  call stats_1d_clear(stats_tot_no3_conc)
  call stats_1d_clear(stats_tot_cl_conc)
  call stats_1d_clear(stats_tot_nh4_conc)
  call stats_1d_clear(stats_tot_msa_conc)
  call stats_1d_clear(stats_tot_aro1_conc)
  call stats_1d_clear(stats_tot_aro2_conc)
  call stats_1d_clear(stats_tot_alk1_conc)
  call stats_1d_clear(stats_tot_ole1_conc)
  call stats_1d_clear(stats_tot_api1_conc)
  call stats_1d_clear(stats_tot_api2_conc)
  call stats_1d_clear(stats_tot_lim1_conc)
  call stats_1d_clear(stats_tot_lim2_conc)
  call stats_1d_clear(stats_tot_co3_conc)
  call stats_1d_clear(stats_tot_na_conc)
  call stats_1d_clear(stats_tot_ca_conc)
  call stats_1d_clear(stats_tot_oin_conc)
  call stats_1d_clear(stats_tot_oc_conc)
  call stats_1d_clear(stats_tot_bc_conc)
  call stats_1d_clear(stats_tot_h2o_conc)

  
  call pmc_mpi_finalize()

end program s_process_scenario_library
