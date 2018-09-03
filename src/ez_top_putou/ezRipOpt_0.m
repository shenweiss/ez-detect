function [varargout] = ezRipOpt_0(eegList)

Fs = 2000;
N = size(eegList,2);
Neeg = size(eegList,1);

freqR = [50 250];
% freqR1 = [freqR(1) floor(diff(freqR)/2)+freqR(1)];
% freqR2 = [floor(diff(freqR)/2)+freqR(1)+1 freqR(2)];
widthR = 7;
gwidthR = 5;
Results = {};

disp('Generating Wavelets...')
[A foi toi tapm] = ezWavelet_single(1201,freqR, widthR, gwidthR);
% [A1 foi1 toi1 tapm1] = ezWavelet(1201,freqR1, widthR, gwidthR);
% [A2 foi2 toi2 tapm2] = ezWavelet(1201,freqR2, widthR, gwidthR);

% Split eegListR up into 900 blocks and generate ALL tf plots
% Nint = 500;
Nint = 1200;
div = floor(Neeg/Nint);

disp('Performing Convolutions...')
cdatSet = single(zeros(201,1201,Neeg));
for ii = 1:div
% for ii = 1
    b1 = (ii-1)*Nint+1;
    b2 = Nint*ii;
    [cdat toi foi] = ezConv_single(eegList(b1:b2,:),A,foi,toi,tapm);
    cdatSet(:,:,b1:b2) = cdat;
    clear cdat
end
if div*Nint ~= Neeg
    b1 = div*Nint+1;
    [cdat toi foi] = ezConv_single(eegList(b1:end,:),A,foi,toi,tapm);
    cdatSet(:,:,b1:end) = cdat;
    clear cdat
end        

parfor ii = 1:Neeg
    cdat = double(cdatSet(:,:,ii));
    eeg = eegList(ii,:);
    Results{ii,1} = ezRipInt_0(eeg,cdat,toi,foi,0);
end

varargout{1} = Results;
if nargout == 2
    A0.A = gather(A);
    A0.foi = foi;
    A0.toi = toi;
    A0.tapm = gather(tapm);
    varargout{2} = gather(A0);
end

disp('Ripple Complete')