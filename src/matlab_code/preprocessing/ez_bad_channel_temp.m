function [data, metadata] = ez_bad_channel_temp(input_args_fname)

  load(input_args_fname); % loads variables: data, support_bipolar, metadata, chanlist
  eeg_bp.eeg_data = support_bipolar;
  eeg_bps.eeg_data = data.bp_channels;
  if strcmp(class(metadata.ch_names_bp), 'char') 
    metadata.ch_names_bp = cellstr(metadata.ch_names_bp);
  end
  eeg_bps.chanlist = metadata.ch_names_bp;
  eeg_mp.eeg_data = data.mp_channels;
  if strcmp(class(metadata.ch_names_mp), 'char')
    metadata.ch_names_mp = cellstr(metadata.ch_names_mp);
  end
  eeg_mp.chanlist = metadata.ch_names_mp;
  metadata.old_montage= [];
  metadata.montage_shape = [numel(ez_montage(:,1)),numel(ez_montage(1,:))];
  metadata.montage= reshape(ez_montage,1,[]); %matlab engine can only return 1*n cell arrays. I changed the data structure to get mlarray.



  fprintf('Running neural network to find bad electrode recording sites \r');
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


data.mp_channels = eeg_mp.eeg_data;
data.bp_channels = eeg_bps.eeg_data;
if ~isempty(eeg_mp.eeg_data)
metadata.m_chanlist=eeg_mp.chanlist;
end;
if ~isempty(eeg_bp.eeg_data)
metadata.bp_chanlist=eeg_bps.chanlist;
end;
metadata.lf_bad=lf_bad;



%save('/home/tpastore/Documents/ez-detect/disk_dumps/lfbad_metadata.mat','-v7.3')
