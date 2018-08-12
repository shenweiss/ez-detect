function eeg=eeg_filter(eeg,low,high)
%EEG is the data source
%Filters eeg into new eeg files with filtered data
%Set low or high to 0 to not have a frequency, 1,0 would be a high pass 1Hz

samplingrate = eeg.samp_rate;

%Filter Settings
if(low == 0) && (high == 0)
    disp('Impossible Filter between 0 and 0 Hz');
    return;
elseif (high == 0)
    CustomFilter = fir1(1000,low/(samplingrate/2),'high');
    filetag = strcat('_filtered_hp_',int2str(low),'.mat');
elseif (low == 0)
    CustomFilter = fir1(1000,high/(samplingrate/2),'low');
    filetag = strcat('_filtered_lp_',int2str(low),'.mat');
else
    CustomFilter = fir1(1000,[low/(samplingrate/2) high/(samplingrate/2)]);
    filetag = strcat('_filtered_',int2str(low),'_',int2str(high),'.mat');
end


for i = 1:length(eeg.eeg_data(:,1))
    disp(strcat('Filtered:_',int2str(i),'_of_',int2str(length(eeg.eeg_data(:,1))),'_data.'));
    eeg_filtered_data(i,:) = filtfilt(CustomFilter,1,eeg.eeg_data(i,:));
end

eeg.eeg_data_unfiltered = eeg.eeg_data;
eeg.eeg_data = eeg_filtered_data;

end