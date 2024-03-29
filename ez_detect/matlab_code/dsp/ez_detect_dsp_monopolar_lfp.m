% this is prototype code to detect HFOs and spikes in LFP recordings from
% Behnke-Fried microelectrodes. In contrast to the SEEG pipeline this code
% "hfo_annotate_nothreads" does not include any functions for the exclusion
% of bad electrodes. It is assummed that the user will include only valid
% electrodes within Micromed. In addition, this version performs only a
% referential analysis and does not include a bipolar analysis. Note also
% that ICA functions have been removed because ICA is applied during the
% conversion from Neuralynx data to TRC format in nlx2mat.m

% This work is protected by US patent applications US20150099962A1,
% UC-2016-158-2-PCT, US provisional #62429461

% Written by Shennan Aibel Weiss MD, PhD. in Matlab at Thomas Jefferson University
% Philadelphia, PA USA.

function dsp_monopolar_output = ez_detect_dsp_monopolar_lfp(eeg_mp, eeg_bp, metadata, paths);

    % hf_bad uses the HFO band pass filtered EEG mutual information
    % adjacency matrix, and graph theory (community) during episodes of artifact to define dissimar
    % electrodes. The bipolar montage is calculated for the dissimilar
    % electrodes recover cell structure after matlab engine
    dims = metadata.montage_shape;
    metadata.montage = reshape(metadata.montage, dims(1), dims(2));
    metadata.hf_bad_bp=[];
    metadata.hf_bad_m=[];
    metadata.lf_bad=[];

    mp_toolbox = MonopolarDspToolbox; 
    bp_toolbox = BipolarDspToolbox; 
    error_status = 0; 
    error_msg = '';
    file_block = metadata.file_block;
    file_id = metadata.file_id;
    ripple.low = 80;
    ripple.high = 600;
    fripple.low = 200;
    fripple.high = 600;
    sampling_rate = 2000; %view if we can add it to metadata struct

    % v4 bug fix perform xcorr function prior to running hfbad in order to
    % remove other 60 cycle artifact outliers prior to hfbad
    
    % cudaica_matlab function isolates muscle artifact producing artifactual
    % HFOs to the first independent component of the HFO band pass filtered
    % EEG. The first independent component is removed to reduce artifact, and
    % IC1 is also used to refine the artifact index on a millisecond time
    % scale.
    hfo = ez_eegfilter(eeg_mp, ripple.low, ripple.high, sampling_rate);
    
        % Start Ripple detection
        % Calculate smoothed HFO amplitude
        num_of_data_rows = numel(hfo(:,1));
        ics = hfo;
        score_amp_ripple_i_method = @bp_toolbox.score_amp_ripple_i_method_1;
        zscore_amp_ripple_i_method = @bp_toolbox.zscore_amp_ripple_i_method_1;
        [score_amp_ripple, zscore_amp_ripple] = bp_toolbox.calculateSmoothedHFOamplitude(num_of_data_rows, ics, ...
                                                score_amp_ripple_i_method, zscore_amp_ripple_i_method);

        num_of_m_channels = numel(metadata.m_chanlist);
        thresh_z_values = struct(...
            'first', 0.8, ...
            'second', 1.0, ...
            'third', 1.2, ...
            'fourth', 1.7, ...
            'fifth', 1.9 ...
        );
        thresh_zoff_values = struct(...
            'first', 0.1, ...
            'second', 0.2, ...
            'third', 0.4, ...
            'fourth', 0.8, ...
            'fifth', 1 ...
        );
        [thresh_z, thresh_zoff] = mp_toolbox.skewnessCorrection(zscore_amp_ripple, num_of_m_channels, ...
                                                         thresh_z_values, thresh_zoff_values);

        % initialize data structures '2D array of cells' note that this structure can flexibly
        % store different length elements within each cell, and the number of cells can vary by
        % row. This structure may need to be revised to improve efficiency.
        config = struct();
        config.ai_thresh = 0.1; 
        config.zscore_amp_thresh_z = thresh_z;
        config.zscore_amp_thresh_zoff = thresh_zoff;
        config.amp_thresh = 5.5;
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
        hfo_ai=zeros(numel(hfo(1,:)),1);
        fr_ai=hfo_ai;

        ripple_data = bp_toolbox.rippleDetection(eeg_mp, score_amp_ripple, zscore_amp_ripple, hfo, hfo_ai, config);
        num_of_data_rows = numel(eeg_mp(:,1));
        num_of_data_cols = numel(eeg_mp(1,:));
        % Fast ripple detection

        low = 200;
        high = 600;
        fr = ez_eegfilter(eeg_mp, fripple.low, fripple.high, sampling_rate);
        
        num_of_data_rows = numel(fr(:,1));
        score_amp_ripple_i_method = @bp_toolbox.score_amp_ripple_i_method_2;
        zscore_amp_ripple_i_method = @zscore_2;
        [score_amp_fripple, zscore_amp_fripple] = bp_toolbox.calculateSmoothedHFOamplitude(num_of_data_rows, fr, ...
                                                score_amp_ripple_i_method, zscore_amp_ripple_i_method);
        
            thresh_z_values = struct(...
                'first', 2.0, ...
                'second', 2.2, ...
                'third', 2.5, ...
                'fourth', 3.0, ...
                'fifth', 3.3 ...
            );
            thresh_zoff_values = struct(...
                'first', 0.4, ...
                'second', 0.6, ...
                'third', 0.8, ...
                'fourth', 1.2, ...
                'fifth', 1.4 ...
            );

            [thresh_z, thresh_zoff] = mp_toolbox.skewnessCorrection(zscore_amp_fripple, num_of_m_channels, ...
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

            fripple_data = bp_toolbox.rippleDetection(eeg_mp, score_amp_fripple, zscore_amp_fripple, ics, fr_ai, config);
        
            % output the stored discrete HFOs
            DSP_data_m.error_status=0;
            DSP_data_m.error_msg=0;
            DSP_data_m.metadata=metadata;
            DSP_data_m.file_block=file_block;
            DSP_data_m.data_duration=num_of_data_cols/2000;
            DSP_data_m.fr_clean_duration=DSP_data_m.data_duration;
            DSP_data_m.ripple_clip=ripple_data.clip;
            DSP_data_m.ripple_clip_abs_t=ripple_data.clip_abs_t;
            DSP_data_m.ripple_clip_event_t=ripple_data.clip_event_t;
            DSP_data_m.total_ripple=ripple_data.total_count;
            DSP_data_m.fripple_clip=fripple_data.clip;
            DSP_data_m.fripple_clip_abs_t=fripple_data.clip_abs_t;
            DSP_data_m.fripple_clip_event_t=fripple_data.clip_event_t;
            DSP_data_m.total_fripple=fripple_data.total_count;
            
            filename1 = ['dsp_' metadata.file_id '_m_' metadata.file_block '.mat'];
            filename1 = strcat('/data/downstate/ez-detect/disk_dumps/ez_top/input', '/' ,filename1);
            save(filename1,'DSP_data_m', '-v7.3');
            error_flag=0;
            dsp_monopolar_output = struct( ...
                'ez_mp', eeg_mp, ...      
                'ez_bp', eeg_bp, ...
                'hfo_ai', hfo_ai, ...
                'fr_ai', fr_ai, ...
                'ez_hfo_mp', hfo, ...
                'ez_fr_mp', fr, ...
                'metadata', metadata, ...
                'error_flag', error_flag, ...
                'path_to_data', filename1 ...
            );

                %%%fixing metadata montage dims
           dsp_monopolar_output.metadata.montage_shape = [numel(dsp_monopolar_output.metadata.montage(:,1)),numel(dsp_monopolar_output.metadata.montage(1,:))];
           dsp_monopolar_output.metadata.montage= reshape(dsp_monopolar_output.metadata.montage,1,[]); %matlab engine can only return 1*n cell arrays. I changed the data structure to get mlarray.
           
end