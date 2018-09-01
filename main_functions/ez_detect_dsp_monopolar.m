% This is the first production code of the monopolar EZ detect DSP codename
% putou. It has been fully calibrated using NK intracranial data from TJU
% and UCLA. Prior to running this program the EEG data has been converted
% in to tall data block structures. LF bad channels have been removed. The
% referential and bipolar montages have also been created. The output for
% this program includes the ripple and fast ripple clips, time stamps, TRC
% files and annotations (for now), tall data structures for ic1, fr_ic1,
% mean ai, and mean fr_ai.

% hf_bad uses the HFO band pass filtered EEG mutual information
% adjacency matrix, and graph theory (community) during episodes of artifact
% to define dissimilar electrodes. 
%The bipolar montage is calculated for the dissimilar electrodes

% This work is protected by US patent applications US20150099962A1,
% UC-2016-158-2-PCT, US provisional #62429461

% Written by Shennan Aibel Weiss MD, PhD. in Matlab at Thomas Jefferson University
% Philadelphia, PA USA.

function dsp_monopolar_output = ez_detect_dsp_monopolar(ez_tall_m, ez_tall_bp, metadata, paths);

    error_status = 0; error_msg = '';
    file_block = metadata.file_block;
    file_id = metadata.file_id;
    ripple.low = 80;
    ripple.high = 600;
    fripple.low = 200;
    fripple.high = 600;
    sampling_rate = 2000; %view if we can add it to metadata struct
    
    % v4 bug fix perform xcorr function prior to running hfbad in order to
    % remove other 60 cycle artifact outliers prior to hfbad
    [ez_tall_m, metadata] = remove60CycleArtifactOutliers(ez_tall_m, metadata); %NEW

    fprintf('Removing excess HF artifact electrodes \r');
    [metadata] = ez_hfbad_putou02(ez_tall_m, metadata); % Find MI of maximum artifact

    % Remove bad channels from monopolar montage
    chan_indexes = metadata.hf_bad_m_index;
    metadata.hf_bad_m = metadata.m_chanlist(chan_indexes);
    [ez_tall_m, ez_tall_bp, metadata] = removeBadChannelsFromMonopolarMontage(ez_tall_m, ....
                                                                     ez_tall_bp, metadata, chan_indexes);

    % Bug fix for empty cells (search and correct)
    emptyCells = cellfun(@isempty, metadata.m_chanlist);
    [a,b] = find(emptyCells==1);
    metadata.m_chanlist(b) = {'BUG'};

    %% Notch filter eeg_data
    [eeg_data, eeg_data_no_notch] = notchFilter(ez_tall_m);

    % cudaica_matlab function isolates muscle artifact producing artifactual
    % HFOs to the first independent component of the HFO band pass filtered
    % EEG. The first independent component is removed to reduce artifact, and
    % IC1 is also used to refine the artifact index on a millisecond time
    % scale.

    [hfo, ic1, EEG, error_flag] = ez_cudaica_ripple(eeg_data_no_notch, ripple.low, ripple.high, sampling_rate, paths);
    if error_flag == 0 
        
        ez_tall_hfo_m = tall(hfo);

        % The code below is used to detect overstripped recordings
        % following pruning of IC1.
        [~, z_lost_peaks] = detectOverstrippedRecordings(hfo, ic1, @method_one);
        % The artifact index is used to define epochs of muscle and electrode
        % artifact it is used to reject HFO detections in both the referential
        % and bipolar molost_peaks, counterntages.

        ai_rows = numel(hfo(:,1));
        ai_cols = numel(hfo(1,:));
        smooth_span = 1200;
        smooth_method = 'lowess';
        [ai] = calculateArtifactIndex(ai_rows, ai_cols, hfo, ic1, smooth_span, smooth_method);
        hfo_ai = ai; 
        
        % Compensate for overstripping in HFO IC1
        % you will need to take this out for completed EZ detect %% ask for this comment
        nan_ica_size = numel(hfo(:,1));
        threshold = 15;
        nan_ica = compensateOverstrippingHFO_IC1(nan_ica_size, z_lost_peaks, threshold);

        % Start Ripple detection
        [score_amp_ripple, zscore_amp_ripple] = calculateSmoothedHFOamplitude(nan_ica, hfo, ic1); 
        
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
        [thresh_z, thresh_zoff] = skewnessCorrection(zscore_amp_ripple, num_of_m_channels, ...
                                                         thresh_z_values, thresh_zoff_values);
        
        % initialize data structures '2D array of cells' note that this structure can flexibly
        % store different length elements within each cell, and the number of cells can vary by
        % row. This structure may need to be revised to improve efficiency.
        
        %ask if calculateSmoothedHFOamplitude isnt rip detection as well, to move the message inside this func
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

        ripple_data = rippleDetection(eeg_data, score_amp_ripple, zscore_amp_ripple, ic1, ai, config);

        % Convert ripple clips from time to indices, this can be improved directly in rippleDetection saving them
        num_of_data_rows = numel(eeg_data(:,1));
        [hfo_times, hfo_values] = convRippleClips_timeToIndices(num_of_data_rows, ripple_data.clip_t, ic1, ripple_data.total_count);
        
        % v7 MODIFICATION: this new section removes bad channels based on a trained neural network
        % improve b name
        b = detectAdditionalBadElectrodes_nn(hfo, hfo_values);

        if numel(b)< numel(metadata.m_chanlist)-10 % if number of bad electrodes are not the vast majority
            if ~isempty(b)  % if bad electrodes detected
                
                fprintf('Removing bad electrodes repeating calculations and detections \r');
                
                chan_indexes = b;
                metadata.hf_bad_m2 = metadata.m_chanlist(chan_indexes);
                [ez_tall_m, ez_tall_bps, metadata] = removeBadChannelsFromMonopolarMontage(ez_tall_m, ...
                                                                         ez_tall_bp, metadata, b);
                
                % Remove bad electrodes from eeg_data and eeg_data_no_notch
                eeg_data(b,:)=[];
                eeg_data_no_notch(b,:)=[];
                
                % Bug fix for empty cells
                emptyCells = cellfun(@isempty,metadata.m_chanlist);
                [a,b]=find(emptyCells==1);
                metadata.m_chanlist(b)={'BUG'};
                
                % Repeat ICA
                [hfo, ic1, EEG, error_flag] = ez_cudaica_ripple(eeg_data_no_notch, ripple.low, ripple.high, sampling_rate, paths);
                
                if error_flag == 0
                    ez_tall_hfo_m = tall(hfo);

                    % The code below is used to detect overstripped recordings
                    % following pruning of IC1.
                    [~, z_lost_peaks] = detectOverstrippedRecordings(hfo, ic1, @method_one);
                    
                    % The artifact index is used to define epochs of muscle and electrode
                    % artifact it is used to reject HFO detections in both the referential
                    % and bipolar molost_peaks, counterntages.
                    ai_rows = numel(hfo(:,1));
                    ai_cols = numel(hfo(1,:));
                    smooth_span = 1200;
                    smooth_method = 'lowess';
                    [ai] = calculateArtifactIndex(ai_rows, ai_cols, hfo, ic1, smooth_span, smooth_method);
                    hfo_ai = ai; 

                    % Reperform ripple detection part 1.
                    
                    % Compensate for overstripping in HFO IC1
                    % you will need to take this out for completed EZ detect %% ask for this comment
                    nan_ica_size = numel(hfo(:,1));
                    threshold = 15;
                    nan_ica = compensateOverstrippingHFO_IC1(nan_ica_size, z_lost_peaks, threshold);

                    % Start Ripple detection
                    % Calculate smoothed HFO amplitude
                    [score_amp_ripple, zscore_amp_ripple] = calculateSmoothedHFOamplitude(nan_ica, hfo, ic1); 
                    
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
                    [thresh_z, thresh_zoff] = skewnessCorrection(zscore_amp_ripple, num_of_m_channels, ...
                                                                    thresh_z_values, thresh_zoff_values);
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
                    config.ai_thresh = 0.05; 

                    ripple_data = rippleDetection(eeg_data, score_amp_ripple, zscore_amp_ripple, ic1, ai, config);

                    % Convert ripple clips from time to indices
                    num_of_data_rows = numel(eeg_data(:,1));
                    [hfo_times, ~] = convRippleClips_timeToIndices(num_of_data_rows, ripple_data.clip_t, ic1, ripple_data.total_count);
                else % error_flag 1 i.e. CUDAICA exploded ICA #2 
                    dsp_monopolar_output = cudaica_failure_handle(ez_tall_m, ez_tall_bp, metadata, paths.ez_top_in);
                    DSP_data_m = dsp_monopolar_output.DSP_data_m;
                    ez_tall_m = dsp_monopolar_output.ez_tall_m;
                    ez_tall_bp = dsp_monopolar_output.ez_tall_bp;
                    hfo_ai = dsp_monopolar_output.hfo_ai;
                    fr_ai = dsp_monopolar_output.fr_ai;
                    ez_tall_hfo_m = dsp_monopolar_output.ez_tall_hfo_m;
                    ez_tall_fr_m = dsp_monopolar_output.ez_tall_fr_m;
                    metadata = dsp_monopolar_output.metadata;
                    num_trc_blocks = dsp_monopolar_output.num_trc_blocks ;
                    error_flag = dsp_monopolar_output.error_flag;
                end
            end % bad electrode detected loop
        
            % Write TRC files
            % The function first outputs the 32 channel .TRC files for the annotations
            % from the input iEEG file.
            num_trc_blocks = writeTRCfiles(ez_tall_m, metadata, sampling_rate, paths.trc_tmp_monopolar, paths.executable);
           
            % Continue ripple detection part 2.
            % Calculate ripple extract index
            num_of_data_cols = numel(eeg_data(1,:));
            num_of_data_rows = numel(eeg_data(:,1));
            ripple_art_index_thresh = 0.025;
            ripple_hfo_extract_index_thresh = 800;
            ripple_ics = getRippleIcs(num_of_data_cols, num_of_data_rows, EEG, hfo_times, ai, ripple_art_index_thresh, ripple_hfo_extract_index_thresh);

            % redefine z_score block using ripple_ics
            num_of_data_rows = numel(hfo(:,1));            
            score_amp_ripple_i_method = @score_amp_ripple_i_method_2;
            zscore_amp_ripple_i_method = @zscore_amp_ripple_i_method_2;
            [score_amp_ripple, zscore_amp_ripple] = calculateSmoothedHFOamplitude_3(num_of_data_rows, ripple_ics, ...
                                                    score_amp_ripple_i_method, zscore_amp_ripple_i_method);
            
            %%DEBUG
            disp('THESE DIMENSIONS SHOULD BE THE SAME');  %_2
            %check this should be the same for _2
            disp(['eeg_data_channels' num2str(numel(eeg_data(:,1)) )] );
            disp(['eeg_data_cols' num2str(numel(eeg_data(1,:)) )] );

            disp(['hfo_channels' num2str(numel(hfo(:,1)) )] );
            disp(['hfo_cols' num2str(numel(hfo(1,:)))]);

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

            ripple_ics_data = rippleDetection(eeg_data, score_amp_ripple, zscore_amp_ripple, ripple_ics, ai, config);
            
            % Create master look up ripple time index for step 1 detection
            % Convert ripple clips from time to indices, we can have save indexes in rippleDeteccion, for later
            % Create ripple index
            num_of_data_rows = numel(eeg_data(:,1));
            [hfo_times, ~ ] = convRippleClips_timeToIndices(num_of_data_rows, ripple_data.clip_t, ic1, ripple_data.total_count);

            total_ripple_backup = ripple_data.total_count;
            % if ripple not in look up index add the to total_ripple and add ripples
            % from step 2 to ripple clips

            ripple_data = addRipples(num_of_data_rows,hfo_times, ripple_data, ripple_ics_data);
    
            %% Calculate ICA for fast ripples (FR)
            [fr, fr_ic1, EEG, error_flag] = ez_cudaica_ripple(eeg_data_no_notch, fripple.low, fripple.high, sampling_rate, paths);
            
            if error_flag == 0
                ez_tall_fr_m=tall(fr);
                [z_delta_amp_peak_fr, z_lost_peaks_fr] = detectOverstrippedRecordings(fr, fr_ic1, @zscore_2);
                
                %[a_value,b_ind]=min((z_delta_amp_peak_fr)); % Find Replacement AI index  %THIS WASN'T BEING USED
                
                % compensate for overstripping in FR IC1
                % you will need to replace this completed EZ detect and include HF bad channels

                nan_ica_size = numel(eeg_data(:,1));
                threshold = 5;
                nan_ica = compensateOverstrippingHFO_IC1(nan_ica_size, z_lost_peaks_fr, threshold);

                ai_rows = numel(eeg_data(:,1));
                ai_cols = numel(eeg_data(1,:));
                smooth_span = 3000;
                smooth_method = 'moving';
                [ai] = calculateArtifactIndex(ai_rows, ai_cols, fr, fr_ic1, smooth_span, smooth_method);
                fr_ai = ai; 
                
                num_of_data_rows = numel(fr(:,1));
                ics = fr_ic1;
                score_amp_ripple_i_method = @score_amp_ripple_i_method_3; 
                zscore_amp_ripple_i_method = @zscore_2;
                [score_amp_fripple, zscore_amp_fripple] = calculateSmoothedHFOamplitude_3(num_of_data_rows, ics, ...
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

                [thresh_z, thresh_zoff] = skewnessCorrection(zscore_amp_fripple, num_of_m_channels, ...
                                                                      thresh_z_values, thresh_zoff_values);
                config = struct();
                config.zscore_amp_thresh_z = thresh_z;
                config.zscore_amp_thresh_zoff = thresh_zoff;
                config.amp_thresh = 4;
                config.min_event_duration_snds = 0.006;
                config.sampling_rate = sampling_rate;
                config.cycle_thresh = 59.9;
                config.fripple_run = true;
                config.ai_thresh = 0.1;
                
                fripple_data = rippleDetection(eeg_data, score_amp_fripple, zscore_amp_fripple, ics, ai, config);
                
                % Create ripple index
                num_of_data_rows = numel(eeg_data(:,1));
                [hfo_times, ~] = convRippleClips_timeToIndices(num_of_data_rows, fripple_data.clip_t, ic1,fripple_data.total_count);

                num_of_data_cols = numel(eeg_data(1,:));
                fripple_art_index_thresh = 0.020;
                fripple_hfo_extract_index_thresh = 150;
                fripple_ics = getRippleIcs(num_of_data_cols, num_of_data_rows, EEG, hfo_times, ai, fripple_art_index_thresh, fripple_hfo_extract_index_thresh);

                score_amp_ripple_i_method = @score_amp_ripple_i_method_2;
                zscore_amp_ripple_i_method = @zscore_amp_ripple_i_method_2;
                [eeg.score_amp_fripple, eeg.zscore_amp_fripple] = calculateSmoothedHFOamplitude_3(num_of_data_rows, fripple_ics, ...
                                                                  score_amp_ripple_i_method, zscore_amp_ripple_i_method);
                
                config = struct();
                config.zscore_amp_thresh_z = ones(1, numel(eeg_data(:,1)))*0.5;
                config.zscore_amp_thresh_zoff = ones(1, numel(eeg_data(:,1)))*(-0.2);
                config.amp_thresh = 3;
                config.min_event_duration_snds = 0.005;
                config.sampling_rate = sampling_rate;
                config.cycle_thresh = 59.9; %in seconds %improve name
                config.fripple_run = true;
                config.ai_thresh = 0.1; 

                fripple_ics_data = rippleDetection(eeg_data, eeg.score_amp_fripple, eeg.zscore_amp_fripple, ics, ai, config);
                total_fripple_backup = fripple_data.total_count;

                fripple_data = addRipples(num_of_data_rows,hfo_times, fripple_data, fripple_ics_data);
    
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
                DSP_data_m.total_ripple=ripple_data.total_count;
                DSP_data_m.ripple_clip=ripple_data.clip;
                DSP_data_m.ripple_clip_abs_t=ripple_data.clip_abs_t;
                DSP_data_m.ripple_clip_event_t=ripple_data.clip_event_t;
                DSP_data_m.total_fripple=fripple_data.total_count;
                DSP_data_m.fripple_clip=fripple_data.clip;
                DSP_data_m.fripple_clip_abs_t=fripple_data.clip_abs_t;
                DSP_data_m.fripple_clip_event_t=fripple_data.clip_event_t;
                
                dsp_monopolar_output = struct( ...
                    'DSP_data_m', DSP_data_m, ...
                    'ez_tall_m', ez_tall_m, ...      
                    'ez_tall_bp', ez_tall_bp, ...
                    'hfo_ai', hfo_ai, ...
                    'fr_ai', fr_ai, ...
                    'ez_tall_hfo_m', ez_tall_hfo_m, ...
                    'ez_tall_fr_m', ez_tall_fr_m, ...
                    'metadata', metadata, ...
                    'num_trc_blocks', num_trc_blocks, ...
                    'error_flag', error_flag ...
                );

                filename1 = ['dsp_' file_id '_m_' file_block '.mat'];
                filename1 = strcat(paths.ez_top_in,filename1);
                save(filename1,'DSP_data_m', '-v7.3');
            
            else % error_flag 1 i.e. CUDAICA exploded ICA #1
                dsp_monopolar_output = cudaica_failure_handle(ez_tall_m, ez_tall_bp, metadata, paths.ez_top_in);
            end
        else % number of bad electrodes are the vast majority
            error_status = 1;
            error_msg = 'mostly noisy mp electrodes';
        end
    else % error_flag 1 i.e. CUDAICA exploded ICA #3
        dsp_monopolar_output = cudaica_failure_handle(ez_tall_m, ez_tall_bp, metadata, paths.ez_top_in);
    end %end of enormous if else

end %end of dsp function

function dsp_monopolar_output = cudaica_failure_handle(ez_tall_m, ez_tall_bp, metadata, ez_top_in_dir)

    fprintf('CUDAICA exploded moving channels to bipolar montage \r');
    chan_indexes = 1:numel(metadata.m_chanlist);
    metadata.hf_bad_m2 = metadata.m_chanlist(chan_indexes);
    [ez_tall_m, ez_tall_bp, metadata] = removeBadChannelsFromMonopolarMontage(ez_tall_m, ez_tall_bp, metadata, chan_indexes);

    %ask if this will be used, otherwise remove 
    cudaica_failure_ai = zeros(numel(gather(ez_tall_bp(1,:))),1);
    DSP_data_m = [];
    dsp_monopolar_output = struct( ...
        'DSP_data_m', DSP_data_m, ...
        'ez_tall_m', [], ...      
        'ez_tall_bp', ez_tall_bp, ...
        'hfo_ai', cudaica_failure_ai, ...
        'fr_ai', cudaica_failure_ai, ...
        'ez_tall_hfo_m', [], ...
        'ez_tall_fr_m', [], ...
        'metadata', metadata, ...
        'num_trc_blocks', 1, ...
        'error_flag', 1 ...
    );

    filename1 = ['dsp_' metadata.file_id '_m_' metadata.file_block '.mat'];
    filename1 = strcat(ez_top_in_dir, filename1);
    save(filename1,'DSP_data_m', '-v7.3'); %in this case you are saving just an empty array? 
end


function [ez_tall_m, metadata] = remove60CycleArtifactOutliers(ez_tall_m, metadata)

    eeg_data = gather(ez_tall_m); %add un _m to var name
    
    low = 200; high = 600; sampling_rate = 2000;
    fr = ez_eegfilter(eeg_data, low, high, sampling_rate);%improve fr variable name
    fr_xcorr = [];
    for i = 1:numel(fr(:,1))
        temp_data_gpu = fr(i,:); %improve variable name temp_data_gpu
        [xcorrelations,lags] = xcorr(temp_data_gpu);
        xcorrelations = gather(xcorrelations);
        nbins = 1000;
        [no,xo] = hist(xcorrelations,nbins); %matlab suggest reeplacing hist for histogram, see later
        fr_xcorr(i) = sum(no(531:nbins));
    end
    zfr_xcorr = zscore_2(fr_xcorr);

    [a,b] = find(zfr_xcorr > 0.75); 
    [c,d] = find(fr_xcorr > 10000); % changed from 50k in order to remove more 60 cycle channels.
    b = intersect(b,d);
    eeg_data(b,:) = [];
    metadata.m_chanlist(b) = [];
    metadata.hf_xcorr_bad = b;
    
    ez_tall_m = tall(eeg_data); 
end

% Remove bad channels from monopolar montage
function [ez_tall_m, ez_tall_bp, metadata] = removeBadChannelsFromMonopolarMontage(ez_tall_m, ...
                                                              ez_tall_bp, metadata, chan_indexes)
    eeg_mp=gather(ez_tall_m);
    eeg_bps=gather(ez_tall_bp);
    hf_bad_m=metadata.m_chanlist(chan_indexes);
    
    new_eeg_bp=[];
    new_bp_chans={''};
    counter=0;
    for i=1:numel(chan_indexes)
        %% locate bp channel (possibly not found)
        [C,IA,IB]=intersect(hf_bad_m(i),metadata.montage(:,1));
        if ~isempty(C)
            ref=cell2mat(metadata.montage(IB,3));
            if ref~=0
                [C2,IIA,IIB]=intersect(metadata.montage(ref,1),metadata.m_chanlist);
                if ~isempty(C2)
                    counter=counter+1;
                    new_eeg_bp(counter,:)=eeg_mp(chan_indexes(i),:)-eeg_mp(IIB,:);
                    new_bp_chans(counter)=hf_bad_m(i);
                end;
            end;
        end;
    end;

    %% add bp recording to bp array
    fprintf('Rebuilding monopolar and bipolar montages \r');
    eeg_bps=vertcat(new_eeg_bp, eeg_bps);
    metadata.bp_chanlist=horzcat(new_bp_chans, metadata.bp_chanlist);

    %% build tall structure
    ez_tall_bp=tall(eeg_bps);
    eeg_bps=[];
    new_eeg_bp=[];

    %%remove bipolar recordings from memory
    eeg_mp(chan_indexes,:)=[];
    metadata.m_chanlist(chan_indexes)=[];
    ez_tall_m=tall(eeg_mp);

    %{ 
    I think this will be faster and equivalent. I have to do further testing to check if the i is being calculated ok,
    otherwise we can use ismember instead of intersecting for each index.
    
    eeg_mp = gather(ez_tall_m);
    eeg_bps = gather(ez_tall_bp);
    hf_bad_m = metadata.m_chanlist(chan_indexes);  
    % Filter from chan_indexes the ones that are in montage, 
    % have a ref for that channel ~=0 and that are in metadata.m_chanlist.  
    
    % From the ones I want to remove, I get the indexes of the ones that are in montage
    [~,chan_relative_indexes, montage_row_indexes] = intersect(hf_bad_m, metadata.montage(:,1));
    % This maps the ref for each index in montage
    get_montage_refs = @(i) cell2mat(metadata.montage(i,3));
    montage_refs = get_montage_refs(montage_row_indexes);
    % Filter zeros (non refs)
    non_cero_indexes = find(montage_refs ~= 0);
    montage_refs = montage_refs(non_cero_indexes); 
    chan_relative_indexes = chan_relative_indexes(non_cero_indexes);
    %This maps the 'chan label' for each ref in montage
    get_ref_channel = @(ref) metadata.montage(ref,1);
    ref_channels = get_ref_channel(montage_refs);
    %Get the indexes of one that are in m_chanlist
    [~,ref_channels_indexes,ref_m_chanlist_indexes] = intersect(ref_channels, metadata.m_chanlist);
    chan_relative_indexes = chan_relative_indexes(ref_channels_indexes);
    
    efective_indexes = chan_indexes(chan_relative_indexes);
    new_eeg_bp = eeg_mp(efective_indexes,:) - eeg_mp(ref_m_chanlist_indexes,:);
    new_bp_chans = hf_bad_m(ref_channels_indexes);

    % Add bipolar recordings to bp 
    fprintf('Rebuilding monopolar and bipolar montages \r');
    eeg_bps = vertcat(new_eeg_bp, eeg_bps);
    ez_tall_bp = tall(eeg_bps);
    metadata.bp_chanlist = horzcat(new_bp_chans, metadata.bp_chanlist);
    
    % Remove bipolar recordings from m memory. 
    eeg_mp(chan_indexes,:) = [];
    ez_tall_m = tall(eeg_mp);
    metadata.m_chanlist(chan_indexes) = [];

    %}
end

function [eeg_data, eeg_data_no_notch] = notchFilter(ez_tall_m)
    %I think that eeg_data is the filtered one. The other one is just a copy. Improve names later.
    eeg_mp = gather(ez_tall_m);
    eeg_data_no_notch = eeg_mp;
    for i = 1:numel(eeg_mp(:,1));
        eeg_temp = eeg_mp(i,:);
        f0 = (2*(60/2000));
        df = .1;
        N = 30; % must be even for this trick
        h = remez(N,[0 f0-df/2 f0+df/2 1],[1 1 0 0]);
        h = 2*h - ((0:N)==(N/2));
        eeg_notch = filtfilt(h,1,eeg_temp);
        eeg_data(i,:) = eeg_notch;
    end
end    

function [z_delta_amp_peak, z_lost_peaks] = detectOverstrippedRecordings(data, ic1, z_lost_peaks_method)
    fprintf('Compensating for overstripping ripple ica \r');
    data_rows = numel(data(:,1));
    lost_peaks = [];
    delta_amp_peak = zeros(data_rows,1);

    for j = 1:data_rows
        [peaks] = find_inflections(data(j,:),'maxima');
        event_peaks = [];
        counter = 0;
        for i = 1:numel(peaks)
            if data(j, peaks(i)) > 7
                counter = counter + 1;
                event_peaks(counter) = peaks(i);
                temp_delta = data(j,peaks(i))-ic1(j,peaks(i));
                delta_amp_peak(j) = delta_amp_peak(j)+temp_delta;
            end
        end
        [peaks] = find_inflections(ic1(j,:),'maxima');
        event_peaks_ic1 = [];
        counter2 = 0;
        for i = 1:numel(peaks)
            if ic1(j,peaks(i)) > 7
                counter2 = counter2+1;
                event_peaks_ic1(counter2) = peaks(i);
            end
        end
        lost_peaks(j) = numel(event_peaks)-numel(event_peaks_ic1);
    end
    z_delta_amp_peak = zscore_2(delta_amp_peak);
    
    z_lost_peaks = z_lost_peaks_method(lost_peaks);
end

% ask what name should be here
function z_lost_peaks = method_one(lost_peaks)
    lost_peaks = lost_peaks-min(lost_peaks);
    lambdahat = poissfit_2(lost_peaks);
    z_lost_peaks = 2 * (sqrt(lost_peaks)-sqrt(lambdahat));
end

function [ai] = calculateArtifactIndex(ai_rows, ai_cols, eeg_data, ic1, smooth_span, smooth_method)  
    fprintf('Calculating artifact index \r')
    ai = zeros(ai_rows, ai_cols); % corrected for intra-op data usually remove.
    %artifact_segments=[]; % corrected for intra-op data usually remove. NOT USED
    for i=1:numel(eeg_data(:,1));
        ai_baseline_correct=mean(abs(eeg_data(i,:)));
        for j=1:numel(eeg_data(1,:))
            scale_factor=1;
            if abs(ic1(i,j))>10
                scale_factor=(abs(ic1(i,j))/10)*1;
            end;
            if ai(i,j)<10
                ai(i,j)=(abs(eeg_data(i,j)-ic1(i,j))/scale_factor)/ai_baseline_correct;
            end;
        end;
    end;
    ai_mean=mean(ai);
    for i=1:numel(eeg_data(:,1));
        for j=1:numel(eeg_data(1,:));
            ai(i,j)=(ai(i,j)*ai_mean(j));
        end;
        ai(i,:)=smooth(ai(i,:),smooth_span,smooth_method);
        temp=zscore_2(ai(i,:));
        [a,b]=sort(temp,'descend');
        [c,d]=find(a<2);
        temp2=d(1);
        size_array=numel(ai(i,:));
        temp3=ai(i,temp2:size_array);
        temp4=ai(i,b);
        temp5=mean(temp4(temp2:size_array));
        ai(i,:)=ai(i,:)-temp5;
    end;
    ai = max(ai);
    fprintf('Done calculating artifact index \r')
end

function nan_ica = compensateOverstrippingHFO_IC1(nan_ica_size, z_lost_peaks, threshold)
    nan_ica=zeros(nan_ica_size,1);% you will need to take this out for completed EZ detect
    for i=1:nan_ica_size
        if z_lost_peaks(i)>threshold
            nan_ica(i)=1;
        end
    end
end

function [score_amp_ripple, zscore_amp_ripple] = calculateSmoothedHFOamplitude(nan_ica, hfo, ic1)    
    for i=1:numel(hfo(:,1))
        if nan_ica(i)==1
            hilbert_hfo_amp=abs(hilbert(hfo(i,:)));
        else
            hilbert_hfo_amp=abs(hilbert(ic1(i,:)));
        end
        
        score_amp=hilbert_hfo_amp;
        smooth_length=40;
        score_amp_ripple(i,:)=smooth(score_amp,smooth_length,'loess');
        score_amp_ripple(i,:)=abs(score_amp_ripple(i,:));
        lambdahat = poissfit_2(score_amp_ripple(i,:));
        zscore_amp_ripple(i,:)=2*(sqrt(score_amp_ripple(i,:))-sqrt(lambdahat));
        if nan_ica(i)==1
            zscore_amp_ripple(i,:)=zscore_amp_ripple(i,:)+0.75;
        end
    end
end

function [score_amp_ripple, zscore_amp_ripple] = calculateSmoothedHFOamplitude_3(num_of_data_rows, ics, ...
                                                 score_amp_ripple_i_method, zscore_amp_ripple_i_method)
    for i = 1:num_of_data_rows
        hilbert_amp = abs(hilbert(ics(i,:)));
        smooth_length = round((2000/2000)*40); %ask about this... thats 40 always, ask if they wanna extract variable as srate
        score_amp_ripple(i,:) = score_amp_ripple_i_method(hilbert_amp, smooth_length);
        zscore_amp_ripple(i,:) = zscore_amp_ripple_i_method(score_amp_ripple(i,:));
    end;
end

%Ask if the difference in the calls are ok or are bugs
function score_amp_ripple_i = score_amp_ripple_i_method_2(hilbert_amp, smooth_length)
    score_amp_ripple_i = abs(smooth(hilbert_amp,smooth_length,'loess'));
end
function score_amp_ripple_i = score_amp_ripple_i_method_3(hilbert_amp, smooth_length)
    score_amp_ripple_i = smooth(hilbert_amp,smooth_length,'loess');
end
function zscore_amp_ripple_i = zscore_amp_ripple_i_method_2(score_amp_ripple_i)
    lambdahat = poissfit_2(score_amp_ripple_i);
    zscore_amp_ripple_i = 2*(sqrt(score_amp_ripple_i)-sqrt(2.5*lambdahat)); %difference with _1
end
%zscore_amp_ripple_i_method_3 is zscore_2

function [thresh_z, thresh_zoff] = skewnessCorrection(zscore_amp,num_of_m_channels,thresh_z_values,thresh_zoff_values)
    temp_skew=skewness(zscore_amp'); % v4 add skewness correction for initial ripple detection to improve sensitivity.
    z_skew=zscore_2(temp_skew);
    thresh_z=[];
    thresh_zoff=[];
    for i=1:num_of_m_channels
        if z_skew(i)>3
            thresh_z(i)=thresh_z_values.first;
            thresh_zoff(i)=thresh_zoff_values.first;
        else
            if z_skew(i)>2.5
                thresh_z(i)=thresh_z_values.second;
                thresh_zoff(i)=thresh_zoff_values.second;
            else
                if z_skew(i)>2
                    thresh_z(i)=thresh_z_values.third;
                    thresh_zoff(i)=thresh_zoff_values.third;
                else
                    if z_skew(i)>1.5
                        thresh_z(i)=thresh_z_values.fourth;
                        thresh_zoff(i)=thresh_zoff_values.fourth;
                    else
                        thresh_z(i)=thresh_z_values.fifth;
                        thresh_zoff(i)=thresh_zoff_values.fifth;
                    end
                end
            end
        end
    end
    fprintf('Done calculating baseline stats \r')
end

function block = updateBlockData(block, eeg_index, eeg_data,zscore_amp_ripple, score_amp_ripple, ics, ai, fripple_run)
    block.end_ptr = eeg_index+block.size-1; 
    block.data_range = eeg_index:block.end_ptr;

    block.ieeg = eeg_data(:,block.data_range);
    block.zscore = zscore_amp_ripple(:,block.data_range);
    block.amp = score_amp_ripple(:,block.data_range);
    if (~fripple_run) block.ic1 = ics(:,block.data_range); end
    block.ai = ai(block.data_range);
end

function start_index = fixRelativeStartIndex(current_block)
    if current_block == 1
        start_index = 800; 
    else
        start_index = 1;
    end
end

function HFO_frequency = getHFOfrequency(event_img_count, event_indexes, event_duration_snds, ic1_chan, sampling_rate)
    nfft = 2^nextpow2(event_img_count);
    ic1_chan_fft = fft( ic1_chan(event_indexes), nfft);
    Pxx = abs(ic1_chan_fft).^2/event_duration_snds; %I think this is equivalent
    Hpsd = dspdata.psd(Pxx(1:numel(Pxx)/2),'Fs',sampling_rate);
    [~,max_index]= max(Hpsd.Data);
    HFO_frequency = Hpsd.Frequencies(max_index);
end

function duration_cutoff = getDurationCutOff(HFO_frequency, dur_cutoffs)
    % Calculate the duration cutoff based on the peak frequency ofthe HFO.
    % Optimization Factor #3
    % @Shennan: I changed the <= 150 for < 150 and > 150 for >= 150 to be consistent , is that ok?
    duration_cutoff = 0;
    if (HFO_frequency < dur_cutoffs.fst_range) 
        duration_cutoff = dur_cutoffs.fst_val; end 
    if (HFO_frequency >= dur_cutoffs.fst_range && HFO_frequency < dur_cutoffs.snd_range) 
        duration_cutoff = dur_cutoffs.snd_val; end
    if (HFO_frequency >= dur_cutoffs.snd_range && HFO_frequency < dur_cutoffs.trd_range) 
        duration_cutoff = dur_cutoffs.trd_val; end
    if (HFO_frequency >= dur_cutoffs.trd_range) 
        duration_cutoff = dur_cutoffs.trd_val; end;  
end

function is_artifact = isArtifactualHFO(event_indexes, ai_block, ai_thresh)
    is_artifact = false;
    for i = event_indexes % Look up artifact index to determine if HFO is artefactual.
        if ai_block(i) > ai_thresh % v4 raised AI thresh to 0.05 
            is_artifact = true;
        end
    end
end

function ripple_data = getRippleData(ripple_data, hfo_detection_start_ptr, rel_img_index, block, sampling_rate, chan, current_block)

    ripple_data.total_count(chan) = ripple_data.total_count(chan)+1;
    % Here you are adding margins to the clip right?
    % @Shennan: What does this next line comment mean? 0.25 snds with srate=2000 is 500 images
    clip_start = max(1, hfo_detection_start_ptr-1100);% v3 adjust 0.25 sec for asymmetric filtering.
    clip_end = min(rel_img_index+100, numel(block.ieeg(1,:)));
    chan_hfo_index = ripple_data.total_count(chan);

    ripple_data.clip{chan, chan_hfo_index} = block.ieeg(chan, clip_start:clip_end); 
    %This clip above corresponds to ripple_data.clip_abs_t pointers, but remember that it doesn't match with clip_t nor clip_event_t
    event_clip_rel_start_snds = clip_start/sampling_rate;
    event_clip_rel_stop_snds = clip_end/sampling_rate;
    time_passed_snds = (current_block-1)*60;
    ripple_data.clip_abs_t{chan, chan_hfo_index} = time_passed_snds+ [event_clip_rel_start_snds ...
                                                                      event_clip_rel_stop_snds];
    %Other pointers
    event_rel_start_snds = hfo_detection_start_ptr/sampling_rate;
    event_rel_stop_snds = rel_img_index/sampling_rate;
    % v3 do not adjust 0.25 sec for asymmetric filtering b/c off stage II
    ripple_data.clip_t{chan, chan_hfo_index} = time_passed_snds+[(event_rel_start_snds-0.0035) ... %Shennan this pointer could get out of range if its in the first very beginning of the block. We can set it to max(0.0005, actual_pointer) if we are sure that srate will be >= 2000
                                                                    event_rel_stop_snds]; %@Shennan: is this end correct without the + 0.0035? if you want the +0.0035, same comment than the line above for out of range but we can handle it 
                                                                      
    ripple_data.clip_event_t{chan, chan_hfo_index} = time_passed_snds+[(event_rel_start_snds-0.0035-500) ... %@Shennan: here there could be a bug, I think you want to remove 500 images (0.25 secs) but the left side has already been converted to time, it should be time or images count? Besides we should handle out of range.
                                                                          (event_rel_stop_snds-500)]; %@Shennan: Is this -500 correct for the stop or you meant +500 here
end

%the versions for ics didn't use isArtifactualHFO funciton, this one does it, ask if that doesn't makes trouble.
function ripple_data = rippleDetection(eeg_data, score_amp_ripple, zscore_amp_ripple, ics, ai, config)
    
    fprintf('Running Ripple Detection\r'); 
    channel_count = numel(eeg_data(:,1));
    data_length = numel(eeg_data(1,:));
    initial_value = {cell(channel_count,1)};
    ripple_data = struct( ...
        'clip', initial_value, ...
        'clip_t', initial_value, ...      
        'clip_event_t', initial_value, ...
        'clip_abs_t', initial_value, ...
        'total_count', zeros(channel_count,1) ...
    );
    block = struct();
    block.time_size_snds = 60; %in seconds
    block.size = config.sampling_rate*block.time_size_snds; 
    if config.fripple_run
        search_step = 1;
    else
        hfo_search_step_snds = config.search_granularity; %just to clearify they are seconds
        search_step = floor(hfo_search_step_snds*config.sampling_rate); %added 'floor' just in case in future srate differs 2000
    end
    current_block = 1;

    for eeg_index = 1:block.size:(data_length- config.cycle_thresh*config.sampling_rate) %@Shennan: why are you missing almost the last minute? cycle_thresh is 59.99

        block = updateBlockData(block, eeg_index, eeg_data,zscore_amp_ripple, score_amp_ripple, ics, ai, config.fripple_run);
        for channel_index = 1:channel_count
            
            zscore_amp = block.zscore(channel_index,:);
            amp = block.amp(channel_index,:);
            if (~config.fripple_run) ic1_chan = block.ic1(channel_index,:); end

            hfo_event_detected = false; %old 'flagged var'
            chan = channel_index; %just to reduce syntax
            % Iterate through entire z-scored time series, start of event defined at Z>3.5, note this
            % is a relatively low cut off. The point here is to capture as many events as possible
            % they will be refined later in the analysis. An event is complete when the Z score is
            % below <1.5. An event is only saved if it is greater than 15 msec in duration. %@Shennan I think this is old info, now code says 8ms
            
            %@Shennan: why this? avoids the first 0.4 secs and consider now that dsp_m will be called for many blocks,
            % and then for each of them use these small 1 minute blocks. So you would miss the first 0.4 secs for every main blocks in ez_detect batch
            start_index = fixRelativeStartIndex(current_block);
            for rel_img_index = start_index:search_step:numel(zscore_amp)
                
                %Detect hfo event
                img_detected_positive = false;
                if ~hfo_event_detected 
                    zscore_amp_outstrips_thresh = zscore_amp(rel_img_index) > config.zscore_amp_thresh_z(chan); % v4 with skewness adrel_img_indexustment
                    amp_outstrips_thresh = amp(rel_img_index) > config.amp_thresh;
                    img_detected_positive = and(zscore_amp_outstrips_thresh,amp_outstrips_thresh);
                end
                if  ~hfo_event_detected && img_detected_positive  % Optimization factor #1
                    hfo_event_detected = true;
                    hfo_detection_start_ptr = rel_img_index;
                end
                % Optimization factor #2.
                if (hfo_event_detected && (zscore_amp(rel_img_index) > config.zscore_amp_thresh_zoff(chan)) ) end; %@Shennan: This isn't doing anything, it would be the same to remove it.
                if hfo_event_detected && (zscore_amp(rel_img_index) < config.zscore_amp_thresh_zoff(chan) )
                    
                    event_img_count = rel_img_index-hfo_detection_start_ptr+1; %@Shennan: Fixed bug, +1 was missing, now we count all images
                    event_duration_snds = event_img_count/config.sampling_rate; 
                    event_indexes = hfo_detection_start_ptr:rel_img_index;
                    if  event_duration_snds > config.min_event_duration_snds  %if the image is detected and event since rising flag is longer than 8 milliseconds
                        % To determine if HFO is valid the first step is calculating its frequency at the peak of its psd.
                        
                        if ~config.fripple_run
                            HFO_frequency = getHFOfrequency(event_img_count, event_indexes, ...
                                            event_duration_snds, ic1_chan, config.sampling_rate);
                            duration_cutoff = getDurationCutOff(HFO_frequency, config.duration_cutoffs);
                        end
                        %If the HFO duration exceeds the duration cutoff save the raw HFO accompanying
                        %the event, the instantaneous phase of the eeg at the time of the event, the
                        %unfiltered signal at the time of the event, and the Z-scored HFO stream at the
                        %time of the event.
                        if config.fripple_run || (event_duration_snds > duration_cutoff)
                            if event_duration_snds < 0.5  % prune surely artifacts
                                is_artifact = isArtifactualHFO(event_indexes, block.ai, config.ai_thresh);
                                
                                if ~is_artifact
                                    ripple_data = getRippleData(ripple_data, hfo_detection_start_ptr, rel_img_index, ...
                                                                block, config.sampling_rate, chan, current_block);
                                    hfo_event_detected = false; %@Shennan: I have just added this line, does it make sense to you? When you save, you start again.
                                end
                            else
                                hfo_event_detected = false; %@Shennan: I have just added this line, does it make sense to you? 
                                                            %If event_duration_snds >= 0.5 already tells you is artifactual we should discard the event right?
                            end
                        end
                    end
                     % @Shennan flagged = 0 is happening here. So this is cancelling every start of hfo_event_detection, since at first event duration is 1 millisecond < 8 milliseconds
                     % I think it goes inside 
                     hfo_event_detected = false; % Comment for now, I think that is a bug
                end
            end
        end
    end
end

function [hfo_times, hfo_values] = convRippleClips_timeToIndices(num_of_data_rows, clip_t, ic1, total)

    hfo_times=cell(num_of_data_rows,1);
    hfo_values=cell(num_of_data_rows,1);
    for i=1:numel(clip_t(:,1))
        concat=[];
        val_concat=[];
        for j=1:total(i)
            time_s=(int32(clip_t{i,j}(1)*2000));
            time_e=(int32(clip_t{i,j}(2)*2000));
            time=time_s:time_e;
            concat=horzcat(concat, time);
            val_concat=horzcat(val_concat, ic1(i,time)); %v4 modification calculate ripple values
        end
        if total(i)>0
            hfo_times{i,:}=concat;
            hfo_values{i,:}=val_concat;
        end
    end
end

function b = detectAdditionalBadElectrodes_nn(hfo, hfo_values)

    lookup_vector=[];
    nulls=[];
    counter=0;
    fprintf('Detecting additional bad electrodes using neural network\r');
    for i=1:numel(hfo_values(:,1))
        if isempty(hfo_values{i,1})
            nulls=[nulls i];
        else
            counter=counter+1;
            % length of recording
            samples(counter)=numel(hfo_values{i,1});
            if numel(hfo(1,:))<1140000
                samples(counter)=(1200000/numel(hfo_values{i,1}))*samples(counter);
            end;
            % rms
            rms_calc(counter)=rms(hfo_values{i,1});
            % stdev
            std_calc(counter)=std(hfo_values{i,1});
            % entropy
            entropy_calc(counter) = wentropy(hfo_values{i,1},'shannon');
            % slope calc
            slope_calc(counter) = mean(abs(diff(hfo_values{i,1})));
            % hilbert amplitude < 4 Hz
            data=hfo_values{i,1};
            data=smooth(data,100);
            hilbert_calc(counter)=mean(abs(hilbert(data)));
            lookup_vector(counter)=i;
        end
    end
    %% The fast ripple neural network was also utilized because of a higher likelihood of 
    % excluding bad channels prior to ICA
    if counter > 0
        test_vector=[samples' rms_calc' std_calc' entropy_calc' slope_calc' hilbert_calc']; 
        Y=fripple_nn(test_vector);  
        [a,b]=find(Y>0.4)
        b=lookup_vector(a);
        Y2=ripple_nn(test_vector);
        [c,d]=find(Y2>0.282)
        b2=lookup_vector(c);
        b=[b b2];
    else
        b=[];
    end
end

function num_trc_blocks = writeTRCfiles(ez_tall_m, metadata, sampling_rate, trc_temp_dir, executable_dir)

    fprintf('Writing monopolar iEEG to trc format \r');
    fprintf('Converting data to 2048 Hz sampling rate \r');
    eeg_mp = gather(ez_tall_m);
    % The first step is to convert the sampling rate to 2048 Hz
    number_of_channels = numel(eeg_mp(:,1));
    desired_hz = 2048;
    resampled_data = resampleData(sampling_rate, desired_hz, number_of_channels, eeg_mp);

    TRC.data=resampled_data;
    TRC.chanlist=metadata.m_chanlist;
    % Clear the temporary .mat files  %I would do this at the end of the program
    cleanTempTRC(trc_temp_dir, metadata.file_block);
    
    % The next step is to write the TRC file blocks
    num_trc_blocks = writeTRCBlocks(TRC, metadata.file_block, metadata.file_id, trc_temp_dir, executable_dir);

end

function resampled_data = resampleData(sampling_rate, desired_hz, number_of_channels, eeg_data)
    disp(['Resampling the Data to ' num2str(desired_hz) 'Hz']);
    if sampling_rate ~= desired_hz
        [p,q] = rat(desired_hz/sampling_rate);
        for j=1:number_of_channels
            channel = eeg_data(j,:);
            resampled_data(j,:) = resample(channel,p,q);
        end
        disp(['Resampled: ' num2str(number_of_channels) ' data channels.']);
    else % No resample needed
        resampled_data = eeg_data;
    end
end

function cleanTempTRC(directory, file_block)
    system(['rm -f ' directory 'eeg_2k_a_' file_block '.mat']);
    system(['rm -f ' directory 'eeg_2k_b_' file_block '.mat']);
    system(['rm -f ' directory 'eeg_2k_c_' file_block '.mat']);
    system(['rm -f ' directory 'eeg_2k_d_' file_block '.mat']);
    system(['rm -f ' directory 'eeg_2k_e_' file_block '.mat']);
    system(['rm -f ' directory 'eeg_2k_f_' file_block '.mat']);
    system(['rm -f ' directory 'eeg_2k_g_' file_block '.mat']);
end

function num_trc_blocks = writeTRCBlocks(TRC, file_block, file_id, trc_temp_dir, executable_dir)
    num_trc_blocks = ceil(numel(TRC.chanlist)/32); %I think i can replace metadata.m_chanlist with TRC.chanlist here, 4 later

    for i=1:num_trc_blocks
        if i==1
            if numel(TRC.data(:,1))>=32
                max_trc_channels=32;
            else
                max_trc_channels=numel(TRC.data(:,1));
            end;
            eeg=[];
            eeg.eeg_data=TRC.data(1:max_trc_channels,:);
            eeg.chanlist=TRC.chanlist(1:max_trc_channels);
            save([trc_temp_dir 'eeg_2k_a_' file_block '.mat'],'eeg');
            system_command=[executable_dir 'mat2trc32_m2k_a' ' ' file_id ' ' file_block ' &'];
            system(system_command);
            fprintf('Writing .TRC file #1 in background \r');
        end;
        if i==2
            if numel(TRC.data(:,1))>=64
                max_trc_channels=64;
            else
                max_trc_channels=numel(TRC.data(:,1));
            end;
            eeg=[];
            eeg.eeg_data=TRC.data(33:max_trc_channels,:);
            eeg.chanlist=TRC.chanlist(33:max_trc_channels);
            save([trc_temp_dir 'eeg_2k_b_' file_block '.mat'],'eeg');
            system_command=[executable_dir 'mat2trc32_m2k_b' ' ' file_id ' ' file_block ' &'];
            system(system_command);
            fprintf('Writing .TRC file #2 in background \r');
        end;
        if i==3
            if numel(TRC.data(:,1))>=96
                max_trc_channels=96;
            else
                max_trc_channels=numel(TRC.data(:,1));
            end;
            eeg=[];
            eeg.eeg_data=TRC.data(65:max_trc_channels,:);
            eeg.chanlist=TRC.chanlist(65:max_trc_channels);
            save([trc_temp_dir 'eeg_2k_c_' file_block '.mat'],'eeg');
            system_command=[executable_dir 'mat2trc32_m2k_c' ' ' file_id ' ' file_block ' &'];
            system(system_command);
            fprintf('Writing .TRC file #3 in background \r');
        end;
        if i==4
            if numel(TRC.data(:,1))>=128
                max_trc_channels=128;
            else
                max_trc_channels=numel(TRC.data(:,1));
            end;
            eeg=[];
            eeg.eeg_data=TRC.data(97:max_trc_channels,:);
            eeg.chanlist=TRC.chanlist(97:max_trc_channels);
            save([trc_temp_dir 'eeg_2k_d_' file_block '.mat'],'eeg');
            system_command=[executable_dir 'mat2trc32_m2k_d' ' ' file_id ' ' file_block ' &'];
            system(system_command);
            fprintf('Writing .TRC file #4 in background \r');
        end;
        if i==5
            if numel(TRC.data(:,1))>=160
                max_trc_channels=160;
            else
                max_trc_channels=numel(TRC.data(:,1));
            end;
            eeg=[];
            eeg.eeg_data=TRC.data(129:max_trc_channels,:);
            eeg.chanlist=TRC.chanlist(129:max_trc_channels);
            save([trc_temp_dir 'eeg_2k_e_' file_block '.mat'],'eeg');
            system_command=[executable_dir 'mat2trc32_m2k_e' ' ' file_id ' ' file_block ' &'];
            system(system_command);
            fprintf('Writing .TRC file #5 in background \r');
        end;
        if i==6
            if numel(TRC.data(:,1))>=192
                max_trc_channels=192;
            else
                max_trc_channels=numel(TRC.data(:,1));
            end;
            eeg=[];
            eeg.eeg_data=TRC.data(161:max_trc_channels,:);
            eeg.chanlist=TRC.chanlist(161:max_trc_channels);
            save([trc_temp_dir 'eeg_2k_f_' file_block '.mat'],'eeg');
            system_command=[executable_dir 'mat2trc32_m2k_f' ' ' file_id ' ' file_block ' &'];
            system(system_command);
            fprintf('Writing .TRC file #6 in background \r');
        end;
        if i==7
            if numel(TRC.data(:,1))>=224
                max_trc_channels=224;
            else
                max_trc_channels=numel(TRC.data(:,1));
            end;
            eeg=[];
            eeg.eeg_data=TRC.data(193:max_trc_channels,:);
            eeg.chanlist=TRC.chanlist(193:max_trc_channels);
            save([trc_temp_dir 'eeg_2k_g_' file_block '.mat'],'eeg');
            system_command=[executable_dir 'mat2trc32_m2k_g' ' ' file_id ' ' file_block ' &'];
            system(system_command);
            fprintf('Writing .TRC file #7 in background \r');
        end;
    end;
end

function ripple_ics = getRippleIcs(num_of_data_cols, num_of_data_rows, EEG, hfo_times, ai, art_index_thresh, ...
                                   hfo_extract_index_thresh)
     % Calculate ripple extract index
    hfo_extract_index=[];
    hfo_times_chan=[];
    [~,artindex]=find(ai>art_index_thresh);
    non_artindex=1:num_of_data_cols;
    ai_extract_index=[];

    for i=2:num_of_data_rows
        ic_prune=1:num_of_data_rows;
        ic_prune(i)=[];
        OUTEEG = pop_subcomp(EEG, ic_prune, 0);
        ai_amp= abs(OUTEEG.data(1,artindex));
        non_ai_amp= abs(OUTEEG.data(1,non_artindex));
        ai_extract_index(i-1)=mean(ai_amp)/mean(non_ai_amp);
        
        for j=1:num_of_data_rows
            non_hfo_times=1:num_of_data_cols;
            temp_time=hfo_times{j,1};
            [a,b]=find(temp_time<1);
            temp_time(b)=[];
            non_hfo_times(temp_time)=[];
            hfo_times_chan=hfo_times{j,1};
            hfo_times_chan(b)=[];
            hfo_amp=abs(OUTEEG.data(j,hfo_times_chan));
            non_hfo_amp=abs(OUTEEG.data(j,non_hfo_times));
            %non_hfo_amp=abs(OUTEEG.data(2,non_hfo_times)); getRipple had this line above with the 2 index instead of the j, ask if it was a bug or not
            hfo_extract_index((i-1),j)=mean(hfo_amp)/mean(non_hfo_amp);
            %ai_amp=mean(abs(OUTEEG.data(j,artindex))); getFripppleIcs had this line but ai_amp isn't being used at all, ask if this is a bug or if this can be removed
        end
    end

    % find ripple ics
    temp_zeros=zeros(numel(hfo_extract_index(1,:)),1);
    hfo_extract_index=vertcat(temp_zeros', hfo_extract_index);
    hfo_extract_index(isnan(hfo_extract_index))=0;
    
    ai_extract_index= [NaN ai_extract_index];
    
    C=zscore_2(clustering_coef_wd(hfo_extract_index));
    [a,b]=find(C>1);
    [c,d]=find(hfo_extract_index>hfo_extract_index_thresh);
    e=vertcat(a,c);
    f=unique(e);
    
    D=zscore_2(ai_extract_index);
    g=D(f);
    [h,i]=find(g>0);
    f(i)=[];
    
    % extract ripple ics
    ic_prune=1:num_of_data_rows;
    ic_prune(f)=[];
    OUTEEG = pop_subcomp(EEG, ic_prune, 0);
    
    ripple_ics=OUTEEG.data;

end

% if ripple not in look up index add the to total_ripple and add ripples from step 2 to ripple clips
function ripple_data = addRipples(num_of_data_rows,hfo_times, ripple_data, ripple_ics_data)
    
    for i=1:num_of_data_rows
        temp_lookup=hfo_times{i,:};
        for j=1:ripple_ics_data.total_count(i)
            lookup_val1=int32(ripple_ics_data.clip_t{i,j}(1)*2000);
            lookup_val2=int32(ripple_ics_data.clip_t{i,j}(2)*2000);
            lookup_val12=lookup_val1:lookup_val2;
            if isempty(intersect(lookup_val12,temp_lookup))
                ripple_data.total_count(i)=ripple_data.total_count(i)+1;
                ripple_data.clip{i,ripple_data.total_count(i)}=ripple_ics_data.clip{i,j};
                ripple_data.clip_t{i,total(i)}=ripple_ics_data.clip_t{i,j};
                ripple_data.clip_event_t{i,total(i)}=ripple_ics_data.clip_event_t{i,j};
                ripple_data.clip_abs_t{i,total(i)}=ripple_ics_data.clip_abs_t{i,j};
            end;
        end;
    end;
end
