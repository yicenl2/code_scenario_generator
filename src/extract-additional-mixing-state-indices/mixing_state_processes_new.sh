#!/bin/sh

# exit on error
set -e
# turn on command echoing
set -v

# run the postprocessing 
/data/keeling/a/zzheng25/partmc/build/mixing_state_processes_new &> mixing_state_processes_new.log

