function ez_detect_profiling(edf_dataset, cycle_time, blocks)
	start = tic;
	start_time = 1;
	stop_time = cycle_time * blocks;
	main(edf_dataset, start_time, stop_time, cycle_time);
	toc(start);
end
