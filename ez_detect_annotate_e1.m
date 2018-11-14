function ez_detect_annotate_e1(fname,num_trc_blocks,montage);
load(fname);
file_block=metadata.file_block;
file_block=num2str(file_block);
% remove events with less than 1.5 cycles
if ~isempty(RonO.channel)
    for i=1:numel(RonO.channel(:,1))
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

if ~isempty(TRonS.channel)
    for i=1:numel(TRonS.channel(:,1))
        if TRonS.duration<((1/TRonS.freq_av)*1.5)
            TRonS.channel(i,:)=[];
            TRonS.freq_av(i,:)=[];
            TRonS.freq_pk(i,:)=[];
            TRonS.power_av(i,:)=[];
            TRonS.power_pk(i,:)=[];
            TRonS.duration(i,:)=[];
            TRonS.start_t(i,:)=[];
            TRonS.finish_t(i,:)=[];
        end;
    end;
end;

if ~isempty(ftRonO.channel)
    for i=1:numel(ftRonO.channel(:,1))
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

if ~isempty(ftTRonS.channel)
    for i=1:numel(ftTRonS.channel(:,1))
        if ftTRonS.duration<((1/ftTRonS.freq_av)*1.5)
            ftTRonS.channel(i,:)=[];
            ftTRonS.freq_av(i,:)=[];
            ftTRonS.freq_pk(i,:)=[];
            ftTRonS.power_av(i,:)=[];
            ftTRonS.power_pk(i,:)=[];
            ftTRonS.duration(i,:)=[];
            ftTRonS.start_t(i,:)=[];
            ftTRonS.finish_t(i,:)=[];
        end;
    end;
end;

% corrects the file_id
file_id_size=numel(metadata.file_id);
file_id=metadata.file_id(1:(file_id_size-4));

if montage == 0
    % initialize annotation files
    fprintf('initializing annotation files\r');
    for i=1:num_trc_blocks
        if i==1
            chan_block_str='1';
            evt_1=[file_id 'm_' chan_block_str '_' file_block '.txt'];
            evt_1=strcat('/home/tomas-pastore/hfo_engine_1/TRC_out/',evt_1);
            fid1=fopen(evt_1,'wt');
            fclose(fid1);
        end;
        if i==2
            chan_block_str='2';
            evt_2=[file_id 'm_' chan_block_str '_' file_block '.txt'];
            evt_2=strcat('/home/tomas-pastore/hfo_engine_1/TRC_out/',evt_2);
            fid2=fopen(evt_2,'wt');
            fclose(fid2);
        end;
        if i==3
            chan_block_str='3';
            evt_3=[file_id 'm_' chan_block_str '_' file_block '.txt'];
            evt_3=strcat('/home/tomas-pastore/hfo_engine_1/TRC_out/',evt_3);
            fid3=fopen(evt_3,'wt');
            fclose(fid3);
        end;
        if i==4
            chan_block_str='4';
            evt_4=[file_id '_m_' chan_block_str '_' file_block '.txt'];
            evt_4=strcat('/home/tomas-pastore/hfo_engine_1/TRC_out/',evt_4);
            fid4=fopen(evt_4,'wt');
            fclose(fid4);
        end;
        if i==5
            chan_block_str='5';
            evt_5=[file_id '_m_' chan_block_str '_' file_block '.txt'];
            evt_5=strcat('/home/tomas-pastore/hfo_engine_1/TRC_out/',evt_5);
            fid5=fopen(evt_5,'wt');
            fclose(fid5);
        end;
        if i==6
            chan_block_str='6';
            evt_6=[file_id '_m_' chan_block_str '_' file_block '.txt'];
            evt_6=strcat('/home/tomas-pastore/hfo_engine_1/TRC_out/',evt_6);
            fid6=fopen(evt_6,'wt');
            fclose(fid6);
        end;
        if i==7
            chan_block_str='7';
            evt_7=[file_id '_m_' chan_block_str '_' file_block '.txt'];
            evt_7=strcat('/home/tomas-pastore/hfo_engine_1/TRC_out/',evt_7);
            fid7=fopen(evt_7,'wt');
            fclose(fid7);
        end;
    end;
