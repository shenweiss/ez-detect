%{ 
 This is the old ez_detect_batch file. Mai is for argument handling and file formating to trc.
 
 Usage as follows:
 For first use please see and set the paths in getPaths() local function in this file.
 then run in shell: 

 cd project_path && matlab_binary -r  "main(edf_dataset_path,start_time, stop_time, ...
                                     cycle_time, chan_swap, swap_array_file)"

(You can call it with all optional args except from the requiered edf_dataset_path so 
 If you don't specify, defaults are given) 
 
 Input semantic:
    - edf_dataset_path: The directory path to the file with the data to analize.

    - start_time: a number in seconds indicating from when, relative to the file
      duration, do you want to analize the eeg.
    
    - stop_time: a number in seconds indicating up to when, relative to the file
      duration, do you want to analize the eeg.
      
      For example if you want to process the last 5 minutes of an eeg of 20 minutes
      you would use as input start_time = 15*60 = 900 and stop_time = 20*60 = 1200.
    
    - cycle_time: a number in seconds indicating the size of the blocks to cut the data
      in blocks.This improves time performance since it can be parallelized. 
      Example: 300 (5 minutes)
    
    -Swapping data: a struct containing the channel swapping flag (1:yes, 0:no) (in case that 
     channels were incorrectly assigned in the original EDF file as can be the case for intraop 
     recordings) and the swap_array that can be used to correct the channel assignments.
 
 Output: DSP monopolar/bipolar outputs as matfiles get saved in the corresponding working directory
 indicated in the argument 'paths'.


 This work is protected by US patent applications US20150099962A1,
 UC-2016-158-2-PCT, US provisional #62429461

 Written by Shennan Aibel Weiss MD, PhD. in Matlab at Thomas Jefferson University
 Philadelphia, PA USA. 2017
%}

function main(edf_dataset_path, varargin)
    
    %Argument parsing and structuring
    paths = getPaths(edf_dataset_path);
    optional_args = struct2cell(getDefaults());
    %Overwrites the defaults if variable arguments are given
    optional_args(1:(nargin-1)) = varargin;
    %Setnames of optional arguments
    [start_time, stop_time, cycle_time, chan_swap, swap_array_file] = optional_args{:};
    swapping_data = struct('chan_swap', chan_swap, 'swap_array_file', swap_array_file);
    %validateArgs(paths, start_time, stop_time, cycle_time, swapping_data)
    
    %Generate dsp outputs
    start = tic;
    ez_detect_batch(paths, start_time, stop_time, cycle_time, swapping_data);
    toc(start);

    disp('Starting to process dsp monopolar/bipolar outputs...')
    
    %Process dsp outputs
    start = tic;
    process_dsp_outputs(paths.dsp_monopolar_out, monopolarLabels(), paths);
    process_dsp_outputs(paths.dsp_bipolar_out, bipolarLabels(), paths);
    toc(start);
end

function paths = getPaths(edf_dataset_path)

    paths = struct();
    paths.edf_dataset = edf_dataset_path;
    paths.project_root = '~/ez-detect/';
    paths.hfo_engine = [paths.project_root 'hfo_engine_1/'];
    
    paths.dsp_monopolar_out=[paths.hfo_engine 'dsp_output/monopolar/'];
    paths.dsp_bipolar_out=[paths.hfo_engine 'dsp_output/bipolar/'];
    
    paths.ez_pac_out=[paths.hfo_engine 'ez_pac_output/'];
    paths.ez_top_in=[paths.hfo_engine 'ez_top/input/'];
    paths.ez_top_out=[paths.hfo_engine 'ez_top/output/'];
    
    paths.montages=[paths.hfo_engine 'montages/'];
    paths.research = [paths.hfo_engine 'research_matfiles/'];
    paths.executable=[paths.hfo_engine 'executable/']; %this could be separated in monopolar/bipolar
    
    paths.trc_out=[paths.hfo_engine 'trc/output/'];%this could be separated in monopolar/bipolar
    paths.trc_tmp_monopolar=[paths.hfo_engine 'trc/temp/monopolar/'];
    paths.trc_tmp_bipolar=[paths.hfo_engine 'trc/temp/bipolar/'];
    
    paths.binica_sc=[paths.hfo_engine 'binica.sc'];
    paths.cudaica_bin=[paths.hfo_engine 'cudaica'];
    paths.cudaica_dir= paths.hfo_engine;
end

function defaults = getDefaults()
    defaults = struct();
    defaults.start_time = 1; %starting in the first sec is assumed to include it.
    defaults.stop_time = 0; %if is not given its not relevant because we will take all the file.   
    defaults.cycle_time = 300; %5 minutes
    defaults.chan_swap = 0;
    defaults.swap_array_file = 'default';
end

