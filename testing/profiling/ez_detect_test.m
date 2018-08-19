function ez_detect_test(edf_dataset, cycle_time, blocks)
	start_time = 1;
	stop_time = cycle_time * blocks;
	main(edf_dataset, start_time, stop_time, cycle_time);
end
