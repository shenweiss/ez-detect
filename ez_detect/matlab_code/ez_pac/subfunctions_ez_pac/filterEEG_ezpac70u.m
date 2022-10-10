% Bandpass window-sinc FIR filter of (1) HFOs 60-800Hz with artifact rejection,
% (2) 4-30Hz LP, (3) oscillations

function [output_bpFIR, delays] = filterEEG_ezpacu(eeg, samplingrate);

% freqnecy range determined for each oscillation
spike = [4 30];
sharp = [3 50];
spindle = [12 16];
theta = [9 12];
delta = [2 4];
slow = [0.1 2]; % [2 4] For debugging purposes

for i=1:numel(eeg(:,1))  % SW: Note this change 
    channel=i;
    data_test(i,:)=eeg(channel,:);
    % A notch filter is applied to the data segment with DC noise
    f0 = (2*(60/samplingrate));
    df = .1;
    N = 30; % must be even for this trick
    h=remez(N,[0 f0-df/2 f0+df/2 1],[1 1 0 0]);
    h = 2*h - ((0:N)==(N/2));
    data(i,:)=filtfilt(h,1,data_test(i,:));
end;    
    % Using EEG plugin (pop_eegfiltnew function) hardcoded hamming
    % window-sinc FIR filtering on oscillations from raw iEEG data
    eeg=[];
    % importing data to matlab in EEGLAB EEG data format
    data=data(:,:);
    EEG = pop_importdata('setname','temp','data', data,'dataformat','matlab','srate', samplingrate); % load data in to eeglab
    % then running filtering command for 5 different frequency bands
    [eeg.bpSpindle, com_spindle, b_spindle, delay] = pop_eegfiltnew_gpu(EEG, spindle(1), spindle(2));
    delays(1)=delay;
    [eeg.bpTheta, com_theta, b_theta, delay] = pop_eegfiltnew_gpu(EEG, theta(1), theta(2));
    delays(2)=delay;
    [eeg.bpDelta, com_delta, b_delta, delay] = pop_eegfiltnew_gpu(EEG, delta(1), delta(2));
    delays(3)=delay;
    [eeg.bpSlow, com_slow, b_slow, delay] = pop_eegfiltnew_gpu(EEG, slow(1), slow(2));
    delays(4)=delay;
    [eeg.bpSpike, com_slow, b_slow, delay] = pop_eegfiltnew_gpu(EEG, spike(1), spike(2));
    delays(5)=delay;
    [eeg.bpSharp, com_slow, b_slow, delay] = pop_eegfiltnew_gpu(EEG, sharp(1), sharp(2));
    delays(5)=delay;
    % output the stored discrete HFOs
output_bpFIR.eeg.bpSpindle=tall(eeg.bpSpindle.data);
output_bpFIR.eeg.bpTheta=tall(eeg.bpTheta.data);
output_bpFIR.eeg.bpDelta=tall(eeg.bpDelta.data);
output_bpFIR.eeg.bpSlow=tall(eeg.bpSlow.data);
output_bpFIR.eeg.bpSpike=tall(eeg.bpSpike.data);
output_bpFIR.eeg.bpSharp=tall(eeg.bpSharp.data);
