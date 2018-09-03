% This function is called by main.m to perform dsp processing cutting data in chunks and using
% parallelized computing. This improves time performance corresponding to dsp processing. 

function process_parallel_block(eeg_data, metadata, chanlist, ez_montage, paths)    
    
    ez_tall = tall(eeg_data);
    clear eeg_data;
    %refactor that function
    [ez_tall_m, ez_tall_bp, metadata] = ez_lfbad(ez_tall, metadata, chanlist, ez_montage);
    clear ez_tall;
    metadata.montage = ez_montage;
    montage_names = struct();
    montage_names.monopolar = 'MONOPOLAR';
    montage_names.bipolar = 'BIPOLAR';

    if ~isempty(gather(ez_tall_m))
        
        disp(['Starting dsp ' montage_names.monopolar]);
        dsp_monopolar_output = ez_detect_dsp_monopolar(ez_tall_m, ez_tall_bp, metadata, paths);
        ez_tall_bp = dsp_monopolar_output.ez_tall_bp;
        hfo_ai = dsp_monopolar_output.hfo_ai;
        fr_ai = dsp_monopolar_output.fr_ai;
        metadata = dsp_monopolar_output.metadata;
        disp(['Finished dsp ' montage_names.monopolar]);
        saveDSPOutput(montage_names.monopolar, montage_names, dsp_monopolar_output, metadata, paths);
    else 
        hfo_ai = zeros(numel(gather(ez_tall_bp(1,:))),1)';
        fr_ai = hfo_ai;
    end

    if ~isempty(gather(ez_tall_bp))
        
        disp(['Starting dsp ' montage_names.bipolar]);
        dsp_bipolar_output = ez_detect_dsp_bipolar(ez_tall_bp, hfo_ai, fr_ai, metadata, paths);
        disp(['Finished dsp ' montage_names.bipolar]);
        saveDSPOutput(montage_names.bipolar, montage_names, dsp_bipolar_output);
    end
end

function saveDSPOutput(montage_name, montage_names, dsp_output, metadata, paths)
        disp(['Saving dsp ' montage_name ' output.']);

        if strcmp(montage_name, montage_names.monopolar)
            out_filename = ['dsp_m_output_' metadata.file_block '.mat'];
            saving_directory = paths.dsp_monopolar_out;
        else if strcmp(montage_name, montage_names.bipolar)
            out_filename = ['dsp_bp_output_' metadata.file_block '.mat'];
            saving_directory = paths.dsp_bipolar_out;
        else disp(["Unkown montage_name. Please see available montage_names" 
                  " inside getConstants local function"]);
        end

        save([saving_directory out_filename], '-struct', 'dsp_output');

        disp(['Dsp ' montage_name ' output was saved.']);
    end
end
