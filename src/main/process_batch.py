'''
To call this function all arguments are required. hfo_annotate handles that 
setting and argument parsing.

Input semantic:
    
    - paths: a Struct containing strings for every path is used in the project. 
      It is set in hfo_annotate and it includes paths.trc_fname which is the 
      file to work with, saving directories, etc.
    
    - start_time: a number in seconds indicating from when, relative to the file 
      duration, do you want to analize the eeg.
    
    - stop_time: a number in seconds indicating up to when, relative to the file 
      duration, do you want to analize the eeg.
      
      For example if you want to process the last 5 minutes of an eeg of 20 
      minutes you would use as input start_time = 15*60 = 900 and 
      stop_time = 20*60 = 1200.
    
    - cycle_time: a number in seconds indicating the size of the blocks to cut 
      the data in blocks. This improves time performance since it can be 
      parallelized. Example: 300 (5 minutes)
    
    - swapping data: a struct containing the channel swapping flag (1:yes, 0:no)
      (in case that channels were incorrectly assigned in the original EDF file 
      as can be the case for intraop recordings) and the swap_array that can be
      used to correct the channel assignments.

    - matlab: matlab session to call matlab functions. It will be removed later.
 
 Output: DSP monopolar/bipolar outputs as matfiles get saved in the corresponding
 working directory indicated in the argument 'paths'.
'''
from os.path import basename, splitext
from config import matlab_session as matlab
from trcio import read_raw_trc
import scipy.io
import threading #ask if we will use threads or processes
import multiprocessing
import numpy as np

def process_batch(paths, start_time, stop_time, cycle_time):
    print('Running EZ_Detect v7.0 Putou')

    raw_trc = read_raw_trc(paths['trc_fname'], preload=True, include=None)
    print('TRC file loaded')
    
    data_filename = splitext(basename(paths['trc_fname']))[0] 
    
    sampling_rate = int(raw_trc.info['sfreq'])
    print('Sampling rate: ' + str(sampling_rate) +'Hz')
    
    #Note: the resampling was beeing made after getting the data and for each channel(process_batch.m)
    #so file pointers were being calculated with old sampling rate before, 
    #this may affect performance, especially if you want just a piece of the trc.
    #also npad='auto' may be faster cause gets to the next power of two size with padding
    #but may affect data quality introducing artifacts, this depends on the data.
    desired_hz = 2000
    if sampling_rate != desired_hz:
        print('Resampling data to 2000Hz')
        raw_trc.resample(desired_hz, npad="auto") 
        sampling_rate = int(raw_trc.info['sfreq'])


    print('Sampling rate: ' + str(round(sampling_rate)) +'Hz')

    number_of_channels = raw_trc.info['nchan']  
    print("Number of channels " + str(number_of_channels))
    chanlist = getChanlist(raw_trc.info['ch_names'], paths['swap_array_file'])
    
    eeg = raw_trc.get_data() 
    samples_num = len(eeg[0]) 
    file_pointers = getFilePointers(sampling_rate, start_time, stop_time, cycle_time, samples_num)
    blocks = calculateBlocksAmount(file_pointers, sampling_rate)    
    
    #Note need to add patch that limits second cycle if < 60 seconds. %ask what is this
    eeg_data, metadata = computeEEGSegments(file_pointers, data_filename,  #TODO put this inside processParallel to avoid loading to memory until thread starts
                                            blocks, raw_trc)
    print('Finished creating eeg_data blocks')

    #saveResearchData(paths['research'], blocks, metadata, eeg_data, chanlist, data_filename)
    montage = scipy.io.loadmat(paths['montages']+ data_filename +'_montage')['montage'] #analize if this works as expected
    #montage = matlab.load(paths['montages']+ data_filename +'_montage')['montage'] #analize if this works as expected

    useThreads = True
    if useThreads:
        processParallelBlocks_threads(blocks, eeg_data, chanlist, metadata, montage, paths)
    else:
        processParallelBlocks_processes(blocks, eeg_data, chanlist, metadata, montage, paths)

############  Local Funtions  #########

