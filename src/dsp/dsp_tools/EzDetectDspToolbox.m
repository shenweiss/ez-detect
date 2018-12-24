%The following procedures are used in both monopolar and bipolar dsp routines. 
%For specific procedures see MonopolarDspToolbox and BipolarDspToolbox EzDetectDspToolbox subclasses.

classdef EzDetectDspToolbox
	methods 

		function [eeg_data, eeg_data_no_notch] = notchFilter(Ez, eeg)
			[eeg_data, eeg_data_no_notch] = notchFilter_(eeg);
		end

		function [score_amp_ripple, zscore_amp_ripple] = calculateSmoothedHFOamplitude(Ez, num_of_data_rows, ics, ...
                                                		   score_amp_ripple_i_method, zscore_amp_ripple_i_method)
			[score_amp_ripple, zscore_amp_ripple] = calculateSmoothedHFOamplitude_(num_of_data_rows, ics, ...
				 									score_amp_ripple_i_method, zscore_amp_ripple_i_method);
		end 

		function score_amp_ripple_i = score_amp_ripple_i_method_1(Ez, hilbert_amp, smooth_length)
			score_amp_ripple_i = score_amp_ripple_i_method_1_(hilbert_amp, smooth_length);
		end

		function score_amp_ripple_i = score_amp_ripple_i_method_2(Ez, hilbert_amp, smooth_length)
			score_amp_ripple_i = score_amp_ripple_i_method_2_(hilbert_amp, smooth_length);
		end

		function zscore_amp_ripple_i = zscore_amp_ripple_i_method_1(Ez, score_amp_ripple_i)
			zscore_amp_ripple_i = zscore_amp_ripple_i_method_1_(score_amp_ripple_i);
		end

		function zscore_amp_ripple_i = zscore_amp_ripple_i_method_2(Ez, score_amp_ripple_i)
			zscore_amp_ripple_i = zscore_amp_ripple_i_method_2_(score_amp_ripple_i);
		end
		
		function [thresh_z, thresh_zoff] = skewnessCorrection(Ez, zscore_amp,num_of_m_channels,thresh_z_values,thresh_zoff_values)
			[thresh_z, thresh_zoff] = skewnessCorrection_(zscore_amp,num_of_m_channels,thresh_z_values,thresh_zoff_values);
		end
		
		function b = detectAdditionalBadElectrodes_nn(Ez, hfo, hfo_values, run_ripple_nn, ripple_thresh, ...
		                                                               run_fripple_nn, fripple_thresh)
			b = detectAdditionalBadElectrodes_nn_(hfo, hfo_values, run_ripple_nn, ripple_thresh, ...
		                                                               run_fripple_nn, fripple_thresh);
		end
		
        %not used anymore, will be deleted soon
		function num_trc_blocks = writeTRCfiles(Ez, eeg, chanlist, metadata, sampling_rate, ...
		                                     trc_temp_dir, executable_dir, mat2trc_bin_filename)
			num_trc_blocks = writeTRCfiles_(eeg, chanlist, metadata, sampling_rate, ...
		                                     trc_temp_dir, executable_dir, mat2trc_bin_filename);
		end
		
		function resampled_data = resampleData(Ez, sampling_rate, desired_hz, number_of_channels, eeg_data)
			resampled_data = resampleData_(sampling_rate, desired_hz, number_of_channels, eeg_data);
		end

		function ripple_data = rippleDetection(Ez, eeg_data, score_amp_ripple, zscore_amp_ripple, ics, ai, config)
			ripple_data = rippleDetection_(eeg_data, score_amp_ripple, zscore_amp_ripple, ics, ai, config);
		end

		function [hfo_times, hfo_values] = convRippleClips_timeToIndices(Ez, num_of_data_rows, clip_t, ic1, total)
			[hfo_times, hfo_values] = convRippleClips_timeToIndices_(num_of_data_rows, clip_t, ic1, total);
		end

	end
