function ezdetect_putou70_e1_batch(file_name_in,path_name_in,cycle_time, blocks, vargin, vargin2, vargin3, vargin4, vargin5)

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    nombres de las variables.



    % Modifying variables include
    % iteration start
    % start time (sec) in the case that a file ends with artifact,
    % end time,
    % the channel swapping flag (1: yes 0: no)
    % the case that channels were incorrectly assigned in the original EDF file
    % as can be the case for intraop recordings, and the 4th variable is the swap_array that can be
    % used to correct the channel assignments. Usage as follows ex#2. ezdetect_putou_v2
    % start_time stop_time swap_flag swap_array.

    % This work is protected by US patent applications US20150099962A1,
    % UC-2016-158-2-PCT, US provisional #62429461

    % Written by Shennan Aibel Weiss MD, PhD. in Matlab at Thomas Jefferson University
    % Philadelphia, PA USA. 2017

    % Revision history
    % v3: added asymmetric GPU filtering made adjustments to
    % time annotations in the DSP to account for phase delay.

    % v4 : 1)Added entropy measures to remove noisy electrodes. 2) Added correction for skew of BP
    % filtered distributions. 3) Removed line noise and otherwise noisy
    % channels using GPU autocorrelation function. 4) Impedence check (60 cycles) using GPU FFT.

    % v5 : 1) implement in engine #1/#2, 2) change ez_detect loops to one minute from 20 seconds
    % 3) Remove annotation writing from ez_detect 4) add new GPU ez_top. 5) remove transient events
    % after ez_top. 6) write TRC annotations after ez_top. 7) mongoDB functions to upload ez_pac
    % results and add metadata.

    % v7 : 1) added nnetwork to find bad channels, 2) added nnetwork to find
    % bad channels on the basis of captured ripple events. 3) added nnetwork to
    % find bad channels on the basis of captured fripple events.

    disp(file_name_in);
    fn=file_name_in; % for research purposes only
    file_id=file_name_in;
    file_name_in=[path_name_in file_name_in];
    disp('\r');
    minInputs=0;
    maxInputs=8; %creo que son 9 a menos que saquemos el que está de más para hacer eso de arriba
    narginchk(minInputs,maxInputs);
    
    start_iterations=1 %para que está este si tenes start time?
    starttime_ini=1;
    stoptime_ini=0; 
    chan_swap=0;


    if nargin>2
        for k=1:(nargin-4)
            if k==1
                start_iterations=vargin;
                start_iterations=str2num(start_iterations);
            end
            if k==2
                starttime_ini=vargin2;
                starttime_ini=str2num(starttime_ini)
            end
            if k==3
                stoptime_ini=vargin3;
                stoptime_ini=str2num(stoptime_ini);
            end
            if k==4
                chan_swap=vargin4;
                chan_swap=str2num(chan_swap);
            end
            if k==5
                swap_array_file=vargin5; 
                load(swap_array_file);
            end
        end
    end

    disp('Running EZ_Detect v7.0 Putou \r')
    
    % Read EDF file
    %disp('filename in ')
    %disp(file_name_in)
    %[header, signalHeader, eeg_edf] = ez_edfload_putou02(file_name_in); %Note that this version modified to read max 60 minutes of EEG due to memory constraints.
    %disp('EDF file load')
    %save(['/home/tpastore/Escritorio/449_correct_EDF.mat'], 'header', 'signalHeader', 'eeg_edf', '-v7.3') 
    
    %Read TRC file
    [filepath,fileName,ext] = fileparts(file_name_in)
    ENV = 'LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6 '
    PY = '/home/tpastore/anaconda3/bin/python '
    APP_DIR = '/home/tpastore/ez-detect/python/'
    APP = 'trc_to_mat.py '
    saving_path = ['/home/tpastore/hfo_engine_1/TRC_in_mat/' fileName '_TRC.mat']
    error_flag_readTRC = system([ENV PY APP_DIR APP file_name_in ' ' saving_path]); %lee el trc y guarda lo necesario en un matfile para que lo acceda matlab
    error_flag_readTRC
    load(saving_path, 'header', 'signalHeader', 'eeg_edf' );
    signalHeader = cell2mat(signalHeader);

    eeg_edf_tall=tall(eeg_edf);
    clear eeg_edf
    samplingrate=header.srate;
    if nargin>4
        starttime_ini=starttime_ini*samplingrate;
    end
    disp(strcat('Sampling rate: ', int2str(round(samplingrate)),'Hz'));
    disp('Input file loaded \r')

    % Create file blocks and run EZ_detect
    if stoptime_ini==0 % default condition
        end_time=(cycle_time*samplingrate);
        iterations = gather(floor(((numel(eeg_edf_tall(1,:))-starttime_ini)/end_time)));
    else
        end_time=(cycle_time*samplingrate);
        stoptime_ini=stoptime_ini*samplingrate;
        iterations = floor((stoptime_ini-starttime_ini)/end_time);
    end
    if iterations == 0
        if stoptime_ini==0
            end_time=gather(numel(eeg_edf_tall(1,:)));
        else
            end_time=stoptime_ini;
        end
        cycles=1;
    else
        if stoptime_ini==0
            iteration_rem=gather(rem((numel(eeg_edf_tall(1,:))-starttime_ini),(cycle_time*samplingrate)));
            iteration_rem=iteration_rem+1;
            if (iteration_rem/samplingrate)>100
                cycles=iterations+1;
            else
                cycles=iterations;
            end
            end_time=starttime_ini+(cycle_time*samplingrate);
        else
            iteration_rem=gather(rem((numel(eeg_edf_tall(1,:))-starttime_ini-(numel(eeg_edf_tall(1,:))-stoptime_ini)),(cycle_time*samplingrate)));
            iteration_rem=iteration_rem+1;
            if (iteration_rem/samplingrate)>100
                cycles=iterations+1;
            else
                cycles=iterations;
            end
            end_time=starttime_ini+(cycle_time*samplingrate);
        end
        cycles=ceil(cycles); % bug fix now it reads to end of file.
        % Note need to add patch that limits second cycle
        % if < 60 seconds.
    end

    cycles=blocks; %todo lo de arriba no tiene sentido entonces

    eeg_datas = cell(cycles); %no se usa, sera cycles?
    for i=1:cycles
        [eeg_data,metadata,chanlist] = computeEEGSegment(file_id,i,samplingrate,cycle_time,starttime_ini,stoptime_ini,end_time,eeg_edf_tall,signalHeader,chan_swap,fn);
        %disp(chanlist);
        disp(size(metadata));
        disp(metadata);
        disp(size(eeg_data));
        metadatas(i,:,:) = metadata;
        eeg_datas{i} = eeg_data;
    end
    clear eeg_edf_tall;
    disp('Finished eeg_data processing');

    chanlist
    [~, ~, ~, montage] = ez_lfbad_putou70_ini_e1(tall(eeg_datas{1}), chanlist, metadatas(1,:,:), file_id);
        
    parfor i=start_iterations:cycles
        gd=gpuDevice; 
        disp(gd.Index);
        processBatchs(eeg_datas{i},chanlist,metadatas(i,:,:),montage); %processBatch
        eeg_datas{i} = zeros(1,1); %% = 0? para que?
    end

