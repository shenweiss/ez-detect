% This is the first production code of the bipolar EZ detect DSP codename
% putou. It has been fully calibrated using NK intracranial data from TJU
% and UCLA. Prior to running this program the EEG data has been converted
% in to tall data block structures. LF bad channels have been removed. The
% referential and bipolar montages have also been created. The output for
% this program includes the ripple and fast ripple clips, time stamps, TRC
% files and annotations (for now), tall data structures for ic1, fr_ic1,
% mean ai, and mean fr_ai.

% This work is protected by US patent applications US20150099962A1,
% UC-2016-158-2-PCT, US provisional #62429461

% Written by Shennan Aibel Weiss MD, PhD. in Matlab at Thomas Jefferson University
% Philadelphia, PA USA. 2017

% Main DSP Algorithm for HFO research and calibration

function dsp_bipolar_output = ez_detect_dsp_bipolar(eeg_bp, metadata, hfo_ai, fr_ai, paths);
% hf_bad uses the HFO band pass filtered EEG mutual information
% adjacency matrix during episodes of artifact to define dissimar
% electrodes. The bipolar montage is calculated for the bad electrodes
% and the HFOs are identified in ez_detect_dps_bi.

    dims = metadata.montage_shape;
    metadata.montage = reshape(metadata.montage, dims(1), dims(2));

    bp_toolbox = BipolarDspToolbox; 
    error_status=0;
    error_msg='';

    file_block = metadata.file_block;
    file_id = metadata.file_id;
    ripple.low = 80;
    ripple.high = 600;
    fripple.low = 200;
    fripple.high = 600;
    sampling_rate = 2000; %view if we can add it to metadata struct

    if ~isempty(eeg_bp)
        
        low = 80;
        high = 600;
        hfo = ez_eegfilter(eeg_bp,low, high, sampling_rate);
        [eeg_data, eeg_data_no_notch] = bp_toolbox.notchFilter(eeg_bp); %eeg_data_no_notch is an unfiltered copy of the data.

        % Start Ripple detection
        % Calculate smoothed HFO amplitude
        num_of_data_rows = numel(hfo(:,1));
        ics = hfo;
        score_amp_ripple_i_method = @bp_toolbox.score_amp_ripple_i_method_1;
        zscore_amp_ripple_i_method = @bp_toolbox.zscore_amp_ripple_i_method_1;
        [score_amp_ripple, zscore_amp_ripple] = bp_toolbox.calculateSmoothedHFOamplitude(num_of_data_rows, ics, ...
                                                score_amp_ripple_i_method, zscore_amp_ripple_i_method);
        num_of_m_channels = numel(hfo(:,1));
        thresh_z_values = struct(...
            'first', 1, ...
            'second', 1.2, ...
            'third', 1.4, ...
            'fourth', 1.6, ...
            'fifth', 1.8 ...
        );
        thresh_zoff_values = struct(...
            'first', 0.2, ...
            'second', 0.3, ...
            'third', 0.5, ...
            'fourth', 0.7, ...
            'fifth', 1 ...
        );

        [thresh_z, thresh_zoff] = bp_toolbox.skewnessCorrection(zscore_amp_ripple,num_of_m_channels, ...
                                                     thresh_z_values,thresh_zoff_values);
        config = struct();
        config.zscore_amp_thresh_z = thresh_z; 
        config.zscore_amp_thresh_zoff = thresh_zoff;
        config.amp_thresh = 5.5;
        config.ai_thresh = 0.1; 
        config.min_event_duration_snds = 0.008;
        config.sampling_rate = sampling_rate;
        config.cycle_thresh = 59.99; %in seconds %improve name
        config.search_granularity= 0.001; %Every millisecond
        config.duration_cutoffs = struct(...
            'fst_range', 150, ...
            'fst_val', 0.012, ...
            'snd_range', 250, ...
            'snd_val', 0.008, ...
            'trd_range', 400, ...
            'trd_val', 1 ...  
        );
        config.fripple_run = false;

        ripple_data = bp_toolbox.rippleDetection(eeg_data, score_amp_ripple, zscore_amp_ripple, hfo, hfo_ai, config);

        num_of_data_rows = numel(eeg_data(:,1));
        [hfo_times, hfo_values] = bp_toolbox.convRippleClips_timeToIndices(num_of_data_rows, ripple_data.clip_t, ...
                                                                    hfo, ripple_data.total_count);
        
        run_ripple_nn = true;
        ripple_thresh = 0.282;
        run_fripple_nn = false;
        fripple_thresh = 0; %not used in this call
        b = bp_toolbox.detectAdditionalBadElectrodes_nn(hfo, hfo_values, run_ripple_nn, ripple_thresh, ...
                                             run_fripple_nn, fripple_thresh);

        %create abstraction with the one below
        if numel(b)~=numel(metadata.bp_chanlist)
            % Remove all data for bad channel
            if ~isempty(b)
                eeg_bp(b,:)=[];
                eeg_data(b,:)=[];
                eeg_data_no_notch(b,:)=[];
                hfo(b,:)=[];
                ez_bp = eeg_bp;
                ez_hfo_bp = hfo;
                ripple_data.total_count(b)=[];
                ripple_data.clip(b,:)=[];
                ripple_data.clip_t(b,:)=[];
                ripple_data.clip_event_t(b,:)=[];
                ripple_data.clip_abs_t(b,:)=[];
                
                metadata.hf_bad_bp=metadata.bp_chanlist(b);
                metadata.hf_bad_bp_index=b;
                metadata.bp_chanlist(metadata.hf_bad_bp_index)=[];
            end
        else
            error_status=1;
            error_msg='all noisy bp electrodes';
        end
        
        low = 200;
        high = 600;
        fr = ez_eegfilter(eeg_data_no_notch, low, high, sampling_rate);
        
        num_of_data_rows = numel(fr(:,1));
        score_amp_ripple_i_method = @bp_toolbox.score_amp_ripple_i_method_2;
        zscore_amp_ripple_i_method = @zscore_2;
        [score_amp_fripple, zscore_amp_fripple] = bp_toolbox.calculateSmoothedHFOamplitude(num_of_data_rows, fr, ...
                                                score_amp_ripple_i_method, zscore_amp_ripple_i_method);
        
        num_of_m_channels = numel(hfo(:,1));
        thresh_z_values = struct(...
            'first', 1, ...
            'second', 1.2, ...
            'third', 1.4, ...
            'fourth', 1.5, ...
            'fifth', 1.7 ...
        );
        thresh_zoff_values = struct(...
            'first', 0.1, ...
            'second', 0.3, ...
            'third', 0.6, ...
            'fourth', 0.7, ...
            'fifth', 1 ...
        );

        [thresh_z, thresh_zoff] = bp_toolbox.skewnessCorrection(zscore_amp_fripple, num_of_m_channels, ...
                                                     thresh_z_values, thresh_zoff_values);
        ics = []; %this param is not used for fripple detection
        config = struct();
        config.zscore_amp_thresh_z = thresh_z; 
        config.zscore_amp_thresh_zoff = thresh_zoff;
        config.amp_thresh = 5.5;
        config.ai_thresh = 0.1; 
        config.min_event_duration_snds = 0.006;
        config.sampling_rate = sampling_rate;
        config.cycle_thresh = 59.99; %in seconds %improve name
        config.fripple_run = true; 

        fripple_data = bp_toolbox.rippleDetection(eeg_data, score_amp_fripple, zscore_amp_fripple, ics, fr_ai, config);
    end

    % Create ripple index
    num_of_data_rows = numel(eeg_data(:,1));
    % There was a bug here, it was using ripple_clip_t
    % in the cycle condition for i=1:numel(ripple_clip_t(:,1)) but is fripple
    [hfo_times, hfo_values] = bp_toolbox.convRippleClips_timeToIndices(num_of_data_rows, fripple_data.clip_t, ...
                                                                hfo, fripple_data.total_count);

    run_ripple_nn = false;
    run_ripple_nn = 0; %not used in this call, change for ~ if matlab allows.
    run_fripple_nn = true;
    fripple_thresh = 0.63;
    b = bp_toolbox.detectAdditionalBadElectrodes_nn(hfo, hfo_values, run_ripple_nn, ripple_thresh, ...
                                                        run_fripple_nn, fripple_thresh);
    if numel(b)~=numel(metadata.bp_chanlist)
        % Remove all data for bad channel
        if ~isempty(b)
            eeg_bp(b,:) = [];
            eeg_data(b,:) = [];
            eeg_data_no_notch(b,:) = [];
            hfo(b,:) = [];
            fr(b,:) = [];
            ez_bp = eeg_bp;
            ez_hfo_bp = hfo;
            ez_fr_bp = fr;
            ripple_data.total_count(b) = [];
            fripple_data.total_count(b) = [];
            ripple_data.clip(b,:) = [];
            fripple_data.clip(b,:) = [];
            ripple_data.clip_t(b,:) = [];
            fripple_data.clip_t(b,:) = [];
            ripple_data.clip_event_t(b,:) = [];
            fripple_data.clip_event_t(b,:) = [];
            ripple_data.clip_abs_t(b,:) = [];
            fripple_data.clip_abs_t(b,:) = [];
            
            metadata.hf_bad_bp_fr=metadata.bp_chanlist(b);
            metadata.hf_bad_bp_index_fr=b;
            metadata.bp_chanlist(metadata.hf_bad_bp_index_fr)=[];
        else
            ez_fr_bp = fr;
        end;
    else
        error_status = 1;
        error_msg = 'all noisy bp electrodes';
    end

    eeg_bp = ez_bp;
    if ~isempty(eeg_bp)
        % % Bug fix for empty cells
        emptyCells = cellfun(@isempty,metadata.bp_chanlist);
        [a,b]=find(emptyCells==1);
        metadata.bp_chanlist(b)=[];  %Removed empty channels
        
        chanlist = metadata.bp_chanlist;
        mat2trc_bin_filename ='mat2trc32_bp2k';
        num_trc_blocks = bp_toolbox.writeTRCfiles(eeg_bp, chanlist, metadata, sampling_rate, ...
                         paths.trc_tmp_bipolar, paths.executable, mat2trc_bin_filename);
        % output the stored discrete HFOs
        DSP_data_bp.error_status = error_status;
        DSP_data_bp.error_msg = error_msg;
        DSP_data_bp.metadata = metadata;
        DSP_data_bp.file_block = file_block;
        DSP_data_bp.data_duration = numel(eeg_data(1,:))/2000;
        [a,b]=find(hfo_ai>0.1);
        artifact_duration=(numel(a)/2000);
        DSP_data_bp.r_clean_duration=DSP_data_bp.data_duration-artifact_duration;
        [a,b]=find(fr_ai>0.1);
        artifact_duration=(numel(a)/2000);
        DSP_data_bp.fr_clean_duration=DSP_data_bp.data_duration-artifact_duration;
        DSP_data_bp.ripple_clip=ripple_data.clip;
        DSP_data_bp.ripple_clip_abs_t=ripple_data.clip_abs_t;
        DSP_data_bp.ripple_clip_event_t=ripple_data.clip_event_t;
        DSP_data_bp.total_ripple=ripple_data.total_count;
        DSP_data_bp.fripple_clip=fripple_data.clip;
        DSP_data_bp.fripple_clip_abs_t=fripple_data.clip_abs_t;
        DSP_data_bp.fripple_clip_event_t=fripple_data.clip_event_t;
        DSP_data_bp.total_fripple=fripple_data.total_count;
        
        filename1=['dsp_' file_id '_bp_' file_block '.mat'];
        filename1=strcat(paths.ez_top_in,filename1);
        save(filename1,'DSP_data_bp','-v7.3');
    else
        DSP_data_bp=[];
        ez_bp=[];
        ez_hfo_bp=[];
        ez_fr_bp=[];
    end % if eeg_bp exists

    %to be improved later, add error_flag
        %'DSP_data_bp', DSP_data_bp, ...
    dsp_bipolar_output = struct( ...
        'ez_bp', ez_bp, ...
        'ez_hfo_bp', ez_hfo_bp, ...
        'ez_fr_bp', ez_fr_bp, ...
        'metadata', metadata, ...
        'num_trc_blocks', num_trc_blocks, ...
        'path_to_data', filename1 ...
    );
        
    %%%fixing metadata montage dims
    dsp_bipolar_output.metadata.montage_shape = [numel(dsp_bipolar_output.metadata.montage(:,1)),numel(dsp_bipolar_output.metadata.montage(1,:))];
    dsp_bipolar_output.metadata.montage= reshape(dsp_bipolar_output.metadata.montage,1,[]); %matlab engine can only return 1*n cell arrays. I changed the data structure to get mlarray.

end
