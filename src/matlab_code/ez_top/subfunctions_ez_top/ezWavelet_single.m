function [wavelet, freqoi, timeoi, tapM] = ezWavelet_single(eeg, freq, width, gwidth)
% clearvars -except daughter eegListR eeg eeg0 fileData freq Fs gwidth N width
% gpuDevice(1)
% freq = [50 250];
% freq = [150 600];
% N = 1201;       % Trial Length
% Fs = 2000;      % Sampling Rate
% width = 7;
% gwidth = 5;
% width = 10;
% width = 3;
% gwidth = 4;

Fs = 2000;
if length(eeg) == 1
    N = eeg;
else
    N = size(eeg,2);
end
nPad = (N-1)/2;

padding = 2^nextpow2(max(N));
pad = padding/Fs;

oldfoi = freq(1):freq(2);
fboi   = round(oldfoi .* pad) + 1;
newfoi = (fboi-1) ./ pad; % boi - 1 because 0 Hz is included in fourier output
width = ones(1,size(newfoi,2))*width;
wavelet = complex(single(zeros(N,N,size(newfoi,2))));

% aa = gpuArray(complex(zeros(N,N)));
% parfor ifreqoi = 1:nfreqoi

% Time Of Interest (CHECK THIS LATER)
% % Set timeboi and timeoi
% timeoiinput = timeoi;
% offset = round(time(1)*fsample);
% 
% timeoi   = unique(round(timeoi .* fsample) ./ fsample);
% timeboi  = round(timeoi .* fsample - offset) + 1;
% ntimeboi = length(timeboi);
% %%%%%%%%% ADDED BY ZW %%%%%%%%%
% timeoi = round(timeoi,15);
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
wav0 = [];
dt = 1/Fs;
tapM = logical(zeros(size(newfoi,2),N));
parfor ii = 1:size(newfoi,2)
  sf = newfoi(ii) / width(ii);
  st = 1/(2*pi*sf);
  toi2 = -gwidth*st:dt:gwidth*st;
  A = 1/sqrt(st*sqrt(pi));
  tap = single((A*exp(-toi2.^2/(2*st^2)))');
  acttapnumsmp = size(tap,1);
  taplen(ii) = acttapnumsmp;
  ins = ceil(padding./2) - floor(acttapnumsmp./2);
  
  % produce angle with convention: cos must always be 1  and sin must always be centered in upgoing flank, so the centre of the wavelet (untapered) has angle = 0
  ind  = (-(acttapnumsmp-1)/2 : (acttapnumsmp-1)/2)'   .*  ((2.*pi./Fs) .* newfoi(ii));
  
  % create wavelet and fft it
%   wav = tap.*exp(i.*ind);
  wav = complex(vertcat(tap.*cos(ind)), vertcat(tap.*sin(ind)));
  lpad = N - taplen(ii);
  lpad2 = floor(lpad/2);
  mod1 =  mod(N+1,2)*mod(lpad,2);
  mod2 = mod(N,2)*(mod(lpad,2));
  wav0 = [zeros(lpad2+mod1,1); wav; zeros(lpad2+mod2,1)];
  wav02(:,ii) = wav0;
%   wavelet(:,ii) = [zeros(lpad2+mod1,1); wav; zeros(lpad2+mod2,1)];
  
  aa = convmtx(wav0.',1201);
  wavelet(:,:,ii) = aa(:,nPad+1:nPad+N,1);
  tapm = logical(zeros(1,N));   %%%%%
  tapm(1,[1:N] >= taplen(ii)/2 & [1:N] < (N-taplen(ii)/2)) = 1;
  tapM(ii,:) = tapm;
end

freqoi = newfoi;
timeoi = [1:N]/Fs;
