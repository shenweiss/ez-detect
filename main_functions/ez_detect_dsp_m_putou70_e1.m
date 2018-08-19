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

function dsp_monopolar_output = ez_detect_dsp_m_putou_e1(ez_tall_m,ez_tall_bp,metadata,paths);

% hf_bad uses the HFO band pass filtered EEG mutual information
% adjacency matrix, and graph theory (community) during episodes of artifact to define dissimar
% electrodes. The bipolar montage is calculated for the dissimilar
% electrodes

file_block=metadata.file_block;

error_status=0;
error_msg='';

% v4 bug fix perform xcorr function prior to running hfbad in order to
% remove other 60 cycle artifact outliers prior to hfbad
eeg_data=gather(ez_tall_m);
fr=ez_eegfilter(eeg_data,200,600,2000);
fr_xcorr=[];
for i=1:numel(fr(:,1))
    temp_data=fr(i,:);
    temp_data_gpu=temp_data;
    [c,lags] = xcorr(temp_data_gpu);
    c=gather(c);
    [no,xo]=hist(c,1000);
    fr_xcorr(i)=sum(no(531:1000));
end;
zfr_xcorr=zscore_2(fr_xcorr);
[a,b]=find(zfr_xcorr>0.75);
[c,d]=find(fr_xcorr>10000); % changed from 50k in order to remove more 60 cycle channels.
b=intersect(b,d);
metadata.hf_xcorr_bad=b;
eeg_data(b,:)=[];
metadata.m_chanlist(b)=[];
ez_tall_m=tall(eeg_data);
clear eeg_data

fprintf('removing excess HF artifact electrodes \r');
[metadata]=ez_hfbad_putou02(ez_tall_m,metadata); % Find MI of maximum artifact

% Remove bad channels from monopolar montage
eeg_mp=gather(ez_tall_m);
eeg_bps=gather(ez_tall_bp);
metadata.hf_bad_m=metadata.m_chanlist(metadata.hf_bad_m_index);
new_eeg_bp=[];
new_bp_chans={''};
counter=0;
for i=1:numel(metadata.hf_bad_m_index)
    % locate bp channel (possibly not found)
    [C,IA,IB]=intersect(metadata.hf_bad_m(i),metadata.montage(:,1));
    if ~isempty(C)
        ref=cell2mat(metadata.montage(IB,3));
        if ref~=0
            [C2,IIA,IIB]=intersect(metadata.montage(ref,1),metadata.m_chanlist);
            if ~isempty(C2)
                counter=counter+1;
                new_eeg_bp(counter,:)=eeg_mp(metadata.hf_bad_m_index(i),:)-eeg_mp(IIB,:);
                new_bp_chans(counter)=metadata.hf_bad_m(i);
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

clear eeg_bps new_eeg_bp

% remove bipolar recordings from memory
eeg_mp(metadata.hf_bad_m_index,:)=[];
metadata.m_chanlist(metadata.hf_bad_m_index)=[];
ez_tall_m=tall(eeg_mp);

% Bug fix for empty cells
emptyCells = cellfun(@isempty,metadata.m_chanlist);
[a,b]=find(emptyCells==1);
metadata.m_chanlist(b)={'BUG'};

%% Notch filter eeg_data
eeg_data_no_notch=eeg_mp;
for i=1:length(eeg_mp(:,1));
    eeg_temp=eeg_mp(i,:);
    f0 = (2*(60/2000));
    df = .1;
    N = 30; % must be even for this trick
    h=remez(N,[0 f0-df/2 f0+df/2 1],[1 1 0 0]);
    h = 2*h - ((0:N)==(N/2));
    eeg_notch=filtfilt(h,1,eeg_temp);
    eeg_data(i,:)=eeg_notch;
end;
eeg_mp=[]; % From here on in use the eeg_data structure.

clear f0 df N h eeg_notch eeg_temp eeg_mp eeg_bps

% cudaica_matlab function isolates muscle artifact producing artifactual
% HFOs to the first independent component of the HFO band pass filtered
% EEG. The first independent component is removed to reduce artifact, and
% IC1 is also used to refine the artifact index on a millisecond time
% scale.