else
    fprintf('initializing annotation files\r');
    for i=1:num_trc_blocks
        if i==1
            chan_block_str='1';
            evt_1=[file_id '_bp_' chan_block_str '_' file_block '.txt'];
            evt_1=strcat('/home/tomas-pastore/hfo_engine_1/TRC_out/',evt_1);
            fid1=fopen(evt_1,'wt');
            fclose(fid1);
        end;
        if i==2
            chan_block_str='2';
            evt_2=[file_id '_bp_' chan_block_str '_' file_block '.txt'];
            evt_2=strcat('/home/tomas-pastore/hfo_engine_1/TRC_out/',evt_2);
            fid2=fopen(evt_2,'wt');
            fclose(fid2);
        end;
        if i==3
            chan_block_str='3';
            evt_3=[file_id '_bp_' chan_block_str '_' file_block '.txt'];
            evt_3=strcat('/home/tomas-pastore/hfo_engine_1/TRC_out/',evt_3);
            fid3=fopen(evt_3,'wt');
            fclose(fid3);
        end;
        if i==4
            chan_block_str='4';
            evt_4=[file_id '_bp_' chan_block_str '_' file_block '.txt'];
            evt_4=strcat('/home/tomas-pastore/hfo_engine_1/TRC_out/',evt_4);
            fid4=fopen(evt_4,'wt');
            fclose(fid4);
        end;
        if i==5
            chan_block_str='5';
            evt_5=[file_id 'bp_' chan_block_str '_' file_block '.txt'];
            evt_5=strcat('/home/tomas-pastore/hfo_engine_1/TRC_out/',evt_5);
            fid5=fopen(evt_5,'wt');
            fclose(fid5);
        end;
        if i==6
            chan_block_str='6';
            evt_6=[file_id 'bp_' chan_block_str '_' file_block '.txt'];
            evt_6=strcat('/home/tomas-pastore/hfo_engine_1/TRC_out/',evt_6);
            fid6=fopen(evt_6,'wt');
            fclose(fid6);
        end;
        if i==7
            chan_block_str='7';
            evt_7=[file_id 'bp_' chan_block_str '_' file_block '.txt'];
            evt_7=strcat('/home/tomas-pastore/hfo_engine_1/TRC_out/',evt_7);
            fid7=fopen(evt_7,'wt');
            fclose(fid7);
        end;
    end;
    
end;
% write annotations % v5 Putou adjust for asymmetric filtering
% write spike annotations
if ~isempty(TRonS.channel)
    for i=1:numel(TRonS.channel(:,1))
        channel=TRonS.channel(i,1);
        chan_block_ann=ceil(channel/32);
        if chan_block_ann == 1
            start_ann=TRonS.start_t(i)-.02;
            stop_ann=TRonS.finish_t(i)+.01;
            write_TRC_events(evt_1,1,channel,start_ann,stop_ann,0);
        end;
        if chan_block_ann == 2
            chan_adj=channel-32;
            start_ann=TRonS.start_t(i)-.02;
            stop_ann=TRonS.finish_t(i)+.01;
            write_TRC_events(evt_2,2,chan_adj,start_ann,stop_ann,0);
        end;
        if chan_block_ann == 3
            chan_adj=channel-64;
            start_ann=TRonS.start_t(i)-.02;
            stop_ann=TRonS.finish_t(i)+.01;
            write_TRC_events(evt_3,3,chan_adj,start_ann,stop_ann,0);
        end;
        if chan_block_ann == 4
            chan_adj=channel-96;
            start_ann=TRonS.start_t(i)-.02;
            stop_ann=TRonS.finish_t(i)+.01;
            write_TRC_events(evt_4,4,chan_adj,start_ann,stop_ann,0);
        end;
        if chan_block_ann == 5
            chan_adj=channel-128;
            start_ann=TRonS.start_t(i)-.02;
            stop_ann=TRonS.finish_t(i)+.01;
            write_TRC_events(evt_5,5,chan_adj,start_ann,stop_ann,0);
        end;
        if chan_block_ann == 6
            chan_adj=channel-160;
            start_ann=TRonS.start_t(i)-.02;
            stop_ann=TRonS.finish_t(i)+.01;
            write_TRC_events(evt_6,6,chan_adj,start_ann,stop_ann,0);
        end;
        if chan_block_ann == 7
            chan_adj=channel-192;
            start_ann=TRonS.start_t(i)-.02;
            stop_ann=TRonS.finish_t(i)+.01;
            write_TRC_events(evt_7,7,chan_adj,start_ann,stop_ann,0);
        end;
    end;
