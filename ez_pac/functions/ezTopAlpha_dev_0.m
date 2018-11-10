% ezTopAlpha_dev_0.m 
% Created By Zachary J. Waldman
%
% ezTopAlpha_dev_0.m: Framework for the ezTop detector. Loads files, prepares
% the data, runs detections programs, then structures the results.
clear;

% Load Files and structure data apporopriately. This section can be
% suitably modified to fit alternate file structures.
d1 = dir('/home/tpastore/zac/398/');
d1(1:2,:) = [];
% for ii = size(d1,1):-1:1
%     if ~strcmp('IO0',d1(ii).name(1:3))
%         d1(ii,:) = [];
%     end
% end
% for aa = 1:size(d1)
for aa = 5
%     d2 = dir(['/home/tpastore/zac/eztop/in_data/' d1(aa).name '/']);
%     d2(1:2,:) = [];
%     for bb = 1:size(d2,1)
    for bb = 1
        pat = d1(aa).name;
        load(['/home/tpastore/zac/398/' d1(aa).name])
%         pat = d2(bb).name;
%         load(['/home/tpastore/zac/eztop/in_data/' d1(aa).name '/' pat])
        if strcmp('p', pat(end-6))
            file_data = DSP_data_bp;
        elseif strcmp('m', pat(end-6))
            file_data = DSP_data_m;
        end
