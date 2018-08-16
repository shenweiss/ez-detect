function processDSPBipolarOutput(filename, paths)

    load(filename, 'DSP_data_bp', 'metadata', 'num_trc_blocks')

    montage = 1;
    [output_fname] = eztop_putou_e1(DSP_data_bp,metadata,montage, paths);
    ez_detect_annotate_e1(output_fname, num_trc_blocks,montage, paths);
    
    clear DSP_data_bp 
    load(filename,'ez_tall_bp', 'ez_tall_fr_bp', 'ez_tall_hfo_bp');

    ezpac_putou70_e1(ez_tall_bp, ez_tall_hfo_bp, ez_tall_fr_bp, output_fname, metadata, montage, paths);

    clearvars
    %if error_flag == 0
    %else
    %	disp('Error in processDSPBipolarOutput, error_flag != 0')
    %end

end