end;

if ~isempty(ftTRonS.channel)
    for i=1:numel(ftTRonS.channel(:,1))
        channel=ftTRonS.channel(i,1);
        chan_block_ann=ceil(channel/32);
        if chan_block_ann == 1
            start_ann=ftTRonS.start_t(i)-.02;
            stop_ann=ftTRonS.finish_t(i)+.01;
            write_TRC_events(evt_1,1,channel,start_ann,stop_ann,0);
        end;
        if chan_block_ann == 2
            chan_adj=channel-32;
            start_ann=ftTRonS.start_t(i)-.02;
            stop_ann=ftTRonS.finish_t(i)+.01;
            write_TRC_events(evt_2,2,chan_adj,start_ann,stop_ann,0);
        end;
        if chan_block_ann == 3
            chan_adj=channel-64;
            start_ann=ftTRonS.start_t(i)-.02;
            stop_ann=ftTRonS.finish_t(i)+.01;
            write_TRC_events(evt_3,3,chan_adj,start_ann,stop_ann,0);
        end;
        if chan_block_ann == 4
            chan_adj=channel-96;
            start_ann=ftTRonS.start_t(i)-.02;
            stop_ann=ftTRonS.finish_t(i)+.01;
            write_TRC_events(evt_4,4,chan_adj,start_ann,stop_ann,0);
        end;
        if chan_block_ann == 5
            chan_adj=channel-128;
            start_ann=ftTRonS.start_t(i)-.02;
            stop_ann=ftTRonS.finish_t(i)+.01;
            write_TRC_events(evt_5,5,chan_adj,start_ann,stop_ann,0);
        end;
        if chan_block_ann == 6
            chan_adj=channel-160;
            start_ann=ftTRonS.start_t(i)-.02;
            stop_ann=ftTRonS.finish_t(i)+.01;
            write_TRC_events(evt_6,6,chan_adj,start_ann,stop_ann,0);
        end;
        if chan_block_ann == 7
            chan_adj=channel-192;
            start_ann=ftTRonS.start_t(i)-.02;
            stop_ann=ftTRonS.finish_t(i)+.01;
            write_TRC_events(evt_7,7,chan_adj,start_ann,stop_ann,0);
        end;
    end;
end;

if ~isempty(FRonS.channel)
    for i=1:numel(FRonS.channel(:,1))
        channel=FRonS.channel(i,1);
        chan_block_ann=ceil(channel/32);
        if chan_block_ann == 1
            start_ann=FRonS.start_t(i)-.02;
            stop_ann=FRonS.finish_t(i)+.01;
            write_TRC_events(evt_1,1,channel,start_ann,stop_ann,0);
        end;
        if chan_block_ann == 2
            chan_adj=channel-32;
            start_ann=FRonS.start_t(i)-.02;
            stop_ann=FRonS.finish_t(i)+.01;
            write_TRC_events(evt_2,2,chan_adj,start_ann,stop_ann,0);
        end;
        if chan_block_ann == 3
            chan_adj=channel-64;
            start_ann=FRonS.start_t(i)-.02;
            stop_ann=FRonS.finish_t(i)+.01;
            write_TRC_events(evt_3,3,chan_adj,start_ann,stop_ann,0);
        end;
        if chan_block_ann == 4
            chan_adj=channel-96;
            start_ann=FRonS.start_t(i)-.02;
            stop_ann=FRonS.finish_t(i)+.01;
            write_TRC_events(evt_4,4,chan_adj,start_ann,stop_ann,0);
        end;
        if chan_block_ann == 5
            chan_adj=channel-128;
            start_ann=FRonS.start_t(i)-.02;
            stop_ann=FRonS.finish_t(i)+.01;
            write_TRC_events(evt_5,5,chan_adj,start_ann,stop_ann,0);
        end;
        if chan_block_ann == 6
            chan_adj=channel-160;
            start_ann=FRonS.start_t(i)-.02;
            stop_ann=FRonS.finish_t(i)+.01;
            write_TRC_events(evt_6,6,chan_adj,start_ann,stop_ann,0);
        end;
        if chan_block_ann == 7
            chan_adj=channel-192;
            start_ann=FRonS.start_t(i)-.02;
            stop_ann=FRonS.finish_t(i)+.01;
            write_TRC_events(evt_7,7,chan_adj,start_ann,stop_ann,0);
        end;
    end;