%         mkdir('/home/tpastore/zac/eztop/in_data/IO_output/', [d1(aa).name '_output/']);
%         mkdir(['/home/tpastore/zac/eztop/in_data/IO_output/' d1(aa).name '_output/'], 'variables/');

        mkdir('/home/tpastore/zac/eztop/error_files_output/');
        mkdir('/home/tpastore/zac/eztop/error_files_output/variables/');

        output1 = ['/home/tpastore/zac/eztop/error_files_output/variables/var_' pat];
        output1 = ['/home/tpastore/zac/eztop/error_files_output/ezTop_' pat];

        clearvars -except d1 d2 file_data output* pat aa bb
        
        % Ripple clip start/stop time arrays
        rcet = file_data.ripple_clip_event_t;
        rcat = file_data.ripple_clip_abs_t;
        rcet1 = cell(size(rcet));
        rcets = cell(size(rcet));
        for ii = 1:size(rcet,1)
            for jj = 1:size(rcet,2)
                if ~isempty(rcet{ii,jj})
                    rcets{ii,jj} = rcet{ii,jj} + 500 - 0.25;
                    rcet1{ii,jj} = rcets{ii,jj}(1) - rcat{ii,jj}(1); 
                end
            end
        end
        
        % Fast Ripple clip start/stop time arrays
        frcet = file_data.fripple_clip_event_t;
        frcat = file_data.fripple_clip_abs_t;
        frcets = cell(size(frcet));
        frcet1 = cell(size(frcet));
        for ii = 1:size(frcet,1)
            for jj = 1:size(frcet,2)
                if ~isempty(frcet{ii,jj})
                    frcets{ii,jj} = frcet{ii,jj} + 500 - 0.25;
                    frcet1{ii,jj} = frcets{ii,jj}(1) - frcat{ii,jj}(1); 
                else
                    frcets{ii,jj} = [];
                    frcet1{ii,jj} = [];
                end
            end
        end

        eegListR = {};
        eegListfR = {};
        % Ripple Clip Arrays
        for ii = 1:size(file_data.ripple_clip,1)
            for jj = 1:size(file_data.ripple_clip,2)
                if length(file_data.ripple_clip{ii,jj}) >= 1200
                    eegListR = [eegListR; [file_data.ripple_clip(ii,jj) {[ii jj]} {0.3}]];
                elseif rcet1{ii,jj} > 0.06
                    eegListR = [eegListR; file_data.ripple_clip(ii,jj) {[ii jj]} rcet1(ii,jj)];
                end
            end
        end
        
        % Fast Ripple Clip arrays
        for ii = 1:size(file_data.fripple_clip,1)
            for jj = 1:size(file_data.fripple_clip,2)
                if length(file_data.fripple_clip{ii,jj}) >= 1200
                    eegListfR = [eegListfR; [file_data.fripple_clip(ii,jj) {[ii jj]} {0.3}]];
                elseif frcet1{ii,jj} > 0.06
                    eegListfR = [eegListfR; [file_data.fripple_clip(ii,jj) {[ii jj]} frcet1(ii,jj)]];
                end
            end
        end
        
        % Ripple Detections

        % Set up Ripple Output Structure
        Total_RonO_rip = zeros(size(file_data.ripple_clip,1),1);
        Total_TRonS_rip = zeros(size(file_data.ripple_clip,1),1);
        Total_FRonS_rip = zeros(size(file_data.ripple_clip,1),1);
        Total_ftRonO_rip = zeros(size(file_data.ripple_clip,1),1);
        Total_ftTRonS_rip = zeros(size(file_data.ripple_clip,1),1);
        Total_ftFRonS_rip = zeros(size(file_data.ripple_clip,1),1);

        RonO_rip.channel = [];
        RonO_rip.freq_av = [];
        RonO_rip.freq_pk = [];
        RonO_rip.power_av = [];
        RonO_rip.power_pk = [];
        RonO_rip.duration = [];
        RonO_rip.start_t = [];
        RonO_rip.finish_t = [];

        TRonS_rip.channel = [];
        TRonS_rip.freq_av = [];
        TRonS_rip.freq_pk = [];
        TRonS_rip.power_av = [];
        TRonS_rip.power_pk = [];
        TRonS_rip.duration = [];
        TRonS_rip.start_t = [];
        TRonS_rip.finish_t = [];

        ftRonO_rip.channel = [];
        ftRonO_rip.freq_av = [];
        ftRonO_rip.freq_pk = [];
        ftRonO_rip.power_av = [];
        ftRonO_rip.power_pk = [];
        ftRonO_rip.duration = [];
        ftRonO_rip.start_t = [];
        ftRonO_rip.finish_t = [];

        ftTRonS_rip.channel = [];
        ftTRonS_rip.freq_av = [];
        ftTRonS_rip.freq_pk = [];
        ftTRonS_rip.power_av = [];
        ftTRonS_rip.power_pk = [];
        ftTRonS_rip.duration = [];
        ftTRonS_rip.start_t = [];
        ftTRonS_rip.finish_t = [];

        results = {};

        % Loop through ripple clips and run ripple detector and spike
        % detector
        parfor ii = 1:size(eegListR,1)
            eeg = eegListR{ii,1};
            tC = eegListR{ii,3};
            [results{ii,1}] = zRipAlpha_0(eeg, tC);     % Ripple Detector w/ Frast Ripple Reflex Test
            [spike(ii,1)] = zSpikeAlpha_0(eeg, tC);     % Spike Detector
        end

        % Categorize events using the ripple detector and spike detector
        % results.  Then, organize the results in the appropriate event
        % structures.
        for ii = 1:size(eegListR,1)
            % Categorize Ripple Associated Results
            if results{ii,1}{1,1} == 1
                if spike(ii,1) == 1
                    % Format results in the approriate event structures
                    % using result2struc.m
                    [TRonS_rip] = result2struc(TRonS_rip, results{ii,1}(1,:), eegListR{ii,2}(1,:));
                    Total_TRonS_rip(eegListR{ii,2}(1),1) = Total_TRonS_rip(eegListR{ii,2}(1),1) + 1;
                elseif spike(ii,1) == 0
                    [RonO_rip] = result2struc(RonO_rip, results{ii,1}(1,:), eegListR{ii,2}(1,:));
                    Total_RonO_rip(eegListR{ii,2}(1),1) = Total_RonO_rip(eegListR{ii,2}(1),1) + 1;
                end
            elseif results{ii,1}{1,1} == 0
                if spike(ii,1) == 1 && size(results{ii,1},1) == 1
                    Total_FRonS_rip(eegListR{ii,2}(1),1) = Total_FRonS_rip(eegListR{ii,2}(1),1) + 1;
                end
            end
            % Categorize Fast Ripple Associated Results
            if size(results{ii,1},1) == 2
                if results{ii,1}{2,1} == 1
                    if spike(ii,1) == 1
                        [ftTRonS_rip] = result2struc(ftTRonS_rip, results{ii,1}(2,:), eegListR{ii,2}(1,:));
                        Total_ftTRonS_rip(eegListR{ii,2}(1),1) = Total_ftTRonS_rip(eegListR{ii,2}(1),1) + 1;
                    elseif spike(ii,1) == 0
                        [ftRonO_rip] = result2struc(ftRonO_rip, results{ii,1}(2,:), eegListR{ii,2}(1,:));
                        Total_ftRonO_rip(eegListR{ii,2}(1),1) = Total_ftRonO_rip(eegListR{ii,2}(1),1) + 1;
                    end
                elseif results{ii,1}{2,1} == 0 && spike(ii,1) == 1;
                    Total_ftFRonS_rip(eegListR{ii,2}(1),1) = Total_ftFRonS_rip(eegListR{ii,2}(1),1) + 1;
                end
            end

        end

        % Use tAdjust_0.m to Adjusts the start and stop times given by 
        % zRipAlpha_0.m, from clip time stamps, to overall eeg time stamps.
        opt = 0;
        [TRonS_rip] = tAdjust_0(TRonS_rip, file_data, opt);
        [RonO_rip] = tAdjust_0(RonO_rip, file_data, opt);
        [ftTRonS_rip] = tAdjust_0(ftTRonS_rip, file_data, opt);
        [ftRonO_rip] = tAdjust_0(ftRonO_rip, file_data, opt);
        
       
        % Fast Ripple Detection

        % Set up Fast Ripple Output Structure
        Total_RonO_frip = zeros(size(file_data.fripple_clip,1),1);
        Total_TRonS_frip = zeros(size(file_data.fripple_clip,1),1);
        Total_FRonS_frip = zeros(size(file_data.fripple_clip,1),1);
        Total_ftRonO_frip = zeros(size(file_data.fripple_clip,1),1);
        Total_ftTRonS_frip = zeros(size(file_data.fripple_clip,1),1);
        Total_ftFRonS_frip = zeros(size(file_data.fripple_clip,1),1);

        RonO_frip.channel = [];
        RonO_frip.freq_av = [];
        RonO_frip.freq_pk = [];
        RonO_frip.power_av = [];
        RonO_frip.power_pk = [];
        RonO_frip.duration = [];
        RonO_frip.start_t = [];
        RonO_frip.finish_t = [];

        TRonS_frip.channel = [];
        TRonS_frip.freq_av = [];
        TRonS_frip.freq_pk = [];
        TRonS_frip.power_av = [];
        TRonS_frip.power_pk = [];
        TRonS_frip.duration = [];
        TRonS_frip.start_t = [];
        TRonS_frip.finish_t = [];

        ftRonO_frip.channel = [];
        ftRonO_frip.freq_av = [];
        ftRonO_frip.freq_pk = [];
        ftRonO_frip.power_av = [];
        ftRonO_frip.power_pk = [];
        ftRonO_frip.duration = [];
        ftRonO_frip.start_t = [];
        ftRonO_frip.finish_t = [];

        ftTRonS_frip.channel = [];
        ftTRonS_frip.freq_av = [];
        ftTRonS_frip.freq_pk = [];
        ftTRonS_frip.power_av = [];
        ftTRonS_frip.power_pk = [];
        ftTRonS_frip.duration = [];
        ftTRonS_frip.start_t = [];
        ftTRonS_frip.finish_t = [];

        results_ft = {};
