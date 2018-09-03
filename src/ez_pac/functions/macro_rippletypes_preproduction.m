function [output] = macro_rippletypes_preproduction(filein, input_matrix_file, channel1, fileout);
% input_matrix: e.g., input_matrix([1 3 11 13],1:3)
% channel1 should be a string
load(filein);
load(input_matrix_file);
samplingrate = eeg.samp_rate;

output_bpFIR = [];
output_hilbert = [];
output_osc_epochs = [];
output =[];
ueeg = [];

% Now you need to use the input_matrix this is important for the visual display of the data
channelinfo = matrixreader(input_matrix);
matrixsize = length(channelinfo.names);
numberfoundchannels = 0;
channelindex = 0;
for i = 1:length(channelinfo.names) % Search input_matrix channel
    for j = 1:length(eeg.chanlist)
        if strcmp(eeg.chanlist{j},channelinfo.names{i})
            numberfoundchannels = numberfoundchannels + 1;
            foundchannels{numberfoundchannels} = eeg.chanlist{j};
            channelindex(numberfoundchannels) = j;
            disp(['Channel ', channelinfo.names{i}, ' was found.']);  % display found chan
        end
    end
end

for i = 1:length(foundchannels)
    eeg_data(i,:) = eeg.eeg_data(channelindex(i),:);
    hfo(i,:) = eeg.hfo(channelindex(i),:);
    ic1(i,:) = eeg.ic1(channelindex(i),:);
end

% to save memory exchange eeg for eeg_data, and rebuild data structure. This code lets you analyze only a subset of the total number of channels.
eeg=[];
eeg=eeg_data;
foundplot = 0;

for j = 1:length(channelinfo.names)
    if strcmp(channelinfo.names{j},channel1)
        foundchannel1 = j
    end
end

% try this instead of channelindex or channelvec.
num_channels=numel(eeg(:,1));

% visually inspected raw iEEG artifact index for data #451, $458
ai = zeros(num_channels, numel(eeg(1,:)));
artifact_segments = [];

% filtering each frequency band (spindle, theta, delta, slow wave) using EEGLAB
[output_bpFIR] = filterEEG_test1024(eeg, samplingrate);

% filtering LEEG (4-30Hz) using matlab fir1 function
for i=1:num_channels
    channel = i;
    temp_EEG=eeg(channel,:);
    LEEG = [4 30];
    % A notch filter is applied to the data segment
    f0 = (2*(60/samplingrate));
    df = .1;
    N = 30; % must be even for this trick
    h=remez(N,[0 f0-df/2 f0+df/2 1],[1 1 0 0]);
    h = 2*h - ((0:N)==(N/2));
    bpLEEG=filtfilt(h,1,temp_EEG);
    EEGFilt = fir1(100,[LEEG(1)/(samplingrate/2) LEEG(2)/(samplingrate/2)]);
    ueeg.bpLEEG(channel,:)= filtfilt(EEGFilt,1,bpLEEG);
    % hilbert transform of 4-30Hz EEG data
    ueeg.hLEEG(channel,:) = hilbert(ueeg.bpLEEG(channel,:));
end
fprintf('FIR filter done \r');

[output_hilbert] = zhilbert_test1011(eeg, output_bpFIR, samplingrate);
fprintf('hilbert done \r');

[output_osc_epochs] = epochs_test_1006(eeg, output_hilbert, foundchannel1, samplingrate);
fprintf('epochs test done \r');

t_epoch_theta = gather(output_osc_epochs.t_epoch_theta);
t_epoch_delta = gather(output_osc_epochs.t_epoch_delta);
t_epoch_spindle = gather(output_osc_epochs.t_epoch_spindle);
t_epoch_slow = gather(output_osc_epochs.t_epoch_slow);

clear output_osc_epochs

% HFO data already processed with artefact reduction steps using [hfo, ic1]=cudaica_matlab(eeg_data,samplingrate);

size_hfo=numel(hfo(1,:));
size_ic1=numel(ic1(1,:));
if size_ic1 <= size_hfo
    hfo=hfo(:,1:numel(ic1(1,:)));
    eeg=eeg(:,1:numel(ic1(1,:)));
else
    ic1=ic1(:,1:numel(hfo(1,:)));
    eeg=eeg(:,1:numel(hfo(1,:)));
end;


%eeg.chanlist=foundchannels';

fprintf('Establishing Baseline Values \r')
ini_done = false;
ini_blocks=1;
bad_data_block = false;
baseline_eeg=[];
ini_blocks=0;

fprintf('Calculating artifact index \r')
fprintf('Calculating baseline stats \r')

