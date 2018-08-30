 
%Usage as follows
%For first use please see and set the paths in getPaths() function in this file
%cd project_path && matlab_binary -r  "main(edf_dataset_path,start_time, stop_time, ...
%%                                     cycle_time, chan_swap, swap_array_file)"

%TO ASK
%single instead of double? 
% limpiar memoria haciendo = [] o = 0 
%processBatch %Why monopolar takes and saves ez_tall_bp?  
%ProcessBatch If always will save, maybe should be inside dsp to avoid copies
%warnings , excepciones, error_codes?
%saving dirs separo o no en bipolar / monopolar
%refactor the other main functions, 
%review if monopolar/bipolar could be generalized as 'method to use'
%if so replace fields extentions such as _m _bp everywhere with a method_name field and remove 
%method_labels argument since they will be the same
%lfbad && lfbad ini
%what is the difference btw bps and bp in dsp_monopolar
%num_trc_blocks no va en metadata? metadata is duplicated. Whats the difference btw DSP_data & metadata. Unify.
%name for metadata.montage(:,1) montage chanlist? 
%comments in ez_detect_batch
%add sampling rate to metadata.

%TODO: 
%Backlog:
%correct everywhere the filename -4 
%unify main with batch and move the saves of dsp to the functions
%remember the return after the second error_flag handle in dsp_monopolar
%see if the save for ez_top_in is being used
%refactorize dsp_monopolar local functions
%change for tall expressions the dsp_outputs
% refactor ez detect functions 
%dsp bipolar refactoring = create error_flag for dsp_bipolar (lanzar warning y exc?)
%remove conditional for error_flag in process_DSP_output
%create an ezDetect class?
%use a parser later to optionally get monopolar/bipolar/trc  FR
%validate arguments 
%optimize tall evaluations and argument passing, read about using tall.
%optimize ram usage
%introduce logging
%just pass needed paths to branches instead of all the paths.
%optimize metadata datastructure
%log the input configuration of main and show if defaults.
%variable names declarativity, see lines and files to improve names with sheenan
%remove clears, see function pac
%ask if the matrixes are sparse
%review saving directories
%create a pack to struct

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
    
    start = tic;
    %Generate dsp outputs
    ez_detect_batch(paths, start_time, stop_time, cycle_time, swapping_data);
    toc(start);

    %disp('Starting to process dsp monopolar/bipolar outputs...')
    
    %start = tic;
    %Process dsp outputs
    %process_dsp_outputs(paths.dsp_monopolar_out, monopolarLabels(), paths);
    %process_dsp_outputs(paths.dsp_bipolar_out, bipolarLabels(), paths);
    %toc(start);
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