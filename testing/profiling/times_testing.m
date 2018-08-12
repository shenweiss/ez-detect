function times_testing(cycle_time, batches, file_name)
	addpath(genpath('/home/tomas-pastore/hfo_engine_1'));
	addpath(genpath('/home/tomas-pastore/hfo_engine_2'));
	addpath(genpath('/home/tomas-pastore/ez-detect'));

	start = tic;
	%%%%%%ezdetect_putou70_e1_batch('448_sleep.edf','/home/tomas-pastore/EDFs/',cycle_time, batches);
	%ezdetect_putou70_e1_batch('449_correct.edf','/home/tomas-pastore/EDFs/',cycle_time, batches);

	ezdetect_putou70_e1_batch(file_name,'~/EDFs/',cycle_time, batches);
	toc(start);
end
