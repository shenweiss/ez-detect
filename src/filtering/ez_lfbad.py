from mne.utils import verbose, logger

def ez_lfbad(eeg_data, chan_list, metadata, montage):

  logger.info('Entering ez_lfbad')
  metadata['']



metadata.lf_bad={''}; % start building metadata
metadata.bp_chanlist={''};
metadata.m_chanlist={''};

metadata.montage_shape = [numel(ez_montage(:,1)),numel(ez_montage(1,:))];
metadata.montage= reshape(ez_montage,1,[]); %matlab engine can only return 1*n cell arrays. I changed the data structure to get mlarray.

t.Data=ez_montage; 

def impedence_check():
  logger.info('Performing impedance check.')

  sixty_cycle=[]
  for j in range(len(eeg_data))
      channel = eeg_data[j]
      transformed_signal = fft(channel) #Fast Fourier transform
      frequencyVector = 2000/2 * linspace( 0, 1, numel(eeg_data(1,:))/2 + 1 );
      powerSpectrum = transformedSignal .* conj(transformedSignal) ./ numel(eeg_data(1,:));
      if j==1
          [a,b]=find((frequencyVector>58)&(frequencyVector<62));
          start_index=min(b);
          end_index=max(b);
      end;
      sixty_cycle(j)=sum(real(powerSpectrum(start_index:end_index)));
  end;
  zsixty_cycle=zscore_2(sixty_cycle);
  [a,imp]=find((sixty_cycle>1e9)&(zsixty_cycle>0.3));
  imp=unique(imp);

  t.Data=ez_montage;

  eeg_bp=[];
  eeg_mp=[];
  eeg_bps=[];
  % Calculate bipolar ez_montage for all channels
  counter_1=0;
  counter_2=0;
  counter_3=0;
 
 %Ask, if CHAN_NAME 1 2 0 is marked as ref and bipolar... 449_correct_montage.mat
 for j=1:numel(chanlist)
    if t.Data{j,3}~=0
        if t.Data{j,4}~=1
          if isempty(intersect(imp,j))    
            counter_1=counter_1+1;
            eeg_bp.eeg_data(counter_1,:)=eeg_data(j,:)-eeg_data(t.Data{j,3},:);
            eeg_bp.chanlist(counter_1)=chanlist(j);
          end;
        end;
    end;   
     if t.Data{j,2}==1
       if t.Data{j,4}~=1
         if isempty(intersect(imp,j))
           counter_2=counter_2+1;
           eeg_mp.eeg_data(counter_2,:)=eeg_data(j,:);  
           eeg_mp.chanlist(counter_2)=chanlist(j);
         end;
       end;    
     else
         if t.Data{j,3}~=0
          if t.Data{j,4}~=1
           if isempty(intersect(imp,j))   
             counter_3=counter_3+1;
             eeg_bps.eeg_data(counter_3,:)=eeg_data(j,:)-eeg_data(t.Data{j,3},:);
             eeg_bps.chanlist(counter_3)=chanlist(j);
           end;
          end;
         end;
     end;
 end;

 
if isempty(eeg_bps)
    eeg_bps.eeg_data=[];
    eeg_bps.chanlist={''};
end;

if isempty(eeg_mp)
    eeg_mp.eeg_data=[];
    eeg_mp.chanlist={''};
end;


  %% New section to find bad channels
  fprintf('running neural network to find bad electrode recording sites \r');
  nnetworkin=zeros(numel(eeg_bp.eeg_data(:,1)),11);
  [R,P,RL,RU] = corrcoef(eeg_bp.eeg_data');
  CC=abs(R);
  nnetworkin(:,1)=[clustering_coef_wd(CC)];
  nnetworkin(:,2)=[zscore(clustering_coef_wd(CC))];

  for ii = 1:numel(eeg_bp.eeg_data(:,1))
     nnetworkin(ii,3) = wentropy(eeg_bp.eeg_data(ii,:),'shannon');
  end
      
  %%%%%%%%%%%%%%% POWER SPECTRUM DENSITY (MULTITAPER)
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

      for chan = 1:numel(eeg_bp.eeg_data(:,1))
          chan
          % GENERATE LINEAR FITS FOR LOGLOG POWERSPECTRUM FOR REQUISIT BANDS
          mdl0 = fitlm(logf,logpxx(chan,:));
          mdl1 = fitlm(logf1, logpxx1(chan,:));
          mdl2 = fitlm(logf2, logpxx2(chan,:));
          mdl3 = fitlm(logf3, logpxx3(chan,:));
          
          nnetworkin(chan,4:5) = [mdl0.Rsquared.Ordinary mdl0.Coefficients.Estimate(2,1)] ;
          nnetworkin(chan,6:7) = [mdl1.Rsquared.Ordinary mdl1.Coefficients.Estimate(2,1)] ;
          nnetworkin(chan,8:9) = [mdl2.Rsquared.Ordinary mdl2.Coefficients.Estimate(2,1)] ;
          nnetworkin(chan,10:11) = [mdl3.Rsquared.Ordinary mdl3.Coefficients.Estimate(2,1)] ;
      end
  % End of new code

  %% Running neural network
       [Y] = badchannel_nn(nnetworkin)
       [a,b]= find(Y>0.32);
  % end of section

  counter_lf=0;
  for j=1:numel(a)
    counter_lf=counter_lf+1;
    lf_bad(counter_lf)=chanlist(a(j));
    [C, IA, IB]=intersect(eeg_bps.chanlist, lf_bad(counter_lf));
    if numel(IA)>0
        eeg_bps.eeg_data(IA,:)=[];
        eeg_bps.chanlist(IA)=[];
    end;
    [C, IA, IB]=intersect(eeg_mp.chanlist, lf_bad(counter_lf));
    if numel(IA)>0
        eeg_mp.eeg_data(IA,:)=[];
        eeg_mp.chanlist(IA)=[];
    end;
  end;

  if isempty(a)
      lf_bad=[];
  end;


eeg_data_m=eeg_mp.eeg_data;
eeg_data_bp=eeg_bps.eeg_data;
if ~isempty(eeg_mp.eeg_data)
metadata.m_chanlist=eeg_mp.chanlist;
end;
if ~isempty(eeg_bp.eeg_data)
metadata.bp_chanlist=eeg_bps.chanlist;
end;
metadata.lf_bad=lf_bad;

%save('/home/tomas-pastore/ez-detect/disk_dumps/lfbad_metadata.mat', 'metadata','-v7.3')