end

function processBatchs(eeg_data,chanlist,metadata,montage)
    ez_tall=tall(eeg_data);
    clear eeg_data;
    [ez_tall_m, ez_tall_bp, metadata] = ez_lfbad_putou70_e1(ez_tall, chanlist, metadata, montage);
    clear ez_tall;
    metadata.montage= montage;

    %debug code
    if ~isempty(gather(ez_tall_bp))
        disp('processBatch: ez_tall_bp is empty before dsp_monopolar')
    end
    %%%
    if ~isempty(gather(ez_tall_m))
        disp('Starting dsp_m');
        [DSP_data_m, ez_tall_m,ez_tall_bp, hfo_ai, fr_ai, ez_tall_hfo_m, ez_tall_fr_m, metadata, num_trc_blocks, error_flag] = ez_detect_dsp_m_putou70_e1(ez_tall_m,ez_tall_bp,metadata);
        disp('Finished dsp_m');

        disp('Saving dsp_m output');
        filename = ['dsp_m_output_' metadata.file_block '.mat']
        saveMonopolarData(filename, DSP_data_m, ez_tall_m,ez_tall_bp, hfo_ai, fr_ai, ez_tall_hfo_m, ez_tall_fr_m, metadata, num_trc_blocks, error_flag);
        disp('Saved dsp_m output');
    else
        hfo_ai=zeros(numel(gather(ez_tall_bp(1,:))),1)';
        fr_ai=zeros(numel(gather(ez_tall_bp(1,:))),1)';
    end

    if ~isempty(gather(ez_tall_bp))
        disp('Starting dsp_bp');
        [DSP_data_bp, ez_tall_bp, ez_tall_hfo_bp, ez_tall_fr_bp, metadata, num_trc_blocks] = ez_detect_dsp_bp_putou70_e1(ez_tall_bp, hfo_ai, fr_ai, metadata);
        disp('Finished dsp_bp');
        
        disp('Saved dsp_m output');
        filename = ['dsp_bp_output_' metadata.file_block '.mat']
        saveBipolarData(filename, DSP_data_bp, ez_tall_bp, ez_tall_hfo_bp, ez_tall_fr_bp, metadata, num_trc_blocks);
        disp('Saving dsp_m output');
    else 
        disp('Did not enter to dsp_bipolar because _ez_tall_bp was empty ')
    end

