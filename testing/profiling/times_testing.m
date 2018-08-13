function times_testing(cycle_time, batches, file_name)
	start = tic;
	ezdetect_putou70_e1_batch(file_name,'~/EDFs/',cycle_time, batches);
	toc(start);
end
