function [varargout] = tfdatmat2(cfg, input) %,zlim)


% cfg = [];
% zlimit = zlim;

% if nargin == 2
%     input = varargin{1};
%     zlimit = varargin{2};
%     fig = [];
%     cfg.colormap = colormap(jet);
% elseif nargin == 3
%     input = varargin{1};
%     zlimit = varargin{2};
%     fig = varargin{3};
%     cfg.colormap = colormap(jet);
% elseif nargin == 4
%     input = varargin{1};
%     zlimit = varargin{2};
%     fig = varargin{3};
%     col = varargin{4};
%     cfg.colormap = colormap(col);
% end

% if length(zlimit) == 1;
%     cfg.zlim         = [0 zlimit];         % Power Spectrum of interest
% elseif length(zlimit) == 2;
%     cfg.zlim         = zlimit;         % Power Spectrum of interest
% end
     
% cfg.baseline     = input.time;     % What times used to determine baseline correction
% cfg.baselinetype = 'absolute';      % Baseline type
% cfg.interactive = 'no';
% cfg.maskstyle    = 'saturation';	

if isfield(input,'xlim');
    cfg.xlim = input.xlim;
end

cfg.channel     = input.chan;
% cfg.channel = input.

% cfg.colormap    = colormap(jet);

data = input.data;

% these are used by the ft_preamble/ft_postamble function and scripts
ft_revision = '$Id$';
ft_nargin   = 2;
ft_nargout  = 0;
    
% do the general setup of the function
ft_defaults
ft_preamble init
% ft_preamble debug
% ft_preamble provenance
ft_preamble trackconfig

% cfg
cfg = ft_checkconfig(cfg, 'unused',      {'cohtargetchannel'});
cfg = ft_checkconfig(cfg, 'renamed',     {'matrixside',     'directionality'});
% cfg = ft_checkconfig(cfg, 'renamedval',  {'zlim', 'absmax', 'maxabs'});
cfg = ft_checkconfig(cfg, 'renamedval',  {'directionality', 'feedforward', 'outflow'});
cfg = ft_checkconfig(cfg, 'renamedval',  {'directionality', 'feedback',    'inflow'});
cfg = ft_checkconfig(cfg, 'renamed',     {'channelindex',   'channel'});
cfg = ft_checkconfig(cfg, 'renamed',     {'channelname',    'channel'});
cfg = ft_checkconfig(cfg, 'renamed',     {'cohrefchannel',  'refchannel'});
cfg = ft_checkconfig(cfg, 'renamed',	   {'zparam',         'parameter'});
cfg = ft_checkconfig(cfg, 'deprecated',  {'xparam',         'yparam'});
            
% Set the defaults:
cfg.baseline       = ft_getopt(cfg, 'baseline',     'no');
cfg.baselinetype   = ft_getopt(cfg, 'baselinetype', 'absolute');
cfg.trials         = ft_getopt(cfg, 'trials',       'all', 1);
cfg.xlim           = ft_getopt(cfg, 'xlim',         'maxmin');
cfg.ylim           = ft_getopt(cfg, 'ylim',         'maxmin');
% cfg.zlim           = ft_getopt(cfg, 'zlim',         'maxmin');
cfg.fontsize       = ft_getopt(cfg, 'fontsize',      8);
cfg.colorbar       = ft_getopt(cfg, 'colorbar',     'yes');
cfg.interactive    = ft_getopt(cfg, 'interactive',  'yes');
cfg.hotkeys        = ft_getopt(cfg, 'hotkeys',      'no');
cfg.renderer       = ft_getopt(cfg, 'renderer',      []);
cfg.maskalpha      = ft_getopt(cfg, 'maskalpha',     1);
cfg.maskparameter  = ft_getopt(cfg, 'maskparameter', []);
cfg.maskstyle      = ft_getopt(cfg, 'maskstyle',    'opacity');
cfg.channel        = ft_getopt(cfg, 'channel',      'all');
cfg.masknans       = ft_getopt(cfg, 'masknans',     'yes');
cfg.directionality = ft_getopt(cfg, 'directionality',[]);
cfg.figurename     = ft_getopt(cfg, 'figurename',    []);
cfg.parameter      = ft_getopt(cfg, 'parameter', 'powspctrm');

