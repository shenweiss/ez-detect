% defining epochs of oscillations after hilbert transform

function [output_hilbert] = zhilbert_test1011(eeg, output_bpFIR, samplingrate);

output_hilbert = [];
ueeg = [];
zscore = [];

num_channels=numel(eeg(:,1));
record_samples=numel(eeg(1,:));
temp.Spindle=gather(output_bpFIR.ueeg.bpSpindle(:,1:record_samples));
temp.Theta=gather(output_bpFIR.ueeg.bpTheta(:,1:record_samples));
temp.Delta=gather(output_bpFIR.ueeg.bpDelta(:,1:record_samples));
temp.Slow=gather(output_bpFIR.ueeg.bpSlow(:,1:record_samples));
    
for counter=1:num_channels
    % Apply Hilbert transform to Raw EEG stream of oscillations
    ueeg.hilbertSpindle(counter,:)=hilbert(temp.Spindle(counter,1:record_samples));
    ueeg.hilbertTheta(counter,:)=hilbert(temp.Theta(counter,1:record_samples));
    ueeg.hilbertDelta(counter,:)=hilbert(temp.Delta(counter,1:record_samples));
    ueeg.hilbertSlow(counter,:)=hilbert(temp.Slow(counter,1:record_samples));
    
    % Calculate amplitude envelope and phase of Raw EEG stream of oscillations
    ueeg.ampSpindle(counter,:)=abs(ueeg.hilbertSpindle(counter,:));
    avg_Spindle(counter,:)=mean(ueeg.ampSpindle(counter,:));
    sd_Spindle(counter,:)=std(ueeg.ampSpindle(counter,:));
    
    ueeg.ampTheta(counter,:)=abs(ueeg.hilbertTheta(counter,:));
    avg_Theta(counter,:)=mean(ueeg.ampTheta(counter,:));
    sd_Theta(counter,:)=std(ueeg.ampTheta(counter,:));
    
    ueeg.ampDelta(counter,:)=abs(ueeg.hilbertDelta(counter,:));
    avg_Delta(counter,:)=mean(ueeg.ampDelta(counter,:));
    sd_Delta(counter,:)=std(ueeg.ampDelta(counter,:));
    
    ueeg.ampSlow(counter,:)=abs(ueeg.hilbertSlow(counter,:));
    avg_Slow(counter,:)=mean(ueeg.ampSlow(counter,:));
    sd_Slow(counter,:)=std(ueeg.ampSlow(counter,:));
    
    % calculate the length of smoothing function
    smooth_length_spindle(counter,:)=round((samplingrate/2000)*5000+1);
    smooth_length_theta(counter,:)=round((samplingrate/2000)*5000+1);
    smooth_length_delta(counter,:)=round((samplingrate/2000)*6000+1); % the span of the moving average must be odd
    smooth_length_slow(counter,:)=round((samplingrate/2000)*4500+1);
    
    % calculate zscore of the instantaneous amplitude of oscillations
    zscore.ampSpindle(counter,:)=( (ueeg.ampSpindle(counter,:)-avg_Spindle(counter,:))/sd_Spindle(counter,:) );
    zscore.ampTheta(counter,:)=( (ueeg.ampTheta(counter,:)-avg_Theta(counter,:))/sd_Theta(counter,:) );
    zscore.ampDelta(counter,:)=( (ueeg.ampDelta(counter,:)-avg_Delta(counter,:))/sd_Delta(counter,:) );
    zscore.ampSlow(counter,:)=( (ueeg.ampSlow(counter,:)-avg_Slow(counter,:))/sd_Slow(counter,:) );
    
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

output_hilbert.ueeg.hSpindle=tall(ueeg.hilbertSpindle);
output_hilbert.ueeg.hTheta=tall(ueeg.hilbertTheta);
output_hilbert.ueeg.hDelta=tall(ueeg.hilbertDelta);
output_hilbert.ueeg.hSlow=tall(ueeg.hilbertSlow);



