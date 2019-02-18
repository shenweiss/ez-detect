function [Spikes] = ezSpikeOpt_0(varargin)

if nargin == 1;
    eegList = varargin{1};
    tC = 0.3;
elseif nargin == 2;
    eegList = varargin{1};
    tC = varargin{2};
end

N = size(eegList,2);
Neeg0 = size(eegList,1);
if Neeg0 == 1
    eegList = [eegList; zeros(1,N)];
end
Fs = 2000;
t = [1:N]/Fs;

fmin = 30;
fmax = 80;
omega = 4;

tBuf1 = 0.1;
tEdge = 0.03;

gSize = 700;
foi = [80 240];
nCont = 50;

thresh_m = 0.0257;
thresh_b = 0.7874;

% Generate Unprocessed TF Plot
preTF = ezSpike_PreTF_0_single(eegList);
if size(eegList,1) == 1
    preTF = permute(preTF,[1 3 2]);
end

% Increase Frequency Resolution via Interpolation
%   3D Interpolation on GPU, Linear instead of Cubic

disp('Interpolating...')
% Nint = 500;
% Nint = 800;
Nint = 1200;
[Nf gSize Neeg] = size(preTF);
div = floor(Neeg/Nint);
cdatSet = single(zeros(Nf*floor(gSize/Nf),gSize,Neeg));
for ii = 1:div
    b1 = (ii-1)*Nint+1;
    b2 = b1+floor(Nint/2);
    b3 = Nint*ii;
    [cdat] = ezInterp3D_single(preTF(:,:,b1:b3));
    cdatSet(:,:,b1:b3) = gather(cdat);
    clear cdat
end
clear cdat
if div*Nint ~= Neeg
    b1 = div*Nint+1;
    [cdat] = ezInterp3D_single(preTF(:,:,b1:end));
    cdatSet(:,:,b1:end) = gather(cdat);
end        
clear cdat preTF
if Neeg0 == 1;
    cdatSet(:,:,2) = [];
    Neeg = 1;
end

% disp('TF Plots Complete')
% toc
vdat = linspace(fmin,fmax,size(cdatSet,1));
hdat = linspace(0,size(eegList,2)/Fs,size(cdatSet,2));

% Spike Topographical Analysis
disp('TF-Plot Analysis...')
parfor ii = 1:Neeg
    cdat = cdatSet(:,:,ii);
    Spikes(ii,:) = ezSpikeInt_0(hdat,vdat,cdat);
end
disp('Spikes Complete')