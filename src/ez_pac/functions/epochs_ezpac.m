                          
function [output_osc_epochs] = epochs_ezpac(num_channels, output_hilbert, samplingrate);

header=[];
annotation= [];
annotation_time = [];
annotation_duration = [];

% with the use of two z-amplitude thresholds
amp_thres1_theta = 0.48; %0.55
amp_thres2_theta = 0.45; %0.53

t_epoch_theta = {''};
t_epoch_spindle = {''};
t_epoch_delta = {''};
t_epoch_slow = {''};

% with the use of two z-amplitude thresholds
%% lowering the amp_thres1_spindle to capture spindle/theta events from the beginning
%amp_thres1_spindle = 0.5; then lowered to 0.4
%amp_thres2_spindle = 0.48; then lowered to 0.3
amp_thres1_spindle = 0.35;
amp_thres2_spindle = 0.3;

% amp_thres1_theta = 0.48;
% amp_thres2_theta = 0.45;
amp_thres1_theta = 0.4;
amp_thres2_theta = 0.35;

amp_thres1_slow = -0.2;
amp_thres2_slow = -0.3;

amp_thres1_delta = -0.4;
amp_thres2_delta = -0.6;

% with the duration cut off for each oscillation
%% increasing the duration cutoff to 1 sec
% durcut_spindle = 0.03;
% durcut_theta = 0.05;
durcut_spindle = 1;
durcut_theta = 1;

t_dur_spindle = {''};
t_dur_theta = {''};

t_start.spindle = [];
t_start.theta = [];

t_epoch.spindle = [];
t_epoch.theta = [];

durcut_delta = 0.5;
durcut_slow = 0.8;

t_dur_delta = {''};
t_dur_slow = {''};

t_start.delta = [];
t_start.slow = [];

t_epoch.delta = [];
t_epoch.slow = [];

counter_slow = zeros(num_channels,1);
counter_delta = zeros(num_channels,1);
counter_spindle = zeros(num_channels,1);
counter_theta = zeros(num_channels,1);

zscore.ampTheta_smooth = gather(output_hilbert.zsTheta);
zscore.ampSpindle_smooth = gather(output_hilbert.zsSpindle);
zscore.ampDelta_smooth = gather(output_hilbert.zsDelta);
zscore.ampSlow_smooth = gather(output_hilbert.zsSlow);

clear output_hilbert