end

%Methods definition

function [eeg_data, eeg_data_no_notch] = notchFilter_(eeg)
    %I think that eeg_data is the filtered one. The other one is just a copy. Improve names later.
    eeg_data_no_notch = eeg;
    for i = 1:numel(eeg(:,1));
        eeg_temp = eeg(i,:);
        f0 = (2*(60/2000));
        df = .1;
        N = 30; % must be even for this trick
        h = remez(N,[0 f0-df/2 f0+df/2 1],[1 1 0 0]);
        h = 2*h - ((0:N)==(N/2));
        eeg_notch = filtfilt(h,1,eeg_temp);
        eeg_data(i,:) = eeg_notch;
    end
end    

%ics is sometimes fr
function [score_amp_ripple, zscore_amp_ripple] = calculateSmoothedHFOamplitude_(num_of_data_rows, ics, ...
                                                 score_amp_ripple_i_method, zscore_amp_ripple_i_method)
    for i = 1:num_of_data_rows
        hilbert_amp = abs(hilbert(ics(i,:)));
        smooth_length = round((2000/2000)*40); %ask about this... thats 40 always, ask if they wanna extract variable as srate
        score_amp_ripple(i,:) = score_amp_ripple_i_method(hilbert_amp, smooth_length);
        zscore_amp_ripple(i,:) = zscore_amp_ripple_i_method(score_amp_ripple(i,:));
    end
end


%Ask if the difference in the calls are on purpose or are bugs 
function score_amp_ripple_i = score_amp_ripple_i_method_1_(hilbert_amp, smooth_length)
    score_amp_ripple_i = abs(smooth(hilbert_amp,smooth_length,'loess'));
end

function score_amp_ripple_i = score_amp_ripple_i_method_2_(hilbert_amp, smooth_length)
    score_amp_ripple_i = smooth(hilbert_amp,smooth_length,'loess');
end

function zscore_amp_ripple_i = zscore_amp_ripple_i_method_1_(score_amp_ripple_i)
    lambdahat = poissfit_2(score_amp_ripple_i);
    zscore_amp_ripple_i = 2*(sqrt(score_amp_ripple_i)-sqrt(lambdahat)); 
end
function zscore_amp_ripple_i = zscore_amp_ripple_i_method_2_(score_amp_ripple_i)
    lambdahat = poissfit_2(score_amp_ripple_i);
    zscore_amp_ripple_i = 2*(sqrt(score_amp_ripple_i)-sqrt(2.5*lambdahat)); %difference with _1
end
%zscore_amp_ripple_i_method_3 is zscore_2

function [thresh_z, thresh_zoff] = skewnessCorrection_(zscore_amp,num_of_m_channels,thresh_z_values,thresh_zoff_values)
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

function b = detectAdditionalBadElectrodes_nn_(hfo, hfo_values, run_ripple_nn, ripple_thresh, ...
                                                               run_fripple_nn, fripple_thresh)
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
    b = [];
    if counter > 0
        test_vector=[samples' rms_calc' std_calc' entropy_calc' slope_calc' hilbert_calc']; 
        
        b1 = [];
        if run_ripple_nn
            Y1 = ripple_nn(test_vector);
            [c,d] = find(Y1>ripple_thresh); %this was being printed, avoid printing for now.
            b1 = lookup_vector(c);
        end 
        b2 = [];
        if run_fripple_nn
            Y2 = fripple_nn(test_vector);  
            [a,b] = find(Y2>fripple_thresh); %this was being printed, avoid printing for now.
            b2 = lookup_vector(a);
        end
        b = [b2 b1];
    end
end

% % Write TRC files
% % The function first outputs the 32 channel .TRC files for the annotations
% % from the input iEEG file.

