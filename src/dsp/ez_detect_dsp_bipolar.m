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

error_status=0;
error_msg='';

file_block=metadata.file_block;

if ~isempty(eeg_bp)
    % v7 modification now using neural networks this code is obsolete.
    
    % eeg_bp_ds=[];
    %   for i=1:numel(eeg_bp(:,1))
    %         eeg_bp_ds.eeg_data(i,:)=downsample(eeg_bp(i,:),10);
    %   end;
    % [R,P,RL,RU] = corrcoef(eeg_bp_ds.eeg_data');
    % CC=abs(RL);
    % C=clustering_coef_wd(CC);
    % zC=zscore_2(C);
    % [a,b]=find(zC<-1);
    % meanCC=mean(CC)';
    % [c,d]=find(meanCC<0.03); % removes electrodes with lots of drift
    % [a,Ia,Ib] = intersect(a,c);
    % metadata.lf_bad_bp=metadata.bp_chanlist(a);
    % metadata.lf_bad_bp_index=a;
    % eeg_bp(metadata.lf_bad_bp_index,:)=[];
    % metadata.bp_chanlist(metadata.lf_bad_bp_index)=[];
    
    clear test MI C a b
    
    hfo=ez_eegfilter(eeg_bp,80,600,2000);
    ez_tall_bp=tall(eeg_bp);
    ez_tall_hfo_bp=tall(hfo);
    
    %% Notch filter eeg_data
    eeg_data_no_notch=eeg_bp;
    for i=1:length(eeg_bp(:,1));
        eeg_temp=eeg_bp(i,:);
        f0 = (2*(60/2000));
        df = .1;
        N = 30; % must be even for this trick
        h=remez(N,[0 f0-df/2 f0+df/2 1],[1 1 0 0]);
        h = 2*h - ((0:N)==(N/2));
        eeg_notch=filtfilt(h,1,eeg_temp);
        eeg_data(i,:)=eeg_notch;
    end;
    eeg_bp=[]; % From here on in use the eeg_data structure.
    
    clear f0 df N h eeg_notch eeg_temp eeg_mp eeg_bps
    
    % Start Ripple detection
    % Calculate smoothed HFO amplitude
    for i=1:numel(hfo(:,1));
        hilbert_hfo_amp=abs(hilbert(hfo(i,:)));
        score_amp=hilbert_hfo_amp;
        smooth_length=40;
        score_amp_ripple(i,:)=smooth(score_amp,smooth_length,'loess');
        score_amp_ripple(i,:)=abs(score_amp_ripple(i,:));
        lambdahat = poissfit_2(score_amp_ripple(i,:));
        zscore_amp_ripple(i,:)=2*(sqrt(score_amp_ripple(i,:))-sqrt(lambdahat));
    end;
    clear hilbert_hfo_amp
    
    temp_skew=skewness(zscore_amp_ripple'); % v4 add skewness correction for initial ripple detection to improve sensitivity.
    z_skew=zscore_2(temp_skew);
    thresh_z=[];
    thresh_zoff=[];
    for i=1:numel(hfo(:,1))
        if z_skew(i)>3
            thresh_z(i)=1;
            thresh_zoff(i)=0.2;
        else
            if z_skew(i)>2.5
                thresh_z(i)=1.2;
                thresh_zoff(i)=0.3;
            else
                if z_skew(i)>2
                    thresh_z(i)=1.4;
                    thresh_zoff(i)=0.5;
                else
                    if z_skew(i)>1.5
                        thresh_z(i)=1.6;
                        thresh_zoff(i)=0.7;
                    else
                        thresh_z(i)=1.8;
                        thresh_zoff(i)=1;
                    end;
                end;
            end;
        end;
    end;
    
    clear hilbert_hfo_amp temp_skew z_skew
    fprintf('Done calculating baseline stats \r')
    
    % initialize data structures '2D array of cells' note that this structure can flexibly
    % store different length elements within each cell, and the number of cells can vary by
    % row. This structure may need to be revised to improve efficiency.
    ripple_clip=cell(numel(eeg_data(:,1)),1);
    ripple_clip_t=cell(numel(eeg_data(:,1)),1);
    ripple_clip_event_t=cell(numel(eeg_data(:,1)),1);
    ripple_clip_abs_t=cell(numel(eeg_data(:,1)),1);
    
    total_ripple=zeros(numel(eeg_data(:,1)),1);
    fprintf('Running Ripple Detection\r')
    datablock=0;
    eeg_index=1;
    
    while eeg_index < (numel(eeg_data(1,:))-(59.99*2000))
        ieeg_block=eeg_data(:,(eeg_index+1):(eeg_index+(2000*60)-1));
        zscore_block=zscore_amp_ripple(:,(eeg_index+1):(eeg_index+(2000*60)-1));
        amp_block=score_amp_ripple(:,(eeg_index+1):(eeg_index+(2000*60)-1));
        hfo_block=hfo(:,(eeg_index+1):(eeg_index+(2000*60)-1));
        ai_block=hfo_ai((eeg_index+1):(eeg_index+(2000*60)-1));
        eeg_index=eeg_index+(2000*60)-1;
        eeg_index/2000
        for channel=1:numel(eeg_data(:,1))
            
            % Define ic1,z_score amp traces from blocks.
            zscore_amp=zscore_block(channel,:);
            hfo_chan=hfo_block(channel,:);
            amp=amp_block(channel,:);
            
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
                A_boolean=zscore_amp(j)>thresh_z(channel); %V4 add skewness correction
                B_boolean=amp(j)>5.5;
                C_boolean=and(A_boolean,B_boolean);
                if ((flagged==0) && (C_boolean==1)) % Optimization factor #1
                    flagged=1;
                    start=j;
                end;
                if ((flagged==1) && (zscore_amp(j)>thresh_zoff(channel))) end; % Optimization factor #2
                if ((flagged==1) && (zscore_amp(j)<thresh_zoff(channel)))
                    
                    if  ((j-start)*(1/2000)) > 0.008
                        % to determine if HFO is valid the first step is calculating
                        % its frequency at the peak of its psd.
                        
                        nfft = 2^nextpow2(length(hfo_chan(start:j)));
                        Pxx = abs(fft(hfo_chan(start:j),nfft)).^2/length(hfo_chan(start:j))/2000;
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
                                    if ai_block(k)>0.1 % V4 changed to 0.1 only exclude large artifact.
                                        artifact=1;
                                    end;
                                end;
                                if artifact==0
                                    total_ripple(channel)=total_ripple(channel)+1;
                                    if start-1100 < 1                        % v3 adust -0.25 seconds for asymmetric filtering
                                        clip_start=1;
                                    else
                                        clip_start=start-1100;
                                    end;
                                    if j+100 > numel(ieeg_block(1,:))       % v3 adust -0.25 seconds for asymmetric filtering
                                        clip_end=numel(ieeg_block(1,:));
                                    else
                                        clip_end=j+100;
                                    end;
                                    ripple_clip{channel,total_ripple(channel)}=ieeg_block(channel,(clip_start):(clip_end)); % v3 adjust for asymmetric filtering
                                    ripple_clip_t{channel,total_ripple(channel)}=[((start/2000)+(datablock*60)-.0035) ((j/2000)+(datablock*60))]; %v3 adjust for asymmetric filtering
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
    
    clear A_boolean a_value ai_block amp amp_block artifact b_boolean b_ind C_boolean chan_block_str channel clip_end clip_start counter2 datablock duration_cutoff eeg_index HFO_frequency hilbert_hfo_amp ic1_block ic1_chan i j k lambdahat nfft p Pxx q ref score_amp zscore_amp_ripple zscore_block
    
    % Create ripple index
    hfo_times=cell(numel(eeg_data(:,1)),1);
    hfo_values=cell(numel(eeg_data(:,1)),1);
    for i=1:numel(ripple_clip_t(:,1))
        % convert ripple clips from time to indices
        ripple_concat=[];
        ripple_val_concat=[];
        for j=1:total_ripple(i)
            ripple_time_s=(int32(ripple_clip_t{i,j}(1)*2000));
            ripple_time_e=(int32(ripple_clip_t{i,j}(2)*2000));
            ripple_time=ripple_time_s:ripple_time_e;
            ripple_concat=horzcat(ripple_concat, ripple_time);
            ripple_val_concat=horzcat(ripple_val_concat, hfo(i,ripple_time)); %v4 modification calculate ripple values
        end;
        if total_ripple(i)>0
            hfo_times{i,:}=ripple_concat;
            hfo_values{i,:}=ripple_val_concat;
        end;
    end;
    clear ripple_time_s ripple_time_e ripple_time ripple_concat
    
    % v7 MODIFICATION: this new section removes bad channels based on a trained
    % neural network
    
    samples=[];
    rms_calc=[];
    std_calc=[];
    entropy_calc=[];
    slope_calc=[];
    hilbert_calc=[];
    lookup_vector=[];
    counter=0;
    nulls=[];
    fprintf('detecting additional bad electrodes using neural network\r');
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
        end;
    end;

    if counter > 0
        test_vector=[samples' rms_calc' std_calc' entropy_calc' slope_calc' hilbert_calc'];
        Y=ripple_nn(test_vector);
        [a,b]=find(Y>0.282)
        b=lookup_vector(a);
    else
        b=[];
    end;

    
    if numel(b)~=numel(metadata.bp_chanlist)
        % Remove all data for bad channel
        if ~isempty(b)
            eeg_bp=gather(ez_tall_bp);
            eeg_bp(b,:)=[];
            eeg_data(b,:)=[];
            eeg_data_no_notch(b,:)=[];
            hfo(b,:)=[];
            ez_tall_bp=tall(eeg_bp);
            ez_tall_hfo_bp=tall(hfo);
            total_ripple(b)=[];
            ripple_clip(b,:)=[];
            ripple_clip_t(b,:)=[];
            ripple_clip_event_t(b,:)=[];
            ripple_clip_abs_t(b,:)=[];
            
            metadata.hf_bad_bp=metadata.bp_chanlist(b);
            metadata.hf_bad_bp_index=b;
            metadata.bp_chanlist(metadata.hf_bad_bp_index)=[];
        end;
    else
        error_status=1;
        error_msg='all noisy bp electrodes';
    end;
    
    fr=ez_eegfilter(eeg_data_no_notch,200,600,2000);
    
    %% Calculate baseline FR stats
    for i=1:numel(fr(:,1));
        hilbert_hfo_amp=abs(hilbert(fr(i,:)));
        score_amp=hilbert_hfo_amp;
        smooth_length=round((2000/2000)*40);
        score_amp_fripple(i,:)=smooth(score_amp,smooth_length,'loess');
        zscore_amp_fripple(i,:)=zscore_2(score_amp_fripple(i,:));
    end;
    clear hilbert_hfo_amp;
    temp_skew=skewness(zscore_amp_fripple'); % v4 add skewness correction for initial ripple detection to improve sensitivity.
    z_skew=zscore_2(temp_skew);
    thresh_z=[];
    thresh_zoff=[];
    for i=1:numel(hfo(:,1))
        if z_skew(i)>3
            thresh_z(i)=1;
            thresh_zoff(i)=0.1;
        else
            if z_skew(i)>2.5
                thresh_z(i)=1.2;
                thresh_zoff(i)=0.3;
            else
                if z_skew(i)>2
                    thresh_z(i)=1.4;
                    thresh_zoff(i)=0.6;
                else
                    if z_skew(i)>1.5
                        thresh_z(i)=1.5;
                        thresh_zoff(i)=0.7;
                    else
                        thresh_z(i)=1.7;
                        thresh_zoff(i)=1;
                    end;
                end;
            end;
        end;
    end;
    
    clear temp_skew z_skew
    
    % initialize data structures '2D array of cells' note that this structure can flexibly
    % store different length elements within each cell, and the number of cells can vary by
    % row. This structure may need to be revised to improve efficiency.
    fripple_clip=cell(numel(eeg_data(:,1)),1);
    fripple_clip_t=cell(numel(eeg_data(:,1)),1);
    fripple_clip_event_t=cell(numel(eeg_data(:,1)),1);
    fripple_clip_abs_t=cell(numel(eeg_data(:,1)),1);
    
    total_fripple=zeros(numel(eeg_data(:,1)),1);
    fprintf('Running Fast Ripple Detection \r')
    datablock=0;
    eeg_index=1;
    while eeg_index < (numel(eeg_data(1,:))-(59.9*2000))
        ieeg_block=eeg_data(:,(eeg_index+1):(eeg_index+(2000*60)-1));
        amp_block=score_amp_fripple(:,(eeg_index+1):(eeg_index+(2000*60)-1));
        zscore_block=zscore_amp_fripple(:,(eeg_index+1):(eeg_index+(2000*60)-1));
        ai_block=fr_ai((eeg_index+1):(eeg_index+(2000*60)-1));
        eeg_index=eeg_index+(2000*60)-1;
        eeg_index/2000
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
                A_boolean=zscore_amp(j)>thresh_z(channel);
                B_boolean=amp(j)>5.5;
                C_boolean=and(A_boolean,B_boolean);
                if ((flagged==0) && (C_boolean==1))
                    flagged=1;
                    start=j;
                end;
                if ((flagged==1) && (zscore_amp(j)>thresh_zoff(channel))) end;
                if ((flagged==1) && (zscore_amp(j)<thresh_zoff(channel)))
                    
                    if  ((j-start)*(1/2000)) > 0.006
                        
                        %if the HFO duration exceeds the duration cutoff save the raw HFO accompanying
                        %the event, the instantaneous phase of the eeg at the time of the event, the
                        %unfiltered signal at the time of the event, and the Z-scored HFO stream at the
                        %time of the event.
                        if ((j-start)*(1/2000)) < 0.5; % Is the HFO less than half a second i.e. not artifact
                            artifact=0;
                            for k=start:j % Look up artifact index to determine if HFO is artefactual.
                                if ai_block(k)>0.1 % V4 changed to 0.1 only remove very large artifact.
                                    artifact=1;
                                end;
                            end;
                            
                            total_fripple(channel)=total_fripple(channel)+1;
                            chan_block_ann=ceil(channel/32);
                            
                            if start-1100 < 1    % v3 adust -0.25 seconds for asymmetric filtering
                                clip_start=1;
                            else
                                clip_start=start-1100;
                            end;
                            
                            if j+100 > numel(ieeg_block(1,:))   % v3 adust -0.25 seconds for asymmetric filtering
                                clip_end=numel(ieeg_block(1,:));
                            else
                                clip_end=j+100;
                            end;
                            
                            fripple_clip{channel,total_fripple(channel)}=ieeg_block(channel,(clip_start):(clip_end));
                            fripple_clip_t{channel,total_fripple(channel)}=[((start/2000)+(datablock*60)-.0035) ((j/2000)+(datablock*60))]; % v3 adjust
                            fripple_clip_event_t{channel, total_fripple(channel)}=[((clip_start/2000)+(datablock*60))-500 ((clip_end/2000)+(datablock*60))-500];
                            fripple_clip_abs_t{channel, total_fripple(channel)}=[((clip_start/2000)+(datablock*60)) ((clip_end/2000)+(datablock*60))];
                        end;
                    end;
                    flagged=0;
                end;
            end;
        end;
    end;
    
    datablock=datablock+1;
end;

% Create ripple index
hfo_times=cell(numel(eeg_data(:,1)),1);
hfo_values=cell(numel(eeg_data(:,1)),1);
for i=1:numel(ripple_clip_t(:,1))
    % convert ripple clips from time to indices
    fripple_concat=[];
    fripple_val_concat=[];
    for j=1:total_fripple(i)
        fripple_time_s=(int32(fripple_clip_t{i,j}(1)*2000));
        fripple_time_e=(int32(fripple_clip_t{i,j}(2)*2000));
        fripple_time=fripple_time_s:fripple_time_e;
        fripple_concat=horzcat(fripple_concat, fripple_time);
        fripple_val_concat=horzcat(fripple_val_concat, hfo(i,fripple_time)); %v4 modification calculate ripple values
    end;
    if total_ripple(i)>0
        hfo_times{i,:}=fripple_concat;
        hfo_values{i,:}=fripple_val_concat;
    end;
end;
clear ripple_time_s ripple_time_e ripple_time ripple_concat

% v7 MODIFICATION: this new section removes bad channels based on a trained
% neural network

samples=[];
rms_calc=[];
std_calc=[];
entropy_calc=[];
slope_calc=[];
hilbert_calc=[];
lookup_vector=[];
test_vector=[];
counter=0;
nulls=[];
fprintf('detecting additional bad electrodes using neural network\r');
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
    end;
end;

if counter > 0
    test_vector=[samples' rms_calc' std_calc' entropy_calc' slope_calc' hilbert_calc'];
    disp(test_vector);
    disp(size(test_vector));
    Y=fripple_nn(test_vector);
    [a,b]=find(Y>0.63)
    b=lookup_vector(a);
else
    b=[];
end;


if numel(b)~=numel(metadata.bp_chanlist)
    % Remove all data for bad channel
    if ~isempty(b)
        eeg_bp=gather(ez_tall_bp);
        eeg_bp(b,:)=[];
        eeg_data(b,:)=[];
        eeg_data_no_notch(b,:)=[];
        hfo(b,:)=[];
        fr(b,:)=[];
        ez_tall_bp=tall(eeg_bp);
        ez_tall_hfo_bp=tall(hfo);
        ez_tall_fr_bp=tall(fr);
        total_ripple(b)=[];
        total_fripple(b)=[];
        ripple_clip(b,:)=[];
        fripple_clip(b,:)=[];
        ripple_clip_t(b,:)=[];
        fripple_clip_t(b,:)=[];
        ripple_clip_event_t(b,:)=[];
        fripple_clip_event_t(b,:)=[];
        ripple_clip_abs_t(b,:)=[];
        fripple_clip_abs_t(b,:)=[];
        
        metadata.hf_bad_bp_fr=metadata.bp_chanlist(b);
        metadata.hf_bad_bp_index_fr=b;
        metadata.bp_chanlist(metadata.hf_bad_bp_index_fr)=[];
    else
        ez_tall_fr_bp=tall(fr);
    end;
else
    error_status=1;
    error_msg='all noisy bp electrodes';
end;

eeg_bp=gather(ez_tall_bp);
if ~isempty(eeg_bp)
    % Write TRC files
    % % Bug fix for empty cells
    emptyCells = cellfun(@isempty,metadata.bp_chanlist);
    [a,b]=find(emptyCells==1);
    metadata.bp_chanlist(b)=[];  %Removed empty channels
    
    % % Write TRC files
    % % The function first outputs the 32 channel .TRC files for the annotations
    % % from the input iEEG file.
    fprintf('writing monopolar iEEG to trc format \r');
    fprintf('converting data to 2048 Hz sampling rate \r');
    % % The first step is to convert the sampling rate to 2048 Hz
    temp=[];
    temp2=[];
    [p,q]=rat(2048/2000)
    for j=1:numel(eeg_bp(:,1))
        x=eeg_bp(j,:);
        temp=resample(x,p,q);
        temp2(j,:)=temp;
    end;
    TRC.data=temp2;
    TRC.chanlist=metadata.bp_chanlist;
    temp2=[];
    temp=[];
    
    clear x temp2 temp
    
    file_id=metadata.file_id;
    
    % Clear the temporary .mat files
    system(['rm -f /home/tomas-pastore/hfo_engine_1/bp_temp_trc/eeg_2k_a_' file_block '.mat']);
    system(['rm -f /home/tomas-pastore/hfo_engine_1/bp_temp_trc/eeg_2k_b_' file_block '.mat']);
    system(['rm -f /home/tomas-pastore/hfo_engine_1/bp_temp_trc/eeg_2k_c_' file_block '.mat']);
    system(['rm -f /home/tomas-pastore/hfo_engine_1/bp_temp_trc/eeg_2k_d_' file_block '.mat']);
    system(['rm -f /home/tomas-pastore/hfo_engine_1/bp_temp_trc/eeg_2k_e_' file_block '.mat']);
    system(['rm -f /home/tomas-pastore/hfo_engine_1/bp_temp_trc/eeg_2k_f_' file_block '.mat']);
    system(['rm -f /home/tomas-pastore/hfo_engine_1/bp_temp_trc/eeg_2k_g_' file_block '.mat']);
    
    % The next step is to write the TRC file blocks
    num_trc_blocks=ceil(numel(metadata.bp_chanlist)/32);
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
            save(['/home/tomas-pastore/hfo_engine_1/bp_temp_trc/eeg_2k_a_' file_block '.mat'],'eeg');
            system_command=['/home/tomas-pastore/hfo_engine_1/executable/mat2trc32_bp2k_a' ' ' file_id ' ' file_block ' &'];
            system(system_command);
            fprintf('writing .TRC file #1 in background \r');
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
            save(['/home/tomas-pastore/hfo_engine_1/bp_temp_trc/eeg_2k_b_' file_block '.mat'],'eeg');
            system_command=['/home/tomas-pastore/hfo_engine_1/executable/mat2trc32_bp2k_b' ' ' file_id ' ' file_block ' &'];
            system(system_command);
            fprintf('writing .TRC file #2 in background \r');
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
            save(['/home/tomas-pastore/hfo_engine_1/bp_temp_trc/eeg_2k_c_' file_block '.mat'],'eeg');
            system_command=['/home/tomas-pastore/hfo_engine_1/executable/mat2trc32_bp2k_c' ' ' file_id ' ' file_block ' &'];
            system(system_command);
            fprintf('writing .TRC file #3 in background \r');
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
            save(['/home/tomas-pastore/hfo_engine_1/bp_temp_trc/eeg_2k_d_' file_block '.mat'],'eeg');
            system_command=['/home/tomas-pastore/hfo_engine_1/executable/mat2trc32_bp2k_d' ' ' file_id ' ' file_block ' &'];
            system(system_command);
            fprintf('writing .TRC file #4 in background \r');
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
            save(['/home/tomas-pastore/hfo_engine_1/bp_temp_trc/eeg_2k_e_' file_block '.mat'],'eeg');
            system_command=['/home/tomas-pastore/hfo_engine_1/executable/mat2trc32_bp2k_e' ' ' file_id ' ' file_block ' &'];
            system(system_command);
            fprintf('writing .TRC file #5 in background \r');
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
            save(['/home/tomas-pastore/hfo_engine_1/bp_temp_trc/eeg_2k_f_' file_block '.mat'],'eeg');
            system_command=['/home/tomas-pastore/hfo_engine_1/executable/mat2trc32_bp2k_f' ' ' file_id ' ' file_block ' &'];
            system(system_command);
            fprintf('writing .TRC file #6 in background \r');
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
            save(['/home/tomas-pastore/hfo_engine_1/bp_temp_trc/eeg_2k_g_' file_block '.mat'],'eeg');
            system_command=['/home/tomas-pastore/hfo_engine_1/executable/mat2trc32_bp2k_g' ' ' file_id ' ' file_block ' &'];
            system(system_command);
            fprintf('writing .TRC file #7 in background \r');
        end;
    end;
    clear eeg TRC max_trc_channels
    
    clear A_boolean a_value ai_block amp amp_block artifact b_boolean b_ind C_boolean chan_block_str channel clip_end clip_start counter2 datablock duration_cutoff eeg_index HFO_frequency hilbert_hfo_amp ic1_block ic1_chan i j k lambdahat nfft p Pxx q ref score_amp zscore_amp_ripple zscore_block
    
    % output the stored discrete HFOs
    DSP_data_bp.error_status=error_status;
    DSP_data_bp.error_msg=error_msg;
    DSP_data_bp.metadata=metadata;
    DSP_data_bp.file_block=file_block;
    DSP_data_bp.data_duration=numel(eeg_data(1,:))/2000;
    [a,b]=find(hfo_ai>0.1);
    artifact_duration=(numel(a)/2000);
    DSP_data_bp.r_clean_duration=DSP_data_bp.data_duration-artifact_duration;
    [a,b]=find(fr_ai>0.1);
    artifact_duration=(numel(a)/2000);
    DSP_data_bp.fr_clean_duration=DSP_data_bp.data_duration-artifact_duration;
    DSP_data_bp.total_ripple=total_ripple;
    DSP_data_bp.ripple_clip=ripple_clip;
    DSP_data_bp.ripple_clip_abs_t=ripple_clip_abs_t;
    DSP_data_bp.fripple_clip_abs_t=fripple_clip_abs_t;
    DSP_data_bp.ripple_clip_event_t=ripple_clip_event_t;
    DSP_data_bp.fripple_clip_event_t=fripple_clip_event_t;
    DSP_data_bp.total_fripple=total_fripple;
    DSP_data_bp.fripple_clip=fripple_clip;
    filename1=['dsp_' file_id '_bp_' file_block '.mat'];
    filename1=strcat(paths.ez_top_in,filename1);
    save(filename1,'DSP_data_bp','-v7.3');
else
    DSP_data_bp=[];
    ez_tall_bp=[];
    ez_tall_hfo_bp=[];
    ez_tall_fr_bp=[];
    filename1=['dsp_' file_id '_bp_' file_block '.mat'];
    filename1=strcat(paths.ez_top_in,filename1);
end; % if eeg_bp exists

dsp_bipolar_output = struct( ...
    'ez_bp', gather(ez_tall_bp), ...
    'ez_hfo_bp', gather(ez_tall_hfo_bp), ...
    'ez_fr_bp', gather(ez_tall_fr_bp), ...
    'metadata', metadata, ...
    'num_trc_blocks', num_trc_blocks, ...
    'path_to_data', filename1 ...
);
    
%%%fixing metadata montage dims
dsp_bipolar_output.metadata.montage_shape = [numel(dsp_bipolar_output.metadata.montage(:,1)),numel(dsp_bipolar_output.metadata.montage(1,:))];
dsp_bipolar_output.metadata.montage= reshape(dsp_bipolar_output.metadata.montage,1,[]); %matlab engine can only return 1*n cell arrays. I changed the data structure to get mlarray.

