function [hfo, ic1, EEG, error_flag] = ez_cudaica_ripple(eeg_data, low, high, sampling_rate, paths);

% This work is protected by US patent applications US20150099962A1,
% UC-2016-158-2-PCT, US provisional #62429461

% Written by Shennan Aibel Weiss MD, PhD. in Matlab at Thomas Jefferson University
% Philadelphia, PA USA. 

%Note: paths argument, will be used in the call to cudaica once refactored that function.
	
	%analize this later
	for i = 1:numel(eeg_data(:,1));
	    temp_var = eeg_data(i,:);
	    temp_var(isnan(temp_var)) = 0;
	    eeg_data(i,:) = temp_var;
	    eeg_data(i,:) = eeg_data(i,:)-mean(eeg_data(i,:));
	end

	samplingrate = 2000; %ask if this will always be 2000 or should be the one passed by argument, that is also 2000 as far as I know
	eeg_data = ez_eegfilter(eeg_data, low, high, samplingrate);
	%start = 1; %not used?
	EEG = pop_importdata('setname','temp','data',eeg_data,'dataformat','matlab','srate',sampling_rate); % load data in to eeglab
	[EEG.icaweights, EEG.icasphere, mods, error_flag] = ez_cudaica(EEG.data(:,:), 'lrate', 0.001)
	
	cudaica_succeeded = error_flag == 0;
	if cudaica_succeeded
		EEG.icawinv = pinv(EEG.icaweights*EEG.icasphere); % calculate ICA matrix
		EEG.icachansind = 1:numel(eeg_data(:,1)); % populate channels
		OUTEEG = pop_subcomp(EEG, 1, 0); % remove ICA components
		hfo = eeg_data;
		ic1 = OUTEEG.data; % addend cleaned data 
	else
		hfo = [];
		ic1 = [];
		EEG = [];
	end
end
