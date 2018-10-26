%
% function to find maxima and minima of time series

% inflections: finds all inflection points of the time series,
% ie both maxima and minima
% defined by slope changing sign
% returns index of points found
% optional argument "interval" specifies window of interest

function [peaks] = find_inflections (timeseries, peaktype, interval, slope_threshold)

peaks = [];
if nargin < 1
    warning ('Usage: find_inflections <time series vector> ["maxima"|"minima"|"both"],[<time interval of interest ([pstart end])>], [slope threshold]');
    return;
end

if nargin < 2 || isempty(peaktype)
    peaktype = 'both';
end

if nargin < 3 || isempty(interval)
    interval = [1 length(timeseries)];
end

if nargin < 4 || isempty(slope_threshold)
    slope_threshold = 0;
end

%num2str(timeseries)
firstderiv = diff(timeseries(interval(1):interval(2)));
positive_slope = find (firstderiv >= slope_threshold);
%num2str(positive_slope)
sign_slope = zeros (1,length(firstderiv));
sign_slope(positive_slope) = 1;
%num2str(sign_slope)
sign_changes = diff(sign_slope);

switch peaktype
    case 'both'
        % if finding both positive and negative inflections,
        % look for any nonzero sign changes
        sign_changes = abs(sign_changes);
        peaks = find(sign_changes > 0) + 1;
    case 'maxima'
        peaks = find(sign_changes < 0) + 1;
    case 'minima'
        peaks = find(sign_changes > 0) + 1;
end
        
end