function num_trc_blocks = writeTRCfiles_(eeg, chanlist, metadata, sampling_rate, ...
                                     trc_temp_dir, executable_dir, mat2trc_bin_filename)
    fprintf('Writing monopolar iEEG to trc format \r');
    fprintf('Converting data to 2048 Hz sampling rate \r');
    % The first step is to convert the sampling rate to 2048 Hz
    number_of_channels = numel(eeg(:,1));
    desired_hz = 2048;
    resampled_data = resampleData_(sampling_rate, desired_hz, number_of_channels, eeg);

    TRC.data = resampled_data;
    TRC.chanlist = chanlist;
    % Clear the temporary .mat files  %I would do this at the end of the program
    cleanTempTRC_(trc_temp_dir, metadata.file_block);
    
    % The next step is to write the TRC file blocks
    num_trc_blocks = writeTRCBlocks_(TRC, metadata.file_block, metadata.file_id, ...
                               trc_temp_dir, executable_dir, mat2trc_bin_filename);
end

function resampled_data = resampleData_(sampling_rate, desired_hz, number_of_channels, eeg_data)
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

function cleanTempTRC_(directory, file_block)
    system(['rm -f ' directory 'eeg_2k_a_' file_block '.mat']);
    system(['rm -f ' directory 'eeg_2k_b_' file_block '.mat']);
    system(['rm -f ' directory 'eeg_2k_c_' file_block '.mat']);
    system(['rm -f ' directory 'eeg_2k_d_' file_block '.mat']);
    system(['rm -f ' directory 'eeg_2k_e_' file_block '.mat']);
    system(['rm -f ' directory 'eeg_2k_f_' file_block '.mat']);
    system(['rm -f ' directory 'eeg_2k_g_' file_block '.mat']);
end

%Los binarios esos no existen, cuando se crean ?  revisar. 
function num_trc_blocks = writeTRCBlocks_(TRC, file_block, file_id, trc_temp_dir, executable_dir, mat2trc_bin_filename)
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
            system_command=[executable_dir  mat2trc_bin_filename '_a' ' ' file_id ' ' file_block ' &'];
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
            system_command=[executable_dir  mat2trc_bin_filename '_b' ' ' file_id ' ' file_block ' &'];
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
            system_command=[executable_dir  mat2trc_bin_filename '_c' ' ' file_id ' ' file_block ' &'];
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
            system_command=[executable_dir  mat2trc_bin_filename '_d' ' ' file_id ' ' file_block ' &'];
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
            system_command=[executable_dir  mat2trc_bin_filename '_e' ' ' file_id ' ' file_block ' &'];
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
            system_command=[executable_dir  mat2trc_bin_filename '_f' ' ' file_id ' ' file_block ' &'];
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
            system_command=[executable_dir  mat2trc_bin_filename '_g' ' ' file_id ' ' file_block ' &'];
            system(system_command);
            fprintf('Writing .TRC file #7 in background \r');
        end;
    end;
end

%Main procedure in dsp to detect ripples, ripple_ics, fripples, fripple_ics.
%The versions for ics didn't use isArtifactualHFO funciton, this one does it, ask if that doesn't makes trouble.
%initialize data structures '2D array of cells' note that this structure can flexibly
%store different length elements within each cell, and the number of cells can vary by
%row. This structure may need to be revised to improve efficiency.