%
        % Loop through fast ripple clips and run fast ripple detector and 
        % spike detector
%        parfor ii = 1:size(eegListfR,1)
        for ii = 1:size(eegListfR,1)
            eeg = eegListfR{ii,1};
            tC = eegListfR{ii,3};
            [results_ft{ii,1}] = zftRipAlpha_0(eeg, tC);
            [spike_ft(ii,1)] = zSpikeAlpha_0(eeg, tC);
        end
%
        % Categorize events using the ripple detector and spike detector
        % results.  Then, organize the results in the appropriate event
        % structures.
        for ii = 1:size(eegListfR,1)
            % Categorize Ripple Associated Results
            if results_ft{ii,1}{1,1} == 1
                if spike_ft(ii,1) == 1
                    % Format results in the approriate event structures
                    % using result2struc.m
                    [ftTRonS_frip] = result2struc(ftTRonS_frip, results_ft{ii,1}(1,:), eegListfR{ii,2}(1,:));
                    Total_ftTRonS_frip(eegListfR{ii,2}(1),1) = Total_ftTRonS_frip(eegListfR{ii,2}(1),1) + 1;
                elseif spike_ft(ii,1) == 0
                    [ftRonO_frip] = result2struc(ftRonO_frip, results_ft{ii,1}(1,:), eegListfR{ii,2}(1,:));
                    Total_ftRonO_frip(eegListfR{ii,2}(1),1) = Total_ftRonO_frip(eegListfR{ii,2}(1),1) + 1;
                end
            elseif results_ft{ii,1}{1,1} == 0
                if spike_ft(ii,1) == 1 && size(results_ft{ii,1},1) == 1
                    Total_ftFRonS_frip(eegListfR{ii,2}(1),1) = Total_ftFRonS_frip(eegListfR{ii,2}(1),1) + 1;
                end
            end
            % Categorize Fast Ripple Associated Results
            if size(results_ft{ii,1},1) == 2
                if ~isempty(results_ft{ii,1}{2,1})
                    if results_ft{ii,1}{2,1} == 1
                        if spike_ft(ii,1) == 1
                            % Format results in the approriate event structures
                            % using result2struc.m
                            [TRonS_frip] = result2struc(TRonS_frip, results_ft{ii,1}(2,:), eegListfR{ii,2}(1,:));
                            Total_TRonS_frip(eegListfR{ii,2}(1),1) = Total_TRonS_frip(eegListfR{ii,2}(1),1) + 1;
                        elseif spike_ft(ii,1) == 0
                            [RonO_frip] = result2struc(RonO_frip, results_ft{ii,1}(2,:), eegListfR{ii,2}(1,:));
                            Total_RonO_frip(eegListfR{ii,2}(1),1) = Total_RonO_frip(eegListfR{ii,2}(1),1) + 1;
                        end
                    elseif results_ft{ii,1}{2,1} == 0 && spike_ft(ii,1) == 1;
                        Total_FRonS_frip(eegListfR{ii,2}(1),1) = Total_FRonS_frip(eegListfR{ii,2}(1),1) + 1;
                    end
                end
            end
        end

        % Use tAdjust_0.m to adjust the start and stop times given by 
        % zftRipAlpha_0.m, from clip time stamps, to overall eeg time 
        % stamps.
        opt = 1;
        [TRonS_frip] = tAdjust_0(TRonS_frip, file_data, opt);
        [RonO_frip] = tAdjust_0(RonO_frip, file_data, opt);
        [ftTRonS_frip] = tAdjust_0(ftTRonS_frip, file_data, opt);
        [ftRonO_frip] = tAdjust_0(ftRonO_frip, file_data, opt);

        % Combine Output by Channel to create Total_* Arrays
        Total_RonO = Total_RonO_rip + Total_RonO_frip;
        Total_TRonS = Total_TRonS_rip + Total_TRonS_frip;
        Total_FRonS = Total_FRonS_rip + Total_FRonS_frip;
        Total_ftRonO = Total_ftRonO_rip + Total_ftRonO_frip;
        Total_ftTRonS = Total_ftTRonS_rip + Total_ftTRonS_frip;
        Total_ftFRonS = Total_ftFRonS_rip + Total_ftFRonS_frip;

        % Combine ripple and fast ripple structure fields
        d = fieldnames(TRonS_frip);
        for ii = 1:size(d,1)
            eval(['TRonS.' d{ii,1} ' = [TRonS_rip.' d{ii,1} '; TRonS_frip.' d{ii,1} '];']);
            eval(['RonO.' d{ii,1} ' = [RonO_rip.' d{ii,1} '; RonO_frip.' d{ii,1} '];']);
            eval(['ftTRonS.' d{ii,1} ' = [ftTRonS_rip.' d{ii,1} '; ftTRonS_frip.' d{ii,1} '];']);
            eval(['ftRonO.' d{ii,1} ' = [ftRonO_rip.' d{ii,1} '; ftRonO_frip.' d{ii,1} '];']);
        end
        disp('File Complete: Ripples and Fast Ripples Processed')

        save(output1)
        save(output2,'ftRonO','ftTRonS','RonO','TRonS','Total_FRonS','Total_ftFRonS','Total_ftRonO','Total_ftTRonS','Total_RonO','Total_TRonS')
        
    end
end
