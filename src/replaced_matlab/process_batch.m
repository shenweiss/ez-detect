%{
To call this function all arguments are required. hfo_annotate handles that setting and argument parsing.
 Input semantic:
    
    - paths: a Struct containing strings for every path is used in the project. It is set in main()
      and it includes paths.edf_dataset which is the file to work with, saving directories, etc.
    
    - start_time: a number in seconds indicating from when, relative to the file duration, 
      do you want to analize the eeg.
    
    - stop_time: a number in seconds indicating up to when, relative to the file duration, 
      do you want to analize the eeg.
      
      For example if you want to process the last 5 minutes of an eeg of 20 minutes you would use
      as input start_time = 15*60 = 900 and stop_time = 20*60 = 1200.
    
    - cycle_time: a number in seconds indicating the size of the blocks to cut the data in blocks.
      This improves time performance since it can be parallelized. Example: 300 (5 minutes)
    
    - swapping data: a struct containing the channel swapping flag (1:yes, 0:no) (in case that 
     channels were incorrectly assigned in the original EDF file as can be the case for intraop 
     recordings) and the swap_array that can be used to correct the channel assignments.
 
 Output: DSP monopolar/bipolar outputs as matfiles get saved in the corresponding working directory
 indicated in the argument 'paths'.
%}

function process_batch(paths, start_time, stop_time, cycle_time)
    disp('Running EZ_Detect v7.0 Putou')
    narginchk(4,4);
    paths = struct(paths); %to convert python dic to matlab struct if called with main.py.
    [header, signal_header, eeg_edf] = edf_load(paths.trc_fname); %in this case is a edf. not a trc, but didnt want to change the field name.
    disp('EDF file loaded')
    
    [data_path, data_filename, extention] = fileparts(paths.trc_fname); 
    sampling_rate = double(header.srate);
    %disp(['Sampling rate: ' int2str(round(sampling_rate)) 'Hz']);
    number_of_channels = numel(eeg_edf(:,1));    
    chanlist = getChanlist(number_of_channels, signal_header, paths.swap_array_file);
    file_size = numel(eeg_edf(1,:)); 
    file_pointers = getFilePointers(sampling_rate, start_time, stop_time, cycle_time, file_size);
    
    blocks = calculateBlocksAmount(file_pointers, sampling_rate);    
    %Note need to add patch that limits second cycle if < 60 seconds. %ask what is this
    [eeg_data, metadata] = computeEEGSegments(file_pointers, data_filename, sampling_rate, ...
                                              number_of_channels, blocks, eeg_edf);
    disp('Finished creating eeg_data blocks');

    %saveResearchData(paths.research, blocks, metadata, eeg_data, chanlist, data_filename);
    load([paths.montages data_filename '_montage'],'montage');
    ez_montage = montage; %this is because there is a matlab function with that name and makes trouble

    parfor i=1:blocks
        gd = gpuDevice;
        disp(gd.Index);
        processParallelBlock(eeg_data{i}, chanlist, metadata(i), ez_montage, paths);
        eeg_data{i} = 0; %to release memory? this works?? 
    end
end

%%%%%%% Local Funtions  %%%%%%%

function chanlist = getChanlist(number_of_channels, signal_header, swap_array_file_path)
    chanlist={};
    for j=1:number_of_channels
        chanlist{j} = signal_header(j).signal_labels;
    end

    swap_array_file_given = ~strcmp(swap_array_file_path,'NOT_GIVEN');
    if swap_array_file_given
        load(swap_array_file);
        chanlist = chanlist(swap_array);
    end
end

function file_pointers = getFilePointers(sampling_rate, start_time, stop_time, cycle_time, file_size)
    file_pointers = struct();

    %start_time_default is 1, meaning the first second
    seconds_to_jump = start_time-1;
    file_pointers.start = seconds_to_jump*sampling_rate + 1; 
    
    stop_time_default = 0;
    if stop_time == stop_time_default
        file_pointers.end = file_size; 
    else
        file_pointers.end = stop_time*sampling_rate;
    end
    file_pointers.block_size = cycle_time*sampling_rate;
    file_pointers.file_size = file_size;
end

function blocks = calculateBlocksAmount(file_pointers, sampling_rate)
    images_number = file_pointers.end-file_pointers.start+1;
    full_blocks = floor(images_number/file_pointers.block_size);
    images_remaining = rem(images_number,file_pointers.block_size);
    seconds_remaining = images_remaining/sampling_rate;
    %Ask about this later.
    if seconds_remaining > 100
        blocks = full_blocks+1;
    else
        blocks = full_blocks; 
    end
end

