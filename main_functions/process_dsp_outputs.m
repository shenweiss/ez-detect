
function process_dsp_outputs(dsp_outputs_path, method_labels, paths)
    files = struct2cell(dir([dsp_outputs_path 'dsp*']));
    filenames = files(1,:); 
    for i = 1:length(filenames)
        processDspOutput(filenames{i}, method_labels, paths);
    end
end

function processDspOutput(filename, method_labels, paths)
    %method_data is for example DSP_data, metadata, num_trc_blocks, ...
    % error_flag, ez_tall, ez_tall_hfo, ez_tall_fr
    
    if isfield(method_labels, 'error_flag') %this will be removed when once added the error_flag to dsp_bipolar function

        load(filename, method_labels.dsp_data, method_labels.metadata, ...
             method_labels.num_trc_blocks, method_labels.error_flag);

        if error_flag == 0 
            montage = 0;
            %these _m will be removed later with the conditional isfield, see backlog
            [output_fname] = eztop_putou_e1(DSP_data_m,metadata,montage,paths);
            ez_detect_annotate_e1(output_fname, num_trc_blocks,montage,paths);
            clear DSP_data_m;
            
            load(filename, method_labels.ez_tall, method_labels.ez_tall_fr, method_labels.ez_tall_hfo);
            ezpac_putou70_e1(ez_tall_m, ez_tall_fr_m, ez_tall_hfo_m, output_fname,metadata,montage,paths);
        else
            disp('Error in process_dsp_output error_flag != 0');
        end
    else  

        load(filename, method_labels.dsp_data, method_labels.metadata, ...
             method_labels.num_trc_blocks); %add error_flag to dsp_bipolar and remove condition

        montage = 1; %once removed the if condition, we can use method_name as montage code or put it as variable in the files (better choice)
        [output_fname] = eztop_putou_e1(DSP_data_bp,metadata,montage, paths);
        ez_detect_annotate_e1(output_fname, num_trc_blocks,montage, paths);
        clear DSP_data_bp; 
        
        load(filename, method_labels.ez_tall, method_labels.ez_tall_fr, method_labels.ez_tall_hfo);
        ezpac_putou70_e1(ez_tall_bp, ez_tall_fr_bp, ez_tall_hfo_bp, output_fname, metadata, montage, paths);
            
    end

end