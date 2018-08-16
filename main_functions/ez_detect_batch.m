%{ 

 Modifying variables include
 iteration start
 start time (sec) in the case that a file ends with artifact,
 end time,
 the channel swapping flag (1: yes 0: no)
 the case that channels were incorrectly assigned in the original EDF file
 as can be the case for intraop recordings, and the 4th variable is the swap_array that can be
 used to correct the channel assignments. 

 Usage as follows ex#2. ezdetect_putou_v2 start_time stop_time swap_flag swap_array.

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

function ez_detect_batch(edf_dataset, start_time, stop_time, cycle_time, chan_swap, swap_array_file, saving_dirs)
    disp('Running EZ_Detect v7.0 Putou')
        
    narginchk(7,7);

    [header, signal_header, eeg_edf] = edf_load(edf_dataset); %Note that this version modified to read max 60 minutes of EEG due to memory constraints.
    disp('EDF file loaded')
    eeg_edf_tall=tall(eeg_edf);
    clear eeg_edf;
    
    sampling_rate= double(header.srate);
    %disp(['Sampling rate: ' int2str(round(sampling_rate)) 'Hz']);
    file_size = gather(numel(eeg_edf_tall(1,:))); %To avoid copying the structure in timeToFilePointers.
    file_pointers = getFilePointers(sampling_rate, start_time, stop_time, cycle_time, file_size);
    [data_path, data_filename, extention] = fileparts(edf_dataset); 
    blocks = calculateBlocksAmount(file_pointers, sampling_rate);
    
    %% I think this is not necesary now (Tomás P).
    %cycles = ceil(cycles); % bug fix now it reads to end of file. 
    % Note need to add patch that limits second cycle
        % if < 60 seconds.

    %check matlab scope for variables inside for statement.
    segment_data = struct();
    segment_data.filename = data_filename;
    segment_data.file_pointers = file_pointers;
    segment_data.sampling_rate = sampling_rate;
    segment_data.signal_header = signal_header;
    segment_data.block_index = 0;
    segment_data.chan_swap = chan_swap;
    segment_data.swap_array_file = swap_array_file;

    eeg_datas = cell(blocks);
    for i=1:blocks
        segment_data.block_index = i;
        [eeg_data,metadata,chanlist] = computeEEGSegment(segment_data, eeg_edf_tall);
         %disp(chanlist);
        disp(size(metadata));
        disp(metadata);
        disp(size(eeg_data));
        metadatas(i,:,:) = metadata;
        eeg_datas{i} = eeg_data;

        %log(chanlist, size(metadata), metadatam, size(eeg_data))
    end
    clear eeg_edf_tall;
    disp('Finished eeg_data processing');
    
    %disp('Are chanlist all the same?:')
    %disp(chanlist)
    %saveResearchData(saving_dirs.research, blocks, metadata, eeg_data, chanlist, data_filename);

    %check this function
    [~, ~, ~, montage] = ez_lfbad_putou70_ini_e1(tall(eeg_datas{1}), chanlist, metadatas(1,:,:), [data_filename extention]);

    parfor i=1:blocks
        gd=gpuDevice;
        disp(gd.Index);
        processBatch(eeg_datas{i}, metadatas(i,:,:), chanlist, montage, saving_dirs);
        eeg_datas{i} = 0; %to release memory?
    end

end

%%%%%%% Local Funtions  %%%%%%%


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

function [eeg_data, metadata, chanlist] = computeEEGSegment(segment_data, eeg_edf_tall)
    
    file_pointers = segment_data.file_pointers;
    base_pointer = file_pointers.start;
    stop_pointer = file_pointers.end;

    block_size = file_pointers.block_size;
    blocks_done = segment_data.block_index - 1;
    block_start_ptr = base_pointer+blocks_done*block_size;
    block_stop_ptr = block_start_ptr+block_size-1;
    %For the last block
    if block_stop_ptr > stop_pointer
        block_stop_ptr = stop_pointer;
    end
    disp('File pointer values: ')
    display(['base_pointer:' num2str(base_pointer)])
    display(['stop_pointer:' num2str(stop_pointer)])
    display(['block_size:' num2str(block_size)])
    display(['block_start_ptr:' num2str(block_start_ptr)])
    display(['block_stop_ptr:' num2str(block_stop_ptr)])
    
    eeg_data = gather(eeg_edf_tall(:,block_start_ptr:block_stop_ptr));
    
    metadata = struct();
    metadata.file_id = segment_data.filename;
    metadata.file_block = num2str(segment_data.block_index); %metadata.block_index would be better
    
    number_of_channels = gather(numel(eeg_edf_tall(:,1)));
    chanlist = getChanlist(number_of_channels, segment_data.signal_header,...
                           segment_data.chan_swap, segment_data.swap_array_file);
    
    eeg_data = resampleData(segment_data.sampling_rate, 2000, number_of_channels, eeg_data);

end

function chanlist = getChanlist(number_of_channels, signal_header, chan_swap, swap_array_file)
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
    clear channel;
end

function saveResearchData(contest_path, metadata, eeg_data, chanlist)
    for i = 1:length(metadata)
        metadata_i = metadata{i};
        eeg_data_i = eeg_data{i};
        chanlist_i = chanlist{i};
        data_filename = metadata.file_id;
        full_path=[contest_path data_filename '_' num2str(i) '.mat']; 
        save(full_path, 'metadata_i', 'eeg_data_i', 'chanlist_i'); 
    end
    clear metadata_i eeg_data_i chanlist_i;
end

function processBatch(eeg_data, metadata, chanlist, montage, saving_dirs)    
        
    setGlobalPaths()%to be removed later
    ez_tall = tall(eeg_data);
    clear eeg_data;
    [ez_tall_m, ez_tall_bp, metadata] = ez_lfbad_putou70_e1(ez_tall, chanlist, metadata, montage);
    clear ez_tall;
    metadata.montage=montage;

    if ~isempty(gather(ez_tall_m))
        %Why monopolar takes and saves ez_tall_bp?
        disp('Starting dsp_m');
        [DSP_data_m, ez_tall_m,ez_tall_bp, hfo_ai, fr_ai, ez_tall_hfo_m, ...
         ez_tall_fr_m, metadata, num_trc_blocks, error_flag] = ez_detect_dsp_m_putou70_e1(ez_tall_m, ...
                                                                                         ez_tall_bp, metadata);
        disp('Finished dsp_m');
        %save([saving_path filename], '-struct', 'structName')
        disp('Saving dsp_m output');
        filename = ['dsp_m_output_' metadata.file_block '.mat']
        saveMonopolarData([saving_dirs.dsp_monopolar filename], DSP_data_m, ez_tall_m, ...
                          ez_tall_bp, hfo_ai, fr_ai, ez_tall_hfo_m, ...
                          ez_tall_fr_m, metadata, num_trc_blocks, error_flag);
        disp('Saved dsp_m output');
    else
        hfo_ai = zeros(numel(gather(ez_tall_bp(1,:))),1)';
        fr_ai = hfo_ai;
    end

    if ~isempty(gather(ez_tall_bp))
        disp('Starting dsp_bp');
        [DSP_data_bp, ez_tall_bp, ez_tall_hfo_bp, ....
        ez_tall_fr_bp, metadata, num_trc_blocks] = ez_detect_dsp_bp_putou70_e1(ez_tall_bp, hfo_ai, ...
                                                                               fr_ai, metadata);
        disp('Finished dsp_bp');
        
        disp('Saving dsp_m output');
        filename = ['dsp_bp_output_' metadata.file_block '.mat']
        saveBipolarData([saving_dirs.dsp_bipolar filename], DSP_data_bp, ez_tall_bp, ... 
                        ez_tall_hfo_bp, ez_tall_fr_bp, metadata, num_trc_blocks);
        disp('Saved dsp_m output');
    end
end

function saveMonopolarData(file_path, DSP_data_m, ez_tall_m,ez_tall_bp, hfo_ai, fr_ai, ez_tall_hfo_m, ez_tall_fr_m, metadata, num_trc_blocks, error_flag)
    save(file_path, 'DSP_data_m', 'ez_tall_m','ez_tall_bp', 'hfo_ai', 'fr_ai', 'ez_tall_hfo_m', 'ez_tall_fr_m', 'metadata', 'num_trc_blocks', 'error_flag','-v7.3');
end

function saveBipolarData(file_path, DSP_data_bp, ez_tall_bp, ez_tall_hfo_bp, ez_tall_fr_bp, metadata, num_trc_blocks)
    save(file_path, 'DSP_data_bp', 'ez_tall_bp', 'ez_tall_hfo_bp', 'ez_tall_fr_bp', 'metadata', 'num_trc_blocks','-v7.3');
end
