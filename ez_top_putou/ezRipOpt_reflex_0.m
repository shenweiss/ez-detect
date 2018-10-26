function [ResultsR_reflex] = ezRipOpt_reflex_0(eegList,A0)

A = A0.A;
foi = A0.foi;
toi = A0.toi;
tapm = A0.tapm;
clear A0

Fs = 2000;
N = size(eegList,2);
Neeg = size(eegList,1);

freqR = [50 250];
% freqR1 = [freqR(1) floor(diff(freqR)/2)+freqR(1)];
% freqR2 = [floor(diff(freqR)/2)+freqR(1)+1 freqR(2)];
widthR = 7;
gwidthR = 5;
ResultsR_reflex = {};

% Split eegListR up into 900 blocks and generate ALL tf plots
Nint = 1200;
div = floor(Neeg/Nint);

disp('Performing Convolutions...')
cdatSet = single(zeros(201,1201,Neeg));
for ii = 1:div
% for ii = 1
    b1 = (ii-1)*Nint+1;
    b2 = Nint*ii;
    [cdat hdat vdat] = ezConv_single(eegList(b1:b2,:),A,foi,toi,tapm);
    cdatSet(:,:,b1:b2) = cdat;
    clear cdat
end
if div*Nint ~= Neeg
    b1 = div*Nint+1;
    [cdat hdat vdat] = ezConv_single(eegList(b1:end,:),A,foi,toi,tapm);
    cdatSet(:,:,b1:end) = cdat;
    clear cdat
end        
% vdat = [vdat1 vdat2];
parfor ii = 1:Neeg
    cdat = double(cdatSet(:,:,ii));
    eeg = eegList(ii,:);
    ResultsR_reflex{ii,1} = ezRipInt_reflex_0(eeg,cdat,hdat,vdat,0);
end
disp('Ripple Reflex Complete')
% varargout{1} = ResultsR_reflex;
