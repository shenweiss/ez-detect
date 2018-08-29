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
    sampling_rate = 2000; %view if we can add it to metadata struct
    
    % v4 bug fix perform xcorr function prior to running hfbad in order to
    % remove other 60 cycle artifact outliers prior to hfbad
    [ez_tall_m, metadata] = remove60CycleArtifactOutliers(ez_tall_m, metadata); %NEW

    fprintf('Removing excess HF artifact electrodes \r');
    [metadata] = ez_hfbad_putou02(ez_tall_m,metadata); % Find MI of maximum artifact

    % Remove bad channels from monopolar montage
    chan_indexes = metadata.hf_bad_m_index;
    [ez_tall_m,ez_tall_bp,hf_bad_m_out,metadata] = removeBadChannelsFromMonopolarMontage(ez_tall_m, ....
                                                                     ez_tall_bp, metadata, chan_indexes);
    metadata.hf_bad_m = hf_bad_m_out;

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

    [hfo, ic1, EEG, error_flag] = ez_cudaica_ripple_putou_e1(eeg_data_no_notch, sampling_rate, paths);

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
        %this function will be improved.
        [ripple_clip,ripple_clip_t,ripple_clip_event_t,ripple_clip_abs_t, total_ripple]=runRippleDetection(eeg_data, score_amp_ripple, ...
                                                                     zscore_amp_ripple, ic1, ai, thresh_z, thresh_zoff);
        % Convert ripple clips from time to indices
        num_of_data_rows = numel(eeg_data(:,1));
        [hfo_times, hfo_values] = convRippleClips_timeToIndices(num_of_data_rows, ripple_clip_t, ic1, total_ripple);
        
        % v7 MODIFICATION: this new section removes bad channels based on a trained neural network
        % improve b name
        b = detectAdditionalBadElectrodes_nn(hfo, hfo_values);

        if numel(b)< numel(metadata.m_chanlist)-10 % if number of bad electrodes are not the vast majority
            if ~isempty(b)  % if bad electrodes detected
                
                fprintf('Removing bad electrodes repeating calculations and detections \r');
                
                chan_indexes = b;
                [ez_tall_m, ez_tall_bps, hf_bad_m_out, metadata] = removeBadChannelsFromMonopolarMontage(ez_tall_m, ...
                                                                         ez_tall_bp, metadata, b);
                metadata.hf_bad_m2 = hf_bad_m_out;
                
                % Remove bad electrodes from eeg_data and eeg_data_no_notch
                eeg_data(b,:)=[];
                eeg_data_no_notch(b,:)=[];
                
                % Bug fix for empty cells
                emptyCells = cellfun(@isempty,metadata.m_chanlist);
                [a,b]=find(emptyCells==1);
                metadata.m_chanlist(b)={'BUG'};
                
                % Repeat ICA
                [hfo, ic1, EEG, error_flag]=ez_cudaica_ripple_putou_e1(eeg_data_no_notch,sampling_rate,paths);
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
                   
                    [ripple_clip,ripple_clip_t,ripple_clip_event_t,ripple_clip_abs_t, total_ripple]=runRippleDetection(eeg_data, score_amp_ripple, ...
                                                                     zscore_amp_ripple, ic1, ai, thresh_z, thresh_zoff);
                    % Convert ripple clips from time to indices
                    % in this call there was a difference in a line but I think it was an error, check later,
                    % there was an i missing as argument of ic1 in line
                    % ripple_val_concat=horzcat(ripple_val_concat, ic1(ripple_time)); %v4 modification calculate ripple values
                    % the previous call line was ripple_val_concat=horzcat(ripple_val_concat, ic1(i,ripple_time));
                    num_of_data_rows = numel(eeg_data(:,1));
                    [hfo_times, ~] = convRippleClips_timeToIndices(num_of_data_rows, ripple_clip_t, ic1, total_ripple);
                else % error_flag 1 i.e. CUDAICA exploded ICA #2 
                    fprintf('CUDAICA exploded moving channels to bipolar montage \r');
                    
                    chan_indexes = [1:numel(metadata.m_chanlist)];
                    [ez_tall_m, ez_tall_bp, hf_bad_m_out, metadata] = removeBadChannelsFromMonopolarMontage(ez_tall_m, ez_tall_bp, metadata, chan_indexes);
                    metadata.hf_bad_m2 = hf_bad_m_out;

                    DSP_data_m = [];
                    ez_tall_m = [];
                    hfo_ai = zeros(numel(gather(ez_tall_bp(1,:))),1); 
                    fr_ai = zeros(numel(gather(ez_tall_bp(1,:))),1);
                    ez_tall_hfo_m = [];
                    ez_tall_fr_m = [];
                    num_trc_blocks = 1;
                    error_flag = 1;

                    filename1 = ['dsp_' file_id '_m_' file_block '.mat'];
                    filename1 = strcat(paths.ez_top_in, filename1);
                    save(filename1,'DSP_data_m', '-v7.3'); %in this case you are saving just an empty array? 
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
            ripple_ics = getRippleIcs(num_of_data_cols, num_of_data_rows, EEG, hfo_times, ai);

            % redefine z_score block using ripple_ics
            num_of_data_rows = numel(hfo(:,1));
            [score_amp_ripple, zscore_amp_ripple] = calculateSmoothedHFOamplitude_2(num_of_data_rows, ripple_ics);
            
            [ripple_ic_clip,ripple_ic_clip_t,ripple_ic_clip_event_t,ripple_ic_clip_abs_t, ....
             total_ripple_ic] = runRippleDetection_2(eeg_data, hfo, score_amp_ripple, zscore_amp_ripple, ripple_ics);
            
            % create master look up ripple time index for step 1 detection
            % convert ripple clips from time to indices
            % Create ripple index
            num_of_data_rows = numel(eeg_data(:,1));
            [hfo_times, ~ ] = convRippleClips_timeToIndices(num_of_data_rows, ripple_clip_t, ic1, total_ripple);

            total_ripple_backup = total_ripple;
            % if ripple not in look up index add the to total_ripple and add ripples
            % from step 2 to ripple clips

            [ripple_clip,ripple_clip_t,ripple_clip_event_t,ripple_clip_abs_t, total_ripple] = addRipples(num_of_data_rows, ...
            hfo_times, ripple_clip,ripple_clip_t,ripple_clip_event_t,ripple_clip_abs_t, total_ripple, ripple_ic_clip,ripple_ic_clip_t,ripple_ic_clip_event_t,ripple_ic_clip_abs_t, total_ripple_ic );

            %% Calculate ICA for fast ripples (FR)
            [fr, fr_ic1, EEG, error_flag] = ez_cudaica_fripple_putou_e1(eeg_data_no_notch, sampling_rate, paths);
            
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

                [score_amp_fripple, zscore_amp_fripple] = calculateSmoothedHFOamplitude_3(fr, fr_ic1);
                
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
                
                [fripple_clip,fripple_clip_t,fripple_clip_event_t,fripple_clip_abs_t, ...
                 total_fripple] = runRippleDetection_3(eeg_data, score_amp_fripple, zscore_amp_fripple, ai, thresh_z, thresh_zoff);
                
                % Create ripple index
                num_of_data_rows = numel(eeg_data(:,1));
                [hfo_times, ~] = convRippleClips_timeToIndices(num_of_data_rows, fripple_clip_t, ic1, total_fripple);

                num_of_data_cols = numel(eeg_data(1,:));
                fripple_ics = getFrippleIcs(num_of_data_cols, num_of_data_rows, EEG, hfo_times, ai);
                
                [eeg.score_amp_fripple, eeg.zscore_amp_fripple] = calculateSmoothedHFOamplitude_2(num_of_data_rows, fripple_ics);
                
                [fripple_ic_clip,fripple_ic_clip_t,fripple_ic_clip_event_t,fripple_ic_clip_abs_t, ....
                 total_fripple_ic] = runRippleDetection_4(eeg_data, eeg.score_amp_fripple, eeg.zscore_amp_fripple);

                total_fripple_backup = total_fripple;

                [fripple_clip,fripple_clip_t,fripple_clip_event_t,fripple_clip_abs_t, total_fripple] = addRipples(num_of_data_rows, ...
                hfo_times, fripple_clip,fripple_clip_t,fripple_clip_event_t,fripple_clip_abs_t, total_fripple, fripple_ic_clip,fripple_ic_clip_t,fripple_ic_clip_event_t,fripple_ic_clip_abs_t, total_fripple_ic );

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
                DSP_data_m.total_ripple=total_ripple;
                DSP_data_m.ripple_clip=ripple_clip;
                DSP_data_m.ripple_clip_abs_t=ripple_clip_abs_t;
                DSP_data_m.ripple_clip_event_t=ripple_clip_event_t;
                DSP_data_m.total_fripple=total_fripple;
                DSP_data_m.fripple_clip=fripple_clip;
                DSP_data_m.fripple_clip_abs_t=fripple_clip_abs_t;
                DSP_data_m.fripple_clip_event_t=fripple_clip_event_t;
                
                filename1 = ['dsp_' file_id '_m_' file_block '.mat'];
                filename1 = strcat(paths.ez_top_in,filename1);
                save(filename1,'DSP_data_m', '-v7.3');
            
            else % error_flag 1 i.e. CUDAICA exploded ICA #1
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
                file_id_size=numel(metadata.file_id);
                file_id=metadata.file_id(1:(file_id_size-4));
                filename1=['dsp_' file_id '_m_' file_block '.mat'];
                filename1=strcat(paths.ez_top_in,filename1);
                save('-v7.3',filename1,'DSP_data_m');
                error_flag=1;
            end;
            
        else % number of bad electrodes are the vast majority
            error_status = 1;
            error_msg = 'mostly noisy mp electrodes';
        end
    else % error_flag 1 i.e. CUDAICA exploded ICA #3
        
        fprintf('CUDAICA exploded moving channels to bipolar montage \r');
        chan_indexes = [1:numel(metadata.m_chanlist)];
        [ez_tall_m, ez_tall_bp, hf_bad_m_out, metadata] = removeBadChannelsFromMonopolarMontage(ez_tall_m, ez_tall_bp, metadata, chan_indexes);
        metadata.hf_bad_m2 = hf_bad_m_out;

        DSP_data_m = [];
        ez_tall_m = [];
        hfo_ai = zeros(numel(gather(ez_tall_bp(1,:))),1); 
        fr_ai = zeros(numel(gather(ez_tall_bp(1,:))),1);
        ez_tall_hfo_m = [];
        ez_tall_fr_m = [];
        num_trc_blocks = 1;
        error_flag = 1;

        filename1 = ['dsp_' metadata.file_id '_m_' file_block '.mat'];
        filename1 = strcat(paths.ez_top_in, filename1);
        save(filename1,'DSP_data_m', '-v7.3'); %in this case you are saving just an empty array? 
    end %end of enormous if else

    %to be improved later
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
end %end of dsp function

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
function [ez_tall_m, ez_tall_bp, hf_bad_m_out, metadata] = removeBadChannelsFromMonopolarMontage(ez_tall_m, ...
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
    hf_bad_m_out = hf_bad_m; %to improve later

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

    hf_bad_m_out = hf_bad_m; %to improve later
   
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

% Improve name of function
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

%Merge with the one above later
function [score_amp, zscore_amp] = calculateSmoothedHFOamplitude_2(num_of_data_rows, ics)
    % redefine z_score block using ics
    for i=1:num_of_data_rows
        hilbert_amp=abs(hilbert(ics(i,:)));
        smooth_length=round((2000/2000)*40);
        score_amp(i,:)=smooth(hilbert_amp,smooth_length,'loess');
        score_amp(i,:)=abs(score_amp(i,:));
        lambdahat = poissfit_2(score_amp(i,:));
        zscore_amp(i,:)=2*(sqrt(score_amp(i,:))-sqrt(2.5*lambdahat)); %difference with _1
    end
end

%% Merge with the two above later
function [score_amp_fripple, zscore_amp_fripple] = calculateSmoothedHFOamplitude_3(fr, fr_ic1)
    for i=1:numel(fr(:,1));
        hilbert_hfo_amp=abs(hilbert(fr_ic1(i,:)));
        score_amp=hilbert_hfo_amp;
        smooth_length=round((2000/2000)*40);
        score_amp_fripple(i,:)=smooth(score_amp,smooth_length,'loess');
        zscore_amp_fripple(i,:)=zscore_2(score_amp_fripple(i,:));
    end;
end

function [thresh_z, thresh_zoff] = skewnessCorrection(zscore_amp, num_of_m_channels, ...
                                                      thresh_z_values, thresh_zoff_values)
        
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

%To be refactored.
function [ripple_clip,ripple_clip_t,ripple_clip_event_t,ripple_clip_abs_t, total_ripple]=runRippleDetection(eeg_data, score_amp_ripple, ...
                                                                     zscore_amp_ripple, ic1, ai, thresh_z, thresh_zoff)
    fprintf('Running Ripple Detection\r');

    num_of_data_rows = numel(eeg_data(:,1));
    initial_value = cell(num_of_data_rows,1);
    
    ripple_clip = initial_value;
    ripple_clip_t = initial_value;
    ripple_clip_event_t = initial_value;
    ripple_clip_abs_t = initial_value;
    total_ripple = zeros(num_of_data_rows,1);
    
    datablock=0;
    eeg_index=1;
    while eeg_index < (numel(eeg_data(1,:)) -(59.99*2000))
        ieeg_block=eeg_data(:,(eeg_index+1):(eeg_index+(2000*60)-1));
        zscore_block=zscore_amp_ripple(:,(eeg_index+1):(eeg_index+(2000*60)-1));
        amp_block=score_amp_ripple(:,(eeg_index+1):(eeg_index+(2000*60)-1));
        ic1_block=ic1(:,(eeg_index+1):(eeg_index+(2000*60)-1));
        ai_block=ai((eeg_index+1):(eeg_index+(2000*60)-1));
        eeg_index=eeg_index+(2000*60)-1;
        %eeg_index/2000 this was being printed to std out log later if necesary
        for channel=1:numel(eeg_data(:,1))
            
            % Define ic1,z_score amp traces from blocks.
            zscore_amp=zscore_block(channel,:);
            amp=amp_block(channel,:);
            ic1_chan=ic1_block(channel,:);
            
            % Set initial values for HFO search
            flagged=0;
            start=1;

            % Define interval to search for HFO events in the zscore_amp time series
            step_search=(0.001*2000);
            
            % Iterate through entire z-scored time series, start of event defined at Z>3.5, note this
            % is a relatively low cut off. The point here is to capture as many events as possible
            % they will be refined later in the analysis. An event is complete when the Z score is
            % below <1.5. An event is only saved if it is greater than 15 msec in duration.
            if datablock == 0
                start_index=800;
            else
                start_index=1;
            end;
            for j=start_index:step_search:numel(zscore_amp);
                A_boolean=zscore_amp(j)>thresh_z(channel); % v4 with skewness adjustment
                B_boolean=amp(j)>5.5;
                C_boolean= and(A_boolean,B_boolean);
                if ((flagged==0) && (C_boolean==1)) % Optimization factor #1
                    flagged=1;
                    start=j;
                end;
                if ((flagged==1) && (zscore_amp(j)>thresh_zoff(channel))) end; % Optimization factor #2
                if ((flagged==1) && (zscore_amp(j)<thresh_zoff(channel)))
                    
                    if  ((j-start)*(1/2000)) > 0.008
                        % to determine if HFO is valid the first step is calculating
                        % its frequency at the peak of its psd.
                        
                        nfft = 2^nextpow2(length(ic1_chan(start:j)));
                        Pxx = abs(fft(ic1_chan(start:j),nfft)).^2/length(ic1_chan(start:j))/2000;
                        Hpsd = dspdata.psd(Pxx(1:length(Pxx)/2),'Fs',2000);
                        [a,b]=max(Hpsd.Data);
                        HFO_frequency=Hpsd.Frequencies(b);
                        
                        %  calculate the duration cutoff based on the peak frequency of
                        %  the HFO.
                        duration_cutoff=0;
                        
                        if (HFO_frequency <= 150) duration_cutoff = 0.012; end % Optimization Factor #3
                        if (HFO_frequency > 150 && HFO_frequency < 250) duration_cutoff = 0.008; end
                        if (HFO_frequency >= 250 && HFO_frequency < 400) duration_cutoff = 1; end
                        if (HFO_frequency >= 400)  duration_cutoff = 1; end;
                        
                        %if the HFO duration exceeds the duration cutoff save the raw HFO accompanying
                        %the event, the instantaneous phase of the eeg at the time of the event, the
                        %unfiltered signal at the time of the event, and the Z-scored HFO stream at the
                        %time of the event.
                        if ((j-start)*(1/2000)) > duration_cutoff
                            if ((j-start)*(1/2000)) < 0.5; % Is the HFO less than half a second i.e. not artifact
                                artifact=0;
                                for k=start:j % Look up artifact index to determine if HFO is artefactual.
                                    if ai_block(k)>0.05 % v4 raised AI thresh to 0.05
                                        artifact=1;
                                    end;
                                end;
                                if artifact==0
                                    total_ripple(channel)=total_ripple(channel)+1;
                                    if start-1100 < 1   % v3 adjust 0.25 sec for asymmetric filtering
                                        clip_start=1;
                                    else
                                        clip_start=start-1100;
                                    end;
                                    if j+100 > numel(ieeg_block(1,:))
                                        clip_end=numel(ieeg_block(1,:));
                                    else
                                        clip_end=j+100;
                                    end;
                                    ripple_clip{channel,total_ripple(channel)}=ieeg_block(channel,(clip_start):(clip_end));
                                    ripple_clip_t{channel,total_ripple(channel)}=[((start/2000)+(datablock*60)-.0035) ((j/2000)+(datablock*60))]; % v3 do not adjust 0.25 sec for asymmetric filtering b/c off stage II
                                    ripple_clip_event_t{channel,total_ripple(channel)}=[((start/2000)+(datablock*60)-.0035)-500 ((j/2000)+(datablock*60))-500];
                                    ripple_clip_abs_t{channel, total_ripple(channel)}=[((clip_start/2000)+(datablock*60)) ((clip_end/2000)+(datablock*60))];
                                end;
                            end;
                        end;
                    end;
                    flagged=0;
                end;
            end;
        end;
        datablock=datablock+1;
    end;
    %clear A_boolean a_value ai_block amp amp_block artifact b_boolean b_ind C_boolean chan_block_str channel clip_end clip_start counter2 datablock duration_cutoff eeg_index HFO_frequency hilbert_hfo_amp ic1_block ic1_chan i j k lambdahat nfft p Pxx q ref score_amp zscore_amp_ripple zscore_block
end

%Merge with the one above later
function [ripple_ic_clip,ripple_ic_clip_t,ripple_ic_clip_event_t,ripple_ic_clip_abs_t, ....
          total_ripple_ic] = runRippleDetection_2(eeg_data, hfo, score_amp_ripple, zscore_amp_ripple, ripple_ics)
    fprintf('Running Ripple ic Detection\r');
    
    num_of_data_rows = numel(eeg_data(:,1));
    initial_value = cell(num_of_data_rows,1);

    ripple_ic_clip=initial_value;
    ripple_ic_clip_t=initial_value;
    ripple_ic_clip_event_t=initial_value;
    ripple_ic_clip_abs_t=initial_value;
    total_ripple_ic=zeros(numel(hfo(:,1)),1);

    datablock=0;
    eeg_index=1;
    while eeg_index < (numel(hfo(1,:))-(59.9*2000))
        ieeg_block=eeg_data(:,(eeg_index+1):(eeg_index+(2000*60)-1));
        amp_block=score_amp_ripple(:,(eeg_index+1):(eeg_index+(2000*60)-1));
        zscore_block=zscore_amp_ripple(:,(eeg_index+1):(eeg_index+(2000*60)-1));
        ic1_block=ripple_ics(:,(eeg_index+1):(eeg_index+(2000*60)));
        eeg_index=eeg_index+(2000*60)-1;
        %eeg_index/2000
        for channel=1:numel(hfo(:,1))
            
            % Define ic1,z_score amp traces from blocks.
            zscore_amp=zscore_block(channel,:);
            amp=amp_block(channel,:);
            ic1_chan=ic1_block(channel,:);
            
            % Set initial values for HFO search
            flagged=0;
            start=1;
            
            % Define interval to search for HFO events in the zscore_amp time series
            step_search=(0.002*2000);
            
            % Iterate through entire z-scored time series, start of event defined at Z>3.5, note this
            % is a relatively low cut off. The point here is to capture as many events as possible
            % they will be refined later in the analysis. An event is complete when the Z score is
            % below <1.5. An event is only saved if it is greater than 15 msec in duration.
            if datablock == 0
                start_index=800;
            else
                start_index=1;
            end;
            for j=start_index:step_search:numel(zscore_amp);
                A_boolean=zscore_amp(j)>1;
                B_boolean=amp(j)>4;
                C_boolean=and(A_boolean,B_boolean);
                if ((flagged==0) && (C_boolean==1)) % Optimization factor #1
                    flagged=1;
                    start=j;
                end
                if ((flagged==1) && (zscore_amp(j)>-0.2)) end; % Optimization factor #2
                if ((flagged==1) && (zscore_amp(j)<-0.2))
                    
                    if  ((j-start)*(1/2000)) > 0.001
                        % to determine if HFO is valid the first step is calculating
                        % its frequency at the peak of its psd.
                        
                        nfft = 2^nextpow2(length(ic1_chan(start:j)));
                        Pxx = abs(fft(ic1_chan(start:j),nfft)).^2/length(ic1_chan(start:j))/2000;
                        Hpsd = dspdata.psd(Pxx(1:length(Pxx)/2),'Fs',2000);
                        [a,b]=max(Hpsd.Data);
                        HFO_frequency=Hpsd.Frequencies(b);
                        
                        %  calculate the duration cutoff based on the peak frequency of
                        %  the HFO.
                        duration_cutoff=0;
                        
                        if (HFO_frequency <= 150) duration_cutoff = 0.001; end % Optimization Factor #3
                        if (HFO_frequency > 150 && HFO_frequency < 200) duration_cutoff = 0.001; end
                        if (HFO_frequency >= 200 && HFO_frequency < 400) duration_cutoff = 1; end
                        if (HFO_frequency >= 400)  duration_cutoff = 1; end;
                        
                        %if the HFO duration exceeds the duration cutoff save the raw HFO accompanying
                        %the event, the instantaneous phase of the eeg at the time of the event, the
                        %unfiltered signal at the time of the event, and the Z-scored HFO stream at the
                        %time of the event.
                        if ((j-start)*(1/2000)) > duration_cutoff
                            if ((j-start)*(1/2000)) < 0.5; % Is the HFO less than half a second i.e. not artifact
                                artifact=0;
                                if artifact==0
                                    total_ripple_ic(channel)=total_ripple_ic(channel)+1;
                                    
                                    if start-1100 < 1   % v3 adjust for asymmetric filtering
                                        clip_start=1;
                                    else
                                        clip_start=start-1100;
                                    end;
                                    
                                    if j+100 > numel(ieeg_block(1,:))    % v3 adjust for asymmetric filtering
                                        clip_end=numel(ieeg_block(1,:));
                                    else
                                        clip_end=j+100;
                                    end;
                                    ripple_ic_clip{channel,total_ripple_ic(channel)}=ieeg_block(channel,(clip_start):(clip_end));
                                    ripple_ic_clip_t{channel,total_ripple_ic(channel)}=[((start/2000)+(datablock*60)-.0035) ((j/2000)+(datablock*60))];   % v3 do not adjust b/c step II
                                    ripple_ic_clip_event_t{channel,total_ripple_ic(channel)}=[((start/2000)+(datablock*60)-.0035)-500 ((j/2000)+(datablock*60))-500];
                                    ripple_ic_clip_abs_t{channel,total_ripple_ic(channel)}=[((clip_start/2000)+(datablock*60)) ((clip_end/2000)+(datablock*60))];
                                end;
                            end;
                        end;
                    end;
                    flagged=0;
                end;
            end;
        end;
        datablock=datablock+1;
    end;
end

%Merge with the 2 above later
function [fripple_clip,fripple_clip_t,fripple_clip_event_t,fripple_clip_abs_t, ....
          total_fripple] = runRippleDetection_3(eeg_data, score_amp_fripple, zscore_amp_fripple, ai, thresh_z, thresh_zoff)
    
    fprintf('Running Fast Ripple Detection \r')
    num_of_data_rows = numel(eeg_data(:,1));
    initial_value = cell(num_of_data_rows,1);

    fripple_clip= initial_value;
    fripple_clip_t= initial_value;
    fripple_clip_event_t= initial_value;
    fripple_clip_abs_t=initial_value;
    total_fripple=zeros(num_of_data_rows,1);
    
    datablock=0;
    eeg_index=1;
    while eeg_index < (numel(eeg_data(1,:))-(59.9*2000))
        ieeg_block=eeg_data(:,(eeg_index+1):(eeg_index+(2000*60)-1));
        amp_block=score_amp_fripple(:,(eeg_index+1):(eeg_index+(2000*60)-1));
        zscore_block=zscore_amp_fripple(:,(eeg_index+1):(eeg_index+(2000*60)-1));
        ai_block=ai((eeg_index+1):(eeg_index+(2000*60)-1)); %difference with _4
        eeg_index=eeg_index+(2000*60)-1;
        %eeg_index/2000
        for channel=1:numel(eeg_data(:,1))
            
            % Define z_score amp traces from blocks.
            zscore_amp=zscore_block(channel,:);
            amp=amp_block(channel,:);
            
            % initialize search values
            flagged=0;
            start=1;
            
            % Iterate through entire z-scored time series, start of event defined at Z>3.5, note this
            % is a relatively low cut off. The point here is to capture as many events as possible
            % they will be refined later in the analysis. An event is complete when the Z score is
            % below <1.5. An event is only saved if it is greater than 15 msec in duration.
            if datablock == 0
                start_index=800;
            else
                start_index=1;
            end;
            for j=start_index:numel(zscore_amp);
                A_boolean=zscore_amp(j)>thresh_z(channel); %V4 to account for skewness of deviation
                B_boolean=amp(j)>4;
                C_boolean=and(A_boolean,B_boolean);
                if ((flagged==0) && (C_boolean==1))  % Optimization factor #1
                    flagged=1;
                    start=j;
                end;
                if ((flagged==1) && (zscore_amp(j)>thresh_zoff(channel))) end; % Optimization factor #2 add this in the others
                if ((flagged==1) && (zscore_amp(j)<thresh_zoff(channel)))
                    
                    if  ((j-start)*(1/2000)) > 0.006
                        
                        %if the HFO duration exceeds the duration cutoff save the raw HFO accompanying
                        %the event, the instantaneous phase of the eeg at the time of the event, the
                        %unfiltered signal at the time of the event, and the Z-scored HFO stream at the
                        %time of the event.
                        if ((j-start)*(1/2000)) < 0.5; % Is the HFO less than half a second i.e. not artifact
                            artifact=0;
                            for k=start:j % Look up artifact index to determine if HFO is artefactual.
                                if ai_block(k)>0.1
                                    artifact=1;
                                end;
                            end;
                            if artifact==0
                                total_fripple(channel)=total_fripple(channel)+1;
                                chan_block_ann=ceil(channel/32);
                                
                                if start-1100 < 1 % v3 adjust for asymmetric filtering
                                    clip_start=1;
                                else
                                    clip_start=start-1100;
                                end;
                                
                                if j+100 > numel(ieeg_block(1,:))
                                    clip_end=numel(ieeg_block(1,:));
                                else
                                    clip_end=j+100;
                                end;
                                fripple_clip{channel,total_fripple(channel)}=ieeg_block(channel,(clip_start):(clip_end));
                                fripple_clip_t{channel,total_fripple(channel)}=[((start/2000)+(datablock*60)-.0035) ((j/2000)+(datablock*60))];  %v3 do not adjust due to step II
                                fripple_clip_event_t{channel, total_fripple(channel)}=[((clip_start/2000)+(datablock*60))-500 ((clip_end/2000)+(datablock*60))-500];
                                fripple_clip_abs_t{channel, total_fripple(channel)}=[((clip_start/2000)+(datablock*60)) ((clip_end/2000)+(datablock*60))];
                            end;
                        end;
                    end;
                    flagged=0;
                end;
            end;
        end;
        datablock=datablock+1;
    end;
end

%to be merged with the 3 above later
function [fripple_ic_clip,fripple_ic_clip_t,fripple_ic_clip_event_t,fripple_ic_clip_abs_t, ....
          total_fripple_ic] = runRippleDetection_4(eeg_data, score_amp_fripple, zscore_amp_fripple)
    fprintf('Running Fast Ripple Detection 2 \r')
    num_of_data_rows = numel(eeg_data(:,1));
    initial_value = cell(num_of_data_rows,1);

    fripple_ic_clip= initial_value;
    fripple_ic_clip_t= initial_value;
    fripple_ic_clip_event_t= initial_value;
    fripple_ic_clip_abs_t=initial_value;
    total_fripple_ic = zeros(num_of_data_rows,1);
    
    eeg_index=1;
    datablock=0;
    while eeg_index < (numel(eeg_data(1,:))-(59.9*2000))
        ieeg_block=eeg_data(:,(eeg_index+1):(eeg_index+(2000*60)-1));
        amp_block=score_amp_fripple(:,(eeg_index+1):(eeg_index+(2000*60)-1));
        zscore_block=zscore_amp_fripple(:,(eeg_index+1):(eeg_index+(2000*60)-1));
        eeg_index=eeg_index+(2000*60)-1;
        %eeg_index/2000
        for channel=1:numel(eeg_data(:,1))
            
            % Define ic1,z_score amp traces from blocks.
            zscore_amp=zscore_block(channel,:);
            amp=amp_block(channel,:);
            
            % Set initial values for HFO search
            flagged=0;
            start=1;
            
            % Define interval to search for HFO events in the zscore_amp time series
            step_search=(0.0005*2000);
            
            % Iterate through entire z-scored time series, start of event defined at Z>3.5, note this
            % is a relatively low cut off. The point here is to capture as many events as possible
            % they will be refined later in the analysis. An event is complete when the Z score is
            % below <1.5. An event is only saved if it is greater than 15 msec in duration.
            if datablock == 0
                start_index=800;
            else
                start_index=1;
            end;
            
            for j=start_index:step_search:numel(zscore_amp);
                A_boolean=zscore_amp(j)>0.5;
                B_boolean=amp(j)>3;
                C_boolean=and(A_boolean,B_boolean);
                if ((flagged==0) && (C_boolean==1)) % Optimization factor #1
                    flagged=1;
                    start=j;
                end
                if ((flagged==1) && (zscore_amp(j)>-0.2)) end; % Optimization factor #2
                if ((flagged==1) && (zscore_amp(j)<-0.2))
                    
                    if  ((j-start)*(1/2000)) > 0.005
                        % to determine if HFO is valid the first step is calculating
                        % its frequency at the peak of its psd.
                        
                        %if the HFO duration exceeds the duration cutoff save the raw HFO accompanying
                        %the event, the instantaneous phase of the eeg at the time of the event, the
                        %unfiltered signal at the time of the event, and the Z-scored HFO stream at the
                        %time of the event.
                        if ((j-start)*(1/2000)) < 0.5; % Is the HFO less than half a second i.e. not artifact
                            artifact=0;
                            if artifact==0
                                total_fripple_ic(channel)=total_fripple_ic(channel)+1;
                                
                                if start-1100 < 1 % v3 adjust for asymmetric filtering
                                    clip_start=1;
                                else
                                    clip_start=start-1100;
                                end;
                                
                                if j+100 > numel(ieeg_block(1,:))   % v3 adjust for asymmetric filtering
                                    clip_end=numel(ieeg_block(1,:));
                                else
                                    clip_end=j+100;
                                end;
                                fripple_ic_clip{channel,total_fripple_ic(channel)}=ieeg_block(channel,(clip_start):(clip_end));
                                fripple_ic_clip_t{channel,total_fripple_ic(channel)}=[((start/2000)+(datablock*60)-.0035) ((j/2000)+(datablock*60))]; % v3 do not adjust b/c of step II
                                fripple_ic_clip_event_t{channel, total_fripple_ic(channel)}=[((clip_start/2000)+(datablock*60))-500 ((clip_end/2000)+(datablock*60))-500];
                                fripple_ic_clip_abs_t{channel, total_fripple_ic(channel)}=[((clip_start/2000)+(datablock*60)) ((clip_end/2000)+(datablock*60))];
                            end;
                        end;
                    end;
                    flagged=0;
                end;
            end;
        end;
        datablock=datablock+1;
    end;
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

function ripple_ics = getRippleIcs(num_of_data_cols, num_of_data_rows, EEG, hfo_times, ai)
    hfo_extract_index=[];
    ai_extract_index=[];
    hfo_times_chan=[];
    [~,artindex]=find(ai>0.025);
    non_artindex=1:num_of_data_cols;
    non_artindex(artindex)=[];
    for i=2:num_of_data_rows
        ic_prune=1:num_of_data_rows;
        ic_prune(i)=[];
        OUTEEG = pop_subcomp(EEG, ic_prune, 0);
        ai_amp=(abs(OUTEEG.data(1,artindex)));
        non_ai_amp=(abs(OUTEEG.data(1,non_artindex)));
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
            non_hfo_amp=abs(OUTEEG.data(2,non_hfo_times));
            hfo_extract_index((i-1),j)=mean(hfo_amp)/mean(non_hfo_amp);
        end;
    end;
    
    % find ripple ics
    temp_zeros=zeros(numel(hfo_extract_index(1,:)),1);
    hfo_extract_index=vertcat(temp_zeros', hfo_extract_index);
    hfo_extract_index(isnan(hfo_extract_index))=0;
    
    ai_extract_index= [NaN ai_extract_index];
    
    C=zscore_2(clustering_coef_wd(hfo_extract_index));
    [a,b]=find(C>1);
    [c,d]=find(hfo_extract_index>800);
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

%To be merged with getRippleIcs
function fripple_ics = getFrippleIcs(num_of_data_cols, num_of_data_rows, EEG, hfo_times, ai)
    % Calculate fripple extract index
    hfo_extract_index=[];
    hfo_times_chan=[];
    [~,artindex]=find(ai>0.02);
    non_artindex=1:num_of_data_cols;
    non_artindex(artindex)=[];
    for i=2:num_of_data_rows
        ic_prune= 1:num_of_data_rows;
        ic_prune(i)=[];
        OUTEEG = pop_subcomp(EEG, ic_prune, 0);
        ai_amp=(abs(OUTEEG.data(1,artindex)));
        non_ai_amp=(abs(OUTEEG.data(1,non_artindex)));
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
            ai_amp=mean(abs(OUTEEG.data(j,artindex)));
            non_hfo_amp=abs(OUTEEG.data(j,non_hfo_times));
            hfo_extract_index((i-1),j)=mean(hfo_amp)/mean(non_hfo_amp);
        end;
    end;
    
    % find fripple ics
    temp_zeros=zeros(numel(hfo_extract_index(1,:)),1);
    hfo_extract_index=vertcat(temp_zeros', hfo_extract_index);
    hfo_extract_index(isnan(hfo_extract_index))=0;
    
    ai_extract_index= [NaN ai_extract_index];
    
    C=zscore_2(clustering_coef_wd(hfo_extract_index));
    [a,b]=find(C>1);
    [c,d]=find(hfo_extract_index>150);
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
    
    fripple_ics=OUTEEG.data;
end

% if ripple not in look up index add the to total_ripple and add ripples from step 2 to ripple clips
function [clip,clip_t,clip_event_t,clip_abs_t, total] = addRipples(num_of_data_rows, ...
          hfo_times, clip,clip_t,clip_event_t,clip_abs_t, total, ic_clip, ic_clip_t, ic_clip_event_t, ic_clip_abs_t, total_ic)
            
    for i=1:num_of_data_rows
        temp_lookup=hfo_times{i,:};
        for j=1:total_ic(i)
            lookup_val1=int32(ic_clip_t{i,j}(1)*2000);
            lookup_val2=int32(ic_clip_t{i,j}(2)*2000);
            lookup_val12=lookup_val1:lookup_val2;
            if isempty(intersect(lookup_val12,temp_lookup))
                total(i)=total(i)+1;
                clip{i,total(i)}=ic_clip{i,j};
                clip_t{i,total(i)}=ic_clip_t{i,j};
                clip_event_t{i,total(i)}=ic_clip_event_t{i,j};
                clip_abs_t{i,total(i)}=ic_clip_abs_t{i,j};
            end;
        end;
    end;
end