[hfo, ic1, EEG, error_flag]=ez_cudaica_ripple_putou_e1(eeg_data_no_notch,2000, paths);
if error_flag==0 % error flag 1
    ez_tall_hfo_m=tall(hfo);
    
    % The code below is used to detect overstripped recordings
    % following pruning of IC1.
    fprintf('compensating for overstripping ripple ica \r');
    lost_peaks=[];
    delta_amp_peak=zeros(numel(hfo(:,1)),1);
    for j=1:numel(hfo(:,1))
        [peaks] = find_inflections(hfo(j,:),'maxima');
        event_peaks_hfo=[];
        counter=0;
        for i=1:numel(peaks)
            if hfo(j,peaks(i))>7
                counter=counter+1;
                event_peaks_hfo(counter)=peaks(i);
                temp_delta=hfo(j,peaks(i))-ic1(j,peaks(i));
                delta_amp_peak(j)=delta_amp_peak(j)+temp_delta;
            end;
        end;
        [peaks] = find_inflections(ic1(j,:),'maxima');
        event_peaks_ic1=[];
        counter2=0;
        for i=1:numel(peaks)
            if ic1(j,peaks(i))>7
                counter2=counter2+1;
                event_peaks_ic1(counter2)=peaks(i);
            end;
        end;
        lost_peaks(j)=numel(event_peaks_hfo)-numel(event_peaks_ic1);
    end;
    z_delta_amp_peak=zscore_2(delta_amp_peak);
    lost_peaks=lost_peaks-min(lost_peaks);
    lambdahat=poissfit_2(lost_peaks);
    z_lost_peaks=2*(sqrt(lost_peaks)-sqrt(lambdahat));
    
    clear event_peaks_hfo event_peaks_ic1 z_delta_amp_peak lost_peaks delta_amp_peak peaks
    
    % The artifact index is used to define epochs of muscle and electrode
    % artifact it is used to reject HFO detections in both the referential
    % and bipolar montages.
    
    fprintf('Calculating artifact index \r')
    ai=zeros(numel(hfo(:,1)),numel(hfo(1,:))); % corrected for intra-op data usually remove.
    artifact_segments=[]; % corrected for intra-op data usually remove.
    for i=1:numel(hfo(:,1));
        ai_baseline_correct=mean(abs(hfo(i,:)));
        for j=1:numel(hfo(1,:))
            scale_factor=1;
            if abs(ic1(i,j))>10
                scale_factor=(abs(ic1(i,j))/10)*1;
            end;
            if ai(i,j)<10
                ai(i,j)=(abs(hfo(i,j)-ic1(i,j))/scale_factor)/ai_baseline_correct;
            end;
        end;
    end;
    ai_mean=mean(ai);
    for i=1:numel(hfo(:,1));
        for j=1:numel(hfo(1,:));
            ai(i,j)=(ai(i,j)*ai_mean(j));
        end;
        ai(i,:)=smooth(ai(i,:),1200,'lowess');
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
    ai=max(ai);
    fprintf('Done calculating artifact index \r')
    hfo_ai=ai;
    
    clear temp temp2 temp3 temp4 temp5 a b c d scale_factor ai_baseline_correct ai_mean
    
    % compensate for overstripping in HFO IC1
    nan_ica=zeros(numel(hfo(:,1)),1);   % you will need to take this out for completed EZ detect
    for i=1:numel(hfo(:,1))
        if z_lost_peaks(i)>15
            nan_ica(i)=1;
        end;
    end;
    
    % Start Ripple detection
    % Calculate smoothed HFO amplitude
    for i=1:numel(hfo(:,1));
        if nan_ica(i)==1
            hilbert_hfo_amp=abs(hilbert(hfo(i,:)));
        else
            hilbert_hfo_amp=abs(hilbert(ic1(i,:)));
        end;
        score_amp=hilbert_hfo_amp;
        smooth_length=40;
        score_amp_ripple(i,:)=smooth(score_amp,smooth_length,'loess');
        score_amp_ripple(i,:)=abs(score_amp_ripple(i,:));
        lambdahat = poissfit_2(score_amp_ripple(i,:));
        zscore_amp_ripple(i,:)=2*(sqrt(score_amp_ripple(i,:))-sqrt(lambdahat));
        if nan_ica(i)==1
            zscore_amp_ripple(i,:)=zscore_amp_ripple(i,:)+0.75;
        end;
    end;
    
    temp_skew=skewness(zscore_amp_ripple'); % v4 add skewness correction for initial ripple detection to improve sensitivity.
    z_skew=zscore_2(temp_skew);
    thresh_z=[];
    thresh_zoff=[];
    for i=1:numel(metadata.m_chanlist)
        if z_skew(i)>3
            thresh_z(i)=1.1;
            thresh_zoff(i)=0.2;
        else
            if z_skew(i)>2.5
                thresh_z(i)=1.3;
                thresh_zoff(i)=0.4;
            else
                if z_skew(i)>2
                    thresh_z(i)=1.5;
                    thresh_zoff(i)=0.6;
                else
                    if z_skew(i)>1.5
                        thresh_z(i)=1.7;
                        thresh_zoff(i)=0.8;
                    else
                        thresh_z(i)=1.9;
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
    ripple_clip=cell(numel(eeg_data(:,1)),1);;
    ripple_clip_t=cell(numel(eeg_data(:,1)),1);;
    ripple_clip_event_t=cell(numel(eeg_data(:,1)),1);;
    ripple_clip_abs_t=cell(numel(eeg_data(:,1)),1);;
    
    total_ripple=zeros(numel(eeg_data(:,1)),1);
    fprintf('Running Ripple Detection\r')
    datablock=0;
    
    eeg_index=1;
    while eeg_index < (numel(eeg_data(1,:))-(59.99*2000))
        ieeg_block=eeg_data(:,(eeg_index+1):(eeg_index+(2000*60)-1));
        zscore_block=zscore_amp_ripple(:,(eeg_index+1):(eeg_index+(2000*60)-1));
        amp_block=score_amp_ripple(:,(eeg_index+1):(eeg_index+(2000*60)-1));
        ic1_block=ic1(:,(eeg_index+1):(eeg_index+(2000*60)-1));
        ai_block=ai((eeg_index+1):(eeg_index+(2000*60)-1));
        eeg_index=eeg_index+(2000*60)-1;
        eeg_index/2000
        for channel=1:numel(eeg_data(:,1))
            
            % Define ic1,z_score amp traces from blocks.
            zscore_amp=zscore_block(channel,:);
            ic1_chan=ic1_block(channel,:);
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
                A_boolean=zscore_amp(j)>thresh_z(channel); % v4 with skewness adjustment
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
    
    clear A_boolean a_value ai_block amp amp_block artifact b_boolean b_ind C_boolean chan_block_str channel clip_end clip_start counter2 datablock duration_cutoff eeg_index HFO_frequency hilbert_hfo_amp ic1_block ic1_chan i j k lambdahat nfft p Pxx q ref score_amp zscore_amp_ripple zscore_block
    
    ripple_ic_clip=cell(numel(eeg_data(:,1)),1);;
    ripple_ic_clip_t=cell(numel(eeg_data(:,1)),1);;
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
            ripple_val_concat=horzcat(ripple_val_concat, ic1(i,ripple_time)); %v4 modification calculate ripple values
        end;
        if total_ripple(i)>0
            hfo_times{i,:}=ripple_concat;
            hfo_values{i,:}=ripple_val_concat;
        end;
    end;
    clear ripple_time_s ripple_time_e ripple_time ripple_concat
    
    % v7 MODIFICATION: this new section removes bad channels based on a trained
    % neural network
    
    lookup_vector=[];
    nulls=[];
    counter=0;
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
        Y=fripple_nn(test_vector);  %% the fast ripple neural network was also utilized because of a higher likelihood of excluding bad channels prior to ICA
        [a,b]=find(Y>0.4)
        b=lookup_vector(a);
        Y2=ripple_nn(test_vector);
        [c,d]=find(Y2>0.282)
        b2=lookup_vector(c);
        b=[b b2];
    else
        b=[];
    end;

    if numel(b)<numel(metadata.m_chanlist)-10 % if number of bad electrodes are not the vast majority
        if ~isempty(b)  % if bad electrodes detected
            fprintf('removing bad electrodes repeating calculations and detections \r');
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
            
            clear eeg_bps new_eeg_bp
            
            % remove bipolar recordings from memory
            eeg_mp(b,:)=[];
            metadata.m_chanlist(b)=[];
            ez_tall_m=tall(eeg_mp);
            
            % remove bad electrodes from eeg_data and eeg_data_no_notch
            eeg_data(b,:)=[];
            eeg_data_no_notch(b,:)=[];
            
            % Bug fix for empty cells
            emptyCells = cellfun(@isempty,metadata.m_chanlist);
            [a,b]=find(emptyCells==1);
            metadata.m_chanlist(b)={'BUG'};
            
            % repeat ICA
            [hfo, ic1, EEG, error_flag]=ez_cudaica_ripple_putou_e1(eeg_data_no_notch,2000, paths);
            if error_flag == 0
                ez_tall_hfo_m=tall(hfo);
                
                % recalculate AI
                fprintf('compensating for overstripping ripple ica \r');
                lost_peaks=[];
                delta_amp_peak=zeros(numel(hfo(:,1)),1);
                for j=1:numel(hfo(:,1))
                    [peaks] = find_inflections(hfo(j,:),'maxima');
                    event_peaks_hfo=[];
                    counter=0;
                    for i=1:numel(peaks)
                        if hfo(j,peaks(i))>7
                            counter=counter+1;
                            event_peaks_hfo(counter)=peaks(i);
                            temp_delta=hfo(j,peaks(i))-ic1(j,peaks(i));
                            delta_amp_peak(j)=delta_amp_peak(j)+temp_delta;
                        end;
                    end;
                    [peaks] = find_inflections(ic1(j,:),'maxima');
                    event_peaks_ic1=[];
                    counter2=0;
                    for i=1:numel(peaks)
                        if ic1(j,peaks(i))>7
                            counter2=counter2+1;
                            event_peaks_ic1(counter2)=peaks(i);
                        end;
                    end;
                    lost_peaks(j)=numel(event_peaks_hfo)-numel(event_peaks_ic1);
                end;
                z_delta_amp_peak=zscore_2(delta_amp_peak);
                lost_peaks=lost_peaks-min(lost_peaks);
                lambdahat=poissfit_2(lost_peaks);
                z_lost_peaks=2*(sqrt(lost_peaks)-sqrt(lambdahat));
                
                clear event_peaks_hfo event_peaks_ic1 z_delta_amp_peak lost_peaks delta_amp_peak peaks
                
                fprintf('Calculating artifact index \r')
                ai=zeros(numel(hfo(:,1)),numel(hfo(1,:))); % corrected for intra-op data usually remove.
                artifact_segments=[]; % corrected for intra-op data usually remove.
                for i=1:numel(hfo(:,1));
                    ai_baseline_correct=mean(abs(hfo(i,:)));
                    for j=1:numel(hfo(1,:))
                        scale_factor=1;
                        if abs(ic1(i,j))>10
                            scale_factor=(abs(ic1(i,j))/10)*1;
                        end;
                        if ai(i,j)<10
                            ai(i,j)=(abs(hfo(i,j)-ic1(i,j))/scale_factor)/ai_baseline_correct;
                        end;
                    end;
                end;
                ai_mean=mean(ai);
                for i=1:numel(hfo(:,1));
                    for j=1:numel(hfo(1,:));
                        ai(i,j)=(ai(i,j)*ai_mean(j));
                    end;
                    ai(i,:)=smooth(ai(i,:),1200,'lowess');
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
                ai=max(ai);
                fprintf('Done calculating artifact index \r')
                hfo_ai=ai;
                
                clear temp temp2 temp3 temp4 temp5 a b c d scale_factor ai_baseline_correct ai_mean
                
                % reperform ripple detection part 1.
                % compensate for overstripping in HFO IC1
                nan_ica=zeros(numel(hfo(:,1)),1);   % you will need to take this out for completed EZ detect
                for i=1:numel(hfo(:,1))
                    if z_lost_peaks(i)>15
                        nan_ica(i)=1;
                    end;
                end;
                
                % Start Ripple detection
                % Calculate smoothed HFO amplitude
                for i=1:numel(hfo(:,1));
                    if nan_ica(i)==1
                        hilbert_hfo_amp=abs(hilbert(hfo(i,:)));
                    else
                        hilbert_hfo_amp=abs(hilbert(ic1(i,:)));
                    end;
                    score_amp=hilbert_hfo_amp;
                    smooth_length=40;
                    score_amp_ripple(i,:)=smooth(score_amp,smooth_length,'loess');
                    score_amp_ripple(i,:)=abs(score_amp_ripple(i,:));
                    lambdahat = poissfit_2(score_amp_ripple(i,:));
                    zscore_amp_ripple(i,:)=2*(sqrt(score_amp_ripple(i,:))-sqrt(lambdahat));
                    if nan_ica(i)==1
                        zscore_amp_ripple(i,:)=zscore_amp_ripple(i,:)+0.75;
                    end;
                end;
                
                temp_skew=skewness(zscore_amp_ripple'); % v4 add skewness correction for initial ripple detection to improve sensitivity.
                z_skew=zscore_2(temp_skew);
                thresh_z=[];
                thresh_zoff=[];
                for i=1:numel(metadata.m_chanlist)
                    if z_skew(i)>3
                        thresh_z(i)=1.1;
                        thresh_zoff(i)=0.3;
                    else
                        if z_skew(i)>2.5
                            thresh_z(i)=1.3;
                            thresh_zoff(i)=0.5;
                        else
                            if z_skew(i)>2
                                thresh_z(i)=1.5;
                                thresh_zoff(i)=0.7;
                            else
                                if z_skew(i)>1.5
                                    thresh_z(i)=1.7;
                                    thresh_zoff(i)=0.8;
                                else
                                    thresh_z(i)=1.8;
                                    thresh_zoff(i)=0.9;
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
                ripple_clip=cell(numel(eeg_data(:,1)),1);;
                ripple_clip_t=cell(numel(eeg_data(:,1)),1);;
                ripple_clip_event_t=cell(numel(eeg_data(:,1)),1);;
                ripple_clip_abs_t=cell(numel(eeg_data(:,1)),1);;
                
                total_ripple=zeros(numel(eeg_data(:,1)),1);
                fprintf('Running Ripple Detection\r')
                datablock=0;
                eeg_index=1;
                while eeg_index < (numel(eeg_data(1,:))-(59.99*2000))
                    ieeg_block=eeg_data(:,(eeg_index+1):(eeg_index+(2000*60)-1));
                    zscore_block=zscore_amp_ripple(:,(eeg_index+1):(eeg_index+(2000*60)-1));
                    amp_block=score_amp_ripple(:,(eeg_index+1):(eeg_index+(2000*60)-1));
                    ic1_block=ic1(:,(eeg_index+1):(eeg_index+(2000*60)-1));
                    ai_block=ai((eeg_index+1):(eeg_index+(2000*60)-1));
                    eeg_index=eeg_index+(2000*60)-1;
                    eeg_index/2000
                    for channel=1:numel(eeg_data(:,1))
                        
                        % Define ic1,z_score amp traces from blocks.
                        zscore_amp=zscore_block(channel,:);
                        ic1_chan=ic1_block(channel,:);
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
                            A_boolean=zscore_amp(j)>thresh_z(channel); % v4 with skewness adjustment
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
                                                if ai_block(k)>0.1 % v4 raised AI thresh to 0.1
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
                
                clear A_boolean a_value ai_block amp amp_block artifact b_boolean b_ind C_boolean chan_block_str channel clip_end clip_start counter2 datablock duration_cutoff eeg_index HFO_frequency hilbert_hfo_amp ic1_block ic1_chan i j k lambdahat nfft p Pxx q ref score_amp zscore_amp_ripple zscore_block
                
                ripple_ic_clip=cell(numel(eeg_data(:,1)),1);;
                ripple_ic_clip_t=cell(numel(eeg_data(:,1)),1);;
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
                        ripple_val_concat=horzcat(ripple_val_concat, ic1(ripple_time)); %v4 modification calculate ripple values
                    end;
                    if total_ripple(i)>0
                        hfo_times{i,:}=ripple_concat;
                        hfo_values{i,:}=ripple_val_concat;
                    end;
                end;
                clear ripple_time_s ripple_time_e ripple_time ripple_concat
                
            end; % bad electrode detected loop
        else % if number of bad electrodes are not the vast majority
            error_status=1;
            error_msg='mostly noisy mp electrodes';
        end;
        % Write TRC files
        % The function first outputs the 32 channel .TRC files for the annotations
        % from the input iEEG file.
        fprintf('writing monopolar iEEG to trc format \r');
        fprintf('converting data to 2048 Hz sampling rate \r');
        eeg_mp=gather(ez_tall_m);
        % The first step is to convert the sampling rate to 2048 Hz
        temp=[];
        temp2=[];
        [p,q]=rat(2048/2000)
        for j=1:numel(eeg_mp(:,1))
            x=eeg_mp(j,:);
            temp=resample(x,p,q);
            temp2(j,:)=temp;
        end;
        TRC.data=temp2;
        TRC.chanlist=metadata.m_chanlist;
        temp2=[];
        temp=[];
        
        clear x temp2 temp
        
        % Clear the temporary .mat files
        system(['rm -f ' paths.trc_tmp_monopolar 'eeg_2k_a_' file_block '.mat']);
        system(['rm -f ' paths.trc_tmp_monopolar 'eeg_2k_b_' file_block '.mat']);
        system(['rm -f ' paths.trc_tmp_monopolar 'eeg_2k_c_' file_block '.mat']);
        system(['rm -f ' paths.trc_tmp_monopolar 'eeg_2k_d_' file_block '.mat']);
        system(['rm -f ' paths.trc_tmp_monopolar 'eeg_2k_e_' file_block '.mat']);
        system(['rm -f ' paths.trc_tmp_monopolar 'eeg_2k_f_' file_block '.mat']);
        system(['rm -f ' paths.trc_tmp_monopolar 'eeg_2k_g_' file_block '.mat']);
        
        % corrects the file_id
        file_id_size=numel(metadata.file_id);
        file_id=metadata.file_id(1:(file_id_size-4));
        
        % The next step is to write the TRC file blocks
        num_trc_blocks=ceil(numel(metadata.m_chanlist)/32);
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
                save([paths.trc_tmp_monopolar 'eeg_2k_a_' file_block '.mat'],'eeg');
                system_command=[paths.executable 'mat2trc32_m2k_a' ' ' file_id ' ' file_block ' &'];
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
                save([paths.trc_tmp_monopolar 'eeg_2k_b_' file_block '.mat'],'eeg');
                system_command=[paths.executable 'mat2trc32_m2k_b' ' ' file_id ' ' file_block ' &'];
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
                save([paths.trc_tmp_monopolar 'eeg_2k_c_' file_block '.mat'],'eeg');
                system_command=[paths.executable 'mat2trc32_m2k_c' ' ' file_id ' ' file_block ' &'];
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
                save([paths.trc_tmp_monopolar 'eeg_2k_d_' file_block '.mat'],'eeg');
                system_command=[paths.executable 'mat2trc32_m2k_d' ' ' file_id ' ' file_block ' &'];
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
                save([paths.trc_tmp_monopolar 'eeg_2k_e_' file_block '.mat'],'eeg');
                system_command=[paths.executable 'mat2trc32_m2k_e' ' ' file_id ' ' file_block ' &'];
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
                save([paths.trc_tmp_monopolar 'eeg_2k_f_' file_block '.mat'],'eeg');
                system_command=[paths.executable 'mat2trc32_m2k_f' ' ' file_id ' ' file_block ' &'];
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
                save([paths.trc_tmp_monopolar 'eeg_2k_g_' file_block '.mat'],'eeg');
                system_command=[paths.executable 'mat2trc32_m2k_g' ' ' file_id ' ' file_block ' &'];
                system(system_command);
                fprintf('writing .TRC file #7 in background \r');
            end;
        end;
        clear eeg TRC max_trc_channels eeg_mp
        
        % Continue ripple detection part 2.
        % Calculate ripple extract index
        hfo_extract_index=[];
        ai_extract_index=[];
        hfo_times_chan=[];
        [~,artindex]=find(ai>0.025);
        non_artindex=[1:numel(eeg_data(1,:))];
        non_artindex(artindex)=[];
        for i=2:numel(eeg_data(:,1))
            ic_prune=[1:(numel(eeg_data(:,1)))];
            ic_prune(i)=[];
            OUTEEG = pop_subcomp(EEG, ic_prune, 0);
            ai_amp=(abs(OUTEEG.data(1,artindex)));
            non_ai_amp=(abs(OUTEEG.data(1,non_artindex)));
            ai_extract_index(i-1)=mean(ai_amp)/mean(non_ai_amp);
            for j=1:numel(eeg_data(:,1))
                non_hfo_times=[1:numel(eeg_data(1,:))];
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
        ic_prune=[1:(numel(eeg_data(:,1)))];
        ic_prune(f)=[];
        OUTEEG = pop_subcomp(EEG, ic_prune, 0);
        
        ripple_ics=OUTEEG.data;
        
        % redefine z_score block using ripple_ics
        for i=1:numel(hfo(:,1));
            hilbert_hfo_amp=abs(hilbert(ripple_ics(i,:)));
            score_amp=hilbert_hfo_amp;
            smooth_length=round((2000/2000)*40);
            score_amp_ripple(i,:)=smooth(score_amp,smooth_length,'loess');
            score_amp_ripple(i,:)=abs(score_amp_ripple(i,:));
            lambdahat = poissfit_2(score_amp_ripple(i,:));
            zscore_amp_ripple(i,:)=2*(sqrt(score_amp_ripple(i,:))-sqrt(2.5*lambdahat));
        end;
        
        ripple_ic_clip=cell(numel(eeg_data(:,1)),1);;
        ripple_ic_clip_t=cell(numel(eeg_data(:,1)),1);;
        ripple_ic_clip_event_t=cell(numel(eeg_data(:,1)),1);;
        ripple_ic_clip_abs_t=cell(numel(eeg_data(:,1)),1);;
        
        eeg_index=1;
        total_ripple_ic=zeros(numel(hfo(:,1)),1);
        datablock=0;
        while eeg_index < (numel(hfo(1,:))-(59.9*2000))
            ieeg_block=eeg_data(:,(eeg_index+1):(eeg_index+(2000*60)-1));
            amp_block=score_amp_ripple(:,(eeg_index+1):(eeg_index+(2000*60)-1));
            zscore_block=zscore_amp_ripple(:,(eeg_index+1):(eeg_index+(2000*60)-1));
            ic1_block=ripple_ics(:,(eeg_index+1):(eeg_index+(2000*60)));
            eeg_index=eeg_index+(2000*60)-1;
            eeg_index/2000
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
        eeg.ic1=[];
        
        % create master look up ripple time index for step 1 detection
        % convert ripple clips from time to indices
        % Create ripple index
        hfo_times=cell(numel(eeg_data(:,1)),1);
        for i=1:numel(ripple_clip_t(:,1))
            % convert ripple clips from time to indices
            ripple_concat=[];
            for j=1:total_ripple(i)
                ripple_time_s=(int32(ripple_clip_t{i,j}(1)*2000));
                ripple_time_e=(int32(ripple_clip_t{i,j}(2)*2000));
                ripple_time=ripple_time_s:ripple_time_e;
                ripple_concat=horzcat(ripple_concat, ripple_time);
                
            end;
            if total_ripple(i)>0
                hfo_times{i,:}=ripple_concat;
            end;
        end;
        
        total_ripple_backup=total_ripple;
        % if ripple not in look up index add the to total_ripple and add ripples
        % from step 2 to ripple clips
        for i=1:numel(eeg_data(:,1))
            temp_lookup=hfo_times{i,:};
            for j=1:total_ripple_ic(i)
                lookup_val1=int32(ripple_ic_clip_t{i,j}(1)*2000);
                lookup_val2=int32(ripple_ic_clip_t{i,j}(2)*2000);
                lookup_val12=lookup_val1:lookup_val2;
                if isempty(intersect(lookup_val12,temp_lookup))
                    total_ripple(i)=total_ripple(i)+1;
                    ripple_clip{i,total_ripple(i)}=ripple_ic_clip{i,j};
                    ripple_clip_t{i,total_ripple(i)}=ripple_ic_clip_t{i,j};
                    ripple_clip_event_t{i,total_ripple(i)}=ripple_ic_clip_event_t{i,j};
                    ripple_clip_abs_t{i,total_ripple(i)}=ripple_ic_clip_abs_t{i,j};
                end;
            end;
        end;
        
        clear a A_boolean ai_amp ai ai_extract_index amp amp_block ans artifact artindex b B_boolean c C C_boolean chan_block_str channel clip_end clip_start d D datablock delta_amp_peak duration_cutoff e Hpsd i ic1_block ic1_chan ic_prune ieeg_block j lambdahat lookup_val1 lookup_val12 lookup_val2 nfft ripple_concat ripple_ic_clip ripple_ic_clip_t ripple_time ripple_ics ripple_time_e ripple_time_s score_amp score_amp_ripple size_array smooth_length start start_ann step_search stop_ann temp_delta temp_time temp_zeros total_ripple_backup total_ripple_ic x zscore_amp zscore_amp_ripple zscore_block
        
        %% Calculate ICA for fast ripples (FR)
        [fr, fr_ic1, EEG, error_flag]=ez_cudaica_fripple_putou_e1(eeg_data_no_notch,2000, paths);
        if error_flag==0
            ez_tall_fr_m=tall(fr);
            fprintf('compensating for overstripping fripple ica \r');
            lost_peaks_fr=[];
            delta_amp_peak_fr=zeros(numel(fr(:,1)),1);
            for j=1:numel(fr(:,1))
                j
                [peaks] = find_inflections(fr(j,:),'maxima');
                event_peaks_fr=[];
                counter=0;
                for i=1:numel(peaks)
                    if fr(j,peaks(i))>7
                        counter=counter+1;
                        event_peaks_fr(counter)=peaks(i);
                        temp_delta=fr(j,peaks(i))-fr_ic1(j,peaks(i));
                        delta_amp_peak_fr(j)=delta_amp_peak_fr(j)+temp_delta;
                    end;
                end;
                [peaks] = find_inflections(fr_ic1(j,:),'maxima');
                event_peaks_fr_ic1=[];
                counter2=0;
                for i=1:numel(peaks)
                    if fr_ic1(j,peaks(i))>7
                        counter2=counter2+1;
                        event_peaks_fr_ic1(counter2)=peaks(i);
                    end;
                end;
                lost_peaks_fr(j)=numel(event_peaks_fr)-numel(event_peaks_fr_ic1);
            end;
            z_delta_amp_peak_fr=zscore_2(delta_amp_peak_fr);
            z_lost_peaks_fr=zscore_2(lost_peaks_fr);
            
            % compensate for overstripping in FR IC1
            nan_ica=zeros(numel(eeg_data(:,1)),1);   % you will need to replace this completed EZ detect and include HF bad channels
            [a_value,b_ind]=min((z_delta_amp_peak_fr)); % Find Replacement AI index
            for i=1:numel(eeg_data(:,1))
                if z_lost_peaks_fr(i)>5
                    nan_ica(i)=1;
                end;
            end;
            
            fprintf('Calculating artifact index \r')
            fprintf('Calculating baseline stats \r')
            ai=zeros(numel(eeg_data(:,1)),numel(eeg_data(1,:))); % corrected for intra-op data usually remove.
            for i=1:numel(fr(:,1));
                ai_baseline_correct=mean(abs(fr(i,:)));
                for j=1:numel(fr(1,:))
                    scale_factor=1;
                    if abs(fr_ic1(i,j))>10
                        scale_factor=(abs(fr_ic1(i,j))/10)*1;
                    end;
                    if ai(i,j)<10
                        ai(i,j)=(abs(fr(i,j)-fr_ic1(i,j))/scale_factor)/ai_baseline_correct;
                    end;
                end;
            end;
            ai_mean=mean(ai);
            for i=1:numel(fr(:,1));
                for j=1:numel(fr(1,:));
                    ai(i,j)=(ai(i,j)*ai_mean(j));
                end;
                ai(i,:)=smooth(ai(i,:),3000,'moving');
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
            temp2=[];
            temp3=[];
            temp4=[];
            temp5=[];
            a=[];
            b=[];
            c=[];
            d=[];
            fprintf('Done calculating artifact index \r')
            fprintf('Done calculating baseline stats \r')
            ai=max(ai);
            fr_ai=ai;
            clear temp temp2 temp3 temp4 temp5 a b c d scale_factor ai_baseline_correct ai_mean;
            
            %% Calculate baseline FR stats
            for i=1:numel(fr(:,1));
                hilbert_hfo_amp=abs(hilbert(fr_ic1(i,:)));
                score_amp=hilbert_hfo_amp;
                smooth_length=round((2000/2000)*40);
                score_amp_fripple(i,:)=smooth(score_amp,smooth_length,'loess');
                zscore_amp_fripple(i,:)=zscore_2(score_amp_fripple(i,:));
            end;
            clear hilbert_hfo_amp;
            
            % V4 add adjustment for skewness for fast ripple detection
            temp_skew=skewness(zscore_amp_fripple'); % v4 add skewness correction for initial ripple detection to improve sensitivity.
            z_skew=zscore_2(temp_skew);
            thresh_z=[];
            thresh_zoff=[];
            for i=1:numel(metadata.m_chanlist)
                if z_skew(i)>3
                    thresh_z(i)=2.5;
                    thresh_zoff(i)=0.6;
                else
                    if z_skew(i)>2.5
                        thresh_z(i)=2.7;
                        thresh_zoff(i)=0.8;
                    else
                        if z_skew(i)>2
                            thresh_z(i)=2.9;
                            thresh_zoff(i)=1;
                        else
                            if z_skew(i)>1.5
                                thresh_z(i)=3.2;
                                thresh_zoff(i)=1.3;
                            else
                                thresh_z(i)=3.5;
                                thresh_zoff(i)=1.5;
                            end;
                        end;
                    end;
                end;
            end;
            
            clear temp_skew z_skew
            
            % initialize data structures '2D array of cells' note that this structure can flexibly
            % store different length elements within each cell, and the number of cells can vary by
            % row. This structure may need to be revised to improve efficiency.
            fripple_clip=cell(numel(eeg_data(:,1)),1);;
            fripple_clip_t=cell(numel(eeg_data(:,1)),1);;
            fripple_clip_event_t=cell(numel(eeg_data(:,1)),1);;
            fripple_clip_abs_t=cell(numel(eeg_data(:,1)),1);;
            
            total_fripple=zeros(numel(eeg_data(:,1)),1);
            fprintf('Running Fast Ripple Detection \r')
            datablock=0;
            eeg_index=1;
            while eeg_index < (numel(eeg_data(1,:))-(59.9*2000))
                ieeg_block=eeg_data(:,(eeg_index+1):(eeg_index+(2000*60)-1));
                amp_block=score_amp_fripple(:,(eeg_index+1):(eeg_index+(2000*60)-1));
                zscore_block=zscore_amp_fripple(:,(eeg_index+1):(eeg_index+(2000*60)-1));
                ai_block=ai((eeg_index+1):(eeg_index+(2000*60)-1));
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
                        A_boolean=zscore_amp(j)>thresh_z(channel); %V4 to account for skewness of deviation
                        B_boolean=amp(j)>4;
                        C_boolean=and(A_boolean,B_boolean);
                        if ((flagged==0) && (C_boolean==1))  % Optimization factor #1
                            flagged=1;
                            start=j;
                        end;
                        if ((flagged==1) && (zscore_amp(j)>thresh_zoff(channel))) end; % Optimization factor #2
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
            clear A_boolean a_value ai_block amp amp_block artifact b_boolean b_ind C_boolean chan_block_str channel clip_end clip_start counter2 datablock duration_cutoff eeg_index HFO_frequency hilbert_hfo_amp ic1_block ic1_chan i j k lambdahat nfft p Pxx q ref score_amp zscore_amp_ripple zscore_block
            
            %% Find fast ripple only components
            fripple_ic_clip={''};
            fripple_ic_clip_t={''};
            fripple_ic_clip_event_t={''};
            fripple_ic_clip_abs_t={''};
            
            % Create ripple index
            hfo_times=cell(numel(eeg_data(:,1)),1);
            for i=1:numel(fripple_clip_t(:,1))
                % convert ripple clips from time to indices
                fripple_concat=[];
                for j=1:total_fripple(i)
                    fripple_time_s=(int32(fripple_clip_t{i,j}(1)*2000));
                    fripple_time_e=(int32(fripple_clip_t{i,j}(2)*2000));
                    fripple_time=fripple_time_s:fripple_time_e;
                    fripple_concat=horzcat(fripple_concat, fripple_time);
                    
                end;
                if total_fripple(i)>0
                    hfo_times{i,:}=fripple_concat;
                end;
            end;
            
            % Calculate fripple extract index
            hfo_extract_index=[];
            hfo_times_chan=[];
            [~,artindex]=find(ai>0.02);
            non_artindex=[1:numel(eeg_data(1,:))];
            non_artindex(artindex)=[];
            for i=2:numel(eeg_data(:,1))
                ic_prune=[1:(numel(eeg_data(:,1)))];
                ic_prune(i)=[];
                OUTEEG = pop_subcomp(EEG, ic_prune, 0);
                ai_amp=(abs(OUTEEG.data(1,artindex)));
                non_ai_amp=(abs(OUTEEG.data(1,non_artindex)));
                ai_extract_index(i-1)=mean(ai_amp)/mean(non_ai_amp);
                for j=1:numel(eeg_data(:,1))
                    non_hfo_times=[1:numel(eeg_data(1,:))];
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
            ic_prune=[1:(numel(eeg_data(:,1)))];
            ic_prune(f)=[];
            OUTEEG = pop_subcomp(EEG, ic_prune, 0);
            
            fripple_ics=OUTEEG.data;
            % redefine z_score block using fripple_ics
            for i=1:numel(eeg_data(:,1));
                hilbert_hfo_amp=abs(hilbert(fripple_ics(i,:)));
                eeg.score_amp=hilbert_hfo_amp;
                smooth_length=round((2000/2000)*40);
                eeg.score_amp_fripple(i,:)=smooth(eeg.score_amp,smooth_length,'loess');
                eeg.score_amp_fripple(i,:)=abs(eeg.score_amp_fripple(i,:));
                lambdahat = poissfit_2(eeg.score_amp_fripple(i,:));
                eeg.zscore_amp_fripple(i,:)=2*(sqrt(eeg.score_amp_fripple(i,:))-sqrt(2.5*lambdahat));
            end;
            clear hilbet_hfo_amp
            
            eeg_index=1;
            total_fripple_ic=zeros(numel(eeg_data(:,1)),1);
            datablock=0;
            
            fripple_ic_clip=cell(numel(eeg_data(:,1)),1);;
            fripple_ic_clip_t=cell(numel(eeg_data(:,1)),1);;
            fripple_ic_clip_abs_t=cell(numel(eeg_data(:,1)),1);;
            
            eeg_index=1;
            total_fripple_ic=zeros(numel(eeg_data(:,1)),1);
            datablock=0;
            
            while eeg_index < (numel(eeg_data(1,:))-(59.9*2000))
                ieeg_block=eeg_data(:,(eeg_index+1):(eeg_index+(2000*60)-1));
                amp_block=eeg.score_amp_fripple(:,(eeg_index+1):(eeg_index+(2000*60)-1));
                zscore_block=eeg.zscore_amp_fripple(:,(eeg_index+1):(eeg_index+(2000*60)-1));
                eeg_index=eeg_index+(2000*60)-1;
                eeg_index/2000
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
            total_fripple_backup=total_fripple;
            % if ripple not in look up index add the to total_ripple and add ripples
            % from step 2 to ripple clips
            for i=1:numel(eeg_data(:,1))
                temp_lookup=hfo_times{i,:};
                for j=1:total_fripple_ic(i)
                    lookup_val1=int32(fripple_ic_clip_t{i,j}(1)*2000);
                    lookup_val2=int32(fripple_ic_clip_t{i,j}(2)*2000);
                    lookup_val12=lookup_val1:lookup_val2;
                    if isempty(intersect(lookup_val12,temp_lookup))
                        total_fripple(i)=total_fripple(i)+1;
                        fripple_clip{i,total_fripple(i)}=fripple_ic_clip{i,j};
                        fripple_clip_t{i,total_fripple(i)}=fripple_ic_clip_t{i,j};
                        fripple_clip_event_t{i,total_fripple(i)}=fripple_ic_clip_event_t{i,j};
                        fripple_clip_abs_t{i,total_fripple(i)}=fripple_ic_clip_abs_t{i,j};
                    end;
                end;
            end;
            
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
            filename1=['dsp_' file_id '_m_' file_block '.mat'];
            filename1=strcat(paths.ez_top_in,filename1);
            save('-v7.3',filename1,'DSP_data_m');
            
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
    else % error_flag 1 i.e. CUDAICA exploded ICA #2
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
else % error_flag 1 i.e. CUDAICA exploded ICA #3
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