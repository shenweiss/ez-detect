% This is the first production code of the monopolar EZ detect DSP codename
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
% Philadelphia, PA USA.

function dsp_monopolar_output = ez_detect_dsp_monopolar(eeg_mp, eeg_bp, metadata, paths);

% hf_bad uses the HFO band pass filtered EEG mutual information
% adjacency matrix, and graph theory (community) during episodes of artifact to define dissimar
% electrodes. The bipolar montage is calculated for the dissimilar
% electrodes
 %recover cell structure after matlab engine
dims = metadata.montage_shape;
metadata.montage = reshape(metadata.montage, dims(1), dims(2));

mp_toolbox = MonopolarDspToolbox; 
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
[eeg_mp, metadata] = mp_toolbox.remove60CycleArtifactOutliers(eeg_mp, metadata); %NEW
ez_tall_m=tall(eeg_mp);

fprintf('Removing excess HF artifact electrodes \r');
[metadata]=ez_hfbad_putou02(ez_tall_m,metadata); % Find MI of maximum artifact


% Remove bad channels from monopolar montage
chan_indexes = metadata.hf_bad_m_index;
metadata.hf_bad_m = metadata.m_chanlist(chan_indexes);
[eeg_mp, eeg_bp, metadata] = mp_toolbox.removeBadChannelsFromMonopolarMontage(eeg_mp, ...
                                                     eeg_bp, metadata, chan_indexes);
ez_tall_m=tall(eeg_mp);
ez_tall_bp=tall(eeg_bp);

% Bug fix for empty cells
emptyCells = cellfun(@isempty,metadata.m_chanlist);
[a,b]=find(emptyCells==1);
metadata.m_chanlist(b)={'BUG'};

%% Notch filter eeg_data
[eeg_data, eeg_data_no_notch] = mp_toolbox.notchFilter(eeg_mp);


% cudaica_matlab function isolates muscle artifact producing artifactual
% HFOs to the first independent component of the HFO band pass filtered
% EEG. The first independent component is removed to reduce artifact, and
% IC1 is also used to refine the artifact index on a millisecond time
% scale.

%[hfo, ic1, EEG, error_flag]=ez_cudaica_ripple_putou_e1(eeg_data_no_notch,2000);
[hfo, ic1, EEG, error_flag] = ez_cudaica_ripple(eeg_data_no_notch, ripple.low, ripple.high, sampling_rate, paths);

