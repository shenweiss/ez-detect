
%TODO:
%use a parser later to optionally get monopolar/bipolar/trc
%validate arguments
%remove global variables

function error_code = main(edf_dataset,varargin)
    %to be improved
    setGlobalPaths()
    saving_dirs = struct();
    saving_dirs.research = [MATFILES_PATH 'research/'];
    saving_dirs.dsp_monopolar = [MATFILES_PATH 'dsp_monopolar/'];
    saving_dirs.dsp_bipolar = [MATFILES_PATH 'dsp_bipolar/'];

    start = tic;
    
    start_time_default = 1; %starting in the first sec is assumed to include it.
    stop_time_default = 0; %if is not given its not relevant because we will take all the file.   
    cycle_time_deafult = 300; %5 minutes
    chan_swap_default = 0;
    swap_array_file_default = 'default';
        
    %Set defaults for optional inputs
    optional_args = {start_time_default, stop_time_default, cycle_time_deafult, ...
                     chan_swap_default, swap_array_file_default};

    %Overwrites the defaults if variable arguments are given
    optional_args(1:(nargin-1)) = varargin;

    %There must be a nicer way to do this...
    %Ensure that they are numbers
    for i=1:(length(optional_args)-1)
        optional_arg = optional_args(i);
        if strcmp('char', class(optional_arg))
            optional_args{i} = str2num(optional_arg);
        end
    end
    %Setnames of optional arguments
    [start_time, stop_time, cycle_time, chan_swap, swap_array_file] = optional_args{:};

    ez_detect_batch(edf_dataset, start_time, stop_time, cycle_time, chan_swap, swap_array_file, saving_dirs);
    toc(start);


    %This below can be improved to remove repetead code...
    monopolar_files = struct2cell(dir([saving_dirs.dsp_monopolar 'dsp*']));
    monopolar_filenames = monopolar_files(1,:); 
    for i = 1:length(monopolar_filenames)
        processDSPMonopolarOutput(monopolar_filenames{i});
    end

    bipolar_files = struct2cell(dir([saving_dirs.dsp_bipolar 'dsp*']));
    bipolar_filenames = bipolar_files(1,:); 
    for i = 1:length(bipolar_filenames)
        processDSPBipolarOutput(bipolar_filenames{i});
    end
    

end