end

function saveMonopolarData(filename, DSP_data_m, ez_tall_m,ez_tall_bp, hfo_ai, fr_ai, ez_tall_hfo_m, ez_tall_fr_m, metadata, num_trc_blocks, error_flag)
    save(filename, 'DSP_data_m', 'ez_tall_m','ez_tall_bp', 'hfo_ai', 'fr_ai', 'ez_tall_hfo_m', 'ez_tall_fr_m', 'metadata', 'num_trc_blocks', 'error_flag','-v7.3');
end

function saveBipolarData(filename, DSP_data_bp, ez_tall_bp, ez_tall_hfo_bp, ez_tall_fr_bp, metadata, num_trc_blocks)
    save(filename, 'DSP_data_bp', 'ez_tall_bp', 'ez_tall_hfo_bp', 'ez_tall_fr_bp', 'metadata', 'num_trc_blocks','-v7.3');
end

function [eeg_data, metadata, chanlist] = computeEEGSegment(file_id,i,samplingrate,cycle_time,starttime_ini,stoptime_ini,end_time,eeg_edf_tall,signalHeader,chan_swap,fn)
    metadata=[];
    metadata.file_id=file_id;
    metadata.file_block=num2str(i);
    start_time=((i-1)*(cycle_time*samplingrate))+starttime_ini;
    if i>1
        if stoptime_ini==0
            if starttime_ini+(i*(cycle_time*samplingrate))<numel(gather(eeg_edf_tall(1,:)))
                end_time=starttime_ini+(i*(cycle_time*samplingrate));
            else
                end_time=gather(numel(eeg_edf_tall(1,:)));
            end
        else
            if starttime_ini+(i*(cycle_time*samplingrate))<stoptime_ini
                end_time=starttime_ini+(i*(cycle_time*samplingrate));
            else
                end_time=stoptime_ini;
            end
        end
    end

    if end_time>gather(numel(eeg_edf_tall(1,:)))   % Bug fix for stop time after file end
        end_time=gather(numel(eeg_edf_tall(1,:)))-(samplingrate*15);
    end

    eeg_data=gather(eeg_edf_tall(:,start_time:end_time));

    % read chanlist
    chanlist={''};
    for j=1:gather(numel(eeg_edf_tall(:,1)))
        chanlist{j}=signalHeader(j).signal_labels;
    end

    if chan_swap == 1
        chanlist=chanlist(swap_array);
    end

    % Up or Downsample Data to 2khz required.
    if samplingrate~=2000
        temp2=[];
        samplingrate=double(samplingrate);
        [p,q]=rat(2000/samplingrate);
        fprintf('Resampling the Data to 2KHz \r')
        for j=1:numel(chanlist)
            disp(strcat('Resampled:_',int2str(j),'_data channels.'));
            x=eeg_data(j,:);
            temp2(j,:)=resample(x,p,q);
        end
        eeg_data=temp2;
        clear p q x temp2
    end

    contest_path='/home/tpastore/hfo_engine_1/matfiles/' % for research only
    fname=fn(1:(numel(fn)-4)); %
    fname_int=num2str(i); %
    fname=[fname fname_int '.mat']; %
    fname=[contest_path fname]; %
    save(fname,'eeg_data','chanlist'); %

end

