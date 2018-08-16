 
%Usage as follows
%For first use please see and set the paths in getPaths() function in this file

%Backlog:
%TODO: 
%remove global variables
%create an ezDetect class
%remove repetead code for processMonopolar/Bipolar outputs
%remove repetead code for processBatch in ez_detect_batch
%use a parser later to optionally get monopolar/bipolar/trc
%validate arguments
%optimize tall evaluations
%optimize ram usage
%introduce logging
%just pass needed paths to branches instead of all the paths.
%saving dirs separo o no en bipolar / monopolar

function main(edf_dataset,varargin)
    start = tic;
    paths = getPaths();
    optional_args = struct2cell(getDefaults());
    %Overwrites the defaults if variable arguments are given
    optional_args(1:(nargin-1)) = varargin;
    %There must be a nicer way to do this...
    %Correcting if they were given as strings
    for i=1:(length(optional_args)-1)
        optional_arg = optional_args(i);
        if strcmp('char', class(optional_arg))
            optional_args{i} = str2num(optional_arg);
        end
    end
    %Setnames of optional arguments
    [start_time, stop_time, cycle_time, chan_swap, swap_array_file] = optional_args{:};

    swapping_data = struct('chan_swap', chan_swap, 'swap_array_file', swap_array_file);
    
    %validateArgs(edf_dataset, start_time, stop_time, cycle_time, swapping_data)

    ez_detect_batch(edf_dataset, start_time, stop_time, cycle_time, swapping_data, paths);
    toc(start);

    start = tic;
    %This below can be improved to remove repetead code...
    monopolar_files = struct2cell(dir([paths.dsp_monopolar_out 'dsp*']));
    monopolar_filenames = monopolar_files(1,:); 
    for i = 1:length(monopolar_filenames)
        processDSPMonopolarOutput(monopolar_filenames{i}, paths);
    end

    bipolar_files = struct2cell(dir([paths.dsp_bipolar_out 'dsp*']));
    bipolar_filenames = bipolar_files(1,:); 
    for i = 1:length(bipolar_filenames)
        processDSPBipolarOutput(bipolar_filenames{i}, paths);
    end
    toc(start);
end

function paths = getPaths()

    paths = struct();
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

%function validateArgs(edf_dataset, start_time, stop_time, cycle_time, swapping_data)
%end