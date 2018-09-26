%% this is just a temporal file to delete tall expression and call from python

%parameters eeg_data, chanlist, metadata, ez_montage, now loading from a temp .mat because of matlab.engine
% doesnt support python data types
function [ez_mp, ez_bp, metadata] = ez_lfbad(input_args_fname)
  load(input_args_fname); %temporal solution
  
  number_of_channels = numel(eeg_data(:,1));
  file_size = numel(eeg_data(1,:)); %check if the variable name is correct

  sixty_cycle = impedenceCheck(eeg_data, number_of_channels, file_size);
  zsixty_cycle = zscore_2(sixty_cycle);
  % To remove electrodes with very large sixty cycle artifact. 
  aFilter = (sixty_cycle>1e9)&(zsixty_cycle>0.3);%Leaves a 1 in index i if an element satisfies both conditions
  [a,imp] = find(aFilter); %detects the non zero indexes and outputs them as rows and columns indexes
  imp = unique(imp);%imp are column indexes. What are their semantic?

  % excludes 60 cycle channels (if too many channels removed this should be altered in version 7.1

  %% Calculate montages
  fprintf('Saving data as unipolar and bipolar montages\r') %?
  %Initialize output data structures
  
  eeg_bps.eeg_data=[];
  eeg_bps.chanlist={''};
  eeg_bp=[];
  eeg_mp.eeg_data=[];
  eeg_mp.chanlist={''};
  metadata.lf_bad={''}; % start building metadata
  metadata.bp_chanlist={''};
  metadata.m_chanlist={''};

  % Calculate bipolar montage for all channels
  counter_1=0;
  counter_2=0;
  counter_3=0;
 
  %name the conditions semantic
  %talk with sheenan to see this. Remove repetead code
  %indexes are strange, you may be overwriting cells.
  for j=1:number_of_channels
    columnIndexes_j_validation = ~ismember(j,imp); %improve name of this variable
    if ez_montage{j,3}~=0 && ez_montage{j,4}~=1 && columnIndexes_j_validation
      counter_1=counter_1+1;
      
      eeg_bp.eeg_data(counter_1,:)=eeg_data(j,:)-eeg_data(ez_montage{j,3},:);
      eeg_bp.chanlist(counter_1)=chanlist(j);
    end
     
    if ez_montage{j,2}==1
      if ez_montage{j,4}~=1 && columnIndexes_j_validation
        counter_2=counter_2+1;
        
        eeg_mp.eeg_data(counter_2,:)=eeg_data(j,:);  
        eeg_mp.chanlist(counter_2)=chanlist(j);
      end    
    else
      if ez_montage{j,3}~=0 && ez_montage{j,4}~=1 && columnIndexes_j_validation 
        counter_3=counter_3+1;
        eeg_bps.eeg_data(counter_3,:)=eeg_data(j,:)-eeg_data(ez_montage{j,3},:);
        eeg_bps.chanlist(counter_3)=chanlist(j);
      end
    end
  end

  %% New section to find bad channels
  fprintf('Running neural network to find bad electrode recording sites \r');
  nnetworkin=zeros(numel(eeg_bp.eeg_data(:,1)),11);
  [R,P,RL,RU] = corrcoef(eeg_bp.eeg_data');
  CC=abs(R);
  nnetworkin(:,1)=[clustering_coef_wd(CC)];
  nnetworkin(:,2)=[zscore(clustering_coef_wd(CC))];

  for ii = 1:numel(eeg_bp.eeg_data(:,1))
     nnetworkin(ii,3) = wentropy(eeg_bp.eeg_data(ii,:),'shannon');
  end
      
  %%%%%%%%%%%%% POWER SPECTRUM DENSITY (MULTITAPER)
  Fs_ds = 1000;
  eeg_bp.eeg_data = resample(eeg_bp.eeg_data', Fs_ds, 20000).';      % Downsample to 100 Hz
  eeg = eeg_bp.eeg_data(:,1:floor(size(eeg_bp.eeg_data,2)/2)).';        % Use First 5 min
  [pxx f] = pmtm(eeg,80,[],Fs_ds);                    % Power Spectrum
  pxx = pxx.';
  pxxAll_train{1,1} = pxx;
  
  % GENERATE TRAINING ARRAY DATA
  logpxx = log10(pxx(:,f>=1 & f<= 500));
  logf = log10(f(f>=1 & f<= 500)); % really 0.2-50 Hz (a.a)
  logpxx1 = log10(pxx(:, f>= 1 & f<=8)); % really 0.2-1.6 Hz
  logpxx2 = log10(pxx(:, f>=1 & f<=16,:)); % really 0.2-3.2 Hz
  logpxx3 = log10(pxx(:, f>= 16 & f<=500)); % really 3.2-50 Hz (a.a)
  logf1 = log10(f(f >= 1 & f <= 8));
  logf2 = log10(f(f >= 1 & f <= 16));
  logf3 = log10(f(f >= 16 & f<=500));

  % GENERATE LINEAR FITS FOR LOGLOG POWERSPECTRUM FOR REQUISIT BANDS
  for chan = 1:numel(eeg_bp.eeg_data(:,1))
    mdl0 = fitlm(logf,logpxx(chan,:));
    mdl1 = fitlm(logf1, logpxx1(chan,:));
    mdl2 = fitlm(logf2, logpxx2(chan,:));
    mdl3 = fitlm(logf3, logpxx3(chan,:));
    
    nnetworkin(chan,4:5) = [mdl0.Rsquared.Ordinary mdl0.Coefficients.Estimate(2,1)];
    nnetworkin(chan,6:7) = [mdl1.Rsquared.Ordinary mdl1.Coefficients.Estimate(2,1)];
    nnetworkin(chan,8:9) = [mdl2.Rsquared.Ordinary mdl2.Coefficients.Estimate(2,1)];
    nnetworkin(chan,10:11) = [mdl3.Rsquared.Ordinary mdl3.Coefficients.Estimate(2,1)];
  end
  % End of new code

  %% Running neural network
  [Y] = badchannel_nn(nnetworkin);
  [a,b] = find(Y > 0.32);
  % end of section

  %% Section to remove bad channels
  counter_lf = 0;
  for j = 1:numel(a)
    counter_lf = counter_lf+1;
    lf_bad(counter_lf) = eeg_bp.chanlist(a(j));
    [C, IA, IB] = intersect(eeg_bps.chanlist, lf_bad(counter_lf));
    if numel(IA) > 0
        eeg_bps.eeg_data(IA,:)=[];
        eeg_bps.chanlist(IA)=[];
    end;
    [C, IA, IB]=intersect(eeg_mp.chanlist, lf_bad(counter_lf));
    if numel(IA) > 0
        eeg_mp.eeg_data(IA,:)=[];
        eeg_mp.chanlist(IA)=[];
    end
  end

  if isempty(a)
      lf_bad=[];
  end;

  ez_mp = eeg_mp.eeg_data;
  ez_bp = eeg_bps.eeg_data;
  if ~isempty(eeg_mp.eeg_data)
    metadata.m_chanlist=eeg_mp.chanlist;
  end
  if ~isempty(eeg_bp.eeg_data)
    metadata.bp_chanlist=eeg_bps.chanlist;
  end
  metadata.lf_bad = lf_bad;
  % end of section

end

function sixty_cycle = impedenceCheck(eeg_data, number_of_channels, file_size)

  fprintf('Impedence check\r')
  sixty_cycle=[];
  for j=1:number_of_channels
    gpu_eeg_data=eeg_data(j,:);
    transformedSignal = fft(gpu_eeg_data);
    frequencyVector = 2000/2 * linspace( 0, 1, file_size/2 + 1 );
    powerSpectrum = transformedSignal .* conj(transformedSignal) ./ file_size;
    if j==1
        [a,b]=find((frequencyVector>58)&(frequencyVector<62));
        start_index=min(b);
        end_index=max(b);
    end
    sixty_cycle(j)=sum(real(powerSpectrum(start_index:end_index)));
  end
end