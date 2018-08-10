function [hfo,ic1,EEG]=ez_cudaica_ripple_putou(eeg_data,samplingrate);

% This work is protected by US patent applications US20150099962A1,
% UC-2016-158-2-PCT, US provisional #62429461

% Written by Shennan Aibel Weiss MD, PhD. in Matlab at Thomas Jefferson University
% Philadelphia, PA USA. 

for i=1:numel(eeg_data(:,1));
    temp_var=eeg_data(i,:);
    temp_var(isnan(temp_var))=0;
    eeg_data(i,:)=temp_var;
    eeg_data(i,:)=(eeg_data(i,:)-mean(eeg_data(i,:)));
end;

eeg_data=ez_eegfilter(eeg_data,80,600,2000);

hfo=[];
ic1=[];
start=1;

EEG = pop_importdata('setname','temp','data',eeg_data,'dataformat','matlab','srate',samplingrate); % load data in to eeglab
[EEG.icaweights, EEG.icasphere, mods] = cudaica(EEG.data(:,:), 'lrate', 0.001)
EEG.icawinv = pinv( EEG.icaweights*EEG.icasphere ); % calculate ICA matrix
EEG.icachansind=[1:numel(eeg_data(:,1))]; % populate channels
OUTEEG = pop_subcomp(EEG, 1, 0); % remove ICA components
hfo=horzcat(hfo,eeg_data);
ic1=horzcat(ic1,OUTEEG.data); % addend cleaned data 

