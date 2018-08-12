function [metadata]=ez_hfbad_putou02(ez_tall,metadata);
metadata.hf_bad_m_index=[];
%Downsample the data to 500 Hz
eeg=gather(ez_tall);
eeg_ds=[];
    for i=1:numel(eeg(:,1))
       data=downsample(eeg(i,:),4);
       eeg_ds=vertcat(eeg_ds, data);           
   end;
eeg_ds = ez_eegfilter(eeg_ds,80,150,500);
eeg_hg_amplitude=[];
for j=1:numel(eeg(:,1))  
  hg_hilbert=hilbert(eeg_ds(j,:));
  hg_amplitude=abs(hg_hilbert);
  eeg_hg_amplitude=vertcat(eeg_hg_amplitude, hg_amplitude);
end;
eeg_hg_amplitude_mean=mean(eeg_hg_amplitude);
eeg_hg_amplitude_mean_ds=downsample(eeg_hg_amplitude_mean,5);
mean_amplitude_smoothed=smooth(eeg_hg_amplitude_mean_ds,500);
zmean_amplitude_smoothed=zscore_2(mean_amplitude_smoothed);
flagged=0;
start={''};
finish={''};
duration={''};
event_duration=0;
intervals=0;
for i=1:numel(zmean_amplitude_smoothed)
    if ((flagged==0) && (zmean_amplitude_smoothed(i) > 1.5))  
        intervals=intervals+1;
        start{intervals}=i;
        flagged=1;
    end;
    if ((flagged==1) && (zmean_amplitude_smoothed(i)>1.5)) end;
    if ((flagged==1) && (zmean_amplitude_smoothed(i)<1.5)) 
        finish{intervals}=i;
        duration{intervals}=i-start{intervals};
        flagged=0;
    end;
end;
if ~isempty(cell2mat(duration))
duration=cell2mat(duration);
start=cell2mat(start);
finish=cell2mat(finish);
[A,B]=max(duration);
else
start=1;
finish=5000;
B=1;
end;
MI_test=eeg_ds(:,(start(B)*5):(finish(B)*5));
if ~isempty(MI_test)
MI(:,:) = mutualinformation_norm_strehl_ghosh1(MI_test');
[M,Q]=community_louvain(MI,0.5)
MI_community=[];
for i=1:max(M)
    [a,b]=find(M==i);
    temp_matrix=(MI(a,a));
    MI_community(i) = nansum(nansum(tril(temp_matrix,-1)))/(((numel(temp_matrix(1,:))^2)/2)-(numel(temp_matrix(1,:))));
end;
MI_community(isinf(MI_community)) = 0;
[a,b]=max(MI_community);
if numel(find(M==b))>12
metadata.hf_bad_m_index=find(M~=b);
end;
end;