%function validateArgs(paths, start_time, stop_time, cycle_time, swapping_data)
%end

%This will not be necesary later, see backlog
function monopolar_labels = monopolarLabels()
    monopolar_labels = struct( ...
        'dsp_data', 'DSP_data_m', ...
        'metadata', 'metadata', ...
        'num_trc_blocks', 'num_trc_blocks', ...
        'ez_tall', 'ez_tall_m', ...
        'ez_tall_fr', 'ez_tall_fr_m', ...
        'ez_tall_hfo', 'ez_tall_hfo_m', ...
        'error_flag', 'error_flag' ...
    );
end

function bipolar_labels = bipolarLabels()
    bipolar_labels = struct( ...
        'dsp_data', 'DSP_data_bp', ...
        'metadata', 'metadata', ...
        'num_trc_blocks', 'num_trc_blocks', ...
        'ez_tall', 'ez_tall_bp', ...
        'ez_tall_fr', 'ez_tall_fr_bp', ...
        'ez_tall_hfo', 'ez_tall_hfo_bp' ...
    );
end

%{
To call this function all arguments are required. main() handles that setting.
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
    
    -Swapping data: a struct containing the channel swapping flag (1:yes, 0:no) (in case that 
     channels were incorrectly assigned in the original EDF file as can be the case for intraop 
     recordings) and the swap_array that can be used to correct the channel assignments.
 
 Output: DSP monopolar/bipolar outputs as matfiles get saved in the corresponding working directory
 indicated in the argument 'paths'.
%}

function ez_detect_batch(paths, start_time, stop_time, cycle_time, swapping_data)
    disp('Running EZ_Detect v7.0 Putou')
    narginchk(5,5);

    [header, signal_header, eeg_edf] = edf_load(paths.edf_dataset); %Note that this version modified to read max 60 minutes of EEG due to memory constraints.
    disp('EDF file loaded')
    eeg_edf_tall=tall(eeg_edf);
    clear eeg_edf;
    
    [data_path, data_filename, extention] = fileparts(paths.edf_dataset); 
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
        eeg_data{i} = 0; %to release memory? this works?? 
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
    %Ask about this later.
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

function processBatch(eeg_data, metadata, chanlist, ez_montage, paths)    
    ez_tall = tall(eeg_data);
    clear eeg_data;
    %refactor that function
    [ez_tall_m, ez_tall_bp, metadata] = ez_lfbad(ez_tall, metadata, chanlist, ez_montage);
    clear ez_tall;
    metadata.montage = ez_montage;

    %maybe these two below could be removed if we save inside dsp
    [ez_tall_bp, hfo_ai, fr_ai, metadata] = createMonopolarOutput(ez_tall_m, ez_tall_bp, metadata, paths);
    createBipolarOutput(ez_tall_bp, hfo_ai, fr_ai, metadata, paths);  
end

function [ez_tall_bp, hfo_ai, fr_ai, metadata] = createMonopolarOutput(ez_tall_m, ez_tall_bp, metadata, paths)
    if ~isempty(gather(ez_tall_m))
        %Why monopolar takes and saves ez_tall_bp?
        %If always will save, maybe should be inside dsp to avoid copies
        disp('Starting dsp_m');
        dsp_monopolar_output = ez_detect_dsp_monopolar(ez_tall_m, ez_tall_bp, metadata, paths);
        disp('Finished dsp_m');
        
        dsp_monopolar_filename = ['dsp_m_output_' metadata.file_block '.mat'];
        disp('Saving dsp_m output');
        save([paths.dsp_monopolar_out dsp_monopolar_filename], '-struct', 'dsp_monopolar_output');
        disp('Saved dsp_m output');
        ez_tall_bp = dsp_monopolar_output.ez_tall_bp;
        hfo_ai = dsp_monopolar_output.hfo_ai;
        fr_ai = dsp_monopolar_output.fr_ai;
        metadata = dsp_monopolar_output.metadata;
    else
        hfo_ai = zeros(numel(gather(ez_tall_bp(1,:))),1)';
        fr_ai = hfo_ai;
    end
end

function createBipolarOutput(ez_tall_bp, hfo_ai, fr_ai, metadata, paths)
    if ~isempty(gather(ez_tall_bp))
        disp('Starting dsp_bp');
        dsp_bipolar_output = ez_detect_dsp_bipolar(ez_tall_bp, hfo_ai, fr_ai, metadata, paths);
        disp('Finished dsp_bp');
        
        dsp_bipolar_filename = ['dsp_bp_output_' metadata.file_block '.mat'];
        disp('Saving dsp_bp output');
        save([paths.dsp_bipolar_out dsp_bipolar_filename], '-struct', 'dsp_bipolar_output');
        disp('Saved dsp_bp output');
    end
end 