
classdef MonopolarDspToolbox < EzDetectDspToolbox
	
	methods
		function dsp_monopolar_output = cudaica_failure_handle(Ez, ez_tall_m, ez_tall_bp, metadata, ez_top_in_dir)
			dsp_monopolar_output = cudaica_failure_handle_(ez_tall_m, ez_tall_bp, metadata, ez_top_in_dir);
		end

		function [ez_tall_m, metadata] = remove60CycleArtifactOutliers(Ez, ez_tall_m, metadata)
			[ez_tall_m, metadata] = remove60CycleArtifactOutliers_(ez_tall_m, metadata);
		
		end
		
		function [ez_tall_m, ez_tall_bp, metadata] = removeBadChannelsFromMonopolarMontage(Ez, ez_tall_m, ...
                                                              ez_tall_bp, metadata, chan_indexes)
			[ez_tall_m, ez_tall_bp, metadata] = removeBadChannelsFromMonopolarMontage_(ez_tall_m, ...
                                                              ez_tall_bp, metadata, chan_indexes);
		end
		
		function [z_delta_amp_peak, z_lost_peaks] = detectOverstrippedRecordings(Ez, data, ic1, z_lost_peaks_method)
			[z_delta_amp_peak, z_lost_peaks] = detectOverstrippedRecordings_(data, ic1, z_lost_peaks_method);
		end

		function z_lost_peaks = method_one(Ez, lost_peaks)
			z_lost_peaks = method_one_(lost_peaks);
		end	

		function [ai] = calculateArtifactIndex(Ez, ai_rows, ai_cols, eeg_data, ic1, smooth_span, smooth_method)
			[ai] = calculateArtifactIndex_(ai_rows, ai_cols, eeg_data, ic1, smooth_span, smooth_method);
		end

		function nan_ica = compensateOverstrippingHFO_IC1(Ez, nan_ica_size, z_lost_peaks, threshold)
			nan_ica = compensateOverstrippingHFO_IC1_(nan_ica_size, z_lost_peaks, threshold);
		end

		function [score_amp_ripple, zscore_amp_ripple] = calculateSmoothedHFOamplitudeNanIca(Ez, num_of_data_rows, ...
		                             hfo, ic1, nan_ica, score_amp_ripple_i_method, zscore_amp_ripple_i_method)
			[score_amp_ripple, zscore_amp_ripple] = calculateSmoothedHFOamplitudeNanIca_(num_of_data_rows, ...
		                             hfo, ic1, nan_ica, score_amp_ripple_i_method, zscore_amp_ripple_i_method);
		end

		function ripple_ics = getRippleIcs(Ez, num_of_data_cols, num_of_data_rows, EEG, hfo_times, ai, ...
										   art_index_thresh, hfo_extract_index_thresh)
			ripple_ics = getRippleIcs_(num_of_data_cols, num_of_data_rows, EEG, hfo_times, ai, ...
										   art_index_thresh, hfo_extract_index_thresh);
		end	
		
		function ripple_data = addRipples(Ez, num_of_data_rows,hfo_times, ripple_data, ripple_ics_data)
			ripple_data = addRipples_(num_of_data_rows,hfo_times, ripple_data, ripple_ics_data);
		end
	end
end

%Methods definition

function dsp_monopolar_output = cudaica_failure_handle_(ez_tall_m, ez_tall_bp, metadata, ez_top_in_dir)

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


function [ez_tall_m, metadata] = remove60CycleArtifactOutliers_(ez_tall_m, metadata)

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
function [ez_tall_m, ez_tall_bp, metadata] = removeBadChannelsFromMonopolarMontage_(ez_tall_m, ...
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

function [z_delta_amp_peak, z_lost_peaks] = detectOverstrippedRecordings_(data, ic1, z_lost_peaks_method)
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
function z_lost_peaks = method_one_(lost_peaks)
    lost_peaks = lost_peaks-min(lost_peaks);
    lambdahat = poissfit_2(lost_peaks);
    z_lost_peaks = 2 * (sqrt(lost_peaks)-sqrt(lambdahat));
end

function [ai] = calculateArtifactIndex_(ai_rows, ai_cols, eeg_data, ic1, smooth_span, smooth_method)  
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

function nan_ica = compensateOverstrippingHFO_IC1_(nan_ica_size, z_lost_peaks, threshold)
    nan_ica=zeros(nan_ica_size,1);% you will need to take this out for completed EZ detect
    for i=1:nan_ica_size
        if z_lost_peaks(i)>threshold
            nan_ica(i)=1;
        end
    end
end

function [score_amp_ripple, zscore_amp_ripple] = calculateSmoothedHFOamplitudeNanIca_(num_of_data_rows, ...
                             hfo, ic1, nan_ica, score_amp_ripple_i_method, zscore_amp_ripple_i_method)    
    for i=1:num_of_data_rows
        if nan_ica(i)==1
            hilbert_amp=abs(hilbert(hfo(i,:)));
        else
            hilbert_amp=abs(hilbert(ic1(i,:)));
        end
        smooth_length = round((2000/2000)*40); %ask about this... thats 40 always, ask if they wanna extract variable as srate
        score_amp_ripple(i,:) = score_amp_ripple_i_method(hilbert_amp, smooth_length);
        zscore_amp_ripple(i,:) = zscore_amp_ripple_i_method(score_amp_ripple(i,:));
        if nan_ica(i)==1
            zscore_amp_ripple(i,:) = zscore_amp_ripple(i,:)+0.75;
        end
    end
end

function ripple_ics = getRippleIcs_(num_of_data_cols, num_of_data_rows, EEG, hfo_times, ai, art_index_thresh, ...
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
function ripple_data = addRipples_(num_of_data_rows,hfo_times, ripple_data, ripple_ics_data)
    
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
