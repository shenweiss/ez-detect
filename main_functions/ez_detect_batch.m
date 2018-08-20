%{ 
 Note: Now the main functions is called main() 
 (You can call it with optional args and if you dont specify defaults are given) 
 To call this function all arguments are required. main() handles that setting.
 

 Input semantic:
 
 The channel swapping flag (1: yes 0: no)
 In case that channels were incorrectly assigned in the original EDF file
 as can be the case for intraop recordings, and the 4th variable is the swap_array that can be
 used to correct the channel assignments. 
 
 This work is protected by US patent applications US20150099962A1,
 UC-2016-158-2-PCT, US provisional #62429461

 Written by Shennan Aibel Weiss MD, PhD. in Matlab at Thomas Jefferson University
 Philadelphia, PA USA. 2017

 Revision history  (I THINK THIS SHOULD BE SOMEWHERE ELSE, MAYBE IT WORTHS TO CREATE A REVISION HISTORY FILE)
 
 v3: Added asymmetric GPU filtering, made adjustments to
 time annotations in the DSP to account for phase delay.

 v4: 1)Added entropy measures to remove noisy electrodes. 
     2)Added correction for skew of BP filtered distributions. 
     3) Removed line noise and otherwise noisy channels using GPU autocorrelation function. 
     4) Impedence check (60 cycles) using GPU FFT.

 v5: 1)Implement in engine #1/#2 
     2)Change ez_detect loops to one minute from 20 seconds
     3)Remove annotation writing from ez_detect 
     4) add new GPU ez_top. 
     5) remove transient events after ez_top. 
     6) write TRC annotations after ez_top. 
     7) mongoDB functions to upload ez_pac results and add metadata.

 v7: 1)Added nnetwork to find bad channels 
     2)Added nnetwork to find bad channels on the basis of captured ripple events. 
     3)Added nnetwork to find bad channels on the basis of captured fripple events.

%}

function ez_detect_batch(edf_dataset, start_time, stop_time, cycle_time, swapping_data, paths)
    disp('Running EZ_Detect v7.0 Putou')
    narginchk(6,6);

    [header, signal_header, eeg_edf] = edf_load(edf_dataset); %Note that this version modified to read max 60 minutes of EEG due to memory constraints.
    disp('EDF file loaded')
    eeg_edf_tall=tall(eeg_edf);
    clear eeg_edf;
    
    [data_path, data_filename, extention] = fileparts(edf_dataset); 
    sampling_rate = double(header.srate);
    %disp(['Sampling rate: ' int2str(round(sampling_rate)) 'Hz']);
    number_of_channels = gather(numel(eeg_edf_tall(:,1)));    
    chanlist = getChanlist(number_of_channels, signal_header, swapping_data);
    file_size = gather(numel(eeg_edf_tall(1,:))); 
    file_pointers = getFilePointers(sampling_rate, start_time, stop_time, cycle_time, file_size);
    
    blocks = calculateBlocksAmount(file_pointers, sampling_rate);    
    %Note need to add patch that limits second cycle if < 60 seconds. %ask what is this
    [eeg_data, metadata] = computeEEGSegments(file_pointers, data_filename, sampling_rate, ...
                                              number_of_channels, blocks, eeg_edf_tall);
    clear eeg_edf_tall;
    disp('Finished eeg_data processing');

    %saveResearchData(paths.research, blocks, metadata, eeg_data, chanlist, data_filename);
    load([paths.montages data_filename '_montage'],'montage');
    ez_montage = montage; %this is because there is a matlab function with that name and makes trouble

    parfor i=1:blocks
        gd = gpuDevice;
        disp(gd.Index);
        processBatch(eeg_data{i}, metadata(i), chanlist, ez_montage, paths);
        eeg_data{i} = 0; %to release memory?
    end
end

%%%%%%% Local Funtions  %%%%%%%

function chanlist = getChanlist(number_of_channels, signal_header, swapping_data)
    swap_array_file = swapping_data.swap_array_file;
    chan_swap = swapping_data.chan_swap;
    swap_array_file_given = ~strcmp(swap_array_file,'default');
    if swap_array_file_given
        load(swap_array_file);
    end

    chanlist={};
    for j=1:number_of_channels
        chanlist{j} = signal_header(j).signal_labels;
    end

    if chan_swap
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
    %Ask about this.
    if seconds_remaining > 100
        blocks = full_blocks+1;
    else
        blocks = full_blocks; 
    end
end

