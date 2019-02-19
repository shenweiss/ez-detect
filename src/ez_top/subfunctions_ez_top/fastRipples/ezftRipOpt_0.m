function [varargout] = ezftRipOpt_0(eegList)

% Generate Wavelets
% eegList = eegListR(1:5e3,:);
% clearvars -except eegList eegListR t1* t2*
Fs = 2000;
N = size(eegList,2);
Neeg = size(eegList,1);
widthfR = 10;
gwidthfR = 4;
Results = {};

disp('Generating Wavelets...')

% % OPTION 1
freqfR = [150 600];
freqfR1 = [150 370];
freqfR2 = [371 600];
[A1 foi1 toi tapm1] = ezWavelet_single(1201,freqfR1, widthfR, gwidthfR);
[A2 foi2 toi tapm2] = ezWavelet_single(1201,freqfR2, widthfR, gwidthfR);


% % OPTION 2
% freqfR = [150 600];
% freqfR1 = [150 260];
% freqfR2 = [261 370];
% freqfR3 = [371 480];
% freqfR4 = [481 600];
% [A1 foi1 toi tapm1] = ezWavelet_single(1201,freqfR1, widthfR, gwidthfR);
% [A2 foi2 toi tapm2] = ezWavelet_single(1201,freqfR2, widthfR, gwidthfR);
% [A3 foi3 toi tapm3] = ezWavelet_single(1201,freqfR3, widthfR, gwidthfR);
% [A4 foi4 toi tapm4] = ezWavelet_single(1201,freqfR4, widthfR, gwidthfR);

% ftRip Optimization: Convolution Code Test 3
% Split eegListR up into 900 blocks and generate ALL tf plots
Nint = 900;
div = floor(Neeg/Nint);

disp('Performing Convolutions...')
cdatSet = zeros(451,1201,Neeg,'single');
% tic
for ii = 1:div
    b1 = (ii-1)*Nint+1;
    b2 = Nint*ii;
    
    % OPTION 1B
    [cdat1 toi foi1] = ezConv_single(eegList(b1:b2,:), A1, foi1, toi, tapm1);
    [cdat2 toi foi2] = ezConv_single(eegList(b1:b2,:), A2, foi2, toi, tapm2);
    cdatSet(:,:,b1:b2) = cat(1,cdat1,cdat2);
    clear cdat1 cdat2
    
%     % OPTION 2B
%     [cdat1 hdat vdat1] = ezConv_single(eegList(b1:b2,:), A1, foi1, toi, tapm1);
%     [cdat2 hdat vdat2] = ezConv_single(eegList(b1:b2,:), A2, foi2, toi, tapm2);
%     [cdat3 hdat vdat3] = ezConv_single(eegList(b1:b2,:), A3, foi3, toi, tapm3);
%     [cdat4 hdat vdat4] = ezConv_single(eegList(b1:b2,:), A4, foi4, toi, tapm4);
%     cdatSet(:,:,b1:b2) = cat(1,cdat1,cdat2,cdat3,cdat4);
%     clear cdat1 cdat2 cdat3 cdat4 vdat1 vdat2 vdat3 vdat4

%     disp(num2str(ii));
end
if Nint*div ~= Neeg
    b1 = Nint*div+1;
    b2 = Neeg;

    % OPTION 1B
    [cdat1 toi foi1] = ezConv_single(eegList(b1:b2,:), A1, foi1, toi, tapm1);
    [cdat2 toi foi2] = ezConv_single(eegList(b1:b2,:), A2, foi2, toi, tapm2);
    cdatSet(:,:,b1:b2) = cat(1,cdat1,cdat2);
    clear cdat1 cdat2
    
%     % OPTION 2B
%     [cdat1 hdat vdat1] = ezConv_single(eegList(b1:b2,:), A1, foi1, toi, tapm1);
%     [cdat2 hdat vdat2] = ezConv_single(eegList(b1:b2,:), A2, foi2, toi, tapm2);
%     [cdat3 hdat vdat3] = ezConv_single(eegList(b1:b2,:), A3, foi3, toi, tapm3);
%     [cdat4 hdat vdat4] = ezConv_single(eegList(b1:b2,:), A4, foi4, toi, tapm4);
%     cdatSet(:,:,b1:b2) = cat(1,cdat1,cdat2,cdat3,cdat4);

end
% t1b = toc

% OPTION 2C
% vdat = [vdat1 vdat2 vdat3 vdat4];
% tapm1 = cat(1,tapm1,tapm2);
% tapm2 = cat(1,tapm3,tapm4);

disp('Topographical Analysis...')
parfor ii = 1:Neeg
    cdat = cdatSet(:,:,ii);
    eeg = eegList(ii,:);
    Results{ii,1} = ezftRipInt_0(eeg,cdat,toi,[foi1 foi2],0);
end

varargout{1} = Results;
if nargout == 2
    [A.A1 A.A2] = gather(A1, A2);
    A.foi1 = foi1;
    A.foi2 = foi2;
    A.toi = toi;
    [A.tapm1 A.tapm2] = gather(tapm1, tapm2);
    varargout{2} = A;
end

disp('Fast Ripple Complete')