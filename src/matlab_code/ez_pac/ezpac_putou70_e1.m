function ezpac_putou_e1(eeg_data, fr, hfo, output_fname, metadata, montage, paths)
% Written by Dr. Shennan Aibel Weiss and Dr. Inkyung Song TJU 2016-2017, Portions
% of this code were written by Dr. Shennan Aibel Weiss at UCLA 2014-2016. 

% This work is protected by US patent applications US20150099962A1,
% UC-2016-158-2-PCT, US provisional #62429461


disp("Entering ezpac")
%%only for matlab engine for python, to be removed
%recover cell structure after matlab engine
dims = metadata.montage_shape;
metadata.montage = reshape(metadata.montage, dims(1), dims(2));

%%%



load(output_fname)

if montage == 0
     fname_var='_mp_';
else
     fname_var='_bp_'
end;
file_id = metadata.file_id;

new_output_fname = [paths.ez_pac_out file_id fname_var metadata.file_block '.mat'];

hfo_amp=[];
for i=1:numel(hfo(:,1))
    temp=abs(hilbert(hfo(i,:)));
    temp=downsample(temp,4);
    hfo_amp(i,:)=temp;
end;
hfo_time_index=[0.002:0.002:numel(temp)/500];
TRonS.amp={''};
TRonS.time_index={''};
RonO.amp={''};
RonO.time_index={''};
clear hfo

fr_amp=[];
for i=1:numel(fr(:,1))
    temp=abs(hilbert(fr(i,:)));
    temp=downsample(temp,4);
    fr_amp(i,:)=temp;
end;
ftTRonS.amp={''};
ftTRonS.time_index={''};
ftRonO.amp={''};
ftRonO.time_index={''};
clear fr

eeg_data_ds=[];
for i=1:(numel(eeg_data(:,1)))
    eeg_data_ds(i,:)=decimate(eeg_data(i,:),4,'fir');
end;
eeg_data=eeg_data_ds;
eeg_data_ds=[];

[output_bpFIR, delays] = filterEEG_ezpac70(eeg_data, 500);
[output_hilbert] = zhilbert_ezpac(eeg_data, output_bpFIR, 500);
fprintf('hilbert done \r');
numchan=numel(eeg_data(:,1));
[output_osc_epochs] = epochs_ezpac(numchan, output_hilbert, 500);
fprintf('epochs test done \r');

t_epoch_theta = gather(output_osc_epochs.t_epoch_theta);
t_epoch_delta = gather(output_osc_epochs.t_epoch_delta);
t_epoch_spindle = gather(output_osc_epochs.t_epoch_spindle);
t_epoch_slow = gather(output_osc_epochs.t_epoch_slow);

clear output_osc_epochs
clear eeg_data;
clear output bpFIR;
hSpindle=gather(output_hilbert.eeg.hSpindle);
hTheta=gather(output_hilbert.eeg.hTheta);
hDelta=gather(output_hilbert.eeg.hDelta);
hSlow=gather(output_hilbert.eeg.hSlow);
% iterate through ez_top_out
if ~isempty(RonO.start_t)
for i=1:numel(RonO.channel(:,1))
    [a,b]=find(RonO.start_t(i)<hfo_time_index & RonO.finish_t(i)>hfo_time_index);
    if ~isempty(b)
    event_start=b(1);
    event_start=event_start-1;
    event_start_pdelay=event_start+125-1;
    [a,b]=find(RonO.finish_t(i)<hfo_time_index & (RonO.finish_t(i)+0.01)>hfo_time_index);
    event_finish=b(1);
    event_finish=event_finish+1;
    event_finish_pdelay=event_finish+125+1
    if event_start_pdelay<1
        event_start_pdelay=1;
    end;
    if event_finish_pdelay>numel(hfo_amp(1,:))
        event_finish_pdelay=numel(hfo_amp(1,:));
    end;
    amp=hfo_amp(RonO.channel(i,1),event_start_pdelay:event_finish_pdelay);
    
    [C]=intersect((event_start:event_finish),t_epoch_slow{RonO.channel(i,1),1});
    if ~isempty(C)
        RonO.slow(i)=1;
        phase = (atan2(imag(hSlow(RonO.channel(i,1),event_start:event_finish)),real(hSlow(RonO.channel(i,1),event_start:event_finish))));
        if numel(phase)>numel(amp)
            phase=phase(1:numel(amp));
        end;
        if numel(amp)>numel(phase)
            amp=amp(1:numel(phase));
        end;
        RonO.slow_vs(i)=circ_r(phase',amp');
        RonO.slow_angle(i)=circ_mean(phase',amp');
    else
        RonO.slow(i)=0;
        RonO.slow_vs(i)=NaN;
        RonO.slow_angle(i)=NaN;
    end;

   [C]=intersect((event_start:event_finish),t_epoch_delta{RonO.channel(i,1),1});
    if ~isempty(C)
        RonO.delta(i)=1;
        phase = (atan2(imag(hDelta(RonO.channel(i,1),event_start:event_finish)),real(hDelta(RonO.channel(i,1),event_start:event_finish))));
        if numel(phase)>numel(amp)
            phase=phase(1:numel(amp));
        end;
        if numel(amp)>numel(phase)
            amp=amp(1:numel(phase));
        end;
        RonO.delta_vs(i)=circ_r(phase',amp');
        RonO.delta_angle(i)=circ_mean(phase',amp');
    else
        RonO.delta(i)=0;
        RonO.delta_vs(i)=NaN;
        RonO.delta_angle(i)=NaN;
    end;
    
    [C]=intersect((event_start:event_finish),t_epoch_theta{RonO.channel(i,1),1});
    if ~isempty(C)
        RonO.theta(i)=1;
        phase = (atan2(imag(hTheta(RonO.channel(i,1),event_start:event_finish)),real(hTheta(RonO.channel(i,1),event_start:event_finish))));
        if numel(phase)>numel(amp)
            phase=phase(1:numel(amp));
        end;
        if numel(amp)>numel(phase)
            amp=amp(1:numel(phase));
        end;
        RonO.theta_vs(i)=circ_r(phase',amp');
        RonO.theta_angle(i)=circ_mean(phase',amp');
    else
        RonO.theta(i)=0;
        RonO.theta_vs(i)=NaN;
        RonO.theta_angle(i)=NaN;
    end;
    
    [C]=intersect((event_start:event_finish),t_epoch_spindle{RonO.channel(i,1),1});
    if ~isempty(C)
        RonO.spindle(i)=1;
        phase = (atan2(imag(hSpindle(RonO.channel(i,1),event_start:event_finish)),real(hSpindle(RonO.channel(i,1),event_start:event_finish))));
        if numel(phase)>numel(amp)
            phase=phase(1:numel(amp));
        end;
        if numel(amp)>numel(phase)
            amp=amp(1:numel(phase));
        end;
        RonO.spindle_vs(i)=circ_r(phase',amp');
        RonO.spindle_angle(i)=circ_mean(phase',amp');
    else
        RonO.spindle(i)=0;
        RonO.spindle_vs(i)=NaN;
        RonO.spindle_angle(i)=NaN;
    end;
    end;
