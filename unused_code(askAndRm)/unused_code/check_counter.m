function [change_counter] = check_counter(filein1,filein2)
change_counter = [];
load(filein1)
load(filein2) 
after_tspikeR = rev_cleanOUT.total_tspikeR;
before_tspikeR = clean_output.counter_true_spikeR;
after_fspikeR = rev_cleanOUT.total_fspikeR;
before_fspikeR = clean_output.counter_false_spikeR;

change_counter.tspikeR = after_tspikeR-before_tspikeR;
change_counter.fspikeR = after_fspikeR-before_fspikeR;

outname = [filein1(1:3),'_changeRonS.mat'];
save(outname,'change_counter');