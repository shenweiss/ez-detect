
%Not too fancy because in future these should be arguments. 
%But at least now hardcoded paths are not everywhere in code anymore.
%If kept, should change to be a function with error flag, using exist to verify the paths existence

%Notes:
%Remember you will need to call this script for every matlab session you start
%Remember to use global 'var' for every new workspace(new function) in 
%the current matlab session where the variables are set.

%Please set here the following paths regarding your directory
display('Setting global paths...');

%Path where matlab is installed in your directory
%Note: Dont use ~ for paths cause cudaica.m fails.
global MATLAB_PATH;
MATLAB_PATH='/home/tomas-pastore/matlab/bin/matlab';

%Path to ez-detect project where matlab will 
%lookup to find definition for any function
%needed to run the program
global PROJECT_PATH;
PROJECT_PATH='/home/tomas-pastore/ez-detect/';

%Paths where the outputs are beeing saved
global HFO_ENGINE_PATH;
HFO_ENGINE_PATH=[PROJECT_PATH 'hfo_engine_1/'];

global MATFILES_PATH;
MATFILES_PATH=[HFO_ENGINE_PATH 'matfiles/'];

global MONTAGES_PATH;
MONTAGES_PATH=[HFO_ENGINE_PATH 'montages/'];

global EXECUTABLE_PATH;
TRC_OUT_PATH=[HFO_ENGINE_PATH 'executable/'];


global EZ_PAC_OUT_PATH;
EZ_PAC_OUT_PATH=[HFO_ENGINE_PATH 'ez_pac_out/'];

global EZ_TOP_IN_PATH;
EZ_TOP_IN_PATH=[HFO_ENGINE_PATH 'ez_top_in/'];

global EZ_TOP_OUT_PATH;
EZ_TOP_OUT_PATH=[HFO_ENGINE_PATH 'ez_top_out/'];


global MP_TEMP_TRC_PATH;
MP_TEMP_TRC_PATH=[HFO_ENGINE_PATH 'mp_temp_trc/'];

global BP_TEMP_TRC_PATH;
BP_TEMP_TRC_PATH=[HFO_ENGINE_PATH 'bp_temp_trc/'];

global TRC_OUT_PATH;
TRC_OUT_PATH=[HFO_ENGINE_PATH 'TRC_out/'];


global BINICA_SC_PATH;
BINICA_SC_PATH=[HFO_ENGINE_PATH 'binica.sc'];

global CUDAICA_BINARY_PATH;
CUDAICA_BINARY_PATH=[HFO_ENGINE_PATH 'cudaica'];

global CUDAICA_BINARY_DIR_PATH;
CUDAICA_BINARY_DIR_PATH= HFO_ENGINE_PATH;
