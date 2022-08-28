function removeEvents_1_5_cycles(fname)

    load(fname);
    % remove events with less than 1.5 cycles
    if ~isempty(RonO.channel)
        parfor i=1:numel(RonO.channel(:,1))
            if RonO.duration<((1/RonO.freq_av)*1.5)
                RonO.channel(i,:)=[];
                RonO.freq_av(i,:)=[];
                RonO.freq_pk(i,:)=[];
                RonO.power_av(i,:)=[];
                RonO.power_pk(i,:)=[];
                RonO.duration(i,:)=[];
                RonO.start_t(i,:)=[];
                RonO.finish_t(i,:)=[];
            end;
        end;
    end;

    FRonS_counter=numel(FRonS.channel);
    if ~isempty(TRonS.channel)
        parfor i=1:numel(TRonS.channel(:,1))
            if TRonS.duration<((1/TRonS.freq_av)*1.5)
                FRonS_counter=FRonS_counter+1;
                FRonS.channel(FRonS_counter,:)=TRonS.channel(i,:);
                TRonS.channel(i,:)=[];
                TRonS.freq_av(i,:)=[];
                TRonS.freq_pk(i,:)=[];
                TRonS.power_av(i,:)=[];
                TRonS.power_pk(i,:)=[];
                TRonS.duration(i,:)=[];
                FRonS.start_t(FRonS_counter,:)=TRonS.start_t(i,:);
                TRonS.start_t(i,:)=[];
                FRonS.finish_t(FRonS_counter,:)=TRonS.finish_t(i,:);
                TRonS.finish_t(i,:)=[];
                Total_FRonS(TRonS.channel(i,:))=Total_FRonS(TRonS.channel(i,:))+1;
            end;
        end;
    end;

    if ~isempty(ftRonO.channel)
        parfor i=1:numel(ftRonO.channel(:,1))
            if ftRonO.duration<((1/ftRonO.freq_av)*1.5)
                ftRonO.channel(i,:)=[];
                ftRonO.freq_av(i,:)=[];
                ftRonO.freq_pk(i,:)=[];
                ftRonO.power_av(i,:)=[];
                ftRonO.power_pk(i,:)=[];
                ftRonO.duration(i,:)=[];
                ftRonO.start_t(i,:)=[];
                ftRonO.finish_t(i,:)=[];
            end;
        end;
    end;

    ftFRonS_counter=numel(ftFRonS.channel);
    if ~isempty(ftTRonS.channel)
        parfor i=1:numel(ftTRonS.channel(:,1))
            if ftTRonS.duration<((1/ftTRonS.freq_av)*1.5)
                ftFRonS_counter=ftFRonS_counter+1;
                ftFRonS.channel(ftFRonS_counter,:)=ftTRonS.channel(i,:);
                ftTRonS.channel(i,:)=[];
                ftTRonS.freq_av(i,:)=[];
                ftTRonS.freq_pk(i,:)=[];
                ftTRonS.power_av(i,:)=[];
                ftTRonS.power_pk(i,:)=[];
                ftTRonS.duration(i,:)=[];
                ftFRonS.start_t(ftFRonS_counter,:)=ftTRonS.start_t(i,:);
                ftTRonS.start_t(i,:)=[];
                ftFRonS.finish_t(ftFRonS_counter,:)=ftTRonS.finish_t(i,:);
                ftTRonS.finish_t(i,:)=[];
                Total_ftFRonS(ftTRonS.channel(i,:))=Total_ftFRonS(ftTRonS.channel(i,:))+1;
            end;
        end;
    end;

    save(fname,'RonO','TRonS','FRonS','ftRonO','ftTRonS','ftFRonS','Total_RonO', ...
        'Total_TRonS','Total_FRonS','Total_ftRonO','Total_ftTRonS','Total_ftFRonS', ...
        'monopolar_chanlist', 'bipolar_chanlist', 'metadata');
end