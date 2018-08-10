function [ResultsfR_ref] = ezftRipOpt_reflex_0(eegList,A)

A1 = single(A.A1);
A2 = single(A.A2);
foi1 = A.foi1;
foi2 = A.foi2;
toi = A.toi;
tapm1 = A.tapm1;
tapm2 = A.tapm2;
clear A

% Generate Wavelets
% eegList = eegListR(1:5e3,:);
% clearvars -except eegList eegListR t1* t2*
% Fs = 2000;
% N = size(eegList,2);
Neeg = size(eegList,1);
ResultsfR_ref = {};

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
    
    % OPTION 2B
    [cdat1 toi foi1] = ezConv_single(eegList(b1:b2,:), A1, foi1, toi, tapm1);
    [cdat2 toi foi2] = ezConv_single(eegList(b1:b2,:), A2, foi2, toi, tapm2);
    cdatSet(:,:,b1:b2) = cat(1,cdat1,cdat2);
    clear cdat1 cdat2 

%     disp(num2str(ii));
end
if Nint*div ~= Neeg
    b1 = Nint*div+1;
    b2 = Neeg;
    [cdat1 toi foi1] = ezConv_single(eegList(b1:b2,:), A1, foi1, toi, tapm1);
    [cdat2 toi foi2] = ezConv_single(eegList(b1:b2,:), A2, foi2, toi, tapm2);
    cdatSet(:,:,b1:b2) = cat(1,cdat1,cdat2);
    clear cdat1 cdat2
end
% t1b = toc

disp('Topographical Analysis...')
parfor ii = 1:Neeg
    cdat = double(cdatSet(:,:,ii));
    eeg = eegList(ii,:);
    ResultsfR_ref{ii,1} = ezftRipInt_reflex_0(eeg,cdat,toi,[foi1 foi2],0);
end

disp('Fast Ripple Reflex Complete')