
function times_testing(cycle_time, batches, file_name)
	addpath(genpath('/home/tpastore/hfo_engine_1'));
	%addpath(genpath('/home/tpastore/hfo_engine_2'));
	addpath(genpath('/home/tpastore/ez-detect'));

	start = tic;
	%%%%%%ezdetect_putou70_e1_batch('448_sleep.edf','/home/tpastore/EDFs/',cycle_time, batches);
	%ezdetect_putou70_e1_batch('449_correct.edf','/home/tpastore/EDFs/',cycle_time, batches);

	ezdetect_putou70_e1_batch(file_name,'/home/tpastore/TRCs/',cycle_time, batches);
	toc(start);
end