function [eeg_data, metadata] = computeEEGSegments(file_pointers, data_filename, sampling_rate, ...
                                                   number_of_channels, blocks, eeg_edf_tall)
    desired_hz = 2000;
    base_pointer = file_pointers.start;
    stop_pointer = file_pointers.end;
    block_size = file_pointers.block_size;
    
    for i = 1:blocks
        block_index = i;
        blocks_done = i-1;
        block_start_ptr = base_pointer+blocks_done*block_size;
        block_start_ptr = block_start_ptr; 
        block_stop_ptr = min(block_start_ptr+block_size-1, stop_pointer);
    
        [eeg_data{i},metadata(i)] = computeEEGSegment(data_filename, sampling_rate, desired_hz, ...
                                                      number_of_channels, block_index, ...
                                                      block_start_ptr, block_stop_ptr, eeg_edf_tall);
        %later log(size(metadata), metadatam, size(eeg_data))
    end
end

function [eeg_data, metadata]= computeEEGSegment(filename, sampling_rate, desired_hz, ...
                                                  number_of_channels, block_index, ...
                                                  block_start_ptr, block_stop_ptr, eeg_edf_tall)

    eeg_data = gather(eeg_edf_tall(:,block_start_ptr:block_stop_ptr));
    eeg_data = resampleData(sampling_rate, desired_hz, ...
                            number_of_channels, eeg_data);
    metadata = struct();
    metadata.file_id = filename;
    metadata.file_block = num2str(block_index); %metadata.block_index would be better
end

function eeg_data = resampleData(sampling_rate, desired_hz, number_of_channels, eeg_data)
    %Resample Data to 2khz required.
    if sampling_rate ~= desired_hz
        [p,q] = rat(desired_hz/sampling_rate);
        disp(['Resampling the Data to ' num2str(desired_hz/1000) 'KHz']);
        for j=1:number_of_channels
            channel = eeg_data(j,:);
            eeg_data(j,:) = resample(channel,p,q);
        end
        disp(['Resampled: ' num2str(number_of_channels) ' data channels.']);
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

function processBatch(eeg_data, metadata, chanlist, ez_montage, paths)    
    ez_tall = tall(eeg_data);
    clear eeg_data;
    %refactor that function
    [ez_tall_m, ez_tall_bp, metadata] = ez_lfbad(ez_tall, metadata, chanlist, ez_montage);
    clear ez_tall;
    metadata.montage = ez_montage;

    %maybe they could be removed if we save inside dsp
    [hfo_ai, fr_ai] = createMonopolarOutput(ez_tall_m, ez_tall_bp, metadata, paths);
    createBipolarOutput(ez_tall_bp, hfo_ai, fr_ai, metadata, paths);  
end

function [hfo_ai, fr_ai] = createMonopolarOutput(ez_tall_m, ez_tall_bp, metadata, paths)
    if ~isempty(gather(ez_tall_m))
        %Why monopolar takes and saves ez_tall_bp?
        %If always will save, maybe should be inside dsp to avoid copies
        disp('Starting dsp_m');
        dsp_monopolar_output = ez_detect_dsp_m_putou70_e1(ez_tall_m, ez_tall_bp, metadata, paths);
        disp('Finished dsp_m');
        
        dsp_monopolar_filename = ['dsp_m_output_' metadata.file_block '.mat'];
        disp('Saving dsp_m output');
        save([paths.dsp_monopolar_out dsp_monopolar_filename], '-struct', 'dsp_monopolar_output');
        disp('Saved dsp_m output');
        hfo_ai = dsp_monopolar_output.hfo_ai;
        fr_ai = dsp_monopolar_output.fr_ai;
    else
        hfo_ai = zeros(numel(gather(ez_tall_bp(1,:))),1)';
        fr_ai = hfo_ai;
    end
end

function createBipolarOutput(ez_tall_bp, hfo_ai, fr_ai, metadata, paths)
    if ~isempty(gather(ez_tall_bp))
        disp('Starting dsp_bp');
        dsp_bipolar_output = ez_detect_dsp_bp_putou70_e1(ez_tall_bp, hfo_ai, fr_ai, metadata, paths);
        disp('Finished dsp_bp');
        
        dsp_bipolar_filename = ['dsp_bp_output_' metadata.file_block '.mat'];
        disp('Saving dsp_bp output');
        save([paths.dsp_bipolar_out dsp_bipolar_filename], '-struct', 'dsp_bipolar_output');
        disp('Saved dsp_bp output');
    end
end