for i = 1:num_channels
    
    flagged = 0;
    annotation_counter = 0;
    
    header = [];
    data = [];
    
    t_start.theta = [];
    t_dur.theta=0;
    t_start.spindle = [];
    t_dur.spindle=0;
    
    t_start.delta = [];
    t_dur.delta=0;
    t_start.slow = [];
    t_dur.slow=0;
    
    length_ieeg=numel(zscore.ampTheta_smooth(1,:))-2000;
    % theta epoch
    for j= 1:length_ieeg;
        
        if (flagged==0) && ((zscore.ampTheta_smooth(i,j) > amp_thres1_theta));
            t_start.theta = j;
            flagged = 1;
        end
        
        if (flagged == 1) && ((zscore.ampTheta_smooth(i,j) < amp_thres2_theta));
            
            t_dur.theta = (j-t_start.theta).*(1/samplingrate);
            if t_dur.theta> durcut_theta
                t_end.theta = j;
                
                % create cell array
                counter_theta(i) = counter_theta(i) + 1;
                %t_dur_theta{i,counter_theta(i)} = t_dur.theta;
                
                temp_array = t_start.theta:j;
                t_epoch.theta= horzcat(t_epoch.theta, temp_array);
                t_epoch_theta{i,1} = t_epoch.theta;
                flagged = 0;
                
            else
                flagged = 0;
            end
            
        end
        
    end
    
    if flagged == 1
        t_end.theta = j;
        
        % create cell array
        counter_theta(i) = counter_theta(i) + 1;
        %t_dur_theta{i,counter_theta(i)} = t_dur.theta
        
        temp_array = t_start.theta:j;
        t_epoch.theta= horzcat(t_epoch.theta, temp_array);
        t_epoch_theta{i,1} = t_epoch.theta;
        
        flagged = 0;
    end;
    
    % spindle epochs
    for j= 1:length_ieeg;
        if (flagged==0) & (zscore.ampSpindle_smooth(i,j) > amp_thres1_spindle);
            t_start.spindle = j;
            flagged = 1;
        end
        
        if (flagged == 1) & (zscore.ampSpindle_smooth(i,j) < amp_thres2_spindle);
            
            t_dur.spindle = (j-t_start.spindle).*(1/samplingrate);
            if t_dur.spindle> durcut_spindle
                t_end.spindle = j;
                
                %create cell array
                counter_spindle(i) = counter_spindle(i) + 1;
                %t_dur_spindle{i,counter_spindle(i)} = t_dur.spindle;
                                
                temp_array = t_start.spindle:j;
                t_epoch.spindle= horzcat(t_epoch.spindle, temp_array);
                t_epoch_spindle{i,1} = t_epoch.spindle;
                
                flagged = 0;
                
            else
                flagged = 0;
            end
            
        end
        
    end
    
    if flagged == 1
        t_end.spindle = j;
        
        %create cell array
        counter_spindle(i) = counter_spindle(i) + 1;
        %t_dur_spindle{i,counter_spindle(i)} = t_dur.spindle;
        
        temp_array = t_start.spindle:j;
        t_epoch.spindle= horzcat(t_epoch.spindle, temp_array);
        t_epoch_spindle{i,1} = t_epoch.spindle;
        flagged = 0;
    end;
    

    % delta epoch
    for j= 1:length_ieeg;
        
        if (flagged==0) & (zscore.ampDelta_smooth(i,j) > amp_thres1_delta);
            t_start.delta = j;
            flagged = 1;
        end
        
        if (flagged == 1) & ( zscore.ampDelta_smooth(i,j) < amp_thres2_delta)
            
            t_dur.delta = (j-t_start.delta).*(1/samplingrate);
            if t_dur.delta> durcut_delta
                t_end.delta = j;
                
                % create cell array
                counter_delta(i) = counter_delta(i) + 1;
                %t_dur_delta{i,counter_delta(i)} = t_dur.delta; 
                
                temp_array = t_start.delta:j;
                t_epoch.delta= horzcat(t_epoch.delta, temp_array);
                t_epoch_delta{i,1} = t_epoch.delta;
                flagged = 0;
                
            else
                flagged = 0;
            end
            
        end
        
    end
    
    if flagged == 1
        t_end.delta = j;
        
        % create cell array
        counter_delta(i) = counter_delta(i) + 1;
        %t_dur_delta{i,counter_delta(i)} = t_dur.delta;
                
        temp_array = t_start.delta:j;
        t_epoch.delta= horzcat(t_epoch.delta, temp_array);
        t_epoch_delta{i,1} = t_epoch.delta;
        
        flagged = 0;
    end;
    
    %slow wave epochs
    for j= 1:length_ieeg;
        if (flagged==0) & (zscore.ampSlow_smooth(i,j) > amp_thres1_slow);
            t_start.slow = j;
            flagged = 1;
        end
        
        if (flagged == 1) & ( zscore.ampSlow_smooth(i,j) < amp_thres2_slow)
            
            t_dur.slow = (j-t_start.slow).*(1/samplingrate);
            if t_dur.slow> durcut_slow
                t_end.slow = j;
                
                %create cell array
                counter_slow(i) = counter_slow(i)+ 1;
                %t_dur_slow{i,counter_slow(i)} = t_dur.slow;
                
                temp_array = t_start.slow:j;
                t_epoch.slow= horzcat(t_epoch.slow, temp_array);
                t_epoch_slow{i,1} = t_epoch.slow;
                flagged = 0;
                
            else
                flagged = 0;
            end
            
        end
        
    end
    
    if flagged == 1
        t_end.slow = j;
        
        %create cell array
        counter_slow(i) = counter_slow(i) + 1;
        %t_dur_slow{i,counter_slow(i)} = t_dur.slow;
                
        temp_array = t_start.slow:j;
        t_epoch.slow= horzcat(t_epoch.slow, temp_array);
        t_epoch_slow{i,1} = t_epoch.slow;
        flagged = 0;
    end;
    
    t_epoch.slow = [];
    t_epoch.delta = [];
    t_epoch.spindle = [];
    t_epoch.theta = [];
    
    
end

clearvars -except counter_delta counter_theta counter_spindle counter_slow t_epoch_delta t_epoch_theta t_epoch_spindle t_epoch_slow

output_osc_epochs.counter_delta=tall(counter_delta);
output_osc_epochs.counter_theta=tall(counter_theta);
output_osc_epochs.counter_spindle=tall(counter_spindle);
output_osc_epochs.counter_slow=tall(counter_slow);

output_osc_epochs.t_epoch_delta=tall(t_epoch_delta);
output_osc_epochs.t_epoch_theta=tall(t_epoch_theta);
output_osc_epochs.t_epoch_spindle=tall(t_epoch_spindle);
output_osc_epochs.t_epoch_slow=tall(t_epoch_slow);

