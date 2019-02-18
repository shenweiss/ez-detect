function [freq] = calc_power_slow_delta(eeg, input_matrix);
%eeg is the raw eeg
%loadmatrix is the setup of the channels on the grid
%plotchoice is the eeg time series that you will see in the videos
%setting is for batching
%0 is manual and will let you set parameters in the program
%1 is for automatric and parameters is a variable with the desired
%parameters to use
%[upperfreq lowerfreq upperzscore lowerzscore]
loadmatrix=input_matrix;
data=[];
 
%First Read in the Matrix of EEGs
channelinfo = matrixreader(loadmatrix);
matrixsize = length(channelinfo.names);
%Find Channels
numberfoundchannels = 0;
channelindex = 0;
for i = 1:length(channelinfo.names)
    for j = 1:length(eeg.chanlist)
        if strcmp(eeg.chanlist{j},channelinfo.names{i})
            numberfoundchannels = numberfoundchannels + 1;
            foundchannels{numberfoundchannels} = eeg.chanlist{j};
            channelindex(numberfoundchannels) = j;
            disp(['Channel ', channelinfo.names{i}, ' was found.']);
        end
    end
end
%Put the matrix data into a temp file (copied from Shennen)
for i = 1:length(foundchannels)
    temp(i,:) = eeg.eeg_data(channelindex(i),:);
end

temp2=[];

% Down sample data to 200 Hz
if eeg.samp_rate == 2000
for i=1:numel(temp(:,1))
    temp2(i,:)=downsample(temp(i,:),10);
end;   
else
  for i=1:numel(temp(:,1))
    temp2(i,:)=downsample(temp(i,:),5);
  end;  
end;
temp=temp2;
eeg.samp_rate=200;

channel_list=[];
for i=1:matrixsize
    channel_list{i} = channelinfo.names{i};
end;

data.label = [];

%Labeling channels as part of field trip
data.label=cell(length(foundchannels),1)
for i=1:length(foundchannels)
    a=num2str(i);
    data.label{i} = ['chan' a];
end;
data.fsample=eeg.samp_rate;

%Here on in returns to Shennen's Code
data.time=cell(1,1);
time=[(1/eeg.samp_rate):(1/eeg.samp_rate):(numel(eeg.eeg_data(1,:)))/eeg.samp_rate];
data.time{1,1}=time;
time=[];
data.trial=cell(1,1);
data.trial{1,1}=temp; % the fieldtrip data format has been succesfully constructed
temp=[];
cfg=[];
cfg.lpfilter='no';
cfg.hpfilter='no';
dataLFP=ft_preprocessing(cfg, data); %Fieldtrip preprocessingdbqui
dataLFP.cfg.trl=[1 length(eeg.eeg_data) 0]; % define trial structure

%% Calculating power from here
cfg=[];
cfg=[];
cfg.trials=1;
cfg.offset=0;
cfg.method='mtmfft';
cfg.output='pow';
cfg.foi=[1:1:100] % calculate power across all bands
cfg.tapsmofrq = .1;
freq = ft_freqanalysis(cfg,dataLFP);
slow_delta_ratio=sum(freq.powspctrm(1,1:4))/(sum(freq.powspctrm(1,5:40))+sum(freq.powspctrm(1,1:4)))