end;
end;

% For ftRonO
if ~isempty(ftRonO.start_t)
for i=1:numel(ftRonO.channel(:,1))
    [a,b]=find(ftRonO.start_t(i)<hfo_time_index & ftRonO.finish_t(i)>hfo_time_index);
    if ~isempty(b)
    event_start=b(1);
    event_start=event_start-1;
    event_start_pdelay=event_start+125-1;
    [a,b]=find(ftRonO.finish_t(i)<hfo_time_index & (ftRonO.finish_t(i)+0.01)>hfo_time_index);
    event_finish=b(1);
    event_finish=event_finish+1;
    event_finish_pdelay=event_finish+125+1;
    if event_start_pdelay<1
        event_start_pdelay=1;
    end;
    if event_finish_pdelay>numel(hfo_amp(1,:))
        event_finish_pdelay=numel(hfo_amp(1,:));
    end;
    amp=fr_amp(ftRonO.channel(i,1),event_start_pdelay:event_finish_pdelay);
    
    [C]=intersect((event_start:event_finish),t_epoch_slow{ftRonO.channel(i,1),1});
    if ~isempty(C)
        ftRonO.slow(i)=1;
        phase = (atan2(imag(hSlow(ftRonO.channel(i,1),event_start:event_finish)),real(hSlow(ftRonO.channel(i,1),event_start:event_finish))));
        if numel(phase)>numel(amp)
            phase=phase(1:numel(amp));
        end;
        if numel(amp)>numel(phase)
            amp=amp(1:numel(phase));
        end;
        ftRonO.slow_vs(i)=circ_r(phase',amp');
        ftRonO.slow_angle(i)=circ_mean(phase',amp');
    else
        ftRonO.slow(i)=0;
        ftRonO.slow_vs(i)=NaN;
        ftRonO.slow_angle(i)=NaN;
    end;

   [C]=intersect((event_start:event_finish),t_epoch_delta{ftRonO.channel(i,1),1});
    if ~isempty(C)
        ftRonO.delta(i)=1;
        phase = (atan2(imag(hDelta(ftRonO.channel(i,1),event_start:event_finish)),real(hDelta(ftRonO.channel(i,1),event_start:event_finish))));
        if numel(phase)>numel(amp)
            phase=phase(1:numel(amp));
        end;
        if numel(amp)>numel(phase)
            amp=amp(1:numel(phase));
        end;
        ftRonO.delta_vs(i)=circ_r(phase',amp');
        ftRonO.delta_angle(i)=circ_mean(phase',amp');
    else
        ftRonO.delta(i)=0;
        ftRonO.delta_vs(i)=NaN;
        ftRonO.delta_angle(i)=NaN;
    end;
    
    [C]=intersect((event_start:event_finish),t_epoch_theta{ftRonO.channel(i,1),1});
    if ~isempty(C)
        ftRonO.theta(i)=1;
        phase = (atan2(imag(hTheta(ftRonO.channel(i,1),event_start:event_finish)),real(hTheta(ftRonO.channel(i,1),event_start:event_finish))));
        if numel(phase)>numel(amp)
            phase=phase(1:numel(amp));
        end;
        if numel(amp)>numel(phase)
            amp=amp(1:numel(phase));
        end;
        ftRonO.theta_vs(i)=circ_r(phase',amp');
        ftRonO.theta_angle(i)=circ_mean(phase',amp');
    else
        ftRonO.theta(i)=0;
        ftRonO.theta_vs(i)=NaN;
        ftRonO.theta_angle(i)=NaN;
    end;
    
    [C]=intersect((event_start:event_finish),t_epoch_spindle{ftRonO.channel(i,1),1});
    if ~isempty(C)
        ftRonO.spindle(i)=1;
        phase = (atan2(imag(hSpindle(ftRonO.channel(i,1),event_start:event_finish)),real(hSpindle(ftRonO.channel(i,1),event_start:event_finish))));
        if numel(phase)>numel(amp)
            phase=phase(1:numel(amp));
        end;
        if numel(amp)>numel(phase)
            amp=amp(1:numel(phase));
        end;
        ftRonO.spindle_vs(i)=circ_r(phase',amp');
        ftRonO.spindle_angle(i)=circ_mean(phase',amp');
    else
        ftRonO.spindle(i)=0;
        ftRonO.spindle_vs(i)=NaN;
        ftRonO.spindle_angle(i)=NaN;
    end;
