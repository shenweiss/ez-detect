function removeEvents_1_5_cycles(fname)

    load(fname);
    disp('remove mini HFOs RonO')
    RonO_delidx=[];
    % remove events with less than 1.5 cycles
    if ~isempty(RonO.channel)
      cycles=RonO.duration./(1./RonO.freq_av);
      [RonO_delidx,~]=find(cycles<1.5);
      RonO.channel(RonO_delidx,:)=[];
      RonO.freq_av(RonO_delidx,:)=[];
      RonO.freq_pk(RonO_delidx,:)=[];
      RonO.power_av(RonO_delidx,:)=[];
      RonO.power_pk(RonO_delidx,:)=[];
      RonO.duration(RonO_delidx,:)=[];
      RonO.start_t(RonO_delidx,:)=[];
      RonO.finish_t(RonO_delidx,:)=[];
    end;

    disp('remove mini HFOs TRonS')
    TRonS_delidx=[];
    FRonS_counter=numel(FRonS.channel);
    if ~isempty(TRonS.channel)
        for i=1:numel(TRonS.channel(:,1))
            if TRonS.duration<((1/TRonS.freq_av)*1.5)
                FRonS_counter=FRonS_counter+1;
                FRonS.channel(FRonS_counter,:)=TRonS.channel(i,:);
                FRonS.start_t(FRonS_counter,:)=TRonS.start_t(i,:);
                FRonS.finish_t(FRonS_counter,:)=TRonS.finish_t(i,:);
                Total_FRonS(TRonS.channel(i,:))=Total_FRonS(TRonS.channel(i,:))+1;
                TRonS_delidx=[TRonS_delidx i];
            end;
        end;
   TRonS.channel(TRonS_delidx,:)=[];
   TRonS.freq_av(TRonS_delidx,:)=[];
   TRonS.freq_pk(TRonS_delidx,:)=[];
   TRonS.power_av(TRonS_delidx,:)=[];
   TRonS.power_pk(TRonS_delidx,:)=[];
   TRonS.duration(TRonS_delidx,:)=[];
   TRonS.start_t(TRonS_delidx,:)=[];
   TRonS.finish_t(TRonS_delidx,:)=[];
   end;
    
    disp('remove mini HFOs ftFRon0')
    ftRonO_delidx=[];
    if ~isempty(ftRonO.channel)
          cycles=ftRonO.duration./(1./ftRonO.freq_av);
          [ftRonO_delidx,~]=find(cycles<1.5);
          ftRonO.channel(ftRonO_delidx,:)=[];
          ftRonO.freq_av(ftRonO_delidx,:)=[];
          ftRonO.freq_pk(ftRonO_delidx,:)=[];
          ftRonO.power_av(ftRonO_delidx,:)=[];
          ftRonO.power_pk(ftRonO_delidx,:)=[];
          ftRonO.duration(ftRonO_delidx,:)=[];
          ftRonO.start_t(ftRonO_delidx,:)=[];
          ftRonO.finish_t(ftRonO_delidx,:)=[];
    end;

    disp('remove mini HFOs ftTRonS')
    ftTRonS_delidx=[];
    ftFRonS_counter=numel(ftFRonS.channel);
    if ~isempty(ftTRonS.channel)
        for i=1:numel(ftTRonS.channel(:,1))
            if ftTRonS.duration<((1/ftTRonS.freq_av)*1.5)
                ft_TronS_delidx=[ftTRonS_delidx i];
                ftFRonS_counter=ftFRonS_counter+1;
                ftFRonS.channel(ftFRonS_counter,:)=ftTRonS.channel(i,:);
                ftFRonS.start_t(ftFRonS_counter,:)=ftTRonS.start_t(i,:);
                ftFRonS.finish_t(ftFRonS_counter,:)=ftTRonS.finish_t(i,:);
                Total_ftFRonS(ftTRonS.channel(i,:))=Total_ftFRonS(ftTRonS.channel(i,:))+1;
            end;
        end;
        ftTRonS.channel(i,:)=[];
        ftTRonS.freq_av(i,:)=[];
        ftTRonS.freq_pk(i,:)=[];
        ftTRonS.power_av(i,:)=[];
        ftTRonS.power_pk(i,:)=[];
        ftTRonS.duration(i,:)=[];
        ftTRonS.start_t(i,:)=[];
        ftTRonS.finish_t(i,:)=[];
    end;

    save(fname,'RonO','TRonS','FRonS','ftRonO','ftTRonS','ftFRonS','Total_RonO', ...
        'Total_TRonS','Total_FRonS','Total_ftRonO','Total_ftTRonS','Total_ftFRonS', ...
        'monopolar_chanlist', 'bipolar_chanlist', 'metadata');
end