for i=1:numel(hfo(:,1));
    % why did you comment this out? You still need it to calculate the AI
    % >> uncommented AI parts throughout the code and added the
    % ai and artifact_segments as zeros/empty at this point
    ai_baseline_correct=mean(abs(hfo(i,:)));
    for j=1:numel(hfo(1,:))
        if ai(i,j)<10
            ai(i,j)=(abs(hfo(i,j)-ic1(i,j))/ai_baseline_correct);
        end;
    end;
    
    baseline_hfo=ic1(i,:);
    
    %% SW: You do not need to remove artifact segments.
    %    [a,b]=find(artifact_segments>numel(baseline_hfo(1,:)));
    %    artifact_segments(b)=[];
    %    baseline_hfo(artifact_segments)=[];
    
    hilbert_baseline_hfo=hilbert(baseline_hfo);
    baseline_hfo_amplitude=abs(hilbert_baseline_hfo);
    
    % This calculates the Z-table for HFO data, and EEG stdev.
    hfo_mean(i)=mean(baseline_hfo_amplitude);
    hfo_std(i)=std(baseline_hfo_amplitude);
    % This is what you use for the entire timeseries
end;

fprintf('Done calculating artifact index \r')
fprintf('Done calculating baseline stats \r')
baseline_eeg=[];
baseline_hfo=[];
hilbert_baseline_hfo=[];
baseline_hfo_amplitude=[];

% The next segment of the HFO detector uses the baseline stats and artifact
% index to detect events in 20 second segments of the recording. Visual
% inspection has confirmed that with the accurate artifact detection
% provided by the ICA method this detector is accurate for ripple
% detection. Fast ripples are detected but are often artefactual. New
% methods will be developed for automated fast ripple detection in
% macroelecctrode data.

total_hfo=zeros(num_channels,1);
fprintf('Running Main DSP \r')

header=[];
annotation= [];
annotation_time = [];
annotation_duration = [];
annotation_counter = 0;

epoch_hfo4spike = {''}; %1 sec ripple event duration
epoch_hfo4spw = {''}; %300 msec ripple event duration
epoch_ripple = {''}; %actual brief ripple event duration
events_uv = {''};
events_zampHFO = {''};
events_frequency = {''};

% I'm not sure what you are trying to do here.
% >> here I was trying to intialize 2D cell arrays for RonS, RSpW, and RonO after running 'sort_hfos_worked1011.m'
ripples_on_spikes_array={''};
total_RonS=zeros(num_channels,1);
ripples_on_sharp_waves_array={''};
total_RSpW=zeros(num_channels,1);
ripples_on_oscillations_array={''};
total_RonO=zeros(num_channels,1);
RonS_index_array = {''};
RSpW_index_array = {''};
RonO_index_array = {''};

% >> this is the cell array of 3 ripple types of ripple events (spike-ripple if R_types = 1, spw-ripple if R_types = 2, ripples on oscillations if R_types = 3)
R_types_array= {''};
% end of confusig part

%% this is the raw iEEG data of ripple events
ripple_array = {''};

%% numbers of each ripple type
counter_true_spikeR = zeros(num_channels,1);
counter_false_spikeR = zeros(num_channels,1);
counter_true_spwR = zeros(num_channels,1);
counter_false_spwR = zeros(num_channels,1);
counter_slowR = zeros(num_channels,1);
counter_deltaR = zeros(num_channels,1);
counter_spindleR = zeros(num_channels,1);
counter_thetaR = zeros(num_channels,1);

%% Phasor phase
true_RonS_phase = {''};
false_RonS_phase = {''};
true_spwR_phase = {''};
false_spwR_phase = {''};
thetaR_phase = {''};
deltaR_phase = {''};
spindleR_phase = {''};
slowR_phase = {''};

%% Phasor amplitude
zamp_true_spikeR = {''};
zamp_false_spikeR = {''};
zamp_true_spwR = {''};
zamp_false_spwR = {''};
zamp_thetaR = {''};
zamp_deltaR = {''};
zamp_spindleR = {''};
zamp_slowR = {''};

%% initializing cell arrays of different ripple types during 1 second of HFO duration
%(500ms before and after each ripple event)
true_spikeR_1secRipple = {''};
false_spikeR_1secRipple = {''};
true_spwR_1secRipple = {''};
false_spwR_1secRipple = {''};
thetaR_1secRipple = {''};
deltaR_1secRipple = {''};
spindleR_1secRipple = {''};
slowR_1secRipple = {''};

%% starting of the while/for loop

eeg_index=0;
datablock=0;