end;

if ~isempty(ftFRonS.channel)
    for i=1:numel(ftFRonS.channel(:,1))
        channel=ftFRonS.channel(i,1);
        chan_block_ann=ceil(channel/32);
        if chan_block_ann == 1
            start_ann=ftFRonS.start_t(i)-.02;
            stop_ann=ftFRonS.finish_t(i)+.01;
            write_TRC_events(evt_1,1,channel,start_ann,stop_ann,0);
        end;
        if chan_block_ann == 2
            chan_adj=channel-32;
            start_ann=ftFRonS.start_t(i)-.02;
            stop_ann=ftFRonS.finish_t(i)+.01;
            write_TRC_events(evt_2,2,chan_adj,start_ann,stop_ann,0);
        end;
        if chan_block_ann == 3
            chan_adj=channel-64;
            start_ann=ftFRonS.start_t(i)-.02;
            stop_ann=ftFRonS.finish_t(i)+.01;
            write_TRC_events(evt_3,3,chan_adj,start_ann,stop_ann,0);
        end;
        if chan_block_ann == 4
            chan_adj=channel-96;
            start_ann=ftFRonS.start_t(i)-.02;
            stop_ann=ftFRonS.finish_t(i)+.01;
            write_TRC_events(evt_4,4,chan_adj,start_ann,stop_ann,0);
        end;
        if chan_block_ann == 5
            chan_adj=channel-128;
            start_ann=ftFRonS.start_t(i)-.02;
            stop_ann=ftFRonS.finish_t(i)+.01;
            write_TRC_events(evt_5,5,chan_adj,start_ann,stop_ann,0);
        end;
        if chan_block_ann == 6
            chan_adj=channel-160;
            start_ann=ftFRonS.start_t(i)-.02;
            stop_ann=ftFRonS.finish_t(i)+.01;
            write_TRC_events(evt_6,6,chan_adj,start_ann,stop_ann,0);
        end;
        if chan_block_ann == 7
            chan_adj=channel-192;
            start_ann=ftFRonS.start_t(i)-.02;
            stop_ann=ftFRonS.finish_t(i)+.01;
            write_TRC_events(evt_7,7,chan_adj,start_ann,stop_ann,0);
        end;
    end;
end;

