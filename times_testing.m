function times_testing(cycle_time, batches, file_name)
	addpath(genpath('/home/mgatti/hfo_engine_1'));
	addpath(genpath('/home/mgatti/hfo_engine_2'));
	addpath(genpath('/home/mgatti/ez-detect'));

	start = tic;
	%%%%%%ezdetect_putou70_e1_batch('448_sleep.edf','/home/mgatti/EDFs/',cycle_time, batches);
	%ezdetect_putou70_e1_batch('449_correct.edf','/home/mgatti/EDFs/',cycle_time, batches);

	ezdetect_putou70_e1_batch(file_name,'~/EDFs/',cycle_time, batches);
	toc(start);
end