function ripple_data = rippleDetection_(eeg_data, score_amp_ripple, zscore_amp_ripple, ics, ai, config)
    
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
    config.avoid_reading_last_snds = 0.001; %make it argument later. Review Shennan email about this

    for eeg_index = 1:block.size:data_length %Review Shennan email about this
    	%ask if the line eeg_index/2000 was just for printing or a bug. 
        block = updateBlockData(block, eeg_index, eeg_data,zscore_amp_ripple, score_amp_ripple, ics, ai, config);
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
                zscore_amp_outstrips_thresh = zscore_amp(rel_img_index) > config.zscore_amp_thresh_z(chan); % v4 with skewness adrel_img_indexustment
                amp_outstrips_thresh = amp(rel_img_index) > config.amp_thresh;
                img_detected_positive = and(zscore_amp_outstrips_thresh,amp_outstrips_thresh);

                if  ~hfo_event_detected && img_detected_positive  % Optimization factor #1
                    hfo_event_detected = true;
                    hfo_detection_start_ptr = rel_img_index;
                end
                % Optimization factor #2.
                if (hfo_event_detected && (zscore_amp(rel_img_index) > config.zscore_amp_thresh_zoff(chan)) ) end; %@Shennan: This isn't doing anything, it would be the same to remove it.
                if hfo_event_detected && (zscore_amp(rel_img_index) < config.zscore_amp_thresh_zoff(chan) )
                    
                    event_img_count = rel_img_index-hfo_detection_start_ptr; %@Shennan: +1 is missing, but if you add it less events are detected now we count all images
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
                                    %hfo_event_detected = false; %@Shennan: I have just added this line, does it make sense to you? When you save, you start again.
                                end
                            %else  %comment for now because of Shennan answer
                            %    hfo_event_detected = false; %@Shennan: I have just added this line, does it make sense to you? 
                                                            %If event_duration_snds >= 0.5 already tells you is artifactual we should discard the event right?
                            end
                        end
                    end
                     % @Shennan flagged = 0 is happening here. So this is cancelling every start of hfo_event_detection, since at first event duration is 1 millisecond < 8 milliseconds
                     % I think it goes inside  SW answer: This is correct because of the if second condition. Analize later.
                     hfo_event_detected = false; % Comment for now, I think that is a bug
                end
            end
        end
        current_block = current_block+1;
    end
end

function block = updateBlockData(block, eeg_index, eeg_data,zscore_amp_ripple, score_amp_ripple, ics, ai, config)

    avoid_reading_last_imgs = config.avoid_reading_last_snds * config.sampling_rate;
    data_length = numel(eeg_data(1,:));

    block.end_ptr = min(eeg_index+block.size-1, data_length-avoid_reading_last_imgs); 
    block.data_range = eeg_index:block.end_ptr;

    block.ieeg = eeg_data(:,block.data_range);
    block.amp = score_amp_ripple(:,block.data_range);
    block.zscore = zscore_amp_ripple(:,block.data_range);
    if (~config.fripple_run) block.ic1 = ics(:,block.data_range); end
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
    nfft = 2^nextpow2(length(ic1_chan(event_indexes)));
    %nfft = 2^nextpow2(event_img_count);
    ic1_chan_fft = fft( ic1_chan(event_indexes), nfft);
    %Pxx = abs(ic1_chan_fft).^2/event_duration_snds; %I think this is equivalent
    Pxx = abs(ic1_chan_fft).^2/length(ic1_chan(event_indexes))/2000;
    Hpsd = dspdata.psd(Pxx(1:numel(Pxx)/2),'Fs',sampling_rate);
    [~,max_index]= max(Hpsd.Data);
    HFO_frequency = Hpsd.Frequencies(max_index);
end

function duration_cutoff = getDurationCutOff(HFO_frequency, dur_cutoffs)
    % Calculate the duration cutoff based on the peak frequency ofthe HFO.
    % Optimization Factor #3
    % @Shennan: I changed the <= 150 for < 150 and > 150 for >= 150 to be consistent , is that ok?
    duration_cutoff = 0;
    if (HFO_frequency <= dur_cutoffs.fst_range) %change for <
        duration_cutoff = dur_cutoffs.fst_val; end 
    if (HFO_frequency > dur_cutoffs.fst_range && HFO_frequency < dur_cutoffs.snd_range) %change > for >=
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

%review ic1 variable name, sometimes is called with ic1 = hfo. If they are different concepts analize to avoid confusions.
function [hfo_times, hfo_values] = convRippleClips_timeToIndices_(num_of_data_rows, clip_t, ic1, total)

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
