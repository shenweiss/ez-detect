
function times_testing(cycle_time, batches, file_name)
	addpath(genpath('/home/tomas-pastore/hfo_engine_1'));
	addpath(genpath('/home/tomas-pastore/ez-detect'));
	start = tic;
	ezdetect_putou70_e1_batch(file_name,'/home/tomas-pastore/TRCs/',cycle_time, batches);
	toc(start);
end