end;
end;
end;

clear hSlow hDelta hTheta hSpindle
hSpike=gather(output_hilbert.eeg.hSpike);

if ~isempty(TRonS.start_t)
for i=1:numel(TRonS.channel(:,1))

    [a,b]=find(TRonS.start_t(i)<hfo_time_index & TRonS.finish_t(i)>hfo_time_index);
    if ~isempty(b)
    event_start=b(1);
    event_start=event_start-1;
    event_start_pdelay=event_start+125-1;
    [a,b]=find(TRonS.finish_t(i)<hfo_time_index & (TRonS.finish_t(i)+0.01)>hfo_time_index);
    event_finish=b(1);
    event_finish=event_finish+1;
    event_finish_pdelay=event_finish+125+1;
    if event_start_pdelay<1
        event_start_pdelay=1;
    end;
    if event_finish_pdelay>numel(hfo_amp(1,:))
        event_finish_pdelay=numel(hfo_amp(1,:));
    end;
    amp=hfo_amp(TRonS.channel(i,1),event_start_pdelay:event_finish_pdelay);
    phase = (atan2(imag(hSpike(TRonS.channel(i,1),event_start:event_finish)),real(hSpike(TRonS.channel(i,1),event_start:event_finish))));
        if numel(phase)>numel(amp)
            phase=phase(1:numel(amp));
        end;
        if numel(amp)>numel(phase)
            amp=amp(1:numel(phase));
        end;
        TRonS.vs(i)=circ_r(phase',amp');
        TRonS.angle(i)=circ_mean(phase',amp');
end;
end;
end;

if ~isempty(ftTRonS.start_t)
for i=1:numel(ftTRonS.channel(:,1))
    [a,b]=find(ftTRonS.start_t(i)<hfo_time_index & ftTRonS.finish_t(i)>hfo_time_index);
    if ~isempty(b)
    event_start=b(1);
    event_start=event_start-1;
    event_start_pdelay=event_start+125-1;
    [a,b]=find(ftTRonS.finish_t(i)<hfo_time_index & (ftTRonS.finish_t(i)+0.01)>hfo_time_index);
    event_finish=b(1);
    event_finish=event_finish+1;
    event_finish_pdelay=event_finish+125+1;
    if event_start_pdelay<1
        event_start_pdelay=1;
    end;
    if event_finish_pdelay>numel(hfo_amp(1,:))
        event_finish_pdelay=numel(hfo_amp(1,:));
    end;
    amp=fr_amp(ftTRonS.channel(i,1),event_start_pdelay:event_finish_pdelay);
    phase = (atan2(imag(hSpike(ftTRonS.channel(i,1),event_start:event_finish)),real(hSpike(ftTRonS.channel(i,1),event_start:event_finish))));
        if numel(phase)>numel(amp)
            phase=phase(1:numel(amp));
        end;
        if numel(amp)>numel(phase)
            amp=amp(1:numel(phase));
        end;
        ftTRonS.vs(i)=circ_r(phase',amp');
        ftTRonS.angle(i)=circ_mean(phase',amp');
end;
end;
end;

save(new_output_fname,'RonO','TRonS','FRonS','ftRonO','ftTRonS','ftFRonS','Total_TRonS','Total_FRonS','Total_RonO','Total_ftTRonS','Total_ftFRonS','Total_ftRonO','metadata');