while eeg_index < (numel(eeg(1,:))-(30*samplingrate))
    
    eeg_data_sort=eeg(:,(eeg_index+1):(eeg_index+(samplingrate*20)));
    ic1_temp=ic1(:,(eeg_index+1):(eeg_index+(samplingrate*20)));
    ai_block=ai(:,(eeg_index+1):(eeg_index+(samplingrate*20)));
    
    ueeg.hilbertLEEG = ueeg.hLEEG(:,(eeg_index+1):(eeg_index+(samplingrate*20)));
    ueeg.hilbertSpindle = gather(output_hilbert.ueeg.hSpindle(:,(eeg_index+1):(eeg_index+(samplingrate*20))));
    ueeg.hilbertTheta = gather(output_hilbert.ueeg.hTheta(:,(eeg_index+1):(eeg_index+(samplingrate*20))));
    ueeg.hilbertDelta = gather(output_hilbert.ueeg.hDelta(:,(eeg_index+1):(eeg_index+(samplingrate*20))));
    ueeg.hilbertSlow = gather(output_hilbert.ueeg.hSlow(:,(eeg_index+1):(eeg_index+(samplingrate*20))));
    eeg_index=eeg_index+(samplingrate*20);
    
    %% SW: Calculate instaneous phase segments here
    % >> In the previous version, instantaneous phase of each oscillation was calculated in zhilbert.m
    % but I think you want me to calculate each phase using atan2 function within the while/for loop, so the current verion is revised
    % to reflect this change (please see the lines 262~273)
    
    for i=1:num_channels
        channel = i;
        
        %     % Apply Hilbert transform to bandpass HFO and LEEG streams
        ueeg.bpHFO = ic1_temp(channel,:);
        ueeg.hilbertHFO=hilbert(ueeg.bpHFO);
        
        %     % Calculate instaneous phase segments of 4-30Hz (LEEG) and different frequency bands
        ueeg.phaseLEEG = atan2(imag(ueeg.hilbertLEEG(channel,:)),real(ueeg.hilbertLEEG(channel,:)));
        ueeg.phaseSpindle= atan2(imag(ueeg.hilbertSpindle(channel,:)),real(ueeg.hilbertSpindle(channel,:)));
        ueeg.phaseTheta= atan2(imag(ueeg.hilbertTheta(channel,:)),real(ueeg.hilbertTheta(channel,:)));
        ueeg.phaseDelta = atan2(imag(ueeg.hilbertDelta(channel,:)),real(ueeg.hilbertDelta(channel,:)));
        ueeg.phaseSlow = atan2(imag(ueeg.hilbertSlow(channel,:)),real(ueeg.hilbertSlow(channel,:)));
        
        %     % Calculate amplitude envelope of the HFO stream
        ueeg.ampHFO=abs(ueeg.hilbertHFO);
        avg_HFO=mean(ueeg.ampHFO);
        sd_HFO=std(ueeg.ampHFO);
        
        %     % Calculate smoothed amplitude envelope of the HFO stream
        smooth_length_HFO=round((samplingrate/2000)*40);
        zscore.ampHFO=( (ueeg.ampHFO - avg_HFO )/sd_HFO);
        zscore.ampHFO_smooth =smooth(zscore.ampHFO, smooth_length_HFO); % Smoothing amplitude envelope increases the accuracy of event detection.
        
        % Define interval to search for HFO events in the zscore_amp time series
        step_search=round(0.005*samplingrate);
        
        flagged=0;
        start=1;
        
        % Iterate through entire z-scored time series, start of event defined at Z>3.5, note this
        % is a relatively low cut off. The point here is to capture as many events as possible
        % they will be refined later in the analysis. An event is complete when the Z score is
        % below <1.5. An event is only saved if it is greater than 15 msec in duration.
        
        for j=1:step_search:numel(zscore.ampHFO_smooth);
            
            if ((flagged==0) && (zscore.ampHFO_smooth(j)> 3.5)) % Optimization factor #1
                flagged=1;
                start = j;
            end;
            
            if ((flagged==1) && (zscore.ampHFO_smooth(j)>1.5)) end; % Optimization factor #2
            if ((flagged==1) && (zscore.ampHFO_smooth(j)<1.5))
                
                if  ((j-start)*(1/samplingrate)) > 0.009
                    
                    % to determine if HFO is valid the first step is calculating its frequency at the peak of its psd.
                    nfft = 2^nextpow2(length(ueeg.bpHFO(start:j)));
                    Pxx = abs(fft(ueeg.bpHFO(start:j),nfft)).^2/length(ueeg.bpHFO(start:j))/samplingrate;
                    Hpsd = dspdata.psd(Pxx(1:length(Pxx)/2),'Fs',samplingrate);
                    [a,b]=max(Hpsd.Data);
                    HFO_frequency=Hpsd.Frequencies(b);
                    
                    %  calculate the duration cutoff based on the peak frequency of the HFO.
                    duration_cutoff=0;
                    
                    if (HFO_frequency <= 150) duration_cutoff = 0.015; end % Optimization Factor #3
                    if (HFO_frequency > 150 && HFO_frequency < 200) duration_cutoff = 0.015; end
                    if (HFO_frequency >= 200 && HFO_frequency < 400) duration_cutoff = 0.009; end
                    if (HFO_frequency >= 400)  duration_cutoff = 0.009; end;
                    
                    %if the HFO duration exceeds the duration cutoff save the raw HFO accompanying
                    %the event, the instantaneous phase of the eeg at the time of the event, the
                    %unfiltered signal at the time of the event, and the Z-scored HFO stream at the
                    %time of the event.
                    
                    if ((j-start)*(1/samplingrate)) > duration_cutoff
                        if ((j-start)*(1/samplingrate)) < 0.5; % Is the HFO less than half a second i.e. not artifact
                            artifact=0;
                            
                            for k=start:j % Look up artifact index to determine if HFO is artefactual.
                                if ai_block(channel,k)>3.5
                                    artifact=1;
                                end;
                            end;
                            
                            if artifact==0
                                
                                total_hfo(channel)=total_hfo(channel)+1;
                                s_start.hfo = start + (samplingrate*datablock*20); % ripple start in sampling point
                                s_end.hfo = j + (samplingrate*datablock*20); % ripple end in sampling point
                                epoch_ripple{channel,total_hfo(channel)} = s_start.hfo:s_end.hfo;
                                ripple_array{channel,total_hfo(channel)} = eeg_data_sort(channel, start:j);
                                
                                % IS: this is for if HFOs occur at the beginning
                                if s_start.hfo <= numel(ic1(1,:))-2001
                                    % temp_array_spike (total of 2000 points = 500ms before and after each ripple event)
                                    if (s_start.hfo >= 301) && s_start.hfo < 1001;
                                        temp_array_spike = 1:2001;
                                        temp_array_spw = s_start.hfo-300:s_start.hfo+300;
                                        epoch_hfo4spike{channel,total_hfo(channel)} = 1+(samplingrate*datablock*20):2001+(samplingrate*datablock*20);
                                        epoch_hfo4spw{channel,total_hfo(channel)} = temp_array_spw;
                                    elseif s_start.hfo < 301
                                        temp_array_spike = 1:2001;
                                        temp_array_spw = 1:601;
                                        epoch_hfo4spike{channel,total_hfo(channel)} = 1+(samplingrate*datablock*20):2001+(samplingrate*datablock*20);
                                        epoch_hfo4spw{channel,total_hfo(channel)} = 1+(samplingrate*datablock*20):601+(samplingrate*datablock*20);
                                    elseif s_start.hfo >= 1001
                                        temp_array_spike = s_start.hfo-1000:s_start.hfo+1000;
                                        temp_array_spw = s_start.hfo-300:s_start.hfo+300;
                                        epoch_hfo4spike{channel,total_hfo(channel)} = temp_array_spike;
                                        epoch_hfo4spw{channel,total_hfo(channel)} = temp_array_spw;
                                    end
                                    
                                    % SW: this is for if HFOs occur at the end.
                                elseif s_start.hfo > numel(ic1(1,:))-2001
                                    if ((s_start.hfo + 301)<numel(ic1(1,:))) && ((s_start.hfo + 1001)>=numel(ic1(1,:)));
                                        temp_array_spike = numel(ic1(1,:))-2001:numel(ic1(1,:));
                                        temp_array_spw = s_start.hfo-300:s_start.hfo+300;
                                        epoch_hfo4spike{channel,total_hfo(channel)} = (numel(ic1(1,:))-2001)+(samplingrate*datablock*20):numel(ic1(1,:))+(samplingrate*datablock*20);
                                        epoch_hfo4spw{channel,total_hfo(channel)} = temp_array_spw;
                                    elseif (s_start.hfo + 301)>=numel(ic1(1,:))
                                        temp_array_spike = numel(ic1(1,:))-2001:numel(ic1(1,:));
                                        temp_array_spw = numel(ic1(1,:))-600:numel(ic1(1,:));
                                        epoch_hfo4spike{channel,total_hfo(channel)} = (numel(ic1(1,:))-2001)+(samplingrate*datablock*20):numel(ic1(1,:))+(samplingrate*datablock*20);
                                        epoch_hfo4spw{channel,total_hfo(channel)} = (numel(ic1(1,:))-601)+(samplingrate*datablock*20):numel(ic1(1,:))+(samplingrate*datablock*20);
                                    elseif (s_start.hfo + 1001)< numel(ic1(1,:))
                                        temp_array_spike = s_start.hfo-1000:s_start.hfo+1000;
                                        temp_array_spw = s_start.hfo-300:s_start.hfo+300;
                                        epoch_hfo4spike{channel,total_hfo(channel)} = temp_array_spike;
                                        epoch_hfo4spw{channel,total_hfo(channel)} = temp_array_spw;
                                    end
                                end
                                
                                events_uv{channel,total_hfo(channel)}=ueeg.bpHFO(start:j);
                                events_zampHFO{channel,total_hfo(channel)}=zscore.ampHFO(start:j);
                                events_frequency{channel,total_hfo(channel)}=HFO_frequency;
                                
                                % sort ripples into RonS, RSpW, and RonO
                                % and classifying them into true/false
                                % RonS and RSpW, and spindle-ripple,
                                % theta-ripple, delta-ripple, slow
                                % wave-ripple
                                
                                
                                %%
                                
                                amplitude_variability = [];
                                dur = [];
                                feature = [];
                                
                                raw_signal = eeg(channel, temp_array_spw);
                                %raw_signal = ueeg.bpLEEG(channel, temp_array_spike);
                                [peakLoc, peakMag] = peakfinder(raw_signal,2);
                                [troughLoc, troughMag] = peakfinder(-raw_signal,2);
                                
                                [A,B]=find(peakLoc==1);
                                peakLoc(B)=[];
                                peakMag(B)=[];
                                
                                [A,B]=find(troughLoc==1);
                                troughLoc(B)=[];
                                troughMag(B)=[];
                                
                                smooth_signal=smooth(raw_signal,20);
                                residual_signal=raw_signal-smooth_signal';
                                
                                osc=[];
                                
                                if peakLoc(1) < troughLoc(1)
                                    for k=1:(numel(peakLoc)-1)
                                        osc(((k-1)*2)+1)=(peakMag(k)-troughMag(k));
                                        osc(((k-1)*2)+2)=(-troughMag(k)+peakMag(k+1));
                                        dur(k) = (peakLoc(k+1)-peakLoc(k))/samplingrate;
                                        start_interval(k) = peakLoc(k);
                                        end_interval(k) = peakLoc(k+1);
                                        
                                    end;
                                    
                                else
                                    for k=1:(numel(troughLoc)-1)
                                        osc(((k-1)*2)+1)=(-troughMag(k)+peakMag(k));
                                        osc(((k-1)*2)+2)=(peakMag(k)-troughMag(k+1));
                                        dur(k) = (troughLoc(k+1)-troughLoc(k))/samplingrate;
                                        start_interval(k) = troughLoc(k);
                                        end_interval(k) = troughLoc(k+1);
                                    end;
                                end;
                                
                                %                                 amplitude_mean = mean(osc);
                                %                                 amplitude_variability = std(osc)/rms(residual_signal);
                                %
                                %                                 feature = [channel total_hfo(channel) amplitude_mean amplitude_variability dur];
                                %                                 feature_test{channel,total_hfo(channel)} = feature;
                                pre_type = [];
                                pre_sort = find(dur(1:k) > 0.035);
                                if ~isempty(pre_sort), pre_type = 2; % duration is used to optimize sharp waves detection
                                else pre_type = 1;
                                end
                                                                
                                %%
                                [sorted_hfos_test] = sort_hfos_worked1015(eeg, ueeg, temp_array_spike, temp_array_spw, pre_type, channel);
                                R_types_array{channel,total_hfo(channel)} = sorted_hfos_test.R_types;
                                
                                if (sorted_hfos_test.R_types == 1) 
                                    total_RonS(channel) = total_RonS(channel) + 1;
                                    ripples_on_spikes_array{channel,total_RonS(channel)} = sorted_hfos_test.ripples_on_spikes;
                                    RonS_index_array{channel,total_RonS(channel)} = sorted_hfos_test.RonS_index;
                                    
                                    [tf_sorted_ripples_test]=true_false_hfo_worked1006(sorted_hfos_test);
                                    
                                    if tf_sorted_ripples_test.label_spikeR == 1
                                        counter_true_spikeR(channel) = counter_true_spikeR(channel) + 1;
                                        % extract instantaneous phase of the true spikeR stream
                                        true_RonS_phase{channel,counter_true_spikeR(channel)} = ueeg.phaseLEEG(start:j);
                                        zamp_true_spikeR{channel,counter_true_spikeR(channel)} = zscore.ampHFO(start:j);
                                        true_spikeR_1secRipple{channel,counter_true_spikeR(channel)} = eeg(channel, temp_array_spike);
                                        
                                        if channel == foundchannel1
                                            annotation_counter = annotation_counter+1;
                                            annotation{1, annotation_counter} = 'TRoS';
                                            annotation_time(annotation_counter) = (start/samplingrate) + (datablock*20);
                                            annotation_duration(annotation_counter) = 0.1;
                                            %                                             annotation_counter = annotation_counter+1;
                                            %                                             annotation{1, annotation_counter} = 'rsE';
                                            %                                             annotation_time(annotation_counter) = (j/samplingrate) + (datablock*20);
                                            %                                             annotation_duration(annotation_counter) = 0.1;
                                        end;
                                        
                                    elseif tf_sorted_ripples_test.label_spikeR == 2
                                        counter_false_spikeR(channel) = counter_false_spikeR(channel) + 1;
                                        % extract instantaneous phase of the false spikeR stream
                                        false_RonS_phase{channel,counter_false_spikeR(channel)} = ueeg.phaseLEEG(start:j);
                                        zamp_false_spikeR{channel,counter_false_spikeR(channel)}=zscore.ampHFO(start:j);
                                        false_spikeR_1secRipple{channel,counter_false_spikeR(channel)} = eeg(channel, temp_array_spike);
                                        
                                        if channel == foundchannel1
                                            annotation_counter = annotation_counter+1;
                                            annotation{1,annotation_counter} = 'FRoS';
                                            annotation_time(annotation_counter) = (start/samplingrate) + (datablock*20);
                                            annotation_duration(annotation_counter) = 0.1;
                                            %                                             annotation_counter = annotation_counter+1;
                                            %                                             annotation{1, annotation_counter} = 'rsE';
                                            %                                             annotation_time(annotation_counter) = (j/samplingrate) + (datablock*20);
                                            %                                             annotation_duration(annotation_counter) = 0.1;
                                        end;
                                        
                                    end
                                    
                                elseif (sorted_hfos_test.R_types == 2)
                                    
                                    total_RSpW(channel) = total_RSpW(channel)+1;
                                    ripples_on_sharp_waves_array{channel,total_RSpW(channel)} = sorted_hfos_test.ripples_on_sharp_waves;
                                    RSpW_index_array{channel,total_RSpW(channel)} = sorted_hfos_test.RSpW_index;
                                    
                                    [tf_sorted_ripples_test]=true_false_hfo_worked1006(sorted_hfos_test);
                                    
                                    if tf_sorted_ripples_test.label_spwR == 1
                                        counter_true_spwR(channel) = counter_true_spwR(channel) + 1;
                                        % extract instantaneous phase of the true spwR stream
                                        true_spwR_phase{channel,counter_true_spwR(channel)} = ueeg.phaseLEEG(start:j);
                                        zamp_true_spwR{channel,counter_true_spwR(channel)}=zscore.ampHFO(start:j);
                                        true_spwR_1secRipple{channel,counter_true_spwR(channel)} = eeg(channel, temp_array_spike);
                                        
                                        if channel == foundchannel1
                                            annotation_counter = annotation_counter+1;
                                            annotation{1,annotation_counter} = 'Tspw';
                                            annotation_time(annotation_counter) = (start/samplingrate) + (datablock*20);
                                            annotation_duration(annotation_counter) = 0.1;
                                            %                                              annotation_counter = annotation_counter+1;
                                            %                                             annotation{1,annotation_counter} = 'spwE';
                                            %                                             annotation_time(annotation_counter) = (j/samplingrate) + (datablock*20);
                                            %                                             annotation_duration(annotation_counter) = 0.1;
                                        end;
                                        
                                    elseif tf_sorted_ripples_test.label_spwR == 2
                                        counter_false_spwR(channel) = counter_false_spwR(channel) + 1;
                                        % extract instantaneous phase of the false spwR stream
                                        false_spwR_phase{channel,counter_false_spwR(channel)} = ueeg.phaseLEEG(start:j);
                                        zamp_false_spwR{channel,counter_false_spwR(channel)}=zscore.ampHFO(start:j);
                                        false_spwR_1secRipple{channel,counter_false_spwR(channel)} = eeg(channel, temp_array_spike);
                                        
                                        if channel == foundchannel1
                                            annotation_counter = annotation_counter+1;
                                            annotation{1,annotation_counter} = 'Fspw';
                                            annotation_time(annotation_counter) = (start/samplingrate) + (datablock*20);
                                            annotation_duration(annotation_counter) = 0.1;
                                            %                                              annotation_counter = annotation_counter+1;
                                            %                                             annotation{1,annotation_counter} = 'spwE';
                                            %                                             annotation_time(annotation_counter) = (j/samplingrate) + (datablock*20);
                                            %                                             annotation_duration(annotation_counter) = 0.1;
                                        end;
                                        
                                    end
                                    
                                    
                                    
                                elseif (sorted_hfos_test.R_types == 3)
                                    total_RonO(channel) = total_RonO(channel)+1;
                                    ripples_on_oscillations_array{channel,total_RonO(channel)} =sorted_hfos_test.ripples_on_oscillations;
                                    RonO_index_array{channel,total_RonO(channel)} =  sorted_hfos_test.RonO_index;
                                    
                                    % Followed by a function (RonO_types1006) that classifies ripples on oscillations as
                                    % spindle-ripples, theta-ripples, delta-ripples, and
                                    % slow wave-ripples
                                    
                                    [t_RonO] = RonO_types1006(sorted_hfos_test, t_epoch_theta, t_epoch_delta, t_epoch_spindle, t_epoch_slow, channel);
                                    
                                    if ~isempty(t_RonO.thetaR_epoch)
                                        counter_thetaR(channel) = counter_thetaR(channel) + 1;
                                        % extract instantaneous phase of theta-ripple stream
                                        thetaR_phase{channel,counter_thetaR(channel)} = ueeg.phaseTheta(start:j);
                                        zamp_thetaR{channel,counter_thetaR(channel)}=zscore.ampHFO(start:j);
                                        thetaR_1secRipple{channel,counter_thetaR(channel)} = eeg(channel, temp_array_spike);
                                        
                                        if channel == foundchannel1
                                            annotation_counter = annotation_counter+1;
                                            annotation{1,annotation_counter} = 'tR';
                                            annotation_time(annotation_counter) = t_RonO.thetaR_epoch(1)/samplingrate;
                                            annotation_duration(annotation_counter) = 0.1;
                                            %                                             annotation_counter = annotation_counter+1;
                                            %                                             annotation{1,annotation_counter} = 'trE';
                                            %                                             annotation_time(annotation_counter) = t_RonO.thetaR_epoch(end)/samplingrate;
                                            %                                             annotation_duration(annotation_counter) = 0.1;
                                        end;
                                        
                                    end
                                    
                                    if ~isempty(t_RonO.deltaR_epoch)
                                        counter_deltaR(channel) = counter_deltaR(channel) + 1;
                                        % extract instantaneous phase of delta-ripple stream
                                        deltaR_phase{channel,counter_deltaR(channel)} = ueeg.phaseDelta(start:j);
                                        zamp_deltaR{channel,counter_deltaR(channel)}=zscore.ampHFO(start:j);
                                        deltaR_1secRipple{channel,counter_deltaR(channel)} = eeg(channel, temp_array_spike);
                                        
                                        if channel == foundchannel1
                                            annotation_counter = annotation_counter+1;
                                            annotation{1,annotation_counter} = 'dR';
                                            annotation_time(annotation_counter) = t_RonO.deltaR_epoch(1)/samplingrate;
                                            annotation_duration(annotation_counter) = 0.1;
                                            %                                             annotation_counter = annotation_counter+1;
                                            %                                             annotation{1,annotation_counter} = 'drE';
                                            %                                             annotation_time(annotation_counter) = t_RonO.deltaR_epoch(end)/samplingrate;
                                            %                                             annotation_duration(annotation_counter) = 0.1;
                                        end;
                                        
                                    end
                                    
                                    if ~isempty(t_RonO.spindleR_epoch)
                                        counter_spindleR(channel) = counter_spindleR(channel) + 1;
                                        % extract instantaneous phase of spindle-ripple stream
                                        spindleR_phase{channel,counter_spindleR(channel)} = ueeg.phaseSpindle(start:j);
                                        zamp_spindleR{channel,counter_spindleR(channel)}=zscore.ampHFO(start:j);
                                        spindleR_1secRipple{channel,counter_spindleR(channel)} = eeg(channel, temp_array_spike);
                                        
                                        if channel == foundchannel1
                                            annotation_counter = annotation_counter+1;
                                            annotation{1,annotation_counter} = 'pR';
                                            annotation_time(annotation_counter) = t_RonO.spindleR_epoch(1)/samplingrate;
                                            annotation_duration(annotation_counter) = 0.1;
                                            %                                             annotation_counter = annotation_counter+1;
                                            %                                             annotation{1,annotation_counter} = 'prE';
                                            %                                             annotation_time(annotation_counter) = t_RonO.spindleR_epoch(end)/samplingrate;
                                            %                                             annotation_duration(annotation_counter) = 0.1;
                                        end;
                                        
                                    end
                                    
                                    if ~isempty(t_RonO.slowR_epoch)
                                        counter_slowR(channel) = counter_slowR(channel) + 1;
                                        % extract instantaneous phase of slow wave-ripple stream
                                        slowR_phase{channel,counter_slowR(channel)} = ueeg.phaseSlow(start:j);
                                        zamp_slowR{channel,counter_slowR(channel)}=zscore.ampHFO(start:j);
                                        slowR_1secRipple{channel,counter_slowR(channel)} = eeg(channel, temp_array_spike);
                                        
                                        if channel == foundchannel1
                                            annotation_counter = annotation_counter +1;
                                            annotation{1,annotation_counter} = 'sR';
                                            annotation_time(annotation_counter) = t_RonO.slowR_epoch(1)/samplingrate;
                                            annotation_duration(annotation_counter) = 0.1;
                                            %                                             annotation_counter = annotation_counter +1;
                                            %                                             annotation{1,annotation_counter} = 'srE';
                                            %                                             annotation_time(annotation_counter) = t_RonO.slowR_epoch(end)/samplingrate;
                                            %                                             annotation_duration(annotation_counter) = 0.1;
                                        end;
                                        
                                    end
                                    
                                end
                            end;
                        end;
                    end;
                end;
                
                flagged=0;
                
            end;
        end;
        
        ueeg.bpHFO=[];
        ueeg.hilbertHFO=[];
        ueeg.ampHFO=[];
        
        if channel == foundchannel1
            data{1,1} = eeg(channel,:);
            data = data';
            header.labels={'1' 'EDF Annotations'};
            header.samplerate=round(samplingrate);
            header.annotation.event=annotation;
            header.annotation.starttime=annotation_time;
            header.annotation.duration=annotation_duration;
            filename1 = ['rippletypes(rev)_451_channel_', channel1,'.edf'];
            SaveEDF(filename1,data,header);
        end
        
    end;
    
    ueeg.hilbertLEEG = [];
    sorted_hfos_test = [];
    t_RonO = [];
    
    datablock=datablock+1;
    
