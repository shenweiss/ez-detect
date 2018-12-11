function [wpli, v, n] = wpli(eeg)

siz = size(eeg);
n = siz(1);
if n>1
  input    = imag(eeg);          % make everything imaginary  
  outsum   = nansum(eeg,1);      % compute the sum; this is 1 x size(2:end)
  outsumW  = nansum(abs(eeg),1); % normalization of the WPLI
  if debias
    outssq   = nansum(eeg.^2,1);
    wpli     = (eeg.^2 - eeg)./(eeg.^2 - eeg); % do the pairwise thing in a handy way
  else
    eeg     = outsum./outsumW; % estimator of E(Im(X))/E(|Im(X)|)
  end    
  wpli = reshape(wpli,siz(2:end)); % remove the first singular dimension
else
  wpli = NaN(siz(2:end)); % for one observation, we should return NaNs
end

[leave1outsum, leave1outssq] = deal(zeros([1 siz(2:end)]));
  % compute the sem here 
  n = sum(~isnan(eeg),1); % this is the actual df when nans are found in the input matrix
  v = (n-1).^2.*(leave1outssq - (leave1outsum.^2)./n)./(n - 1); % 11.5 efron, sqrt and 1/n done in ft_connectivityanalysis
  v = reshape(v,siz(2:end)); % remove the first singular dimension   
  n = reshape(n,siz(2:end));  
