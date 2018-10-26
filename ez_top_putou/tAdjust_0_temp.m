function [Event] = tAdjust_0_temp(Event, file_data, opt)
% tAdjust_0.m by Zachary J. Waldman
% 
% Adjusts the start and stop times given by zRipAlpha_0.m, from clip time 
% stamps, to overall eeg time stamps.
% Input:
%   Event       =   Event Structure, must contain the following fields:
%                   channels, start_t, finish_t. Each are described in
%                   result2struct.m.
%   file_data   =   Original file data from ICA detector
%   opt         =   0 if analyzing ripple associated data, 1 if analyzing
%                   fast ripple associated data.
% Output
%   Event       =   Event Structure, containing modified start_t and 
%                   finish_t fields.

if opt == 0
    for ii = 1:size(Event.channel,1)
        % Clips which are greater than 1200 samples in length
        abs_tStart = file_data.ripple_clip_abs_t{Event.channel(ii,1),Event.channel(ii,2)}(1);
        Event.start_t(ii,1) = Event.start_t(ii,1) + abs_tStart;
        Event.finish_t(ii,1) = Event.finish_t(ii,1) + abs_tStart;
    end
elseif opt == 1
    for ii = 1:size(Event.channel,1)
        % Clips which are greater than 1200 samples in length
        abs_tStart = file_data.fripple_clip_abs_t{Event.channel(ii,1),Event.channel(ii,2)}(1);
        Event.start_t(ii,1) = Event.start_t(ii,1) + abs_tStart;
        Event.finish_t(ii,1) = Event.finish_t(ii,1) + abs_tStart;
    end
end