dimord = data.dimord ;
%       = 'chan_freq_time'
dimtok = {'chan' 'freq' 'time'};
%       = 1x3 cell
xparam = 'time';
yparam = 'freq';
% 
cfg.channel = ft_channelselection(cfg.channel, data.label);
%       MEANING: (cfg.channel = 'all') 
%                   --> (cfg.channel = 8x1 cell = 'chan 1' ... 'chan 8'
% 
hasrpt = any(ismember(dimtok, {'rpt' 'subj'}));
%       MEANING: % check whether rpt/subj is present and remove if necessary and whether
%       hasrpt = 0
% 
selchan = strmatch('chan', dimtok);       
isfull  = length(selchan)>1;              
%       MEANING: Check for bivariate metric with 'chan_chan' in the dimord
%                   selchan = 1
%                   isfull = 0
haslabelcmb = isfield(data, 'labelcmb');  % haslabelcmb = 0
%       MEANING: Check for bivariate metric with a labelcmb
%                   haslabelcmb = 0
% 
% APPLY BASELINE CORRECTION
data = ft_freqbaseline(cfg, data);
% 
% X-AXIS TIME RANGE
if strcmp(cfg.xlim,'maxmin')
  xmin = min(data.(xparam));
  xmax = max(data.(xparam));
else
  xmin = cfg.xlim(1);
  xmax = cfg.xlim(2);
end
%       MEANING: xmin = min(data.time)
%                xmax = max(data.time)
xmin = nearest(data.(xparam), xmin);
xmax = nearest(data.(xparam), xmax);
%       MEANING: Find index of value closest to xmin/xmax. NOTE: nearest is
%       a FieldTrip function, not matlab.
% 
% Y-AXIS FREQUENCY RANGE
ymin = min(data.(yparam));
ymax = max(data.(yparam));
%       MEANING: ymin/ymax = min/max(data.freq)
ymin = nearest(data.(yparam), ymin);
ymax = nearest(data.(yparam), ymax);
%        
% CHANNEL SELECTION
selchannel = ft_channelselection(cfg.channel, data.label);
%       MEANING: selchannel = only the strings in BOTH cfg.channel and data.label
sellab     = match_str(data.label, selchannel);
%       MEANING: sellab = indices of dat.label strings which match
%       selchannel strings.
% 
% GET DIMORD DIMENSIONS
ydim = find(strcmp(yparam, dimtok));
%       MEANING: Determine index of dimtok containing 'freq'
xdim = find(strcmp(xparam, dimtok));
%       MEANING: Determine index of dimtok containing 'time'
zdim = setdiff(1:length(dimtok), [ydim xdim]); % all other dimensions
%       MEANING: Determine remaining index of dimtok
% 
% PERMUTE
dat = data.(cfg.parameter);
%       dat = data_freq.powspctrm
dat = permute(dat, [zdim(:)' ydim xdim]);
%       dat = permute(dat, [1 2 3]; i.e. This command does nothing
dat = dat(sellab, ymin:ymax, xmin:xmax);
%       dat = dat(selected cahnnels, :, :); i.e. This command does nothing
siz        = size(dat);
%       siz contains the dimensions of dat
datamatrix = reshape(mean(dat, 1), [siz(2:end) 1]);
%       MEANING: Averages 8 trials, changing that dim 
%       from 8 to 1.  Reshapes datamatrix so x and y are the 1st 2 
%       dimensions while z, being 1, is the 3rd. Equivalent to:
%           datamatrix = permute(mean(dat,1), [2 3 1]);
%           
xvector    = data.(xparam)(xmin:xmax);
yvector    = data.(yparam)(ymin:ymax);
%       xvector = data.time;
%       yvector = data.freq;
% 
% Z-AXIS COLOR VALUE RANGE
% zmin = cfg.zlim(1);
% zmax = cfg.zlim(2);

hdat = xvector;
vdat = yvector;
cdat = datamatrix;

% Set previously optional input arguments
hlim           = [min(hdat) max(hdat)];
vlim           = [min(vdat) max(vdat)];
hpos           = (hlim(1)+hlim(2))/2;
vpos           = (vlim(1)+vlim(2))/2;
width          = hlim(2)-hlim(1);
width = width * length(hdat)/(length(hdat)-1);
height         = vlim(2)-vlim(1);
height = height * length(vdat)/(length(vdat)-1);

% first shift the horizontal axis to zero
hdat = hdat - (hlim(1)+hlim(2))/2;
% then scale to length 1
hdat = hdat ./ (hlim(2)-hlim(1));
% then scale to compensate for the patch size
hdat = hdat * (length(hdat)-1)/length(hdat);
% then scale to the new width
hdat = hdat .* width;
% then shift to the new horizontal position
hdat = hdat + hpos;

% first shift the vertical axis to zero
vdat = vdat - (vlim(1)+vlim(2))/2;
% then scale to length 1
vdat = vdat ./ (vlim(2)-vlim(1));
% then scale to compensate for the patch size
vdat = vdat * (length(vdat)-1)/length(vdat);
% then scale to the new width
vdat = vdat .* height;
% then shift to the new vertical position
vdat = vdat + vpos;

varargout{1} = cdat;
varargout{2} = hdat;
varargout{3} = vdat;