% write ripple annotations
if ~isempty(RonO.channel)
    for i=1:numel(RonO.channel(:,1))
        channel=RonO.channel(i,1);
        chan_block_ann=ceil(channel/32);
        if chan_block_ann == 1
            start_ann=RonO.start_t(i)-.005;
            stop_ann=RonO.finish_t(i)+.005;
            write_TRC_events(evt_1,1,channel,start_ann,stop_ann,1);
        end;
        if chan_block_ann == 2
            chan_adj=channel-32;
            start_ann=RonO.start_t(i)-.005;
            stop_ann=RonO.finish_t(i)+.005;
            write_TRC_events(evt_2,2,chan_adj,start_ann,stop_ann,1);
        end;
        if chan_block_ann == 3
            chan_adj=channel-64;
            start_ann=RonO.start_t(i)-.005;
            stop_ann=RonO.finish_t(i)+.005;
            write_TRC_events(evt_3,3,chan_adj,start_ann,stop_ann,1);
        end;
        if chan_block_ann == 4
            chan_adj=channel-96;
            start_ann=RonO.start_t(i)-.005;
            stop_ann=RonO.finish_t(i)+.005;
            write_TRC_events(evt_4,4,chan_adj,start_ann,stop_ann,1);
        end;
        if chan_block_ann == 5
            chan_adj=channel-128;
            start_ann=RonO.start_t(i)-.005;
            stop_ann=RonO.finish_t(i)+.005;
            write_TRC_events(evt_5,5,chan_adj,start_ann,stop_ann,1);
        end;
        if chan_block_ann == 6
            chan_adj=channel-160;
            start_ann=RonO.start_t(i)-.005;
            stop_ann=RonO.finish_t(i)+.005;
            write_TRC_events(evt_6,6,chan_adj,start_ann,stop_ann,1);
        end;
        if chan_block_ann == 7
            chan_adj=channel-192;
            start_ann=RonO.start_t(i)-.005;
            stop_ann=RonO.finish_t(i)+.005;
            write_TRC_events(evt_7,7,chan_adj,start_ann,stop_ann,1);
        end;
    end;
end;

if ~isempty(TRonS.channel)
    for i=1:numel(TRonS.channel(:,1))
        channel=TRonS.channel(i,1);
        chan_block_ann=ceil(channel/32);
        if chan_block_ann == 1
            start_ann=TRonS.start_t(i)-.005;
            stop_ann=TRonS.finish_t(i)+.005;
            write_TRC_events(evt_1,1,channel,start_ann,stop_ann,1);
        end;
        if chan_block_ann == 2
            chan_adj=channel-32;
            start_ann=TRonS.start_t(i)-.005;
            stop_ann=TRonS.finish_t(i)+.005;
            write_TRC_events(evt_2,2,chan_adj,start_ann,stop_ann,1);
        end;
        if chan_block_ann == 3
            chan_adj=channel-64;
            start_ann=TRonS.start_t(i)-.005;
            stop_ann=TRonS.finish_t(i)+.005;
            write_TRC_events(evt_3,3,chan_adj,start_ann,stop_ann,1);
        end;
        if chan_block_ann == 4
            chan_adj=channel-96;
            start_ann=TRonS.start_t(i)-.005;
            stop_ann=TRonS.finish_t(i)+.005;
            write_TRC_events(evt_4,4,chan_adj,start_ann,stop_ann,1);
        end;
        if chan_block_ann == 5
            chan_adj=channel-128;
            start_ann=TRonS.start_t(i)-.005;
            stop_ann=TRonS.finish_t(i)+.005;
            write_TRC_events(evt_5,5,chan_adj,start_ann,stop_ann,1);
        end;
        if chan_block_ann == 6
            chan_adj=channel-160;
            start_ann=TRonS.start_t(i)-.005;
            stop_ann=TRonS.finish_t(i)+.005;
            write_TRC_events(evt_6,6,chan_adj,start_ann,stop_ann,1);
        end;
        if chan_block_ann == 7
            chan_adj=channel-192;
            start_ann=TRonS.start_t(i)-.005;
            stop_ann=TRonS.finish_t(i)+.005;
            write_TRC_events(evt_7,7,chan_adj,start_ann,stop_ann,1);
        end;
    end;
end;

