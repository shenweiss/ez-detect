function [resampled_amplitude] = ezSpike_PreTF_0_single(eeg)

Fs = 2000;
fmin = 30;
fmax = 80;
omega = 4;
gSize = 500;
% Nint = 500;
Nint = 700;

disp('Generating Wavelet Array...')

wavelet = ezSpikeWavelet_single(eeg,Fs,[fmin fmax],omega);
% ROBUSTNESS RECOMMENDATION: The largest clip set run successfully on the
% above function is 12561. If clip set is significantly larger (~10x),
% May need to break them in to blocks before feeding into the above
% function. Further, may wish to break into blocks for 
% ezSpike_PreTF_0_single 

[Nf N Neeg] = size(wavelet.corrected_amplitude);
div = floor(Neeg/Nint);

% Initialize empty cdat0 array (double) and record its memory
cdat0 = single(zeros(Nf*floor(gSize/Nf),gSize,Neeg));

disp('Downsampling...')
% Downsample the X resolution but have to do it one channel at a time
amplitude = gather(wavelet.corrected_amplitude);
parfor ii = 1:size(amplitude,1)
    resampled_amplitude(ii,:,:) = permute(single(resample(double(squeeze(amplitude(ii,:,:))),gSize,N)),[3 1 2]);
end