def getChanlist(chan_names, swap_array_file):
    
    chan_names = np.array(chan_names ,dtype=object) #for compatibility, for matlab engine to know conversion into cell array

    if swap_array_file != 'NOT_GIVEN':
        swap_array = matlab.load(swap_array_file)
        chan_names = [chan_names[i-1] for i in swap_array] 

    return chan_names

def getFilePointers(sampling_rate, start_time, stop_time, cycle_time, samples_num):
    #We will adopt [....) range convention
    file_pointers = {}

    #start_time_default is 1, meaning the first second
    seconds_to_jump = start_time-1
    file_pointers['start'] = seconds_to_jump*sampling_rate
    
    stop_time_default = 0 #to be moved to main
    if stop_time == stop_time_default:
        file_pointers['end'] = samples_num
    else:
        file_pointers['end'] = int(stop_time*sampling_rate)
    
    file_pointers['block_size'] = cycle_time*sampling_rate
    file_pointers['samples_num'] = samples_num
    return file_pointers

def calculateBlocksAmount(file_pointers, sampling_rate):
    images_number = file_pointers['end']-file_pointers['start']+1
    full_blocks = int(images_number/file_pointers['block_size'])
    images_remaining = images_number % file_pointers['block_size']
    seconds_remaining = int(images_remaining/sampling_rate)
    #Ask about this later.
    blocks = full_blocks+1 if seconds_remaining > 100 else full_blocks
    
    return blocks

def computeEEGSegments(file_pointers, data_filename, blocks, raw_trc):
    base_pointer = file_pointers['start']
    stop_pointer = file_pointers['end']
    block_size = file_pointers['block_size']
    eeg_data = []
    metadata = []
    
    for i in range(blocks):
        blocks_done = i
        block_start_ptr = base_pointer+blocks_done*block_size
        block_stop_ptr = min(block_start_ptr+block_size, stop_pointer)
        #block_data = [ channel[block_start_ptr:block_stop_ptr] for channel in raw_trc]
        block_data = raw_trc.get_data(start=block_start_ptr, stop=block_stop_ptr) 
        metadata_i = {'file_id':data_filename, 'file_block':str(i+1)}
        
        eeg_data.append(block_data)
        metadata.append(metadata_i)
    
    #later log(size(metadata), metadatam, size(eeg_data))
    return eeg_data, metadata

def saveResearchData(contest_path, metadata, eeg_data, chanlist):
    matlab.workspace['chanlist'] = chanlist
    for i in range(len(metadata)):
        matlab.workspace['eeg_data_i'] = eeg_data[i]
        matlab.workspace['metadata_i'] = metadata[i]
        data_filename = metadata.file_id
        full_path = contest_path+data_filename+'_'+str(i)+'.mat' 
        matlab.save(full_path, 'metadata_i', 'eeg_data_i', 'chanlist')
        #ask if it is worthy to save the blocks or not

def processParallelBlocks_threads(blocks, eeg_data, chanlist, metadata, montage, paths):
    
    threads = []
    
    def startBlockThread(i):
        thread = threading.Thread(target=processParallelBlock, name='DSP_block_'+str(i),
                 args=(eeg_data[i], chanlist, metadata[i], montage, paths))
        thread.start()
        threads.append(thread)
        return
    print("amount of blocks " + str(blocks))
    for i in range(blocks-1): #this launches a thread for all but the last block
        print('Starting a thread')
        
        startBlockThread(i)

    # Use main thread for last block
    print('Starting last thread')
    startBlockThread(blocks-1)

    # Wait for all threads to complete
    for t in threads:
        t.join()

def processParallelBlocks_processes(blocks, eeg_data, chanlist, metadata, montage, paths):
    
    #ask pool vs independent processes
    def multi_run_wrapper(args):
      return processParallelBlock(*args)

    pool = Pool(blocks)
    arg_list = [(eeg_data[i], chanlist, metadata[i], montage, paths) for i in range(blocks)]
    pool.map(multi_run_wrapper, arg_list)
    pool.close()
    pool.join()

