function [output_fname] = eztop_putou_e1(fileData,metadata,montage, paths);

if montage == 0
    fname_var='_mp_';
else
    fname_var='_bp_'
end;

file_id = metadata.file_id;
output_fname = ['ezTop_' file_id fname_var metadata.file_block '.mat'];

if sum(fileData.total_ripple) < 40000  % exit function if memory overload
    if sum(fileData.total_fripple) < 15000 % exit function if memory overload
        
        %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        clearvars -except -regexp paths fileData vname_var output_fname metadata
        tic
        % Load Clips
        eegSetR = fileData.ripple_clip;
        eegSetfR = fileData.fripple_clip;
        %     eegSetR = eegSetR(1:4,:);
        
        % Load Clip Times
        cetR = fileData.ripple_clip_event_t;
        cetfR = fileData.fripple_clip_event_t;
        catR = fileData.ripple_clip_abs_t;
        catfR = fileData.fripple_clip_abs_t;
        
        % Clip Sample Size
        N = 1201;
        
        % Qualifying Clip Indicies
        % Qualifying Clip Indicies
        if numel(fileData.ripple_clip(1,:))==1
            eegSetR(:,2)={''};
            [ordR chanR] = find((cell2mat(cellfun(@(x) ~isempty(x) & length(x) > N, eegSetR.','UniformOutput',false))));
            indR = [chanR ordR];
            eegSetR(:,2)=[];
        else
            [ordR chanR] = find((cell2mat(cellfun(@(x) ~isempty(x) & length(x) > N, eegSetR.','UniformOutput',false))));
            indR = [chanR ordR];
        end;
        
        if numel(fileData.fripple_clip(1,:))==1
            eegSetfR(:,2)={''};
            [ordfR chanfR] = find((cell2mat(cellfun(@(x) ~isempty(x) & length(x) > N, eegSetfR.','UniformOutput',false))));
            indfR = [chanfR ordfR];
            eegSetfR(:,2)=[];
        else
            [ordfR chanfR] = find((cell2mat(cellfun(@(x) ~isempty(x) & length(x) > N, eegSetfR.','UniformOutput',false))));
            indfR = [chanfR ordfR];
        end;
        
        eegListR = zeros(size(indR,1),N);
        eegListfR = zeros(size(indfR,1),N);
        if ~isempty(indR)
            for ii = 1:size(indR,1)
                eegtemp = eegSetR{indR(ii,1), indR(ii,2)};
                n = length(eegtemp) - N;
                append = floor(n/2);
                eegListR(ii,:) = [eegtemp(1,append+1:end-append-mod(n,2))];
                cetRsh = cetR{indR(ii,1), indR(ii,2)} + 500 - 0.25;
                ctimeR(ii,:) = cetRsh-catR{indR(ii,1), indR(ii,2)};
            end
        end;
        if ~isempty(indfR)
            for ii = 1:size(indfR,1)
                eegtemp = eegSetfR{indfR(ii,1), indfR(ii,2)};
                n = length(eegtemp) - N;
                append = floor(n/2);
                eegListfR(ii,:) = [eegtemp(1,append+1:end-append-mod(n,2))];
                cetfRsh = cetfR{indfR(ii,1), indfR(ii,2)} + 500 - 0.25;
                ctimefR(ii,:) = cetfRsh-catfR{indfR(ii,1), indfR(ii,2)};
            end
        end;
        %     eegListR = repmat(eegListR, [10 1 1]);
        %     eegListR = eegListR(1:25e3,:);
        %     eegListfR = repmat(eegListfR, [15 1 1]);
        %     eegListfR = eegListfR(1:25e3,:);
        
        %% Initialize Spikes & Results Arrays in memory
        SpikesR = cell(size(eegListR,1),3);
        SpikesfR = cell(size(eegListfR,1),3);
        ResultsR = cell(size(eegListR,1),8);
        ResultsfR = cell(size(eegListfR,1),8);
        
        % SPIKES: Ripple Clips
        % ROBUST ADJUSTMENT: Limit clip sets to 20e3 clip blocks
        % if ~(isempty(eegListR) & isempty(eegListfR))
        Nint = 20e3;
        if ~isempty(indR)
            if size(eegListR,1) <= Nint
                SpikesR = ezSpikeOpt_0(eegListR);              % Ripple Spike Detection
            else
                [Neeg N] = size(eegListR)
                div = floor(Neeg/Nint);
                for ii = 1:div
                    b1 = (ii-1)*Nint+1;
                    b2 = ii*Nint;
                    SpikesR(b1:b2,:) = ezSpikeOpt_0(eegListR(b1:b2,:));              % Ripple Spike Detection
                end
                if div*Nint ~= Neeg
                    b1 = div*Nint+1;
                    b2 = Neeg;
                    SpikesR(b1:b2,:) = ezSpikeOpt_0(eegListR(b1:b2,:));              % Ripple Spike Detection
                end
                clear div b1 b2 ii Neeg N
            end
        end;
        % SPIKES: Fast Ripple clips
        % ROBUST ADJUSTMENT: Limit clip sets to 20e3 clip blocks
        if ~isempty(indfR)
            if size(eegListfR,1) <= Nint
                SpikesfR = ezSpikeOpt_0(eegListfR);             % Fast Ripple Spike Detection
            else
                [Neeg N] = size(eegListfR)
                div = floor(Neeg/Nint);
                for ii = 1:div
                    b1 = (ii-1)*Nint+1;
                    b2 = ii*Nint;
                    SpikesfR(b1:b2,:) = ezSpikeOpt_0(eegListfR(b1:b2,:));              % Fast Ripple Spike Detection
                end
                if div*Nint ~= Neeg
                    b1 = div*Nint+1;
                    b2 = Neeg;
                    SpikesfR(b1:b2,:) = ezSpikeOpt_0(eegListfR(b1:b2,:));              % Fast Ripple Spike Detection
                end
                clear div b1 b2 ii Neeg N
            end
        end;
        
        % RIPPLES: Ripple Clips
        % Unlike spike detection, large clip sets are divided into blocks of 1200 WITHIN ezRipOpt_0
        if ~isempty(indR)
            [ResultsR, AR] = ezRipOpt_0(eegListR);         % Ripple Detection
        else
            freqR = [50 250];
            widthR = 7;
            gwidthR = 5;
            [A foi toi tapm] = ezWavelet_single(1201,freqR, widthR, gwidthR);
            AR.A = gather(A);
            AR.foi = foi;
            AR.toi = toi;
            AR.tapm = gather(tapm);
        end;
        if isequal(ResultsR, cell(size(eegListR,1),8))
            ResultsR{1,1} = ResultsR;
            ResultsR(:,2:end) = [];
        end
        % FAST-RIPPLES: Fast-Ripple Clips
        % Unlike spike detection, large clip sets are divided into blocks of 1200 WITHIN ezRipOpt_0
        if ~isempty(indfR)
            [ResultsfR, AfR] = ezftRipOpt_0(eegListfR);     % Fast Ripple Detection
        else
            widthfR = 10;
            gwidthfR = 4;
            freqfR =  [150 600];
            freqfR1 = [150 370];
            freqfR2 = [371 600];
            [A1 foi1 toi tapm1] = ezWavelet_single(1201,freqfR1, widthfR, gwidthfR);
            [A2 foi2 toi tapm2] = ezWavelet_single(1201,freqfR2, widthfR, gwidthfR);
            [AfR.A1 AfR.A2] = gather(A1, A2);
            AfR.foi1 = foi1;
            AfR.foi2 = foi2;
            AfR.toi = toi;
            [AfR.tapm1 AfR.tapm2] = gather(tapm1, tapm2);
            gpuDevice(1);
        end;
        if isequal(ResultsfR, cell(size(eegListfR,1),8))
            ResultsfR{1,1} = ResultsfR;
            ResultsfR(:,2:end) = [];
        end
        
        % Check Ripple results for reflex Fast Ripple Opportunities
        if ~isempty(eegListR)
            eegListR_reflex = [];
            indR_reflex = [];
            for ii = 1:size(ResultsR,1)
                if size(ResultsR{ii,1},1) == 2
                    eegListR_reflex = [eegListR_reflex; eegListR(ii,:)];
                    indR_reflex = [indR_reflex; ii];
                end
            end
        else
            eegListR_reflex = [];
            indR_reflex = [];
        end;
        
        
        % Run Reflex Fast Ripple Band Detection on Ripple Clips
        if ~isempty(eegListR_reflex)
            [resultsR_reflex] = ezftRipOpt_reflex_0(eegListR_reflex,AfR);
            for jj = 1:size(indR_reflex,1)
                ii = indR_reflex(jj);
                ResultsR{ii,1}(2,:) = resultsR_reflex{jj,:};
            end
            clear eegListR_reflex resultsR_reflex
        end;
        
        % Check Fast Ripple results for reflex Fast Ripple Opportunities
        if ~isempty(eegListfR)
            eegListfR_reflex = [];
            indfR_reflex = [];
            for ii = 1:size(ResultsfR,1)
                if size(ResultsfR{ii,1},1) == 2
                    eegListfR_reflex = [eegListfR_reflex; eegListfR(ii,:)];
                    indfR_reflex = [indfR_reflex; ii];
                end
            end
        else
            eegListfR_reflex = [];
            indfR_reflex = [];
        end;
        
        if ~isempty(eegListfR_reflex)
            % Run Reflex Ripple-Band Detection on Fast Ripple Clips
            [resultsfR_reflex] = ezRipOpt_reflex_0(eegListfR_reflex,AR);
            for jj = 1:size(indfR_reflex,1)
                ii = indfR_reflex(jj);
                ResultsfR{ii,1}(2,:) = resultsfR_reflex{jj,:};
            end
        end;
        clear eegListfR_reflex resultsfR_reflex
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % OUTPUT STRUCTURE ASSEMBLY
        clearvars -except -regexp paths N ResultsR ResultsfR SpikesR SpikesfR catR catfR cetR cetRsh cetfR cetfRsh ctimeR ctimefR eegListR eegListfR eegSet* fileData indR indfR output_fname metadata
        
        % Output Structures: Ripple Detections
        
        % Set up Ripple Output Structure
        Total_RonO_rip = zeros(size(fileData.ripple_clip,1),1);
        Total_TRonS_rip = zeros(size(fileData.ripple_clip,1),1);
        Total_FRonS_rip = zeros(size(fileData.ripple_clip,1),1);
        Total_ftRonO_rip = zeros(size(fileData.ripple_clip,1),1);
        Total_ftTRonS_rip = zeros(size(fileData.ripple_clip,1),1);
        Total_ftFRonS_rip = zeros(size(fileData.ripple_clip,1),1);
        
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
        
        FRonS_rip.channel = [];
        FRonS_rip.start_t = [];
        FRonS_rip.finish_t = [];
        
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
        
        ftFRonS_rip.channel = [];
        ftFRonS_rip.start_t = [];
        ftFRonS_rip.finish_t = [];
        
        % Categorize events using the ripple detector and spike detector
        % results.  Then, organize the results in the appropriate event
        % structures.
        for ii = 1:size(eegListR,1)
            % for ii = 1:size(eegListR(1:150,:),1)
            % Categorize Ripple Associated Results
            if ResultsR{ii,1}{1,1} == 1
                if SpikesR{ii,1} == 1
                    % Format results in the approriate event structures
                    % using result2struc.m
                    [TRonS_rip] = result2struc_temp(TRonS_rip, ResultsR{ii,1}(1,:), indR(ii,:));         % MUST CORRECT result2struc!! Necessary Due to permissions.
                    %       [TRonS_rip] = result2struc(TRonS_rip, ResultsR{ii,1}(1,:), eegListR{ii,2}(1,:));
                    Total_TRonS_rip(indR(ii,1),1) = Total_TRonS_rip(indR(ii,1),1) + 1;
                    %       Total_TRonS_rip(eegListR{ii,2}(1),1) = Total_TRonS_rip(eegListR{ii,2}(1),1) + 1;
                elseif SpikesR{ii,1} == 0
                    [RonO_rip] = result2struc_temp(RonO_rip, ResultsR{ii,1}(1,:), indR(ii,:));         % MUST CORRECT result2struc!! Necessary Due to permissions.
                    %       [RonO_rip] = result2struc(RonO_rip, ResultsR{ii,1}(1,:), eegListR{ii,2}(1,:));
                    Total_RonO_rip(indR(ii,1),1) = Total_RonO_rip(indR(ii,1),1) + 1;
                    %       Total_RonO_rip(eegListR{ii,2}(1),1) = Total_RonO_rip(eegListR{ii,2}(1),1) + 1;
                end
            elseif ResultsR{ii,1}{1,1} == 0
                if SpikesR{ii,1} == 1 && size(ResultsR{ii,1},1) == 1
                    FRonS_rip.channel = [FRonS_rip.channel; indR(ii,:)];
                    FRonS_rip.start_t = [FRonS_rip.start_t; SpikesR{ii,2}];
                    FRonS_rip.finish_t = [FRonS_rip.finish_t; SpikesR{ii,3}];
                    Total_FRonS_rip(indR(ii,1),1) = Total_FRonS_rip(indR(ii,1),1) + 1;
                    %       Total_FRonS_rip(eegListR{ii,2}(1),1) = Total_FRonS_rip(eegListR{ii,2}(1),1) + 1;
                end
            end
            % Categorize Fast Ripple Associated Results
            if size(ResultsR{ii,1},1) == 2
                if ResultsR{ii,1}{2,1} == 1
                    if SpikesR{ii,1} == 1
                        [ftTRonS_rip] = result2struc_temp(ftTRonS_rip, ResultsR{ii,1}(2,:), indR(ii,:));         % MUST CORRECT result2struc!! Necessary Due to permissions.
                        %       [ftTRonS_rip] = result2struc(ftTRonS_rip, ResultsR{ii,1}(2,:), eegListR{ii,2}(1,:));
                        Total_ftTRonS_rip(indR(ii,1),1) = Total_ftTRonS_rip(indR(ii,1),1) + 1;
                        %       Total_ftTRonS_rip(eegListR{ii,2}(1),1) = Total_ftTRonS_rip(eegListR{ii,2}(1),1) + 1;
                    elseif SpikesR{ii,1} == 0
                        [ftRonO_rip] = result2struc_temp(ftRonO_rip, ResultsR{ii,1}(2,:), indR(ii,:));         % MUST CORRECT result2struc!! Necessary Due to permissions.
                        %       [ftRonO_rip] = result2struc(ftRonO_rip, ResultsR{ii,1}(2,:), eegListR{ii,2}(1,:));
                        Total_ftRonO_rip(indR(ii,1),1) = Total_ftRonO_rip(indR(ii,1),1) + 1;
                        %       Total_ftRonO_rip(eegListR{ii,2}(1),1) = Total_ftRonO_rip(eegListR{ii,2}(1),1) + 1;
                    end
                elseif ResultsR{ii,1}{2,1} == 0 & SpikesR{ii,1} == 1;
                    ftFRonS_rip.channel = [ftFRonS_rip.channel; indR(ii,:)];
                    ftFRonS_rip.start_t = [ftFRonS_rip.start_t; SpikesR{ii,2}];
                    ftFRonS_rip.finish_t = [ftFRonS_rip.finish_t; SpikesR{ii,3}];
                    Total_ftFRonS_rip(indR(ii,1),1) = Total_ftFRonS_rip(indR(ii,1),1) + 1;
                    % ftFRonS_rip.start_t(ii,1) = SpikesR{ii,2};
                    % ftFRonS_rip.finish_t(ii,1) = SpikesR{ii,3};
                    % Total_ftFRonS_rip(eegListR{ii,2}(1),1) = Total_ftFRonS_rip(eegListR{ii,2}(1),1) + 1;
                end
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Use tAdjust_0.m to Adjusts the start and stop times given by
        % zRipAlpha_0.m, from clip time stamps, to overall eeg time stamps.
        %   ****NOTE**** Investigate if there is a difference between tAdjust_0 and tAdjust!!!
        opt = 0;
        [TRonS_rip] = tAdjust_0_temp(TRonS_rip, fileData, opt);         % MUST CORRECT tAdjust_0!! Necessary Due to permissions.
        [RonO_rip] = tAdjust_0_temp(RonO_rip, fileData, opt);         % MUST CORRECT tAdjust_0!! Necessary Due to permissions.
        [FRonS_rip] = tAdjust_0_temp(FRonS_rip, fileData, opt);         % MUST CORRECT tAdjust_0!! Necessary Due to permissions.
        [ftTRonS_rip] = tAdjust_0_temp(ftTRonS_rip, fileData, opt);         % MUST CORRECT tAdjust_0!! Necessary Due to permissions.
        [ftRonO_rip] = tAdjust_0_temp(ftRonO_rip, fileData, opt);         % MUST CORRECT tAdjust_0!! Necessary Due to permissions.
        [ftFRonS_rip] = tAdjust_0_temp(ftFRonS_rip, fileData, opt);         % MUST CORRECT tAdjust_0!! Necessary Due to permissions.
        % [FRonS_rip] = tAdjust(FRonS_rip, fileData, opt);
        % [ftFRonS_rip] = tAdjust(ftFRonS_rip, fileData, opt);
        
        
        % Output Structures: Fast Ripple
        
        % Set up Fast Ripple Output Structure
        Total_RonO_frip = zeros(size(fileData.fripple_clip,1),1);
        Total_TRonS_frip = zeros(size(fileData.fripple_clip,1),1);
        Total_FRonS_frip = zeros(size(fileData.fripple_clip,1),1);
        Total_ftRonO_frip = zeros(size(fileData.fripple_clip,1),1);
        Total_ftTRonS_frip = zeros(size(fileData.fripple_clip,1),1);
        Total_ftFRonS_frip = zeros(size(fileData.fripple_clip,1),1);
        
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
        
        FRonS_frip.channel = [];
        FRonS_frip.start_t = [];
        FRonS_frip.finish_t = [];
        
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
        
        ftFRonS_frip.channel = [];
        ftFRonS_frip.start_t = [];
        ftFRonS_frip.finish_t = [];
        
        
        % Categorize events using the ripple detector and spike detector
        % results.  Then, organize the results in the appropriate event
        % structures.
        
        for ii = 1:size(eegListfR,1)
            % Categorize Ripple Associated Results
            if ResultsfR{ii,1}{1,1} == 1
                if SpikesfR{ii,1} == 1
                    % Format results in the approriate event structures
                    % using result2struc.m
                    [ftTRonS_frip] = result2struc_temp(ftTRonS_frip, ResultsfR{ii,1}(1,:), indfR(ii,:));         % MUST CORRECT result2struc!! Necessary Due to permissions.
                    Total_ftTRonS_frip(indfR(ii,1),1) = Total_ftTRonS_frip(indfR(ii,1),1) + 1;
                elseif SpikesfR{ii,1} == 0
                    [ftRonO_frip] = result2struc_temp(ftRonO_frip, ResultsfR{ii,1}(1,:), indfR(ii,:));         % MUST CORRECT result2struc!! Necessary Due to permissions.
                    Total_ftRonO_frip(indfR(ii,1),1) = Total_ftRonO_frip(indfR(ii,1),1) + 1;
                end
            elseif ResultsfR{ii,1}{1,1} == 0
                if SpikesfR{ii,1} == 1 && size(ResultsfR{ii,1},1) == 1
                    ftFRonS_frip.channel = [ftFRonS_frip.channel; indfR(ii,:)];
                    ftFRonS_frip.start_t = [ftFRonS_frip.start_t; SpikesfR{ii,2}];
                    ftFRonS_frip.finish_t = [ftFRonS_frip.finish_t; SpikesfR{ii,3}];
                    Total_ftFRonS_frip(indfR(ii,1),1) = Total_ftFRonS_frip(indfR(ii,1),1) + 1;
                end
            end
            
            % Categorize Fast Ripple Associated Results
            if size(ResultsfR{ii,1},1) == 2
                if ~isempty(ResultsfR{ii,1}{2,1})
                    if ResultsfR{ii,1}{2,1} == 1
                        if SpikesfR{ii,1} == 1
                            % Format results in the approriate event structures
                            % using result2struc.m
                            [TRonS_frip] = result2struc_temp(TRonS_frip, ResultsfR{ii,1}(2,:), indfR(ii,:));         % MUST CORRECT result2struc!! Necessary Due to permissions.
                            Total_TRonS_frip(indfR(ii,1),1) = Total_TRonS_frip(indfR(ii,1),1) + 1;
                        elseif SpikesfR{ii,1} == 0
                            [RonO_frip] = result2struc_temp(RonO_frip, ResultsfR{ii,1}(2,:), indfR(ii,:));         % MUST CORRECT result2struc!! Necessary Due to permissions.
                            Total_RonO_frip(indfR(ii,1),1) = Total_RonO_frip(indfR(ii,1),1) + 1;
                        end
                    elseif ResultsfR{ii,1}{2,1} == 0 & SpikesfR{ii,1} == 1;
                        FRonS_frip.channel = [FRonS_frip.channel; indfR(ii,:)];
                        FRonS_frip.start_t = [FRonS_frip.start_t; SpikesfR{ii,2}];
                        FRonS_frip.finish_t = [FRonS_frip.finish_t; SpikesfR{ii,3}];
                        Total_FRonS_frip(indfR(ii,1),1) = Total_FRonS_frip(indfR(ii,1),1) + 1;
                    end
                end
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Use tAdjust_0.m to adjust the start and stop times given by
        % zftRipAlpha_0.m, from clip time stamps, to overall eeg time
        % stamps.
        %   ****NOTE**** Investigate if there is a difference between tAdjust_0 and tAdjust!!!
        opt = 1;
        [TRonS_frip] = tAdjust_0_temp(TRonS_frip, fileData, opt);         % MUST CORRECT tAdjust_0!! Necessary Due to permissions.
        [RonO_frip] = tAdjust_0_temp(RonO_frip, fileData, opt);         % MUST CORRECT tAdjust_0!! Necessary Due to permissions.
        [FRonS_frip] = tAdjust_0_temp(FRonS_frip, fileData, opt);         % MUST CORRECT tAdjust_0!! Necessary Due to permissions.
        [ftTRonS_frip] = tAdjust_0_temp(ftTRonS_frip, fileData, opt);         % MUST CORRECT tAdjust_0!! Necessary Due to permissions.
        [ftRonO_frip] = tAdjust_0_temp(ftRonO_frip, fileData, opt);         % MUST CORRECT tAdjust_0!! Necessary Due to permissions.
        [ftFRonS_frip] = tAdjust_0_temp(ftFRonS_frip, fileData, opt);         % MUST CORRECT tAdjust_0!! Necessary Due to permissions.
        
        % Combine Output by Channel to create Total_* Arrays
        Total_RonO = Total_RonO_rip + Total_RonO_frip;
        Total_TRonS = Total_TRonS_rip + Total_TRonS_frip;
        Total_FRonS = Total_FRonS_rip + Total_FRonS_frip;
        Total_ftRonO = Total_ftRonO_rip + Total_ftRonO_frip;
        Total_ftTRonS = Total_ftTRonS_rip + Total_ftTRonS_frip;
        Total_ftFRonS = Total_ftFRonS_rip + Total_ftFRonS_frip;
        
        % Combine ripple and fast ripple structure fields: TRonS RonO ftTRonS ftRonO
        dRip = fieldnames(TRonS_frip);
        for ii = 1:size(dRip,1)
            eval(['TRonS.' dRip{ii,1} ' = [TRonS_rip.' dRip{ii,1} '; TRonS_frip.' dRip{ii,1} '];']);
            eval(['RonO.' dRip{ii,1} ' = [RonO_rip.' dRip{ii,1} '; RonO_frip.' dRip{ii,1} '];']);
            eval(['ftTRonS.' dRip{ii,1} ' = [ftTRonS_rip.' dRip{ii,1} '; ftTRonS_frip.' dRip{ii,1} '];']);
            eval(['ftRonO.' dRip{ii,1} ' = [ftRonO_rip.' dRip{ii,1} '; ftRonO_frip.' dRip{ii,1} '];']);
        end
        % Combine ripple and fast ripple structure fields: FRonS ftFRonS
        dSpk = fieldnames(FRonS_frip);
        for ii = 1:size(dSpk,1)
            eval(['FRonS.' dSpk{ii,1} ' = [FRonS_rip.' dSpk{ii,1} '; FRonS_frip.' dSpk{ii,1} '];']);
            eval(['ftFRonS.' dSpk{ii,1} ' = [ftFRonS_rip.' dSpk{ii,1} '; ftFRonS_frip.' dSpk{ii,1} '];']);
        end
        
        % else
        %     %%% IF ALL LISTS ARE EMPTY CREATE EMPTY STRUCTURES
        
        disp('File Complete: Ripples and Fast Ripples Processed');
        output_fname=[paths.ez_top_out output_fname];
        save(output_fname,'ftRonO','ftTRonS','RonO','TRonS','FRonS','ftFRonS','Total_FRonS','Total_ftFRonS','Total_ftRonO','Total_ftTRonS','Total_RonO','Total_TRonS','metadata');
        toc
        
    else
        RonO.channel=[];
        RonO.freq_av=[];
        RonO.freq_pk=[];
        RonO.power_av=[];
        RonO.power_pk=[];
        RonO.duration=[];
        RonO.start_t=[];
        RonO.finish_t=[];
        TRonS.channel=[];
        TRonS.freq_av=[];
        TRonS.freq_pk=[];
        TRonS.power_av=[];
        TRonS.power_pk=[];
        TRonS.duration=[];
        TRonS.start_t=[];
        TRonS.finish_t=[];
        ftRonO.channel=[];
        ftRonO.freq_av=[];
        ftRonO.freq_pk=[];
        ftRonO.power_av=[];
        ftRonO.power_pk=[];
        ftRonO.duration=[];
        ftRonO.start_t=[];
        ftRonO.finish_t=[];
        ftTRonS.channel=[];
        ftTRonS.freq_av=[];
        ftTRonS.freq_pk=[];
        ftTRonS.power_av=[];
        ftTRonS.power_pk=[];
        ftTRonS.duration=[];
        ftTRonS.start_t=[];
        ftTRonS.finish_t=[];
        FRonS.channel=[];
        FRonS.start_t=[];
        FRonS.finish_t=[];
        ftFRonS.channel=[];
        ftFRonS.start_t=[];
        ftFRonS.finish_t=[];
        Total_FRonS=[];
        Total_ftFRonS=[];
        Total_ftRonO=[];
        Total_ftTRonS=[];
        Total_RonO=[];
        Total_TRonS=[];
        disp('File Complete: Ripples and Fast Ripples Processed');
        output_fname=[paths.ez_top_out output_fname];
        save(output_fname,'ftRonO','ftTRonS','RonO','TRonS','FRonS','ftFRonS','Total_FRonS','Total_ftFRonS','Total_ftRonO','Total_ftTRonS','Total_RonO','Total_TRonS','metadata');
    end;
    
else
    RonO.channel=[];
    RonO.freq_av=[];
    RonO.freq_pk=[];
    RonO.power_av=[];
    RonO.power_pk=[];
    RonO.duration=[];
    RonO.start_t=[];
    RonO.finish_t=[];
    TRonS.channel=[];
    TRonS.freq_av=[];
    TRonS.freq_pk=[];
    TRonS.power_av=[];
    TRonS.power_pk=[];
    TRonS.duration=[];
    TRonS.start_t=[];
    TRonS.finish_t=[];
    ftRonO.channel=[];
    ftRonO.freq_av=[];
    ftRonO.freq_pk=[];
    ftRonO.power_av=[];
    ftRonO.power_pk=[];
    ftRonO.duration=[];
    ftRonO.start_t=[];
    ftRonO.finish_t=[];
    ftTRonS.channel=[];
    ftTRonS.freq_av=[];
    ftTRonS.freq_pk=[];
    ftTRonS.power_av=[];
    ftTRonS.power_pk=[];
    ftTRonS.duration=[];
    ftTRonS.start_t=[];
    ftTRonS.finish_t=[];
    FRonS.channel=[];
    FRonS.start_t=[];
    FRonS.finish_t=[];
    ftFRonS.channel=[];
    ftFRonS.start_t=[];
    ftFRonS.finish_t=[];
    Total_FRonS=[];
    Total_ftFRonS=[];
    Total_ftRonO=[];
    Total_ftTRonS=[];
    Total_RonO=[];
    Total_TRonS=[];
    disp('File Complete: Ripples and Fast Ripples Processed');
    output_fname=[paths.ez_top_out output_fname];
    save(output_fname,'ftRonO','ftTRonS','RonO','TRonS','FRonS','ftFRonS','Total_FRonS','Total_ftFRonS','Total_ftRonO','Total_ftTRonS','Total_RonO','Total_TRonS','metadata');
end;



