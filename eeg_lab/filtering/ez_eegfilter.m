function eeg_data=ez_eegfilter(eeg_data,low,high,samplingrate)
%EEG is the data source
%Filters eeg into new eeg files with filtered data
%Set low or high to 0 to not have a frequency, 1,0 would be a high pass 1Hz

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

    eeg_data_length = length(eeg_data(:,1));

    for i = 1:eeg_data_length
        %fprintf('Filtered: %i of %i data.', i, length(eeg_data(:,1)) );
        eeg_data(i,:) = filter(CustomFilter,1,eeg_data(i,:));
    end
    fprintf('Filtered: %i of %i data.', i, length(eeg_data(:,1)) );

end