% write fast ripple annotations
if ~isempty(ftRonO.channel)
    for i=1:numel(ftRonO.channel(:,1))
        channel=ftRonO.channel(i,1);
        chan_block_ann=ceil(channel/32);
        if chan_block_ann == 1
            start_ann=ftRonO.start_t(i)-.0025;
            stop_ann=ftRonO.finish_t(i)+.0025;
            write_TRC_events(evt_1,1,channel,start_ann,stop_ann,2);
        end;
        if chan_block_ann == 2
            chan_adj=channel-32;
            start_ann=ftRonO.start_t(i)-.0025;
            stop_ann=ftRonO.finish_t(i)+.0025;
            write_TRC_events(evt_2,2,chan_adj,start_ann,stop_ann,2);
        end;
        if chan_block_ann == 3
            chan_adj=channel-64;
            start_ann=ftRonO.start_t(i)-.0025;
            stop_ann=ftRonO.finish_t(i)+.0025;
            write_TRC_events(evt_3,3,chan_adj,start_ann,stop_ann,2);
        end;
        if chan_block_ann == 4
            chan_adj=channel-96;
            start_ann=ftRonO.start_t(i)-.0025;
            stop_ann=ftRonO.finish_t(i)+.0025;
            write_TRC_events(evt_4,4,chan_adj,start_ann,stop_ann,2);
        end;
        if chan_block_ann == 5
            chan_adj=channel-128;
            start_ann=ftRonO.start_t(i)-.0025;
            stop_ann=ftRonO.finish_t(i)+.0025;
            write_TRC_events(evt_5,5,chan_adj,start_ann,stop_ann,2);
        end;
        if chan_block_ann == 6
            chan_adj=channel-160;
            start_ann=ftRonO.start_t(i)-.0025;
            stop_ann=ftRonO.finish_t(i)+.0025;
            write_TRC_events(evt_6,6,chan_adj,start_ann,stop_ann,2);
        end;
        if chan_block_ann == 7
            chan_adj=channel-192;
            start_ann=ftRonO.start_t(i)-.0025;
            stop_ann=ftRonO.finish_t(i)+.0025;
            write_TRC_events(evt_7,7,chan_adj,start_ann,stop_ann,2);
        end;
    end;
end;

if ~isempty(ftTRonS.channel)
    for i=1:numel(ftTRonS.channel(:,1))
        channel=ftTRonS.channel(i,1);
        chan_block_ann=ceil(channel/32);
        if chan_block_ann == 1
            start_ann=ftTRonS.start_t(i)-.0025;
            stop_ann=ftTRonS.finish_t(i)+.0025;
            write_TRC_events(evt_1,1,channel,start_ann,stop_ann,2);
        end;
        if chan_block_ann == 2
            chan_adj=channel-32;
            start_ann=ftTRonS.start_t(i)-.0025;
            stop_ann=ftTRonS.finish_t(i)+.0025;
            write_TRC_events(evt_2,2,chan_adj,start_ann,stop_ann,2);
        end;
        if chan_block_ann == 3
            chan_adj=channel-64;
            start_ann=ftTRonS.start_t(i)-.0025;
            stop_ann=ftTRonS.finish_t(i)+.0025;
            write_TRC_events(evt_3,3,chan_adj,start_ann,stop_ann,2);
        end;
        if chan_block_ann == 4
            chan_adj=channel-96;
            start_ann=ftTRonS.start_t(i)-.0025;
            stop_ann=ftTRonS.finish_t(i)+.0025;
            write_TRC_events(evt_4,4,chan_adj,start_ann,stop_ann,2);
        end;
        if chan_block_ann == 5
            chan_adj=channel-128;
            start_ann=ftTRonS.start_t(i)-.0025;
            stop_ann=ftTRonS.finish_t(i)+.0025;
            write_TRC_events(evt_5,5,chan_adj,start_ann,stop_ann,2);
        end;
        if chan_block_ann == 6
            chan_adj=channel-160;
            start_ann=ftTRonS.start_t(i)-.0025;
            stop_ann=ftTRonS.finish_t(i)+.0025;
            write_TRC_events(evt_6,6,chan_adj,start_ann,stop_ann,2);
        end;
        if chan_block_ann == 7
            chan_adj=channel-192;
            start_ann=ftTRonS.start_t(i)-.0025;
            stop_ann=ftTRonS.finish_t(i)+.0025;
            write_TRC_events(evt_7,7,chan_adj,start_ann,stop_ann,2);
        end;
    end;
end;
save(fname,'RonO','TRonS','FRonS','ftRonO','ftTRonS','ftFRonS','Total_RonO','Total_TRonS','Total_FRonS','Total_ftRonO','Total_ftTRonS','Total_ftFRonS','monopolar_chanlist', 'bipolar_chanlist');