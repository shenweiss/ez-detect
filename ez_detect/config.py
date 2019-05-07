#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#import pdb ;pdb.set_trace() 
from multiprocessing import Value
import matlab.engine
import os
from pathlib import Path
import platform

IS_RUNNING = False
PROGRESS = 0
START_TIME_DEFAULT = 0
STOP_TIME_DEFAULT = 0  #If not given by user, this value is corrected once read the eeg.
CYCLE_TIME_DEFAULT = 600 #600 seconds = 10 minutes

DESIRED_FREC_HZ = 2000
BLOCK_MIN_DUR = 100 #In seconds

#MONTAGE CONSTANTS
REFERENTIAL = 1
BIPOLAR = 0
NO_BP_REF = 0
EXCLUDE_CH = 1
DONT_EXCLUDE_CH = 0

MP_ANNOTATIONS_FLAG = 0 
BP_ANNOTATIONS_FLAG = 1
        
#Working paths

paths = {}
paths['trc_fname']= "NOT_GIVEN"
paths['project_root'] = str( Path(Path.home(), 'ez-detect'))
paths['disk_dumps'] = str( Path(paths['project_root'], 'disk_dumps')) + '/'

TEMPORARY_DUE_TRANSLATION = str( Path(paths['disk_dumps'], 'temp_pythonToMatlab_dsp/bad_chans_args_'))

paths['xml_output_path'] = str( Path(paths['disk_dumps'], 'xml_output/xml_out.evt'))
paths['swap_array_file'] = "NOT_GIVEN"

paths['ez_top_in'] = str( Path(paths['disk_dumps'], 'ez_top/input')) + '/'
paths['ez_top_out'] = str( Path(paths['disk_dumps'], 'ez_top/output')) + '/'
paths['ez_pac_out'] = str( Path(paths['disk_dumps'], 'ez_pac_output')) + '/'

paths['research'] = str( Path(paths['disk_dumps'], 'research_matfiles')) + '/'

paths['cudaica_dir'] = str( Path(paths['project_root'], 'ez_detect/matlab_code/cudaica')) + '/'
paths['binica_sc'] = str( Path(paths['cudaica_dir'], 'binica.sc'))
paths['cudaica_bin'] = str( Path(paths['cudaica_dir'], 'cudaica'))
paths['misc_code'] = str( Path(paths['project_root'], 'ez_detect/matlab_code/misc_code')) + '/'
paths['temp_pythonToMatlab_dsp'] = str(Path(paths['disk_dumps'], 'temp_pythonToMatlab_dsp')) + '/'

def resolvePath(path_str):
    return str(Path(path_str).expanduser().resolve())

def getAllPaths(trc_fname, xml_output_path, project_dir_path=paths['project_root'], 
                                             swap_array_path=paths['swap_array_file']):
    paths['trc_fname']= resolvePath(trc_fname)
    paths['project_root']= resolvePath(project_dir_path)
    paths['xml_output_path']= str(Path(xml_output_path).expanduser().absolute())
    if paths['swap_array_file'] != "NOT_GIVEN":
        paths['swap_array_file'] = resolvePath(swap_array_path)

    return paths

#Cleans previous execution outputs
#TODO use a function to avoid executing this in each import
def clean_previous_execution():
    cwd = os.getcwd()
    os.chdir(paths['disk_dumps']) 
    running_os = platform.system()
    if running_os == 'Windows':
        os.system('clean') 
    elif running_os == 'Linux':
        os.system('./clean.sh') 
    os.chdir(cwd)

def get_matlab_session():
    cwd = os.getcwd()
    os.chdir(paths['misc_code']) #to find tryAddPaths
    matlab_session = matlab.engine.start_matlab() 
    matlab_session.tryAddPaths(paths['project_root'], nargout=0) #for program method lookups
    os.chdir(cwd)
    return matlab_session

class ProgressNotifier(object):
    def __init__(self):
        self.progress = Value('i', 0)

    def get(self):
        with self.progress.get_lock():
            return self.progress.value
   
    def delete(self):
        with self.progress.get_lock():
            del self

    def update(self, val):
        with self.progress.get_lock():
            self.progress.value = val
