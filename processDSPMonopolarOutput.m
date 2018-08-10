
function processDSPMonopolarOutput(filename)

	load(filename, 'DSP_data_m', 'ez_tall_m','ez_tall_bp', 'hfo_ai', 'fr_ai', 'ez_tall_hfo_m', 'ez_tall_fr_m', 'metadata', 'num_trc_blocks', 'error_flag');

    if error_flag == 0
        [output_fname] = eztop_putou_e1(DSP_data_m,metadata,0);
        ez_detect_annotate_e1(output_fname, num_trc_blocks,0);
        ezpac_putou70_e1(ez_tall_m,ez_tall_hfo_m,ez_tall_fr_m,output_fname,metadata,0);
    end

end