end;

% output the stored discrete HFOs, shorten the name of the output structure

output.channelinfo=channelinfo;
output.samplingrate=samplingrate;

output.events_uv=events_uv;
output.events_zampHFO=events_zampHFO; %regardless of ripple types
output.events_freq=events_frequency;

output.hfo_mean=hfo_mean;
output.hfo_std=hfo_std;
output.ripple_array = ripple_array;

output.t_epoch.ripple = epoch_ripple; %only brief ripple event
output.t_epoch.hfo4spike = epoch_hfo4spike; %500ms before and after spike-ripple event
output.t_epoch.hfo4spw = epoch_hfo4spw; %150ms before and after sharp wave-ripple event
output.R_types_array = R_types_array; %spike-ripple, sharp wave-ripple, or ripples on oscillations

output.ripples_on_spikes=ripples_on_spikes_array;
output.ripples_on_sharp_wave=ripples_on_sharp_waves_array;
output.ripples_on_oscillations=ripples_on_oscillations_array;

output.RonS_index = RonS_index_array;
output.RSpW_index = RSpW_index_array;
output.RonO_index = RonO_index_array;

output.total_RonS = total_RonS;
output.total_RSpW = total_RSpW;
output.total_RonO = total_RonO;

%% numbers of each distinct ripple type
output.total_hfo=total_hfo; %total number of hfo events
output.counter_true_spikeR = counter_true_spikeR;
output.counter_false_spikeR = counter_false_spikeR;
output.counter_true_spwR = counter_true_spwR;
output.counter_false_spwR = counter_false_spwR;
output.counter_thetaR = counter_thetaR;
output.counter_deltaR = counter_deltaR;
output.counter_spindleR = counter_spindleR;
output.counter_slowR = counter_slowR;

