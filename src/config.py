#Global variables

import matlab.engine
    
#starts matlab session in current dir
matlab_session = matlab.engine.start_matlab() 

#Set paths used in the project
paths = {}
paths['hfo_engine']= paths['project_root']+'hfo_engine_1/'
paths['dsp_monopolar_out']= paths['hfo_engine']+'dsp_output/monopolar/'
paths['dsp_bipolar_out']= paths['hfo_engine']+'dsp_output/bipolar/'

paths['ez_pac_out']= paths['hfo_engine']+'ez_pac_output/'
paths['ez_top_in']= paths['hfo_engine']+'ez_top/input/'
paths['ez_top_out']= paths['hfo_engine']+'ez_top/output/'

paths['montages']= paths['hfo_engine']+'montages/'
paths['research']= paths['hfo_engine']+'research_matfiles/'
paths['executable']= paths['hfo_engine']+'executable/'

paths['trc_out']= paths['hfo_engine']+'trc/output/'
paths['trc_tmp_monopolar']= paths['hfo_engine']+'trc/temp/monopolar/'
paths['trc_tmp_bipolar']= paths['hfo_engine']+'trc/temp/bipolar/'

paths['cudaica_dir']= paths['project_root']+'/src/cudaica/'
paths['binica_sc']= paths['cudaica_dir']+'binica.sc'
paths['cudaica_bin']= paths['cudaica_dir']+'cudaica'
paths['misc_code']= paths['project_root']+'tools/misc_code'

