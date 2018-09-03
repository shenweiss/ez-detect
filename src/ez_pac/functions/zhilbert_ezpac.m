% defining epochs of oscillations after hilbert transform

function [output_hilbert] = zhilbert_test1011(eeg_data, output_bpFIR, samplingrate);

output_hilbert = [];
zscore = [];

num_channels=numel(eeg_data(:,1));
record_samples=numel(eeg_data(1,:));
temp.Spindle=gather(output_bpFIR.eeg.bpSpindle(:,1:record_samples));
temp.Theta=gather(output_bpFIR.eeg.bpTheta(:,1:record_samples));
temp.Delta=gather(output_bpFIR.eeg.bpDelta(:,1:record_samples));
temp.Slow=gather(output_bpFIR.eeg.bpSlow(:,1:record_samples));
temp.Spike=gather(output_bpFIR.eeg.bpSpike(:,1:record_samples));
    
for counter=1:num_channels
    % Apply Hilbert transform to Raw EEG stream of oscillations
    eeg.hilbertSpindle(counter,:)=hilbert(temp.Spindle(counter,1:record_samples));
    eeg.hilbertTheta(counter,:)=hilbert(temp.Theta(counter,1:record_samples));
    eeg.hilbertDelta(counter,:)=hilbert(temp.Delta(counter,1:record_samples));
    eeg.hilbertSlow(counter,:)=hilbert(temp.Slow(counter,1:record_samples));
    eeg.hilbertSpike(counter,:)=hilbert(temp.Spike(counter,1:record_samples));
    
    % Calculate amplitude envelope and phase of Raw EEG stream of oscillations
    eeg.ampSpindle(counter,:)=abs(eeg.hilbertSpindle(counter,:));
    avg_Spindle(counter,:)=mean(eeg.ampSpindle(counter,:));
    sd_Spindle(counter,:)=std(eeg.ampSpindle(counter,:));
    
    eeg.ampTheta(counter,:)=abs(eeg.hilbertTheta(counter,:));
    avg_Theta(counter,:)=mean(eeg.ampTheta(counter,:));
    sd_Theta(counter,:)=std(eeg.ampTheta(counter,:));
    
    eeg.ampDelta(counter,:)=abs(eeg.hilbertDelta(counter,:));
    avg_Delta(counter,:)=mean(eeg.ampDelta(counter,:));
    sd_Delta(counter,:)=std(eeg.ampDelta(counter,:));
    
    eeg.ampSlow(counter,:)=abs(eeg.hilbertSlow(counter,:));
    avg_Slow(counter,:)=mean(eeg.ampSlow(counter,:));
    sd_Slow(counter,:)=std(eeg.ampSlow(counter,:));
    
    % calculate the length of smoothing function
    smooth_length_spindle(counter,:)=round((samplingrate/2000)*5000+1);
    smooth_length_theta(counter,:)=round((samplingrate/2000)*5000+1);
    smooth_length_delta(counter,:)=round((samplingrate/2000)*6000+1); % the span of the moving average must be odd
    smooth_length_slow(counter,:)=round((samplingrate/2000)*4500+1);
    
    % calculate zscore of the instantaneous amplitude of oscillations
    zscore.ampSpindle(counter,:)=( (eeg.ampSpindle(counter,:)-avg_Spindle(counter,:))/sd_Spindle(counter,:) );
    zscore.ampTheta(counter,:)=( (eeg.ampTheta(counter,:)-avg_Theta(counter,:))/sd_Theta(counter,:) );
    zscore.ampDelta(counter,:)=( (eeg.ampDelta(counter,:)-avg_Delta(counter,:))/sd_Delta(counter,:) );
    zscore.ampSlow(counter,:)=( (eeg.ampSlow(counter,:)-avg_Slow(counter,:))/sd_Slow(counter,:) );
    
    % smoothed instantaneous amplitude of osccilations
    zscore.ampSpindle_smooth(counter,:) = smooth(zscore.ampSpindle(counter,:),smooth_length_spindle(counter,:));
    zscore.ampTheta_smooth(counter,:) = smooth(zscore.ampTheta(counter,:),smooth_length_theta(counter,:));
    zscore.ampDelta_smooth(counter,:) = smooth(zscore.ampDelta(counter,:),smooth_length_delta(counter,:));
    zscore.ampSlow_smooth(counter,:) = smooth(zscore.ampSlow(counter,:),smooth_length_slow(counter,:));
end


%% output the stored discrete HFOs

output_hilbert.zsSpindle = tall(zscore.ampSpindle_smooth);
output_hilbert.zsTheta = tall(zscore.ampTheta_smooth);
output_hilbert.zsDelta = tall(zscore.ampDelta_smooth);
output_hilbert.zsSlow = tall(zscore.ampSlow_smooth);

output_hilbert.zSpindle = tall(zscore.ampSpindle);
output_hilbert.zTheta = tall(zscore.ampTheta);
output_hilbert.zDelta = tall(zscore.ampDelta);
output_hilbert.zSlow = tall(zscore.ampSlow);

output_hilbert.eeg.hSpindle=tall(eeg.hilbertSpindle);
output_hilbert.eeg.hTheta=tall(eeg.hilbertTheta);
output_hilbert.eeg.hDelta=tall(eeg.hilbertDelta);
output_hilbert.eeg.hSlow=tall(eeg.hilbertSlow);
output_hilbert.eeg.hSpike=tall(eeg.hilbertSpike);