%% phase of distinct ripple types
output.true_RonS_phase = true_RonS_phase;
output.false_RonS_phase = false_RonS_phase;
output.true_spwR_phase = true_spwR_phase;
output.false_spwR_phase = false_spwR_phase;
output.thetaR_phase = thetaR_phase;
output.deltaR_phase = deltaR_phase;
output.spindleR_phase = spindleR_phase;
output.slowR_phase = slowR_phase;

%% z-score ripple amplitudes of distinct ripple-associated events
output.zamp_true_spikeR = zamp_true_spikeR;
output.zamp_false_spikeR = zamp_false_spikeR;
output.zamp_true_spwR = zamp_true_spwR;
output.zamp_false_spwR = zamp_false_spwR;
output.zamp_thetaR = zamp_thetaR;
output.zamp_deltaR = zamp_deltaR;
output.zamp_spindleR = zamp_spindleR;
output.zamp_slowR = zamp_slowR;

%% raw iEEG data during 1 sec HFO duration of each ripple type event (500ms before and after each distinct ripple event)
output.true_spikeR_1secRipple = true_spikeR_1secRipple; % true spike-ripple event
output.false_spikeR_1secRipple = false_spikeR_1secRipple; % false spike-ripple event
output.true_spwR_1secRipple = true_spwR_1secRipple; % true sharp wave-ripple event
output.false_spwR_1secRipple = false_spwR_1secRipple; % false sharp wave-ripple event
output.thetaR_1secRipple = thetaR_1secRipple; % theta-ripple event
output.deltaR_1secRipple = deltaR_1secRipple; % delta-ripple event
output.spindleR_1secRipple = spindleR_1secRipple; % spindle-ripple event
output.slowR_1secRipple = slowR_1secRipple; % slow wave-ripple event

save(fileout,'output', 'header', '-v7.3');


