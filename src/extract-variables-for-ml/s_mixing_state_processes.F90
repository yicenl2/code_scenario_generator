! Processing script for Zhonghua 

!> file
!> Read NetCDF output files and process them.

program s_process_mixing_state

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
  real(kind=dp) :: time, del_t 
  
  !!!!!!!!!!!!!!!!The mixing state metrics !!!!!!!!!!!!!!!
  real(kind=dp) :: d_alpha_hyg, d_gamma_hyg, chi_hyg, &
                   d_alpha_opt1, d_gamma_opt1, chi_opt1, &
                   d_alpha_opt2, d_gamma_opt2, chi_opt2, &
                   d_alpha, d_gamma, chi_abd

  !!!!!!!!!!!!!!!!The aerosol species !!!!!!!!!!!!!!!
  real(kind=dp), allocatable :: times(:), dry_diameters_ref(:)

  !!!!!!!!!!!!!!!!The aerosol species !!!!!!!!!!!!!!!
  type(stats_1d_t) :: stats_chi_hyg, stats_chi_opt1, stats_chi_opt2, &
                      stats_chi_abd 
  
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

      !> Read in mixing state based on hygroscopicity
      call aero_state_mixing_state_metrics(aero_state, aero_data, &
           d_alpha_hyg, d_gamma_hyg, chi_hyg, exclude=(/"H2O"/), & 
           group=(/"BC ", "OC ", "OIN"/))
      call stats_1d_add_entry(stats_chi_hyg, chi_hyg, i_index)

      !> Read in mixing state of optical properties based on BC
      call aero_state_mixing_state_metrics(aero_state, aero_data, &
           d_alpha_opt1, d_gamma_opt1, chi_opt1, exclude=(/"H2O"/), group=(/"BC "/))
      call stats_1d_add_entry(stats_chi_opt1, chi_opt1, i_index)

      !> Read in mixing state of optical properties based on BC
      call aero_state_mixing_state_metrics(aero_state, aero_data, &
           d_alpha_opt2, d_gamma_opt2, chi_opt2, exclude=(/"H2O"/), group=(/"BC ","OIN"/))
      call stats_1d_add_entry(stats_chi_opt2, chi_opt2, i_index)

      !< Read in mixing state based on chemical species, i.e. not grouping anything.
      call aero_state_mixing_state_metrics(aero_state, aero_data, &
           d_alpha, d_gamma, chi_abd, exclude=(/"H2O"/))
      call stats_1d_add_entry(stats_chi_abd, chi_abd, i_index)

      end do
  end do
    

  !> Output all variables in netcdf format
  call make_filename(out_filename, prefix, "_mixing_state.nc")
  write(*,*) "Writing " // trim(out_filename)
  call pmc_nc_open_write(out_filename, ncid)
  call pmc_nc_write_info(ncid, uuid, "mixing_state")
  call pmc_nc_write_real_1d(ncid, times, "time", dim_name="time", unit="s")

  call stats_1d_output_netcdf(stats_chi_hyg, ncid, 'chi_hyg', &
         dim_name="time", unit="1")
  call stats_1d_output_netcdf(stats_chi_opt1, ncid, 'chi_opt1', &
         dim_name="time", unit="1")
  call stats_1d_output_netcdf(stats_chi_opt2, ncid, 'chi_opt2', &
         dim_name="time", unit="1")
  call stats_1d_output_netcdf(stats_chi_abd, ncid, 'chi_abd', &
         dim_name="time", unit="1")    

  call pmc_nc_close(ncid)

  call stats_1d_clear(stats_chi_hyg)
  call stats_1d_clear(stats_chi_opt1)
  call stats_1d_clear(stats_chi_opt2)
  call stats_1d_clear(stats_chi_abd)

  
  call pmc_mpi_finalize()

end program s_process_mixing_state
