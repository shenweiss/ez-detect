function processDSPBipolarOutput(filename)

    load(filename, 'DSP_data_bp', 'ez_tall_bp', 'ez_tall_hfo_bp', 'ez_tall_fr_bp', 'metadata', 'num_trc_blocks');

    [output_fname] = eztop_putou_e1(DSP_data_bp,metadata,1);
    ez_detect_annotate_e1(output_fname, num_trc_blocks,1);
    %ezpac_putou70_e1(ez_tall_bp,ez_tall_hfo_bp,ez_tall_fr_bp,output_fname,metadata,1);

end
