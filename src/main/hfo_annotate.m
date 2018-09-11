%{
 Description: Main function of ez-detect project. Just makes argument parsing and calls
 ez_detect_batch.m

 Usage as follows:
 For first use please see and set the paths in getPaths() local function in this file.
 then run in shell: 

 cd project_path && matlab_binary -r  "hfo_annotate(edf_dataset_path,start_time, stop_time, ...
                                     cycle_time, chan_swap, swap_array_file)"

(You can call it with all optional args except from the requiered edf_dataset_path so 
 If you don't specify, defaults are given) 
 
 Input semantic:
    - edf_dataset_path: The directory path to the file with the data to analize.

    - [start_time]: a number in seconds indicating from when, relative to the file
      duration, do you want to analize the eeg.
    
    - [stop_time]: a number in seconds indicating up to when, relative to the file
      duration, do you want to analize the eeg.
      
      For example if you want to process the last 5 minutes of an eeg of 20 minutes
      you would use as input start_time = 15*60 = 900 and stop_time = 20*60 = 1200.
    
    - [cycle_time]: a number in seconds indicating the size of the blocks for the data to
      be cut. This improves time performance since it can be parallelized. 
      Example: 300 (5 minutes)

    - [Swapping data]: a struct containing the channel swapping flag (1:yes, 0:no) (in case that 
     channels were incorrectly assigned in the original EDF file as can be the case for intraop 
     recordings) and the swap_array that can be used to correct the channel assignments.
 
 Output: DSP monopolar/bipolar outputs as matfiles get saved in the corresponding working directory
 indicated in the argument 'paths'.


 This work is protected by US patent applications US20150099962A1,
 UC-2016-158-2-PCT, US provisional #62429461

 Written by Shennan Aibel Weiss MD, PhD. in Matlab at Thomas Jefferson University
 Philadelphia, PA USA. 2017
%}
% varargin = [start_time, stop_time, cycle_time, chan_swap, swap_array_file]
function hfo_annotate(edf_dataset_path, varargin)
    
    %Argument parsing and structuring
    paths = getPaths(edf_dataset_path); 
    cd(paths.misc_code);
    tryAddPaths(paths.project_root); %for method lookups
    cd(paths.hfo_engine);
    system('./clean.sh'); %cleans previous execution outputs

    optional_args = struct2cell(getDefaults());
    %Overwrites the defaults if variable arguments are given
    optional_args(1:(nargin-1)) = varargin;
    %Setnames of optional arguments
    [start_time, stop_time, cycle_time, chan_swap, swap_array_file] = optional_args{:};
    swapping_data = struct('chan_swap', chan_swap, 'swap_array_file', swap_array_file);
    %validateArgs(paths, start_time, stop_time, cycle_time, swapping_data)
    
    %Generate dsp outputs
    start = tic;
    process_batch(paths, start_time, stop_time, cycle_time, swapping_data);
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
    paths.matlab_bin='~/matlab/bin/matlab';

    paths.project_root = '~/ez-detect/';  %then will be an argument
    paths.hfo_engine = [paths.project_root 'hfo_engine_1/'];
    
    paths.misc_code = [paths.project_root '/tools/misc_code'];
    paths.xml_output_path = [paths.hfo_engine 'xml_output/'];
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
    
    paths.cudaica_dir= [paths.project_root 'src/cudaica/'];
    paths.binica_sc=[paths.cudaica_dir 'binica.sc'];
    paths.cudaica_bin=[paths.cudaica_dir 'cudaica'];
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
