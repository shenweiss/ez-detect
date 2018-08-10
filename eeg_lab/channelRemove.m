function channelRemove(filein, chanNum);

%load('451_iy_concatOUT.mat');

output.hfo_mean(1,chanNum) = 0;
output.hfo_std(1,chanNum) = 0;
output.total_hfo(chanNum,1) = 0;
output.total_RonS(chanNum,1) = 0;
output.total_RSpW(chanNum,1)= 0;
output.total_RonO(chanNum,1) = 0;
output.counter_true_spikeR(chanNum,1) = 0;
output.counter_false_spikeR(chanNum,1) = 0;
output.counter_true_spwR(chanNum,1) = 0;
output.counter_false_spwR(chanNum,1) = 0;
output.counter_spindleR(chanNum,1) = 0;
output.counter_thetaR(chanNum,1) = 0;
output.counter_deltaR(chanNum,1) = 0;
output.counter_slowR(chanNum,1)= 0;

output.events_uv(chanNum,:) = {''};
output.events_zampHFO(chanNum,:) = {''};
output.events_freq(chanNum,:) = {''};
output.t_epoch.ripple(chanNum,:) = {''};
output.t_epoch.hfo4spike(chanNum,:) = {''};
output.t_epoch.hfo4spw(chanNum,:) = {''};
output.true_RonS_phase(chanNum,:) = {''};
output.zamp_true_spikeR(chanNum,:) = {''};
output.true_spikeR_1sec(chanNum,:) = {''};
output.false_RonS_phase(chanNum,:) = {''};
output.zamp_false_spikeR(chanNum,:) = {''};
output.false_spikeR_1sec(chanNum,:) = {''};
output.true_spwR_phase(chanNum,:) = {''};
output.zamp_true_spwR(chanNum,:) = {''};
output.true_spwR_1sec(chanNum,:) = {''};
output.false_spwR_phase(chanNum,:) = {''};
output.zamp_false_spwR(chanNum,:) = {''};
output.false_spwR_1sec(chanNum,:) = {''};
output.spindleR_phase(chanNum,:) = {''};
output.zamp_spindleR(chanNum,:) = {''};
output.spindleR_1sec(chanNum,:) = {''};
output.thetaR_phase(chanNum,:) = {''};
output.zamp_thetaR(chanNum,:) = {''};
output.thetaR_1sec(chanNum,:) = {''};
output.deltaR_phase(chanNum,:) = {''};
output.zamp_deltaR(chanNum,:) = {''};
output.deltaR_1sec(chanNum,:) = {''};
output.slowR_phase(chanNum,:) = {''};
output.zamp_slowR(chanNum,:) = {''};
output.slowR_1sec(chanNum,:) = {''};

outname = [filein(1,1:3),'_concatOUT_REV.mat'];
save(outname,'output');


load('453_zacout.mat');
freq.true_spikeR_1sec(chanNum,:) = {''};
freq.false_spikeR_1sec(chanNum,:) = {''};
freq.thetaR_1sec(chanNum,:) = {''};
freq.spindleR_1sec(chanNum,:) = {''};
freq.deltaR_1sec(chanNum,:) = {''};
freq.slowR_1sec(chanNum,:) = {''};
pow.true_spikeR_1sec(chanNum,:) = {''};
pow.false_spikeR_1sec(chanNum,:) = {''};
pow.thetaR_1sec(chanNum,:) = {''};
pow.spindleR_1sec(chanNum,:) = {''};
pow.deltaR_1sec(chanNum,:) = {''};
pow.slowR_1sec(chanNum,:) = {''};
hfo.true_spikeR_1sec(chanNum,:) = {''};
hfo.false_spikeR_1sec(chanNum,:) = {''};
hfo.thetaR_1sec(chanNum,:) = {''};
hfo.spindleR_1sec(chanNum,:) = {''};
hfo.deltaR_1sec(chanNum,:) = {''};
hfo.slowR_1sec(chanNum,:) = {''};

amp.zamp_true_spikeR(chanNum,:) = {''};
amp.zamp_false_spikeR(chanNum,:) = {''};

phase.true_RonS_phase(chanNum,:) = {''};
phase.false_RonS_phase(chanNum,:) = {''};

sec.true_spikeR_1sec(chanNum,:) = {''};
sec.false_spikeR_1sec(chanNum,:) = {''};

save('453_zacout.mat','freq','hfo','amp','phase','pow','sec');