if error_flag==0 % error flag 1
    ez_tall_hfo_m=tall(hfo);
    
    % The code below is used to detect overstripped recordings
    % following pruning of IC1.
    [~, z_lost_peaks] = mp_toolbox.detectOverstrippedRecordings(hfo, ic1, @mp_toolbox.method_one);
    
    % The artifact index is used to define epochs of muscle and electrode
    % artifact it is used to reject HFO detections in both the referential
    % and bipolar montages.
    ai_rows = numel(hfo(:,1));
    ai_cols = numel(hfo(1,:));
    smooth_span = 1200;
    smooth_method = 'lowess';
    [ai] = mp_toolbox.calculateArtifactIndex(ai_rows, ai_cols, hfo, ic1, smooth_span, smooth_method);
    hfo_ai = ai; 

    % compensate for overstripping in HFO IC1
    nan_ica_size = numel(hfo(:,1));
    threshold = 15;
    nan_ica = mp_toolbox.compensateOverstrippingHFO_IC1(nan_ica_size, z_lost_peaks, threshold);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Start Ripple detection
    % Calculate smoothed HFO amplitude
    num_of_data_rows = numel(hfo(:,1));
    score_amp_ripple_i_method = @mp_toolbox.score_amp_ripple_i_method_1;
    zscore_amp_ripple_i_method = @mp_toolbox.zscore_amp_ripple_i_method_1;
    [score_amp_ripple, zscore_amp_ripple] = mp_toolbox.calculateSmoothedHFOamplitudeNanIca(num_of_data_rows, ...
                                        hfo, ic1, nan_ica, score_amp_ripple_i_method, zscore_amp_ripple_i_method);

    num_of_m_channels = numel(metadata.m_chanlist);
    thresh_z_values = struct(...
        'first', 1.1, ...
        'second', 1.3, ...
        'third', 1.5, ...
        'fourth', 1.7, ...
        'fifth', 1.9 ...
    );
    thresh_zoff_values = struct(...
        'first', 0.2, ...
        'second', 0.4, ...
        'third', 0.6, ...
        'fourth', 0.8, ...
        'fifth', 1 ...
    );
    [thresh_z, thresh_zoff] = mp_toolbox.skewnessCorrection(zscore_amp_ripple, num_of_m_channels, ...
                                                     thresh_z_values, thresh_zoff_values);

    
    % initialize data structures '2D array of cells' note that this structure can flexibly
    % store different length elements within each cell, and the number of cells can vary by
    % row. This structure may need to be revised to improve efficiency.
    config = struct();
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
    config.ai_thresh = 0.05; %1

    ripple_data = mp_toolbox.rippleDetection(eeg_data, score_amp_ripple, zscore_amp_ripple, ic1, ai, config);

    ripple_clip=ripple_data.clip;
    ripple_clip_t=ripple_data.clip_t;
    ripple_clip_event_t=ripple_data.clip_event_t;
    ripple_clip_abs_t=ripple_data.clip_abs_t;
    total_ripple=ripple_data.total_count;

    num_of_data_rows = numel(eeg_data(:,1));
    [hfo_times, hfo_values] = mp_toolbox.convRippleClips_timeToIndices(num_of_data_rows, ripple_data.clip_t, ...
                                                                    ic1, ripple_data.total_count);
    
    % v7 MODIFICATION: this new section removes bad channels based on a trained
    % neural network
    run_ripple_nn = true;
    ripple_thresh = 0.282; %not used in this call, change for ~ if matlab allows.
    run_fripple_nn = true;
    fripple_thresh = 0.4;
    b = mp_toolbox.detectAdditionalBadElectrodes_nn(hfo, hfo_values, run_ripple_nn, ripple_thresh, ...
                                                        run_fripple_nn, fripple_thresh);

    if numel(b)<numel(metadata.m_chanlist)-10 % if number of bad electrodes are not the vast majority
        if ~isempty(b)  % if bad electrodes detected
            fprintf('removing bad electrodes repeating calculations and detections \r');

            chan_indexes = b;
            metadata.hf_bad_m2 = metadata.m_chanlist(chan_indexes);
            %i think that the parameter may be eeg_data instead of eeg_mp
            [eeg_mp, eeg_bp, metadata] = mp_toolbox.removeBadChannelsFromMonopolarMontage(eeg_mp, ...
                                                                     eeg_bp, metadata, chan_indexes);
            ez_tall_m=tall(eeg_mp);
            ez_tall_bp=tall(eeg_bp);

            % Remove bad electrodes from eeg_data and eeg_data_no_notch
            eeg_data(b,:)=[];
            eeg_data_no_notch(b,:)=[];
            
            % Bug fix for empty cells
            emptyCells = cellfun(@isempty,metadata.m_chanlist);
            [a,b]=find(emptyCells==1);
            metadata.m_chanlist(b)={'BUG'};

            % repeat ICA
            [hfo, ic1, EEG, error_flag] = ez_cudaica_ripple(eeg_data_no_notch, ripple.low, ripple.high, sampling_rate, paths);
            
            if error_flag == 0
                ez_tall_hfo_m=tall(hfo);
                % The code below is used to detect overstripped recordings
                % following pruning of IC1.
                [~, z_lost_peaks] = mp_toolbox.detectOverstrippedRecordings(hfo, ic1, @mp_toolbox.method_one);
                
                % The artifact index is used to define epochs of muscle and electrode
                % artifact it is used to reject HFO detections in both the referential
                % and bipolar molost_peaks, counterntages.
                ai_rows = numel(hfo(:,1));
                ai_cols = numel(hfo(1,:));
                smooth_span = 1200;
                smooth_method = 'lowess';
                [ai] = mp_toolbox.calculateArtifactIndex(ai_rows, ai_cols, hfo, ic1, smooth_span, smooth_method);
                hfo_ai = ai; 

                % Reperform ripple detection part 1.
                
                % Compensate for overstripping in HFO IC1
                % you will need to take this out for completed EZ detect %% ask for this comment
                nan_ica_size = numel(hfo(:,1));
                threshold = 15;
                nan_ica = mp_toolbox.compensateOverstrippingHFO_IC1(nan_ica_size, z_lost_peaks, threshold);

                % Start Ripple detection
                % Calculate smoothed HFO amplitude
                num_of_data_rows = numel(hfo(:,1));
                score_amp_ripple_i_method = @mp_toolbox.score_amp_ripple_i_method_1;
                zscore_amp_ripple_i_method = @mp_toolbox.zscore_amp_ripple_i_method_1;
                [score_amp_ripple, zscore_amp_ripple] = mp_toolbox.calculateSmoothedHFOamplitudeNanIca(num_of_data_rows, ...
                                        hfo, ic1, nan_ica, score_amp_ripple_i_method, zscore_amp_ripple_i_method); 
                
                num_of_m_channels = numel(metadata.m_chanlist);
                thresh_z_values = struct(...
                    'first', 1.1, ...
                    'second', 1.3, ...
                    'third', 1.5, ...
                    'fourth', 1.7, ...
                    'fifth', 1.8 ...
                );
                thresh_zoff_values = struct(...
                    'first', 0.3, ...
                    'second', 0.5, ...
                    'third', 0.7, ...
                    'fourth', 0.8, ...
                    'fifth', 0.9 ...
                );
                [thresh_z, thresh_zoff] = mp_toolbox.skewnessCorrection(zscore_amp_ripple, num_of_m_channels, ...
                                                                thresh_z_values, thresh_zoff_values);
            
                % initialize data structures '2D array of cells' note that this structure can flexibly
                % store different length elements within each cell, and the number of cells can vary by
                % row. This structure may need to be revised to improve efficiency.
                config = struct();
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
                config.ai_thresh = 0.1; 

                ripple_data = mp_toolbox.rippleDetection(eeg_data, score_amp_ripple, zscore_amp_ripple, ic1, ai, config);
                ripple_clip=ripple_data.clip;
                ripple_clip_t=ripple_data.clip_t;
                ripple_clip_event_t=ripple_data.clip_event_t;
                ripple_clip_abs_t=ripple_data.clip_abs_t;
                total_ripple=ripple_data.total_count;

                % Create ripple index
                num_of_data_rows = numel(eeg_data(:,1));
                [hfo_times, ~] = mp_toolbox.convRippleClips_timeToIndices(num_of_data_rows, ripple_data.clip_t, ic1, ripple_data.total_count);
                %check I think hfo_times is not used after this
            else % error_flag 1 i.e. CUDAICA exploded ICA #2 
                dsp_monopolar_output = mp_toolbox.cudaicaFailureHandle(eeg_mp, eeg_bp, metadata, paths.ez_top_in);
                DSP_data_m = dsp_monopolar_output.DSP_data_m;
                ez_mp = dsp_monopolar_output.ez_mp;
                ez_bp = dsp_monopolar_output.ez_bp;
                hfo_ai = dsp_monopolar_output.hfo_ai;
                fr_ai = dsp_monopolar_output.fr_ai;
                ez_hfo_m = dsp_monopolar_output.ez_hfo_mp;
                ez_fr_m = dsp_monopolar_output.ez_fr_mp;
                metadata = dsp_monopolar_output.metadata;
                num_trc_blocks = dsp_monopolar_output.num_trc_blocks ;
                error_flag = dsp_monopolar_output.error_flag;

                %temp until we remove talls
                ez_tall_bp=tall(ez_bp);
                ez_tall_m=[];
                ez_tall_hfo_m=[];
                ez_tall_fr_m=[];

            end
        end % bad electrode detected loop
    else % if number of bad electrodes are not the vast majority
        error_status=1;
        error_msg='mostly noisy mp electrodes';
    end
        
    num_trc_blocks=ceil(numel(metadata.m_chanlist)/32);

    % Continue ripple detection part 2.
    % Calculate ripple extract index
    num_of_data_cols = numel(eeg_data(1,:));
    num_of_data_rows = numel(eeg_data(:,1));
    ripple_art_index_thresh = 0.025;
    ripple_hfo_extract_index_thresh = 800;
    ripple_ics = mp_toolbox.getRippleIcs(num_of_data_cols, num_of_data_rows, EEG, hfo_times, ai, ...
                                         ripple_art_index_thresh, ripple_hfo_extract_index_thresh);
    % Redefine z_score block using ripple_ics
    num_of_data_rows = numel(hfo(:,1));            
    score_amp_ripple_i_method = @mp_toolbox.score_amp_ripple_i_method_1;
    zscore_amp_ripple_i_method = @mp_toolbox.zscore_amp_ripple_i_method_2;
    [score_amp_ripple, zscore_amp_ripple] = mp_toolbox.calculateSmoothedHFOamplitude(num_of_data_rows, ripple_ics, ...
                                            score_amp_ripple_i_method, zscore_amp_ripple_i_method);

    %{
    %% The original next call to ripple detection 
    %used hfo instead of eeg data for iterating rows and columns of eeg_data, but dimensions 
    %are the same and in the other calls eeg data is used, which makes sense because you are 
    %iterating that structure. I leave this comment just in case to remember the change.
    disp('THESE DIMENSIONS SHOULD BE THE SAME');  
    disp(['eeg_data_channels' num2str(numel(eeg_data(:,1)) )] );
    disp(['eeg_data_cols' num2str(numel(eeg_data(1,:)) )] );
    disp(['hfo_channels' num2str(numel(hfo(:,1)) )] );
    disp(['hfo_cols' num2str(numel(hfo(1,:)))]);
    %}

    %ai were not being used in this call, it was added, ask if it doesn't mess up
    config = struct();
    config.zscore_amp_thresh_z = ones(1, numel(eeg_data(:,1)));
    config.zscore_amp_thresh_zoff = ones(1, numel(eeg_data(:,1)))*(-0.2);
    config.amp_thresh = 4;
    config.min_event_duration_snds = 0.001;
    config.sampling_rate = sampling_rate;
    config.cycle_thresh = 59.9;
    config.search_granularity = 0.002; %Every two millisecond
    config.duration_cutoffs = struct(...
        'fst_range', 150, ...
        'fst_val', 0.001, ...
        'snd_range', 200, ...
        'snd_val', 0.001, ...
        'trd_range', 400, ...
        'trd_val', 1 ...  
    );
    config.fripple_run = false;
    config.ai_thresh = 0.05; 

    ripple_ics_data = mp_toolbox.rippleDetection(eeg_data, score_amp_ripple, zscore_amp_ripple, ripple_ics, ai, config);
    ripple_ic_clip=ripple_ics_data.clip;
    ripple_ic_clip_t=ripple_ics_data.clip_t;
    ripple_ic_clip_event_t=ripple_ics_data.clip_event_t;
    ripple_ic_clip_abs_t=ripple_ics_data.clip_abs_t;
    total_ripple_ic=ripple_ics_data.total_count;
    
    % Create master look up ripple time index for step 1 detection
    % Convert ripple clips from time to indices, we can have save indexes in rippleDeteccion, for later
    % Create ripple index
    num_of_data_rows = numel(eeg_data(:,1));
    [hfo_times, ~ ] = mp_toolbox.convRippleClips_timeToIndices(num_of_data_rows, ripple_data.clip_t, ic1, ripple_data.total_count);

    % if ripple not in look up index add the to total_ripple and add ripples
    % from step 2 to ripple clips
    ripple_data = mp_toolbox.addRipples(num_of_data_rows,hfo_times, ripple_data, ripple_ics_data);

    %% Calculate ICA for fast ripples (FR)
    [fr, fr_ic1, EEG, error_flag] = ez_cudaica_ripple(eeg_data_no_notch, fripple.low, fripple.high, sampling_rate, paths);
    
    if error_flag==0
        ez_tall_fr_m=tall(fr);
        
        [z_delta_amp_peak_fr, z_lost_peaks_fr] = mp_toolbox.detectOverstrippedRecordings(fr, fr_ic1, @zscore_2);
                
        %[a_value,b_ind]=min((z_delta_amp_peak_fr)); % Find Replacement AI index  %THIS WASN'T BEING USED
        
        % compensate for overstripping in FR IC1
        % you will need to replace this completed EZ detect and include HF bad channels

        nan_ica_size = numel(eeg_data(:,1));
        threshold = 5;
        nan_ica = mp_toolbox.compensateOverstrippingHFO_IC1(nan_ica_size, z_lost_peaks_fr, threshold);

        ai_rows = numel(eeg_data(:,1));
        ai_cols = numel(eeg_data(1,:));
        smooth_span = 3000;
        smooth_method = 'moving';
        [ai] = mp_toolbox.calculateArtifactIndex(ai_rows, ai_cols, fr, fr_ic1, smooth_span, smooth_method);
        fr_ai = ai; 
        
        num_of_data_rows = numel(fr(:,1));
        ics = fr_ic1;
        score_amp_ripple_i_method = @mp_toolbox.score_amp_ripple_i_method_2; 
        zscore_amp_ripple_i_method = @zscore_2;
        [score_amp_fripple, zscore_amp_fripple] = mp_toolbox.calculateSmoothedHFOamplitude(num_of_data_rows, ics, ...
                                                  score_amp_ripple_i_method, zscore_amp_ripple_i_method);
        
        % V4 add adjustment for skewness for fast ripple detection
        num_of_m_channels = numel(metadata.m_chanlist);

        thresh_z_values = struct(...
            'first', 2.5, ...
            'second', 2.7, ...
            'third', 2.9, ...
            'fourth', 3.2, ...
            'fifth', 3.5 ...
        );
        thresh_zoff_values = struct(...
            'first', 0.6, ...
            'second', 0.8, ...
            'third', 1, ...
            'fourth', 1.3, ...
            'fifth', 1.5 ...
        );

        [thresh_z, thresh_zoff] = mp_toolbox.skewnessCorrection(zscore_amp_fripple, num_of_m_channels, ...
                                                              thresh_z_values, thresh_zoff_values);


        % initialize data structures '2D array of cells' note that this structure can flexibly
        % store different length elements within each cell, and the number of cells can vary by
        % row. This structure may need to be revised to improve efficiency.
        config = struct();
        config.zscore_amp_thresh_z = thresh_z;
        config.zscore_amp_thresh_zoff = thresh_zoff;
        config.amp_thresh = 4;
        config.min_event_duration_snds = 0.006;
        config.sampling_rate = sampling_rate;
        config.cycle_thresh = 59.9;
        config.fripple_run = true;
        config.ai_thresh = 0.1;
        
        fripple_data = mp_toolbox.rippleDetection(eeg_data, score_amp_fripple, zscore_amp_fripple, ics, ai, config);
        
        fripple_clip=fripple_data.clip;
        fripple_clip_t=fripple_data.clip_t;
        fripple_clip_event_t=fripple_data.clip_event_t;
        fripple_clip_abs_t=fripple_data.clip_abs_t;
        total_fripple=fripple_data.total_count;

        
        % Create ripple index
        num_of_data_rows = numel(eeg_data(:,1));
        [hfo_times, ~] = mp_toolbox.convRippleClips_timeToIndices(num_of_data_rows, fripple_data.clip_t, ...
                                                           ic1,fripple_data.total_count);

        num_of_data_cols = numel(eeg_data(1,:));
        fripple_art_index_thresh = 0.020;
        fripple_hfo_extract_index_thresh = 150;
        fripple_ics = mp_toolbox.getRippleIcs(num_of_data_cols, num_of_data_rows, EEG, hfo_times, ai, ...
                                   fripple_art_index_thresh, fripple_hfo_extract_index_thresh);

        score_amp_ripple_i_method = @mp_toolbox.score_amp_ripple_i_method_1;
        zscore_amp_ripple_i_method = @mp_toolbox.zscore_amp_ripple_i_method_2;
        [eeg.score_amp_fripple, eeg.zscore_amp_fripple] = mp_toolbox.calculateSmoothedHFOamplitude(num_of_data_rows, ....
                                    fripple_ics, score_amp_ripple_i_method, zscore_amp_ripple_i_method);

        config = struct();
        config.zscore_amp_thresh_z = ones(1, numel(eeg_data(:,1)))*0.5;
        config.zscore_amp_thresh_zoff = ones(1, numel(eeg_data(:,1)))*(-0.2);
        config.amp_thresh = 3;
        config.min_event_duration_snds = 0.005;
        config.sampling_rate = sampling_rate;
        config.cycle_thresh = 59.9; %in seconds %improve name
        config.fripple_run = true;
        config.ai_thresh = 0.1; 

        fripple_ics_data = mp_toolbox.rippleDetection(eeg_data, eeg.score_amp_fripple, eeg.zscore_amp_fripple, ics, ai, config);
        fripple_data = mp_toolbox.addRipples(num_of_data_rows,hfo_times, fripple_data, fripple_ics_data);

        fripple_clip=fripple_data.clip;
        fripple_clip_t=fripple_data.clip_t;
        fripple_clip_event_t=fripple_data.clip_event_t;
        fripple_clip_abs_t=fripple_data.clip_abs_t;
        total_fripple=fripple_data.total_count;
        
        % output the stored discrete HFOs
        DSP_data_m.error_status=error_status;
        DSP_data_m.error_msg=error_msg;
        DSP_data_m.metadata=metadata;
        DSP_data_m.file_block=file_block;
        DSP_data_m.data_duration=num_of_data_cols/2000;
        [a,b]=find(hfo_ai>0.1);
        artifact_duration=(numel(a)/2000);
        DSP_data_m.r_clean_duration=DSP_data_m.data_duration-artifact_duration;
        [a,b]=find(fr_ai>0.1);
        artifact_duration=(numel(a)/2000);
        DSP_data_m.fr_clean_duration=DSP_data_m.data_duration-artifact_duration;
        DSP_data_m.ripple_clip=ripple_data.clip;
        DSP_data_m.ripple_clip_abs_t=ripple_data.clip_abs_t;
        DSP_data_m.ripple_clip_event_t=ripple_data.clip_event_t;
        DSP_data_m.total_ripple=ripple_data.total_count;
        DSP_data_m.fripple_clip=fripple_data.clip;
        DSP_data_m.fripple_clip_abs_t=fripple_data.clip_abs_t;
        DSP_data_m.fripple_clip_event_t=fripple_data.clip_event_t;
        DSP_data_m.total_fripple=fripple_data.total_count;
        
        filename1 = ['dsp_' metadata.file_id '_m_' metadata.file_block '.mat'];
        filename1 = strcat(paths.ez_top_in,filename1);
        save(filename1,'DSP_data_m', '-v7.3');
        %'DSP_data_m', DSP_data_m, ...  
        dsp_monopolar_output = struct( ...
            'ez_mp', eeg_mp, ...      
            'ez_bp', eeg_bp, ...
            'hfo_ai', hfo_ai, ...
            'fr_ai', fr_ai, ...
            'ez_hfo_mp', hfo, ...
            'ez_fr_mp', fr, ...
            'metadata', metadata, ...
            'num_trc_blocks', num_trc_blocks, ...
            'error_flag', error_flag, ...
            'path_to_data', filename1 ...
        );


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %{
        % output the stored discrete HFOs
        DSP_data_m.error_status=error_status;
        DSP_data_m.error_msg=error_msg;
        DSP_data_m.metadata=metadata;
        DSP_data_m.file_block=file_block;
        DSP_data_m.data_duration=numel(eeg_data(1,:))/2000;
        [a,b]=find(hfo_ai>0.1);
        artifact_duration=(numel(a)/2000);
        DSP_data_m.r_clean_duration=DSP_data_m.data_duration-artifact_duration;
        [a,b]=find(fr_ai>0.1);
        artifact_duration=(numel(a)/2000);
        DSP_data_m.fr_clean_duration=DSP_data_m.data_duration-artifact_duration;
        DSP_data_m.total_ripple=total_ripple;
        DSP_data_m.ripple_clip=ripple_clip;
        DSP_data_m.ripple_clip_abs_t=ripple_clip_abs_t;
        DSP_data_m.ripple_clip_event_t=ripple_clip_event_t;
        DSP_data_m.total_fripple=total_fripple;
        DSP_data_m.fripple_clip=fripple_clip;
        DSP_data_m.fripple_clip_abs_t=fripple_clip_abs_t;
        DSP_data_m.fripple_clip_event_t=fripple_clip_event_t;
         
        filename1 = ['dsp_' metadata.file_id '_m_' metadata.file_block '.mat'];
        filename1 = strcat(paths.ez_top_in,filename1);
        save(filename1,'DSP_data_m', '-v7.3');

            %'DSP_data_m', DSP_data_m, ...
        dsp_monopolar_output = struct( ...
            'ez_mp', gather(ez_tall_m), ...      
            'ez_bp', gather(ez_tall_bp), ...
            'hfo_ai', hfo_ai, ...
            'fr_ai', fr_ai, ...
            'ez_hfo_mp', gather(ez_tall_hfo_m), ...
            'ez_fr_mp', gather(ez_tall_fr_m), ...
            'metadata', metadata, ...
            'num_trc_blocks', num_trc_blocks, ...
            'error_flag', error_flag, ...
            'path_to_data', filename1 ...
        );
        %}
    else % error_flag 1 i.e. CUDAICA exploded ICA #3

        dsp_monopolar_output = mp_toolbox.cudaicaFailureHandle(eeg_mp, eeg_bp, metadata, paths.ez_top_in);
        %{
        b=numel(metadata.m_chanlist);
        b=[1:b];
        fprintf('CUDAICA exploded moving channels to bipolar montage \r');
        % Remove bad channels from monopolar montage
        eeg_mp=gather(ez_tall_m);
        eeg_bps=gather(ez_tall_bp);
        metadata.hf_bad_m2=(metadata.m_chanlist(b));
        new_eeg_bp=[];
        new_bp_chans={''};
        counter=0;
        for i=1:numel(b)
            % locate bp channel (possibly not found)
            [C,IA,IB]=intersect(metadata.hf_bad_m2(i),metadata.montage(:,1));
            if ~isempty(C)
                ref=cell2mat(metadata.montage(IB,3));
                if ref~=0
                    [C2,IIA,IIB]=intersect(metadata.montage(ref,1),metadata.m_chanlist);
                    if ~isempty(C2)
                        counter=counter+1;
                        new_eeg_bp(counter,:)=eeg_mp(b(i),:)-eeg_mp(IIB,:);
                        new_bp_chans(counter)=metadata.hf_bad_m2(i);
                    end;
                end;
            end;
        end;
        
        clear C C2 IA IIA IB IIB counter
        % add bp recording to bp array
        fprintf('rebuilding monopolar and bipolar montages \r');
        eeg_bps=vertcat(new_eeg_bp, eeg_bps);
        metadata.bp_chanlist=horzcat(new_bp_chans, metadata.bp_chanlist);
        
        % build tall structure
        ez_tall_bp=tall(eeg_bps);
        eeg_bps=[];
        new_eeg_bp=[];
        DSP_data_m=[];
        ez_tall_m=[];
        hfo_ai=zeros(numel(gather(ez_tall_bp(1,:))),1);
        fr_ai=zeros(numel(gather(ez_tall_bp(1,:))),1);
        ez_tall_hfo_m=[];
        ez_tall_fr_m=[];
        num_trc_blocks=1;
         
        filename1 = ['dsp_' metadata.file_id '_m_' metadata.file_block '.mat'];
        filename1 = strcat(paths.ez_top_in,filename1);
        save(filename1,'DSP_data_m', '-v7.3');

            %'DSP_data_m', DSP_data_m, ...
        dsp_monopolar_output = struct( ...
            'ez_mp', [], ...      
            'ez_bp', gather(ez_tall_bp), ...
            'hfo_ai', zeros(numel(gather(ez_tall_bp(1,:))),1), ...
            'fr_ai', zeros(numel(gather(ez_tall_bp(1,:))),1), ...
            'ez_hfo_mp', [], ...
            'ez_fr_mp', [], ...
            'metadata', metadata, ...
            'num_trc_blocks', 1, ...
            'error_flag', 1, ...
            'path_to_data', filename1 ...
        );
    end;

    %}
    end    
    
