#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#import pdb ;pdb.set_trace() 
from multiprocessing import Value
import matlab.engine
import os
from pathlib import Path
import platform

PROJECT_ROOT = Path(__file__).resolve().parent.parent

#CUDAICA constraint, detection needs a the parallel blocks to be bigger than a constraint
#TODO find this constraint experimentally
MIN_BLOCK_SNDS = 100 #The minimum acceptable size in seconds for a parallel block


#Working paths

TRC_EXTENSION = 'TRC'
EVT_EXTENSION = 'evt'
EDF_EXTENSION = 'edf'

def file_extension(filename):
    try:
        return filename.rsplit('.', 1)[1]
    except IndexError:
        raise ValueError('There is no extension in filename ' + filename)


#TODO remove endings + /
def get_working_paths(trc_fname, evt_fname, saf_fname):
    paths = {}
    project_root = PROJECT_ROOT
    disk_dumps = Path(project_root, 'disk_dumps')

    #Fix trc_fname
    try:
        trc_path = Path(trc_fname).expanduser().resolve()
        assert(file_extension( str(trc_path) ) == TRC_EXTENSION)
    except Exception:
        raise ValueError('The provided trc file is not valid')


    #Fix evt_fname
    default_evt_fname = "{fname}.{ext}".format(fname=trc_path.stem, ext=EVT_EXTENSION)
    if evt_fname is None :
        evt_path = Path(disk_dumps, 'evt_output', default_evt_fname)
    else:
        evt_path = Path(evt_fname).expanduser().absolute()

    try:
        assert(file_extension(str(evt_path)) == EVT_EXTENSION)
        assert(evt_path.parent.is_dir())
    except Exception:
        raise ValueError('The provided evt saving path is not valid.')

    #Fix saf_fname
    saf_path = 'NOT_GIVEN' if saf_fname is None else Path(saf_fname).expanduser().resolve()

    #Build needed path dict
    paths['disk_dumps'] = str(disk_dumps)
    paths['trc_fname'] = str(trc_path)
    paths['evt_fname'] = str(evt_path)
    paths['saf_fname'] = str(saf_path)

    cudaica_dir = Path(project_root, 'ez_detect/matlab_code/cudaica')
    paths['cudaica_bin'] = str(Path(cudaica_dir, 'cudaica'))
    paths['binica_sc'] = str(Path(cudaica_dir, 'binica.sc'))

    paths['ez_top_in'] = str( Path(disk_dumps, 'ez_top/input'))
    paths['ez_top_out'] = str( Path(disk_dumps, 'ez_top/output'))
    paths['ez_pac_out'] = str( Path(disk_dumps, 'ez_pac_output'))
    paths['ez_bad_nn_in'] = str(Path(paths['disk_dumps'], 'temp_pythonToMatlab_dsp/bad_chans_args_'))

    paths['research'] = str( Path(disk_dumps, 'research_matfiles'))

    return paths


#Cleans previous execution outputs
def clean_previous_execution():
    cwd = os.getcwd()
    disk_dumps = str(Path(PROJECT_ROOT, 'disk_dumps'))
    os.chdir(disk_dumps)
    running_os = platform.system()
    if running_os == 'Windows':
        os.system('clean') 
    elif running_os == 'Linux':
        os.system('./clean.sh') 
    os.chdir(cwd)

def get_matlab_session():
    cwd = os.getcwd()
    misc_code_path = Path(PROJECT_ROOT, 'ez_detect/matlab_code/misc_code')
    os.chdir(str(misc_code_path)) #to find tryAddPaths
    matlab_session = matlab.engine.start_matlab() 
    matlab_session.tryAddPaths(str(PROJECT_ROOT), nargout=0) #for program method lookups
    os.chdir(cwd)
    return matlab_session


#UI progress notifier

IS_RUNNING = False
PROGRESS = 0

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
