function [struct] = result2struc_temp(struct, results, chan);
% result2struc.m by Zachary J. Waldman
% 
% Using the results generated by the above functions, result2struc formats 
% the results to the desired event structures. Which event structure is 
% determined by the zRipAlpha_0 and zSpikeAlpha_0 results.
% Input:
%   struct:     =   event structure, which may or may not contain the 
%                   following fields, for n events:
%       channel:    nx2 double array, 1st column being channel,
%                   2nd column being clip index.
%       freq_av:    nx1 double array, power weighted mean frequency.
%       freq_pk:    nx1 double array, frequency at peak power magnitude
%       power_av:   nx1 double array, mean power magnitude
%       power_pk:   nx1 double array, peak power magnitude
%       duration:   nx1 double array, event duration
%       start_t:    nx1 double array, event start time
%       finish_t:   nx1 double array, event end time
%       
%	results:    [{det} {avFreq} {pkFreq} {avMag} {pkMag} {tDur} {tStart} {tEnd}];
%       det     =   detector determination value (no units).
%       avFreq  =   power weighted mean frequency (Hz).
%       pkFreq  =   frequency at peak power magnitude (no units).
%       avMag   =   average power magnitude (no units).
%       pkMag   =   peak power magnitude (no units).
%       tDur    =   event duration, (seconds).
%       tStart  =   event start time relative to clip, (seconds)
%       tEnd    =   event end time relative to clip, (seconds)
% 
%   chan:       =   channel and clip index as recorded in the eegList.
%
% Output:
%   struct      =   event structure, which contains all of the fields
%                   listed in the input struct.

struct.channel = [struct.channel; chan];
struct.freq_av = [struct.freq_av; results{1,2}];
struct.freq_pk = [struct.freq_pk; results{1,3}];
struct.power_av = [struct.power_av; results{1,4}];
struct.power_pk = [struct.power_pk; results{1,5}];
struct.duration = [struct.duration; results{1,6}];
struct.start_t = [struct.start_t; results{1,7}];
struct.finish_t = [struct.finish_t; results{1,8}];