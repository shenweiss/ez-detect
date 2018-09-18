function resample_edf_to(edf_path, desired_srate)
    narginchk(1,2); %at least the file is required
	if nargin<2
		desired_srate = 128; %default
	end

	[data, header] = ReadEDF(edf_path);
	record_srate = header.samplerate;
	record_duration_snds = header.duration;
	sampling_rate = 1/record_duration_snds * record_srate;
	number_of_channels= numel(data);
	resampled_data = resampleData(sampling_rate, desired_srate, number_of_channels, data)


	[file_path, filename, extention] = fileparts(edf_path); 

	SaveEDF([file_path filename '_resampled_' num2str(desired_srate) extention], resampled_data, header);
end

function resampled_data = resampleData(sampling_rate, desired_srate, number_of_channels, eeg_data)
    %Resample Data to 2khz required.
    if sampling_rate ~= desired_srate
        [p,q] = rat(desired_srate/sampling_rate);
        disp(['Resampling the Data to ' num2str(desired_srate) 'Hz']);
        for j=1:number_of_channels
            channel = eeg_data{j};
            resampled_data{j} = resample(channel,p,q);
        end
        disp(['Resampled: ' num2str(number_of_channels) ' data channels.']);
    else % No resample needed
        resampled_data = eeg_data;
    end
end