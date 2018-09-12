'''
To call this function all arguments are required. hfo_annotate handles that 
setting and argument parsing.

Input semantic:
    
    - paths: a Struct containing strings for every path is used in the project. 
      It is set in hfo_annotate and it includes paths.edf_dataset which is the 
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
import scipy.io
import threading #ask if we will use threads or processes
import multiprocessing
import numpy as np

def process_batch(paths, start_time, stop_time, cycle_time):
    print('Running EZ_Detect v7.0 Putou')

    #Note that this edf_load version modified to read max 60 minutes of EEG due to memory constraints.
    header, signal_header, eeg_edf = matlab.edf_load(paths['edf_dataset'], nargout=3)
    print('EDF file loaded')
    #eeg_edf_tall = matlab.tall(eeg_edf) #to be removed
    #matlab.clear('eeg_edf', nargout=0) #to be removed
    
    data_filename = splitext(basename(paths['edf_dataset']))[0] 
    sampling_rate = float(header.srate)
    #print(['Sampling rate: ' str(round(sampling_rate)) 'Hz']);
    #number_of_channels = matlab.gather(numel(eeg_edf_tall(:,1)))   
    number_of_channels = len(eeg_edf)   
    chanlist = getChanlist(number_of_channels, signal_header, paths['swap_array_file'])
    
    #file_size = matlab.gather(numel(eeg_edf_tall(1,:))) 
    file_size = len(eeg_edf[0]) 
    file_pointers = getFilePointers(sampling_rate, start_time, stop_time, cycle_time, file_size)
    
    blocks = calculateBlocksAmount(file_pointers, sampling_rate)    
    #Note need to add patch that limits second cycle if < 60 seconds. %ask what is this
    eeg_data, metadata = computeEEGSegments(file_pointers, data_filename, sampling_rate,
                                            number_of_channels, blocks, eeg_edf)
    print('Finished creating eeg_data blocks')

    #saveResearchData(paths['research'], blocks, metadata, eeg_data, chanlist, data_filename)
    montage = scipy.io.loadmat(paths['montages']+ data_filename +'_montage')['montage'] #analize if this works as expected

    useThreads = True
    if useThreads:
        processParallelBlocks_threads(blocks, eeg_data, chanlist, metadata, montage, paths)
    else
        processParallelBlocks_processes(blocks, eeg_data, chanlist, metadata, montage, paths)

############  Local Funtions  #########

def getChanlist(number_of_channels, signal_header, swap_array_file):
    chanlist={}
    for j in range(1,number_of_channels+1):
        chanlist{j} = signal_header(j).signal_labels
    
    if swap_array_file != 'NOT_GIVEN':
        swap_array = scipy.io.loadmat(swap_array_file)
        chanlist = [chanlist[i-1] for i in swap_array] 

    return chanlist

def getFilePointers(sampling_rate, start_time, stop_time, cycle_time, file_size):
    file_pointers = {}

    #start_time_default is 1, meaning the first second
    seconds_to_jump = start_time-1
    file_pointers['start'] = seconds_to_jump*sampling_rate + 1 
    
    stop_time_default = 0 #to be moved to main
    if stop_time == stop_time_default
        file_pointers['end'] = file_size
    else
        file_pointers['end'] = stop_time*sampling_rate
    
    file_pointers['block_size'] = cycle_time*sampling_rate
    file_pointers['file_size'] = file_size
    return file_pointers

def calculateBlocksAmount(file_pointers, sampling_rate):
    images_number = file_pointers['end']-file_pointers['start']+1
    full_blocks = int(images_number/file_pointers['block_size'])
    images_remaining = images_number % file_pointers['block_size']
    seconds_remaining = int(images_remaining/sampling_rate)
    #Ask about this later.
    blocks = full_blocks+1 if seconds_remaining > 100 else full_blocks
    
    return blocks

def computeEEGSegments(file_pointers, data_filename, sampling_rate, 
                          number_of_channels, blocks, eeg_edf):
    desired_hz = 2000
    base_pointer = file_pointers['start']
    stop_pointer = file_pointers['end']
    block_size = file_pointers['block_size']
    eeg_data = []
    metadata = []
    for i in range(blocks):
        blocks_done = i
        block_start_ptr = base_pointer+blocks_done*block_size
        block_stop_ptr = min(block_start_ptr+block_size-1, stop_pointer)

        block_data = eeg_edf(:,block_start_ptr:block_stop_ptr) #to be done
        block_data = resampleData(sampling_rate, desired_hz, number_of_channels, block_data)
        metadata_i = {'file_id':data_filename, 'file_block':str(i+1)}
        
        eeg_data.append(block_data)
        metadata.append(metadata_i)
    
    #later log(size(metadata), metadatam, size(eeg_data))
    return eeg_data, metadata


def  resampleData(sampling_rate, desired_hz, number_of_channels, eeg_data):
    #Resample Data to 2khz required.
    if sampling_rate != desired_hz:
        p,q = matlab.rat(desired_hz/sampling_rate, nargout=2)
        print('Resampling the Data to ' +str(desired_hz/1000) +'KHz')
        for j in range(number_of_channels):
            eeg_data[j] = matlab.resample(eeg_data[j],p,q)
        
        print('Resampled: '+ str(number_of_channels) +' data channels.')

    return eeg_data

def saveResearchData(contest_path, metadata, eeg_data, chanlist):
    matlab.workspace['chanlist'] = chanlist
    for i in range(len(metadata)):
        matlab.workspace['eeg_data_i'] = eeg_data[i]
        matlab.workspace['metadata_i'] = metadata[i]
        data_filename = metadata.file_id
        full_path = contest_path+data_filename+'_'+str(i)+'.mat' 
        matlab.save(full_path, 'metadata_i', 'eeg_data_i', 'chanlist')
        #ask if it is worthy to save the blocks or not

# This function performs dsp processing cutting data in chunks and using
# parallelized computing. This improves time performance corresponding to dsp processing. 

def processParallelBlock(eeg_data, chanlist, metadata, ez_montage, paths):    
    
    #refactor this function below later  FIX THIS
    [matlab.workspace['ez_tall_m'], matlab.workspace['ez_tall_bp'], metadata] = matlab.ez_lfbad(ez_tall, 
                                                                chanlist, metadata, ez_montage, nargout=3)

    metadata.montage = ez_montage;
    montage_names = {'monopolar':'MONOPOLAR', 'bipolar':'BIPOLAR'}

    if matlab.(~isempty(gather(ez_tall_m))):
        
        print('Starting dsp '+montage_names['monopolar']);
        dsp_monopolar_output = matlab.ez_detect_dsp_monopolar(matlab.workspace['ez_tall_m'], 
                                                              matlab.workspace['ez_tall_bp'], 
                                                              metadata, paths);
        print('Finished dsp '+montage_names['monopolar'])

        #fix this
        #ez_tall_bp = dsp_monopolar_output.ez_tall_bp;
        #hfo_ai = dsp_monopolar_output.hfo_ai;
        #fr_ai = dsp_monopolar_output.fr_ai;
        #metadata = dsp_monopolar_output.metadata;
        saveDSPOutput(montage_names['monopolar'], montage_names, dsp_monopolar_output, metadata['file_block'], paths)
    else 
        hfo_ai = np.zeros(len(ez_bp[0]))
        fr_ai = hfo_ai

    if matlab.(~isempty(gather(ez_tall_bp)))
        
        print('Starting dsp '+ montage_names['bipolar'])
        dsp_bipolar_output = matlab.ez_detect_dsp_bipolar(ez_tall_bp, hfo_ai, fr_ai, metadata, paths);
        print('Finished dsp '+ montage_names['bipolar'])
        saveDSPOutput(montage_names['bipolar'], montage_names, dsp_bipolar_output, metadata['file_block'], paths)
    else
        print("Didnt enter dsp bipolar, ez_tall_bp was empty")


def saveDSPOutput(montage_name, montage_names, dsp_output, file_block, paths):

    print('Saving dsp '+montage_name+' output.')
    
    if montage_name == montage_names['monopolar']:
        
        out_filename = ['dsp_m_output_' file_block '.mat']
        saving_directory = paths.dsp_monopolar_out
    
    elif montage_name == montage_names['bipolar']
        
        out_filename = ['dsp_bp_output_' file_block '.mat'];
        saving_directory = paths.dsp_bipolar_out;
    
    else print("Unkown montage_name.")
    
    matlab.save(saving_directory+out_filename, '-struct', 'dsp_output')
    print('Dsp '+ montage_name '+ output was saved.')

def processParallelBlocks_threads(blocks, eeg_data, chanlist, metadata, montage, paths):
    
    threads = []
    
    def launchBlockThread(i):
        thread = threading.Thread(target=processParallelBlock, 
                 args=(eeg_data[i], chanlist, metadata[i], montage, paths))
        thread.start()
        threads.append(thread)
        return

    for i in range(blocks-1): #this launches a thread for all but the last block
        launchBlockThread(i)

    # Use main thread for last block
        launchBlockThread(blocks)

    # Wait for all threads to complete
    for t in threads:
        t.join()

def processParallelBlocks_processes(blocks, eeg_data, chanlist, metadata, montage, paths):
    
    #ask pool vs independent processes
    def multi_run_wrapper(args):
      return processParallelBlock(*args)

    pool = Pool(blocks)
    arg_list = [(eeg_data[i], chanlist, metadata[i], montage,paths) for i in range(blocks)]
    pool.map(multi_run_wrapper, arg_list)
    pool.close()
    pool.join()