function [eeg_data, metadata] = computeEEGSegments(file_pointers, data_filename, sampling_rate, ...
                                                   number_of_channels, blocks, eeg_edf)
    desired_hz = 2000;
    base_pointer = file_pointers.start;
    stop_pointer = file_pointers.end;
    block_size = file_pointers.block_size;
    
    for i = 1:blocks
        block_index = i;
        blocks_done = i-1;
        block_start_ptr = base_pointer+blocks_done*block_size;
        block_stop_ptr = min(block_start_ptr+block_size-1, stop_pointer);
    
        [eeg_data{i},metadata(i)] = computeEEGSegment(data_filename, sampling_rate, desired_hz, ...
                                                      number_of_channels, block_index, ...
                                                      block_start_ptr, block_stop_ptr, eeg_edf);
        %later log(size(metadata), metadatam, size(eeg_data))
    end
end

function [eeg_data, metadata]= computeEEGSegment(filename, sampling_rate, desired_hz, ...
                                                  number_of_channels, block_index, ...
                                                  block_start_ptr, block_stop_ptr, eeg_edf)

    eeg_data = eeg_edf(:,block_start_ptr:block_stop_ptr);
    eeg_data = resampleData(sampling_rate, desired_hz, ...
                            number_of_channels, eeg_data);
    metadata = struct();
    metadata.file_id = filename;
    metadata.file_block = num2str(block_index); %metadata.block_index would be better
end

function resampled_data = resampleData(sampling_rate, desired_hz, number_of_channels, eeg_data)
    %Resample Data to 2khz required.
    if sampling_rate ~= desired_hz
        [p,q] = rat(desired_hz/sampling_rate);
        disp(['Resampling the Data to ' num2str(desired_hz/1000) 'KHz']);
        for j=1:number_of_channels
            channel = eeg_data(j,:);
            resampled_data(j,:) = resample(channel,p,q);
        end
        disp(['Resampled: ' num2str(number_of_channels) ' data channels.']);
    else % No resample needed
        resampled_data = eeg_data;
    end
end

function saveResearchData(contest_path, metadata, eeg_data, chanlist)
    for i = 1:numel(metadata)
        eeg_data_i = eeg_data{i};
        metadata_i = metadata{i};
        chanlist_i = chanlist{i};
        data_filename = metadata.file_id;
        full_path=[contest_path data_filename '_' num2str(i) '.mat']; 
        save(full_path, 'metadata_i', 'eeg_data_i', 'chanlist_i'); 
    end
end

% This function performs dsp processing cutting data in chunks and using
% parallelized computing. This improves time performance corresponding to dsp processing. 

function processParallelBlock(eeg_data, chanlist, metadata, ez_montage, paths)    
    %%%% testing transaltion to python
    args_fname = [paths.temp_pythonToMatlab_dsp_MATLAB 'lfbad_args_' metadata.file_block '.mat']; 
    save(args_fname, 'eeg_data', 'chanlist', 'metadata', 'ez_montage');
    %%%%%

    [ez_mp, ez_bp, metadata] = ez_lfbad_m(eeg_data, chanlist, metadata, ez_montage);

    metadata.montage = ez_montage;
    montage_names = struct();
    montage_names.monopolar = 'MONOPOLAR';
    montage_names.bipolar = 'BIPOLAR';

    if ~isempty(ez_mp)
        
        disp(['Starting dsp ' montage_names.monopolar]);
        dsp_monopolar_output = ez_detect_dsp_monopolar(ez_mp, ez_bp, metadata, paths);
        disp(['Finished dsp ' montage_names.monopolar]);

        ez_bp = dsp_monopolar_output.ez_bp;
        hfo_ai = dsp_monopolar_output.hfo_ai;
        fr_ai = dsp_monopolar_output.fr_ai;
        metadata = dsp_monopolar_output.metadata;
        saveDSPOutput(montage_names.monopolar, montage_names, dsp_monopolar_output, metadata.file_block, paths);
    else 
        hfo_ai = zeros(numel(ez_bp(1,:)),1)';
        fr_ai = hfo_ai;
    end

    if ~isempty(ez_bp)
        
        disp(['Starting dsp ' montage_names.bipolar]);
        dsp_bipolar_output = ez_detect_dsp_bipolar(ez_bp, hfo_ai, fr_ai, metadata, paths);
        disp(['Finished dsp ' montage_names.bipolar]);
        saveDSPOutput(montage_names.bipolar, montage_names, dsp_bipolar_output, metadata.file_block, paths);
    else
        disp("Didn't enter dsp bipolar, ez_bp was empty");

    end
end

function saveDSPOutput(montage_name, montage_names, dsp_output, file_block, paths)

    disp(['Saving dsp ' montage_name ' output.']);
    
    switch montage_name
        
        case montage_names.monopolar
            
            out_filename = ['dsp_m_output_' file_block '.mat'];
            saving_directory = paths.dsp_monopolar_out;

        case montage_names.bipolar
            
            out_filename = ['dsp_bp_output_' file_block '.mat'];
            saving_directory = paths.dsp_bipolar_out;
        
        otherwise 
            
            disp(["Unkown montage_name. Please see available montage_names", 
                  " inside getConstants local function"]);
    end
    
    save([saving_directory out_filename], '-struct', 'dsp_output');
    disp(['Dsp ' montage_name ' output was saved.']);
end
