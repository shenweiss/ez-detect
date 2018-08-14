function processDSPMonopolarOutput(filename)
	
	setGlobalPaths(); %Just because it is used with a new matlab session. To be improved...
	%For now.. removed from load variables 'ez_tall_bp' 'hfo_ai', 'fr_ai' since they arent being used.
	%For future, we can optimize RAM allocation of that load. 

	load(filename, 'DSP_data_m', 'metadata', 'num_trc_blocks', ... 
				   'error_flag');

    if error_flag == 0
        montage = 0;
        [output_fname] = eztop_putou_e1(DSP_data_m,metadata,montage);
        ez_detect_annotate_e1(output_fname, num_trc_blocks,montage);
        
        clear DSP_data_m 
        load(filename,'ez_tall_m', 'ez_tall_hfo_m', 'ez_tall_fr_m');

        ezpac_putou70_e1(ez_tall_m,ez_tall_hfo_m,ez_tall_fr_m,output_fname,metadata,montage);
        
        clearvars
    else
    	disp('Error in processDSPMonopolarOutput, error_flag != 0')
    end

end

