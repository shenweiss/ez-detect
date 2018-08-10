function wavelet = ezSpikeWavelet_single(eeg,Fs,fLim,omega)

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% clearvars -except eegListR fileData 
% eeg = eegListR;
% Fs = 2000;
% fmin = 30;
% fmax = 80;
% omega = 4;
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fmin = fLim(1);
fmax = fLim(2);

N = size(eeg,2);
Neeg = size(eeg,1);
wavelet.samp_rate = Fs;

dt      = 1/Fs;	
dj      = 0.1;
s0      = 1/(fmax+(0.1*fmax));    % the smallest resolvable scale
J1 = (log2(N*dt/s0))/dj;                  % [Eqn(10)] (J1 determines the largest scale)

eeg0 = eeg - mean(eeg,2);

%....construct wavenumber array used in transform [Eqn(5)]
k = [1:fix(N/2)];                               % k n/2 elembol all
k = k*((2*pi)/(N*dt));                  
k = [0, k, -k(fix((N-1)/2):-1:1)];              % k ismet n elembol all - angular frequency

%....compute FFT of the (padded) time series (DFT)
f = permute(fft(single(eeg0),[],2), [2 1 3]);                % [Eqn(3)]
    % TO ENSURE ROBUSTNESS: 
    %   Tested with 376830 clips (1201 samples)
    %   Ran Successfully
    %   GPU Memory Used: 3.62e9
    
%....construct SCALE array
scale = s0*2.^((0:J1)*dj);                      % [Eqn(9)]  (choice of scales to use in wavelet transform ([Eqn(9)]))
fourier_factor = (4*pi)/(omega + sqrt(2 + omega^2));  % Scale-->Fourier [Sec.3h]
cone_of_influence = fourier_factor/sqrt(2);                   % Cone-of-influence [Sec.3g]
period = fourier_factor*scale;

invperiod = 1./period;
xxx = min (find (invperiod < fmin));
period=fliplr(period(1:xxx));
scale=fliplr(scale(1:xxx));

scale1=scale;
fscale=size(period,2);

wave = complex(single(zeros(fscale, N, Neeg)));     % define the wavelet array

% ....loop through all scales and compute transform
expnt = -(scale1.'.*k - omega).^2/2.*(k > 0.);
norm = sqrt(scale1.'.*k(2))*(pi^(-0.25))*sqrt(N);

%%%%%%% SUCCESSFUL OPTIMIZATION ALGORITHM (TRIAL #1 & #3) %%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
daughter = permute(single(norm.*exp(expnt).*(k>0)),[2 1 3]);
f = repmat(permute(f,[1 3 2]),1,size(daughter,2),1);

%wave2 = pagefun(@times, f, daughter);
[n1,m1,P] = size(f);

wave2 = zeros(n1,m1,P);
for i=1:P
    wave2(:,:,i) = times(f(:,:,i), daughter);
end


clear f daughter
Nint = 2.85e3;          % Most efficient (trial & error)
div = floor(Neeg/Nint);
for ii = 1:div
    wave2_temp = permute(ifft(wave2(:,:,(ii-1)*Nint+1:ii*Nint)),[2,1,3]);
    wave(:,:,(ii-1)*Nint+1:ii*Nint) = wave2_temp;
    clear wave2_temp
end
if div*Nint ~= size(wave2,3)
    wave2_temp = permute(ifft(wave2(:,:,div*Nint+1:end)),[2,1,3]);
    wave(:,:,div*Nint+1:end) = wave2_temp;
    clear wave2_temp
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% clear wave2 wave2_temp 

% period = fourier_factor*scale1;                                 % az �jfajta, fourier frekvenci�knak megfelelo period
cone_of_influence = cone_of_influence*dt*[1E-5,1:((N+1)/2-1),fliplr((1:(N/2-1))),1E-5];   % COI [Sec.3g]

% wavelet.wave = wave;
wave =(((abs(wave)/24).^2)*1000)/Fs; 
corrected_wave = wave.*sqrt(1:fscale).';

wavelet.cone_of_influence = 1./cone_of_influence;
wavelet.frequencies = 1./period;
wavelet.corrected_amplitude = corrected_wave;
% wavelet.amplitude = wave;













