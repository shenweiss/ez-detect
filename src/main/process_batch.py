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

 
 Output: DSP monopolar/bipolar outputs as matfiles get saved in the corresponding
 working directory indicated in the argument 'paths'.
'''
from os.path import basename, splitext
from config import matlab_session as MATLAB
from trcio import read_raw_trc
import scipy.io
import threading #ask if we will use threads or processes
import multiprocessing
import numpy as np
import matlab.engine
from os import listdir

#For the xml
from lxml import etree as eTree
import uuid
from datetime import datetime, tzinfo, timedelta

def process_batch(paths, start_time, stop_time, cycle_time):
    print('Running EZ_Detect v7.0 Putou')

    raw_trc = read_raw_trc(paths['trc_fname'], preload=True, include=None)
    print('TRC file loaded')
    
    #mont = raw_trc._raw_extras[0]['montages']

    #print(mont)


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
    
    header = raw_trc._raw_extras[0]
    rec_time = datetime( year = header['rec_year'], month= header['rec_month'],
                         day = header['rec_day'], hour = header['rec_hour'],
                         minute = header['rec_min'], second = header['rec_sec'])
    
    #print('Printing channel names')
    #print(raw_trc.info['ch_names'])
    chanlist = updateChanlist(raw_trc.info['ch_names'], paths['swap_array_file'])
    
    eeg = raw_trc.get_data() 
    samples_num = len(eeg[0]) 
    file_pointers = getFilePointers(sampling_rate, start_time, stop_time, cycle_time, samples_num)
    blocks = calculateBlocksAmount(file_pointers, sampling_rate)    
    
    #Note need to add patch that limits second cycle if < 60 seconds. %ask what is this
    eeg_data, metadata = computeEEGSegments(file_pointers, data_filename,  #TODO put this inside processParallel to avoid loading to memory until thread starts
                                            blocks, raw_trc)
    print('Finished creating eeg_data blocks')

    #saveResearchData(paths['research'], blocks, metadata, eeg_data, chanlist, data_filename)

    #TEMP SOLUTION UNTIL WE GET MONTAGE FROM TRC
    #montages .mat had 4 columns for each channel: 
    #column 1 : channel name
    #column 2: 1 if referential 0 if bipolar 
    #column 3: index of channel to substract if marked as bipolar in column 2
    #column 4: 1 to exclude this channel, 0 to take it.

    montage = generateMontage(chanlist)    
    #print(montage)

    xml_set_event_types(paths['xml_output_path'])

    useThreads = True
    if useThreads:
        processParallelBlocks_threads(blocks, eeg_data, chanlist, metadata, montage, paths, rec_time)
    else:
        processParallelBlocks_processes(blocks, eeg_data, chanlist, metadata, montage, paths, rec_time)

    for f in listdir(paths['ez_top_out']):
        if f != '.keep':
            xml_append_annotations(paths['xml_output_path'], output_fname, rec_time)

############  Local Funtions  #########

def updateChanlist(chan_names, swap_array_file):
    
    chan_names = np.array(chan_names ,dtype=object) #because of matlab engine limitations

    if swap_array_file != 'NOT_GIVEN':
        swap_array = MATLAB.load(swap_array_file)
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
    MATLAB.workspace['chanlist'] = chanlist
    for i in range(len(metadata)):
        MATLAB.workspace['eeg_data_i'] = eeg_data[i]
        MATLAB.workspace['metadata_i'] = metadata[i]
        data_filename = metadata.file_id
        full_path = contest_path+data_filename+'_'+str(i)+'.mat' 
        MATLAB.save(full_path, 'metadata_i', 'eeg_data_i', 'chanlist')
        #ask if it is worthy to save the blocks or not

def processParallelBlocks_threads(blocks, eeg_data, chanlist, metadata, montage, paths, rec_time):
    
    threads = []
    
    def startBlockThread(i):
        thread = threading.Thread(target=processParallelBlock, name='DSP_block_'+str(i),
                 args=(eeg_data[i], chanlist, metadata[i], montage, paths, rec_time))
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

def processParallelBlock(eeg_data, chanlist, metadata, ez_montage, paths, rec_time):    
    
    #matlab.engine doesnt support np arrays...
    #sol 1 save as matfile using scipy.io.savemat('test.mat', dict(x=x, y=y))
    args_fname = paths['temp_pythonToMatlab_dsp']+'lfbad_args_'+metadata['file_block']+'.mat' 
    scipy.io.savemat(args_fname, dict(eeg_data=eeg_data, chanlist=chanlist, metadata=metadata, ez_montage=ez_montage))

    eeg_mp, eeg_bp, metadata = MATLAB.ez_lfbad(args_fname, nargout=3)
    #metadata.montage is a cell array of 1 * n 

    eeg_bp, metadata, hfo_ai, fr_ai = monopolarAnnotations(eeg_mp, eeg_bp, metadata, paths, rec_time)

    bipolarAnnotations(eeg_bp, metadata, hfo_ai, fr_ai, paths, rec_time)

def monopolarAnnotations(eeg_mp, eeg_bp, metadata, paths, rec_time):
        
    if eeg_mp: #not empty
        
        print('Starting dsp monopolar block')
        #print("accepted type in linux")
        #print(str(type(eeg_mp)))
        #print(str(type(eeg_bp)))

        dsp_monopolar_out = MATLAB.ez_detect_dsp_monopolar(eeg_mp, eeg_bp, metadata, paths)

        print('Finished dsp monopolar block')
        if dsp_monopolar_out['error_flag'] == 0: 
            montage = 0
            output_fname = MATLAB.eztop_putou_e1(dsp_monopolar_out['DSP_data_m'], 
                                                 dsp_monopolar_out['metadata'], 
                                                 montage, 
                                                 paths)
            MATLAB.ez_detect_annotate_e1(output_fname, 
                                         dsp_monopolar_out['num_trc_blocks'], 
                                         montage, 
                                         paths, 
                                         nargout=0)
            

            MATLAB.ezpac_putou70_e1(dsp_monopolar_out['ez_mp'], 
                                    dsp_monopolar_out['ez_fr_mp'], 
                                    dsp_monopolar_out['ez_hfo_mp'], 
                                    output_fname,
                                    dsp_monopolar_out['metadata'],
                                    montage,
                                    paths, 
                                    nargout=0)
        else:
            print('Error in process_dsp_output, error_flag != 0')
        print("updating metadata")

        eeg_bp = dsp_monopolar_out['ez_bp']
        metadata = dsp_monopolar_out['metadata']
        hfo_ai = dsp_monopolar_out['hfo_ai']
        fr_ai = dsp_monopolar_out['fr_ai']
    
    else:  #eeg_mp is empty
        
        hfo_ai = np.zeros(len(eeg_bp[0])).tolist()
        fr_ai = hfo_ai
    
    return eeg_bp, metadata, hfo_ai, fr_ai 

def bipolarAnnotations(eeg_bp, metadata, hfo_ai, fr_ai, paths, rec_time):

    if eeg_bp:
        
        print('Starting bipolar dsp block')
        dsp_bipolar_out = MATLAB.ez_detect_dsp_bipolar(eeg_bp, metadata, hfo_ai, fr_ai, paths)
        print('Finished bipolar dsp block')
        print('Annotating bipolar block')
        montage = 1; 
        output_fname = MATLAB.eztop_putou_e1(dsp_bipolar_out['DSP_data_bp'],
                                             dsp_bipolar_out['metadata'],
                                             montage, 
                                             paths)
        
        MATLAB.ez_detect_annotate_e1(output_fname, 
                                     dsp_bipolar_out['num_trc_blocks'],
                                     montage, 
                                     paths, 
                                     nargout=0)
        

        MATLAB.ezpac_putou70_e1(dsp_bipolar_out['ez_bp'], 
                                dsp_bipolar_out['ez_fr_bp'], 
                                dsp_bipolar_out['ez_hfo_bp'], 
                                output_fname, 
                                dsp_bipolar_out['metadata'], 
                                montage, 
                                paths, nargout=0)

        print('Finished annotating bipolar block')
    else:
        print("Didn't enter dsp bipolar, eeg_bp was empty")

def generateMontage(chanlist):
    montage = []
    #Temp solution
    for chan in chanlist:
        #ref = int(chan_index+1) if chan_index % 10 == 1 else 0
        referential = int(1)
        no_matter = int(0)
        dont_exclude = int(0)
        chan_montage_info = tuple([chan, referential, no_matter, dont_exclude])
        montage.append(chan_montage_info)

    return np.array(montage,dtype=object)


#this is just to communicate matlab and python. Matlab engine doesn't support n*m arrays so I have to reshape to 1*n to
#avoid dumping to disk, what is too costly
#input : dictionary of variables
def restoreShapes(dic):
    print("Restoring shapes for matlab engine")    
    for k,v in dic.items():
        
        if isinstance(v,dict):
            dic[k] = restoreShapes(v)
        
        elif len(k) > len("_shape") and k[len(k)-6:len(k)] == "_shape": #if i find something that has been reshaped
            #restore
            print("restoring shape of "+ k)
            original_varname = k[0:len(k)-6] #cuts the _shape of the var name
            print(original_varname)
            print(str(type(dic[original_varname])))
            dic[original_varname].reshape((int(dic[k][0][0]),int(dic[k][0][1]))) 
        print("Done with reshapes")
    return dic


###XML FUNCTIONS, alpha?

def newGuidString():
    return str(uuid.uuid4())

def fixFormat(aDateTime):
    
    return aDateTime.strftime('%Y-%m-%dT%H:%M:%S') + aDateTime.strftime('.%f')[:7] + 'Z'

def xml_set_event_types(xml_filename):

    #move these defs to config.py
    HFO_CATEGORY_GUID = "27e2727f-e49d-4113-aa8c-4944ef8f2588"
    HFO_SUBCATEGORY_GUID = "c142e214-826e-4dfe-965a-110246492c9e"
    DEF_HFO_SPIKE_GUID = "bf513752-2cb7-43bc-93f5-370def800b93"
    DEF_HFO_RIPPLE_GUID = "167b6fad-f95a-4880-a9c6-968f468a1297"
    DEF_HFO_FASTRIPPLE_GUID = "e0a58c9c-b3c0-4a7d-a3c3-d3ed6a57dc3a"

    now = fixFormat(datetime.utcnow())  
    
    #puse un salto de linea por tab en el arbol xml para ordenar un poco
    root = eTree.Element("EventFile", Version="1.00", CreationDate=now, Guid=newGuidString() )
    
    evt_types = eTree.SubElement(root, "EventTypes")
    
    category = eTree.SubElement(evt_types, "Category", Name="HFO")
    
    eTree.SubElement(category, "Description").text = "HFO Category"
    eTree.SubElement(category, "IsPredefined").text = "true"
    eTree.SubElement(category, "Guid").text = HFO_CATEGORY_GUID
    subCategory = eTree.SubElement(category, "SubCategory", Name="HFO")
    
    eTree.SubElement(subCategory, "Description").text = "HFO Subcategory"
    eTree.SubElement(subCategory, "IsPredefined").text = "true"
    eTree.SubElement(subCategory, "Guid").text = HFO_SUBCATEGORY_GUID

    #TODO: create this abstraction below to remove the repetead code below
    #defineHFOType(subCategory, type_name, def_evt_guid, description, graph_argb_color)

    defHFOSpike = eTree.SubElement(subCategory, "Definition", Name="HFO Spike")
    
    eTree.SubElement(defHFOSpike, "Guid").text = DEF_HFO_SPIKE_GUID
    eTree.SubElement(defHFOSpike, "Description").text = "HFO Spike Event Definition"
    eTree.SubElement(defHFOSpike, "IsPredefined").text = "true"
    eTree.SubElement(defHFOSpike, "isDefinitionAdjustable").text = "false"
    eTree.SubElement(defHFOSpike, "CanInsert").text = "true"
    eTree.SubElement(defHFOSpike, "CanDelete").text = "true"
    eTree.SubElement(defHFOSpike, "CanUpdateText").text = "true"
    eTree.SubElement(defHFOSpike, "CanUpdatePosition").text = "true"
    eTree.SubElement(defHFOSpike, "CanReassign").text = "false"
    eTree.SubElement(defHFOSpike, "InsertionType").text = "ClickAndDrag"
    eTree.SubElement(defHFOSpike, "FixedInsertionDuration").text = "PT1S"
    eTree.SubElement(defHFOSpike, "TextType").text = "FromDefinitionDescription"
    eTree.SubElement(defHFOSpike, "ReferenceType").text = "SingleLine"
    eTree.SubElement(defHFOSpike, "DurationType").text = "Interval"
    eTree.SubElement(defHFOSpike, "TextArgbColor").text = "4294901760"
    eTree.SubElement(defHFOSpike, "GraphicArgbColor").text = "805306623"
    eTree.SubElement(defHFOSpike, "GraphicType").text = "FillRectangle"
    eTree.SubElement(defHFOSpike, "VisualizationType").text = "Graphic"
    eTree.SubElement(defHFOSpike, "FontFamily").text = "Segoe UI"
    eTree.SubElement(defHFOSpike, "FontSize").text = "11"
    eTree.SubElement(defHFOSpike, "FontItalic").text = "false"
    eTree.SubElement(defHFOSpike, "FontBold").text = "false"


    defHFORipple = eTree.SubElement(subCategory, "Definition", Name="HFO Ripple")
    
    eTree.SubElement(defHFORipple, "Guid").text = DEF_HFO_RIPPLE_GUID
    eTree.SubElement(defHFORipple, "Description").text = "HFO Ripple Event Definition"
    eTree.SubElement(defHFORipple, "IsPredefined").text = "true"
    eTree.SubElement(defHFORipple, "isDefinitionAdjustable").text = "false"
    eTree.SubElement(defHFORipple, "CanInsert").text = "true"
    eTree.SubElement(defHFORipple, "CanDelete").text = "true"
    eTree.SubElement(defHFORipple, "CanUpdateText").text = "true"
    eTree.SubElement(defHFORipple, "CanUpdatePosition").text = "true"
    eTree.SubElement(defHFORipple, "CanReassign").text = "false"
    eTree.SubElement(defHFORipple, "InsertionType").text = "ClickAndDrag"
    eTree.SubElement(defHFORipple, "FixedInsertionDuration").text = "PT1S"
    eTree.SubElement(defHFORipple, "TextType").text = "FromDefinitionDescription"
    eTree.SubElement(defHFORipple, "ReferenceType").text = "SingleLine"
    eTree.SubElement(defHFORipple, "DurationType").text = "Interval"
    eTree.SubElement(defHFORipple, "TextArgbColor").text = "4294901760"
    eTree.SubElement(defHFORipple, "GraphicArgbColor").text = "822018048"
    eTree.SubElement(defHFORipple, "GraphicType").text = "FillRectangle"
    eTree.SubElement(defHFORipple, "VisualizationType").text = "Graphic"
    eTree.SubElement(defHFORipple, "FontFamily").text = "Segoe UI"
    eTree.SubElement(defHFORipple, "FontSize").text = "11"
    eTree.SubElement(defHFORipple, "FontItalic").text = "false"
    eTree.SubElement(defHFORipple, "FontBold").text = "false"

    defHFOFripple = eTree.SubElement(subCategory, "Definition", Name="HFO FastRipple")
    
    eTree.SubElement(defHFOFripple, "Guid").text = DEF_HFO_FASTRIPPLE_GUID
    eTree.SubElement(defHFOFripple, "Description").text = "HFO FastRipple Event Definition"
    eTree.SubElement(defHFOFripple, "IsPredefined").text = "true"
    eTree.SubElement(defHFOFripple, "isDefinitionAdjustable").text = "false"
    eTree.SubElement(defHFOFripple, "CanInsert").text = "true"
    eTree.SubElement(defHFOFripple, "CanDelete").text = "true"
    eTree.SubElement(defHFOFripple, "CanUpdateText").text = "true"
    eTree.SubElement(defHFOFripple, "CanUpdatePosition").text = "true"
    eTree.SubElement(defHFOFripple, "CanReassign").text = "false"
    eTree.SubElement(defHFOFripple, "InsertionType").text = "ClickAndDrag"
    eTree.SubElement(defHFOFripple, "FixedInsertionDuration").text = "PT1S"
    eTree.SubElement(defHFOFripple, "TextType").text = "FromDefinitionDescription"
    eTree.SubElement(defHFOFripple, "ReferenceType").text = "SingleLine"
    eTree.SubElement(defHFOFripple, "DurationType").text = "Interval"
    eTree.SubElement(defHFOFripple, "TextArgbColor").text = "4294901760"
    eTree.SubElement(defHFOFripple, "GraphicArgbColor").text = "805371648"
    eTree.SubElement(defHFOFripple, "GraphicType").text = "FillRectangle"
    eTree.SubElement(defHFOFripple, "VisualizationType").text = "Graphic"
    eTree.SubElement(defHFOFripple, "FontFamily").text = "Segoe UI"
    eTree.SubElement(defHFOFripple, "FontSize").text = "11"
    eTree.SubElement(defHFOFripple, "FontItalic").text = "false"
    eTree.SubElement(defHFOFripple, "FontBold").text = "false"

    #Create Events label empty to append annotations later.
    events = eTree.SubElement(root, "Events")

    tree = eTree.ElementTree(root)
    tree.write(xml_filename, encoding="utf-8", xml_declaration=True, pretty_print=True)


def xml_append_annotations(xml_file, events_matfile, rec_time):

    #parti en 3 por si las variables que se cargan de matlab ocupan mucha memoria, despues vemos.
    append_spike_annotations(xml_file, events_matfile, rec_time)
    append_ripple_annotations(xml_file, events_matfile, rec_time)
    append_fripple_annotations(xml_file, events_matfile, rec_time)


def append_spike_annotations(xml_file, events_matfile, rec_time):
    
    parser = eTree.XMLParser(remove_blank_text=True)
    tree = eTree.parse(xml_file, parser)
    root = tree.getroot()
    events = scipy.io.loadmat(events_matfile, variable_names=["TRonS", "ftTRonS", "FRonS", "ftFRonS"])
    
    DEF_HFO_SPIKE_GUID = "bf513752-2cb7-43bc-93f5-370def800b93"
    spike_on_offset = - timedelta(seconds=0.02)
    spike_off_offset = + timedelta(seconds=0.01)
    now = fixFormat(datetime.utcnow())  #ver si quieren hacerlo mas preciso por evento.
    
    appendEventsOfKind('TRonS', events, rec_time, xml_file, tree, root, 
                        DEF_HFO_SPIKE_GUID, spike_on_offset, spike_off_offset, now)

    appendEventsOfKind('ftTRonS', events, rec_time, xml_file, tree, root, 
                        DEF_HFO_SPIKE_GUID, spike_on_offset, spike_off_offset, now)

    appendEventsOfKind('FRonS', events, rec_time, xml_file, tree, root, 
                        DEF_HFO_SPIKE_GUID, spike_on_offset, spike_off_offset, now)
    
    appendEventsOfKind('ftFRonS', events, rec_time, xml_file, tree, root, 
                        DEF_HFO_SPIKE_GUID, spike_on_offset, spike_off_offset, now)


def append_ripple_annotations(xml_file, events_matfile, rec_time):
    
    parser = eTree.XMLParser(remove_blank_text=True)
    tree = eTree.parse(xml_file, parser)
    root = tree.getroot()
    events = scipy.io.loadmat(events_matfile, variable_names=["RonO", "TRonS"])
    
    DEF_HFO_RIPPLE_GUID = "167b6fad-f95a-4880-a9c6-968f468a1297"
    ripple_on_offset = - timedelta(milliseconds=5)
    ripple_off_offset = + timedelta(milliseconds=5)
    now = fixFormat(datetime.utcnow())  
    
    appendEventsOfKind('RonO', events, rec_time, xml_file, tree, root, 
                        DEF_HFO_RIPPLE_GUID, ripple_on_offset, ripple_off_offset, now)

    #Warning, this kind below appeared also as spike annotation, ask if it is a bug.
    appendEventsOfKind('TRonS', events, rec_time, xml_file, tree, root, 
                        DEF_HFO_RIPPLE_GUID, ripple_on_offset, ripple_off_offset, now)

def append_fripple_annotations(xml_file, events_matfile, rec_time):
    
    parser = eTree.XMLParser(remove_blank_text=True)
    tree = eTree.parse(xml_file, parser)
    root = tree.getroot()
    events = scipy.io.loadmat(events_matfile, variable_names=["ftRonO", "ftTRonS"])
    
    DEF_HFO_FASTRIPPLE_GUID = "e0a58c9c-b3c0-4a7d-a3c3-d3ed6a57dc3a"
    fripple_on_offset = - timedelta(milliseconds=2.5)
    fripple_off_offset = + timedelta(milliseconds=2.5)
    now = fixFormat(datetime.utcnow())  
    
    appendEventsOfKind('ftRonO', events, rec_time, xml_file, tree, root, 
                        DEF_HFO_FASTRIPPLE_GUID, fripple_on_offset, fripple_off_offset, now)

    appendEventsOfKind('ftTRonS', events, rec_time, xml_file, tree, root, 
                        DEF_HFO_FASTRIPPLE_GUID, fripple_on_offset, fripple_off_offset, now)


def appendEventsOfKind(aKindOfEvent, events, rec_time, xml_file, tree, root, 
                       evt_def_guid, on_offset, off_offset, now):

    if len(events[aKindOfEvent]['channel']) > 0:
        for i in range(len(events[aKindOfEvent]['channel'])):
            channel = events[aKindOfEvent]['channel'][i][0]
            begin = fixFormat(rec_time + timedelta(seconds=events[aKindOfEvent]['start_t'][i])+on_offset)
            end = fixFormat(rec_time + timedelta(seconds=events[aKindOfEvent]['finish_t'][i])+off_offset)

            appendEvent(xml_file, tree, root, evt_def_guid, channel, begin, end, now)

#TODO MERGE WITH appendEventsOfkind    
def appendEvent(xml_file, tree, root, evt_def_guid, channel, begin, end, now):
    
    evt = eTree.SubElement(root.find("Events"), "Event", Guid=newGuidString() )
    eTree.SubElement(evt, "EventDefinitionGuid").text = evt_def_guid
    eTree.SubElement(evt, "Begin").text = begin
    eTree.SubElement(evt, "End").text = end
    eTree.SubElement(evt, "Value").text = "0"
    eTree.SubElement(evt, "ExtraValue").text = "0"
    eTree.SubElement(evt, "DerivationInvID").text = str(channel) #review this. Shennan was adding +63 in matlab code, but the doc says it is the channel reference
    eTree.SubElement(evt, "DerivationNotInvID").text = "0"
    eTree.SubElement(evt, "CreatedBy").text = "Shennan Weiss"
    eTree.SubElement(evt, "CreatedDate").text = now
    eTree.SubElement(evt, "UpdatedBy").text = "Shennan Weiss"
    eTree.SubElement(evt, "UpdatedDate").text = now

    tree.write(xml_file, encoding="utf-8", xml_declaration=True, pretty_print=True)
    