def processParallelBlock(eeg_data, chanlist, metadata, ez_montage, paths):    
    
    #matlab.engine doesnt support np arrays...
    #sol 1 save as matfile using scipy.io.savemat('test.mat', dict(x=x, y=y))
    args_fname = paths['temp_pythonToMatlab_dsp']+'lfbad_args_'+metadata['file_block']+'.mat' 
    #print("eeg_data: "+str(type(eeg_data)) + "shape "+ str(eeg_data.shape))
    #print("chanlist: "+str(type(chanlist)) + "shape "+ str(chanlist.shape)+ "type "+ str(chanlist.dtype.name))
    #print("metadata: "+str(type(metadata)))
    #print("ez_montage: "+str(type(ez_montage))+ "shape "+ str(ez_montage.shape) + "type "+ str(ez_montage.dtype.name))
    scipy.io.savemat(args_fname, dict(eeg_data=eeg_data, chanlist=chanlist, metadata=metadata, ez_montage=ez_montage))

    [eeg_mp, eeg_bp, metadata] = matlab.ez_lfbad(args_fname, nargout=3)
    metadata.montage = ez_montage;

    mp_updated_vars = monopolarAnnotations(eeg_mp, eeg_bp, metadata, paths)

    bipolarAnnotations(mp_updated_vars, paths)

def monopolarAnnotations(eeg_mp, eeg_bp, metadata, paths):
        
    if eeg_mp: #not empty
        
        print('Starting dsp monopolar')
        dsp_monopolar_out = matlab.ez_detect_dsp_monopolar(eeg_mp, eeg_bp, 
                                                           metadata, paths) 
        print('Finished dsp bipolar')
        if dsp_monopolar_output['error_flag'] == 0: 
            montage = 0
            output_fname = matlab.eztop_putou_e1(dsp_monopolar_out['DSP_data_m'], 
                                                 dsp_monopolar_out['metadata'], 
                                                 montage, 
                                                 paths)
            matlab.ez_detect_annotate_e1(output_fname, 
                                         dsp_monopolar_out['num_trc_blocks'], 
                                         montage, 
                                         paths, 
                                         nargout=0)
            matlab.ezpac_putou70_e1(dsp_monopolar_out['ez_mp'], 
                                    dsp_monopolar_out['ez_fr_mp'], 
                                    dsp_monopolar_out['ez_hfo_mp'], 
                                    output_fname,
                                    dsp_monopolar_out['metadata'],
                                    montage,
                                    paths, 
                                    nargout=0)
        else:
            print('Error in process_dsp_output, error_flag != 0');

        output = {'eeg_bp' : dsp_monopolar_out['ez_bp'],
                'metadata' : dsp_monopolar_out['metadata'],
                'hfo_ai' : dsp_monopolar_out['hfo_ai'],
                'fr_ai' : dsp_monopolar_out['fr_ai']}
    else:  #eeg_mp is empty
        
        output = {'eeg_bp' : eeg_bp,
                'metadata' : metadata,
                'hfo_ai' : np.zeros(len(eeg_bp[0])),
                'fr_ai' : hfo_ai}

    return output

def bipolarAnnotations(mp_updated_vars, paths):

    if eeg_bp:
        
        print('Starting bipolar dsp block')
        dsp_bipolar_out = matlab.ez_detect_dsp_bipolar(mp_updated_vars['eeg_bp'], 
                                                          mp_updated_vars['hfo_ai'], 
                                                          mp_updated_vars['fr_ai'], 
                                                          mp_updated_vars['metadata'], 
                                                          paths)
        print('Finished bipolar dsp block')
        print('Annotating bipolar block')
        montage = 1; 
        output_fname = matlab.eztop_putou_e1(dsp_bipolar_out['DSP_data_bp'],
                                             dsp_bipolar_out['metadata'],
                                             montage, 
                                             paths)
        
        matlab.ez_detect_annotate_e1(output_fname, 
                                     dsp_bipolar_out['num_trc_blocks'],
                                     montage, 
                                     paths, 
                                     nargout=0)

        matlab.ezpac_putou70_e1(dsp_bipolar_out['ez_bp'], 
                                dsp_bipolar_out['ez_fr_bp'], 
                                dsp_bipolar_out['ez_hfo_bp'], 
                                output_fname, 
                                dsp_bipolar_out['metadata'], 
                                montage, 
                                paths, nargout=0)

        print('Finished annotating bipolar block')
    else:
        print("Didn't enter dsp bipolar, eeg_bp was empty")

