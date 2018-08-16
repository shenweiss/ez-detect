function ez_detect_batch_profiling(edf_dataset, cycle_time, blocks)
	start = tic;
	start_time = 1;
	stop_time = cycle_time * blocks;
	ez_detect_batch(edf_dataset, start_time, stop_time, cycle_time);
	disp('Exiting from ez_detect_batch');
	toc(start);
end
