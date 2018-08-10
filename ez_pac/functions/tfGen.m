function [varargout] = tfGen(eeg, Fs, freq, width);
% eeg = eeg_gn{1,1};
% Fs = 2000;
% freq = [50 250];

% NOTE: 
%     For ripples:          width = [5 7] 
%     For Fast Ripples:     width = [4 10]


global ft_default
ft_default.showcallinfo = 'no';
warning('off')
t = (1: length(eeg))/Fs;
% Define Event Start/Stop Times
dt = [t(1) t(end)];

% Preprocessing
cfg = [];

cfg.showcallinfo = 'no';            % Suppress Output
cfg.demean = 'yes';                 % Baseline correction

% Create Data Structure
data = [];
data.trial{1,1} = eeg;          % 1 trial containing 8 channels
data.time{1,1} = t;             % Assign spike time vector
data.sampleinfo = [find(t==dt(1)) find(t==dt(2))];      % start stop indicies of spike within original data
data.fsample = Fs;                  % Assign sampling frequency
data.label{1,1} = 'all';

% Execute Preprocessing
cfg.feedback = 'none';
[data_proc] = ft_preprocessing(cfg, data);  % Bandpass filtered and baseline corrected data

% Time Frequency Analysis
cfg = [];
cfg.showcallinfo = 'no';            % Suppress Output

% Specify Freq of Interest
cfg.foi = [freq(1):freq(2)];
cfg.method      = 'tfr';        % Method of Analysis
    cfg.gwidth      = width(1);
    cfg.width       = width(2);
cfg.output      = 'pow';        % Power spectrum (try without)
cfg.taper       = 'hanning';    % Tapering Window(try without)
cfg.pad         = 'nextpow2';

% Times of interest 
cfg.toi = t;

% Execute Frequency Analysis
cfg.feedback = 'no';
data_freq = ft_freqanalysis(cfg, data_proc);

input = [];
input.data = data_freq;
input.chan = 'all';
input.time = dt;
input.xlim = [0 t(end)];  

% [cdat, hdat, vdat] = tfdatmat2(cfg, input);
[cdat, hdat, vdat] = tfdatmat(input);

if nargout >= 1
    varargout{1} = cdat;
    if nargout >= 2
        varargout{2} = hdat;
        if nargout == 3
            varargout{3} = vdat;
        end
    end
end