else % error_flag 1 i.e. CUDAICA exploded ICA #1
    dsp_monopolar_output = mp_toolbox.cudaicaFailureHandle(eeg_mp, eeg_bp, metadata, paths.ez_top_in);
end %end of enormous if else


    %{
    b=numel(metadata.m_chanlist);
    b=[1:b];
    fprintf('CUDAICA exploded moving channels to bipolar montage \r');
    % Remove bad channels from monopolar montage
    eeg_mp=gather(ez_tall_m);
    eeg_bps=gather(ez_tall_bp);
    metadata.hf_bad_m2=(metadata.m_chanlist(b));
    new_eeg_bp=[];
    new_bp_chans={''};
    counter=0;
    for i=1:numel(b)
        % locate bp channel (possibly not found)
        [C,IA,IB]=intersect(metadata.hf_bad_m2(i),metadata.montage(:,1));
        if ~isempty(C)
            ref=cell2mat(metadata.montage(IB,3));
            if ref~=0
                [C2,IIA,IIB]=intersect(metadata.montage(ref,1),metadata.m_chanlist);
                if ~isempty(C2)
                    counter=counter+1;
                    new_eeg_bp(counter,:)=eeg_mp(b(i),:)-eeg_mp(IIB,:);
                    new_bp_chans(counter)=metadata.hf_bad_m2(i);
                end;
            end;
        end;
    end;
    
    clear C C2 IA IIA IB IIB counter
    
    % add bp recording to bp array
    fprintf('rebuilding monopolar and bipolar montages \r');
    eeg_bps=vertcat(new_eeg_bp, eeg_bps);
    metadata.bp_chanlist=horzcat(new_bp_chans, metadata.bp_chanlist);
    
    % build tall structure
    ez_tall_bp=tall(eeg_bps);
    eeg_bps=[];
    new_eeg_bp=[];
    DSP_data_m=[];
    ez_tall_m=[];
    hfo_ai=zeros(numel(gather(ez_tall_bp(1,:))),1);
    fr_ai=zeros(numel(gather(ez_tall_bp(1,:))),1);
    ez_tall_hfo_m=[];
    ez_tall_fr_m=[];
    num_trc_blocks=1;
    file_id=metadata.file_id;
    
    filename1 = ['dsp_' metadata.file_id '_m_' metadata.file_block '.mat'];
    filename1 = strcat(paths.ez_top_in,filename1);
    save(filename1,'DSP_data_m', '-v7.3');

        %'DSP_data_m', DSP_data_m, ...
    dsp_monopolar_output = struct( ...
        'ez_mp', [], ...      
        'ez_bp', gather(ez_tall_bp), ...
        'hfo_ai', zeros(numel(gather(ez_tall_bp(1,:))),1), ...
        'fr_ai', zeros(numel(gather(ez_tall_bp(1,:))),1), ...
        'ez_hfo_mp', [], ...
        'ez_fr_mp', [], ...
        'metadata', metadata, ...
        'num_trc_blocks', 1, ...
        'error_flag', 1, ...
        'path_to_data', filename1 ...
    );

    error_flag=1;
end;

%}

%%%%%%FOR MATLAB ENGINE only

%%%fixing metadata montage dims
%matlab engine can only return 1*n cell arrays. I changed the data structure to get mlarray.
dsp_monopolar_output.metadata.montage_shape = [numel(dsp_monopolar_output.metadata.montage(:,1)),numel(dsp_monopolar_output.metadata.montage(1,:))];
dsp_monopolar_output.metadata.montage= reshape(dsp_monopolar_output.metadata.montage,1,[]); %matlab engine can only return 1*n cell arrays. I changed the data structure to get mlarray.


end%end of dsp function