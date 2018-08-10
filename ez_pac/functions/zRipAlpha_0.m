function [results] = zRipAlpha_0(varargin)
% zRipAlpha_0 by Zachary J. Waldman
% 
% Ripple Detector using time frequency analysis combined with topgraphical 
% techniques. Includes lower frequency reflex test, as well as a seperate 
% upper frequency reflex test using zftRipAlpha_reflex_0.m.
% Input:
%   eeg:    EEG clip with a sampling frequency of 2000 Hz, and at least 651
%           samples
%   tC:     Onset time of candidate event relative to the start of the
%           clip, where the clip starts at t=0. tC must be greater than
%           0.06. 
% Output
%   results = [{det} {avFreq} {pkFreq} {avMag} {pkMag} {tDur} {tStart} {tEnd}];
%       det     =   detector determination value (no units).
%       avFreq  =   power weighted mean frequency (Hz).
%       pkFreq  =   frequency at peak power magnitude (no units).
%       avMag   =   average power magnitude (no units).
%       pkMag   =   peak power magnitude (no units).
%       tDur    =   event duration, (seconds).
%       tStart  =   event start time relative to clip, (seconds)
%       tEnd    =   event end time relative to clip, (seconds)


if nargin == 1
    eeg = varargin{1};
    tC = 0.3;
    plots = 0;
elseif nargin == 2;
    eeg = varargin{1};
    tC = varargin{2};
    plots = 0;
elseif nargin == 3
    eeg = varargin{1};
    tC = varargin{2};
    plots = varargin{3};
end
if tC <= 0.1
    tLow = 0;
else
    tLow = tC - 0.1;
end
tHigh = tC + 0.1;

% clearvars -except eegListR
% for i = 1:30;
% eeg = eegListR{i,1};

Fs = 2000;                  % Sampling Frequency
P = 2;                      % Group Population Limit
% tC = 0.3;                   % Event location
tB = 0.05;                  % Buffer timex
fmin = 50;                 % Min Frequency for Analysis
fmax = 250;                 % Max Frequency for Analysis
fLow = 80;                 % Lower Limit Frequency for Event
fHigh = 200;
fLowR = 70;

    P = 2;
    warning('off')
    t = (1: length(eeg))/Fs;
    % Define Event Start/Stop Times
    dt = [t(1) t(end)];

    % Preprocessing
    cfg = [];
    cfg.showcallinfo = 'no';            % Suppress Output
    cfg.demean = 'yes';                 % Baseline correction

    % Create Data Structure
    data = [];
    data.trial{1,1} = eeg;          % 1 trial containing 8 channels
    data.time{1,1} = t;             % Assign spike time vector
    data.sampleinfo = [find(t==dt(1)) find(t==dt(2))];      % start stop indicies of spike within original data
    data.fsample = Fs;                  % Assign sampling frequency
    data.label{1,1} = 'all';

    % Execute Preprocessing
    cfg.feedback = 'none';
    [data_proc] = ft_preprocessing(cfg, data);  % Bandpass filtered and baseline corrected data

    % Time Frequency Analysis
    cfg = [];
    cfg.showcallinfo = 'no';            % Suppress Output

    % Specify Freq of Interest
    cfg.foi = [fmin:fmax];
    cfg.method      = 'tfr';        % Method of Analysis
%     cfg.gwidth = 4;
%     cfg.width = 10;
    cfg.gwidth      = 5;
    cfg.output      = 'pow';        % Power spectrum (try without)
    cfg.taper       = 'hanning';    % Tapering Window(try without)
    cfg.pad         = 'nextpow2';

    % Times of interest 
    cfg.toi = t;

    % Execute Frequency Analysis
    cfg.feedback = 'no';
    data_freq = ft_freqanalysis(cfg, data_proc);

    % Time-Freq Plot with Filtered EEG
    % Configure Plot Parameters
    cfg = [];
    cfg.channel = 'all';
    cfg.baseline     = dt;              % What times used to determine baseline correction
    cfg.colormap    = jet;              % Color Map
    cfg.baselinetype = 'absolute';      % Baseline type
    cfg.maskstyle    = 'saturation';	

    input = [];
    input.data = data_freq;
    input.chan = 'all';
    input.time = dt;

    input.xlim = [0 t(end)];  
    cfg.feedback = 'n one';
    
    % Generate Time-Frequency Map
    [cdat_raw, hdat_raw, vdat_raw] = tfdatmat(input);
    
    det = [];
    avFreq = [];
    pkFreq = [];
    avMag = [];
    pkMag = [];
    tDur = [];
    tStart = [];
    tEnd = [];
    
    cdat = cdat_raw;
    hdat = hdat_raw;
    vdat = vdat_raw;

    vdat0 = vdat(vdat(:,:) >= fLow);
    hdat0 = hdat(:, (hdat(:,:) >= tLow & hdat(:,:) <= tHigh));
    cdat0 = cdat(ismember(vdat,vdat0),ismember(hdat,hdat0));
    
    levels = linspace(min(cdat0(:)), max(cdat0(:)), 52)';
    levels = levels(2:51);
    C = contourc(hdat0, vdat0, cdat0, levels)';
    
    % FIND ALL CONTOURS ABOVE THRESHOLD AND GROUP CLOSED LOOP CONTOURS
    thresh = 0.2*max(cdat0(:));         % Set threshold to 20% of max power
    ind = find(C(:) > thresh);          % Index of Contours above threshold
    [r c] = find(ind > size(C,1));
    r = unique(r);
    ind(r,:) = [];
    
    olc = {};
    if isempty(C(ind)) || thresh < 1 || size(find(C(:) > thresh),1) > size(C,1)
        disp('NO EVENT DETECTED')
    else
        % clsd_lp: FIND ALL CLOSED LOOP CONTOURS ABOVE THRESHOLD
        clsd_lp = {};   
        cont = {};
        for ee = 1:size(ind,1)
            cont{ee,1} = [C((ind(ee)):(ind(ee)+C(ind(ee),2)),:)];
            if isequal([C(ind(ee)+1,:)], [C(ind(ee)+C(ind(ee),2),:)]);
                clsd_lp = [clsd_lp; {[C((ind(ee)):(ind(ee)+C(ind(ee),2)),:)]}];
            elseif isequal([C(ind(ee)+1,2) C(ind(ee)+C(ind(ee),2),2)], [fmax fmax]);        % (#1)
                olc = [olc; {[C((ind(ee)):(ind(ee)+C(ind(ee),2)),:)]}];                     % (#1)
            end
        end    

        % GROUP CLOSED-LOOP CONTOURS 
        cClean = clsd_lp;
        clp_grps = cell(0,1);
        grp_ind = 0;
        clcGrp = {};
        cGrp = {};

        while length(cClean) ~= 0
            % IF P=1, THE ind_low FUNCTION BELOW WILL NOT INCLUDE ANY GROUPS WITH FEWER
            % THAN P CONTOURS (i.e. single closed-loop countours), and will not include
            % them in clp_grps. Therefore, the removal loops above are unnecessary.
            ind_low = find(arrayfun(@(xx) inpolygon(cClean{end,1}(2,1), cClean{end,1}(2,2), cClean{xx,1}(2:end,1), cClean{xx,1}(2:end,2)), [1:length(cClean(1:end-1,1))]),1);

            if ~isempty(ind_low) 
                grp_ind = grp_ind + 1;      % Increment Group Index
                clp_grps{grp_ind,:} = cClean(end,:);
                cClean(end,:) = [];
                for jj = length(cClean):-1:ind_low
                    if inpolygon(cClean{jj,1}(2,1), cClean{jj,1}(2,2), cClean{ind_low,1}(2:end,1), cClean{ind_low,1}(2:end,2))
                        clp_grps{grp_ind,1}{end+1,:} = cClean{jj,:};
                        cClean(jj,:) = [];
                    end
                end
            elseif isempty(ind_low)
                cClean(end,:) = [];
            end
        end
        if length(clsd_lp) == 0
            det = 0; 
            avFreq = 0; 
            avMag = 0; 
            tStart = 0;
            tEnd = 0;

            avFreq = 0;         
            avMag = 0;          
            tDur = 0;           
            pkFreq = 0;         
            pkMag = 0;          
            
        elseif length(clp_grps) == 0
           det = 0; 
            avFreq = 0; 
            avMag = 0; 
            tStart = 0;
            tEnd = 0;
            
            avFreq = 0;         
            avMag = 0;          
            tDur = 0;           
            pkFreq = 0;         
            pkMag = 0;          
            
        elseif length(clp_grps) >= 1

            % Calculate Frequency and Time Weighted Averages for All Remaining Groups
            cGrp = {};
            for jj = 1:length(clp_grps)
                cGrp(jj,:) = [clp_grps(jj,1) [jj]];
            end
            [H, V] = meshgrid(hdat0,vdat0);
            ctMin = arrayfun(@(x) abs(min(clp_grps{x,1}{end,1}(2:end,1)) - tC) < 0.010, [1:length(clp_grps)]);      % Logic Array: True if minimum time coordinate is less than 10ms from 0.5   (##01)
            perim = {};
            inLg = {};
            freq_wm = {};
            freqRef = {};
            time_wm = {};
            pow_m = {};
            powerRef = {};
            dtEv = {};
            cgrpF = {};         
            cdatGrp = {};       
            pow_pk = {};        
            time_pk = {};       
            freq_pk = {};       
            for jj = length(clp_grps):-1:1
                perim{jj,1} = clp_grps{jj,1}{end,1}(2:end,:);
                inLg{jj,1} = inpolygon(H,V,perim{jj,1}(:,1),perim{jj,1}(:,2));
                freq_wm{jj,1} = sum(V(inLg{jj,1}).*cdat0(inLg{jj,1}))/sum(cdat0(inLg{jj,1}));
                freqRef{jj,1} = freq_wm{jj,1};
                time_wm{jj,1} = sum(H(inLg{jj,1}).*cdat0(inLg{jj,1}))/sum(cdat0(inLg{jj,1}));
                pow_m{jj,1} = mean(cdat0(inLg{jj,1}));                                       
                powerRef{jj,1} = pow_m{jj,1};
                dtEv{jj,1} = time_wm{jj,1}-tC;  
                
                cdatGrp{jj,1} = cdat0.*inLg{jj,1};
                [rPk cPk] = find(cdatGrp{jj,1} == max(cdatGrp{jj,1}(:)));
                pow_pk{jj,1} = max(cdatGrp{jj,1}(:));
                time_pk{jj,1} = H(rPk,cPk);
                freq_pk{jj,1} = V(rPk,cPk); 
                
                % REMOVE GROUPS WITH MEAN TIME > 30 ms MINIMUM TIME > 10 ms
                % FROM 0.5 MARK OR IF MEAN FREQ ABOVE 200 OR IF GROUP
                % CONTAINS <= P CONTOURS
                if (~ctMin(1,jj) && abs(dtEv{jj,1}) > 0.03) || freq_wm{jj,1} > fHigh || length(cGrp{jj,1}) <= P
                    cGrp(jj,:) = [];
                end
            end
            if size(cGrp,1) == 0    % If there are no groups within time constraints
                det = 0; 
                avFreq = 0; 
                avMag = 0; 
                tStart = 0;
                tEnd = 0;
                tDur = 0;           
                pkFreq = 0;         
                pkMag = 0;          

            elseif size(cGrp,1) == 1    % if there is 1 group within time constraints
                if isempty(find(cGrp{1,1}{end,1}(2:end,1) - tC > 0)) % If all of the perimeter is below 0.5 (##01)
                    det = 0; 
                    avFreq = 0; 
                    avMag = 0; 
                    tDur = 0;           
                    pkFreq = 0;         
                    pkMag = 0;          
                    tStart = 0;
                    tEnd = 0;

                else
                    det = 1; 
                    avFreq = freqRef{cGrp{1,2},1};
                    avMag = powerRef{cGrp{1,2},1}; 
                    tStart = min(cGrp{1,1}{end,1}(2:end,1));
                    tEnd = max(cGrp{1,1}{end,1}(2:end,1));
                    cgrpF = cGrp(1,:);              
                    tDur = tEnd - tStart;           
                    pkFreq = freq_pk{cGrp{1,2},1};  
                    pkMag = pow_pk{cGrp{1,2},1};    
                            
                end
            elseif  size(cGrp,1) > 1    % if there are multiple groups within time constraints.
                if sum([dtEv{[cGrp{:,2}],1}]' > 0) > 0 % Make sure there is at least 1 group whose t_wm is positive
                    if size(cGrp,1) == 1    % if there 1 group with positive t_wm
                        det = 1; 
                        avFreq = freqRef{cGrp{1,2},1};
                        avMag = powerRef{cGrp{1,2},1};
                        tStart = min(cGrp{1,1}{end,1}(2:end,1));
                        tEnd = max(cGrp{1,1}{end,1}(2:end,1));
                        cgrpF = cGrp(1,:);              
                        tDur = tEnd - tStart;           
                        pkFreq = freq_pk{cGrp{1,2},1};  
                        pkMag = pow_pk{cGrp{1,2},1};    
                        
                    elseif size(cGrp,1) >= 1    % if there is more than one positive t_wm group
                        if sum(arrayfun(@(x) sum(cGrp{x,1}{end,1}(2:end,1) < tC) > 0, [1:size(cGrp,1)])) == 0  % if No groups cross 0.5 (##01)
                            det = 1; 
                            avFreq = freqRef{cGrp{1,2},1};
                            avMag = powerRef{cGrp{1,2},1}; 
                            tStart = min(cGrp{1,1}{end,1}(2:end,1));
                            tEnd = max(cGrp{1,1}{end,1}(2:end,1));
                            cgrpF = cGrp(1,:);              
                            tDur = tEnd - tStart;           
                            pkFreq = freq_pk{cGrp{1,2},1};  
                            pkMag = pow_pk{cGrp{1,2},1};    
                            
                        else
                            xx = arrayfun(@(x) sum(cGrp{x,1}{end,1}(2:end,1) < tC) > 0, [1:size(cGrp,1)]);  
                            det = 1; 
                            cGrp2 = cGrp(xx,:);
                            x = cGrp{xx,2};
                            avFreq = freqRef{x,1};
                            avMag = powerRef{x,1}; 
                            tStart = min(cGrp2{1,1}{end,1}(2:end,1));
                            tEnd = max(cGrp2{1,1}{end,1}(2:end,1));
                            cgrpF = cGrp2(1,:);              
                            tDur = tEnd - tStart;            
                            pkFreq = freq_pk{cGrp2{1,2},1};  
                            pkMag = pow_pk{cGrp2{1,2},1};    
                        end
                    end
                else
                    [B I] = min(abs([dtEv{[cGrp{:,2}],:}]' - tC)); % if all group's have t_wm < 0 choose the group closest to 0.5 (##01)
                    det = 1; 
                    avFreq = freqRef{cGrp{I,2},1};
                    avMag = powerRef{cGrp{I,2},1}; 
                    tStart = min(cGrp{I,1}{end,1}(2:end,1));
                    tEnd = max(cGrp{I,1}{end,1}(2:end,1));
                    cgrpF = cGrp(I,:);              
                    tDur = tEnd - tStart;           
                    pkFreq = freq_pk{cGrp{I,2},1};  
                    pkMag = pow_pk{cGrp{I,2},1};    
                    
                end
            end
        end
    end

    % REFLEX TESTING AT 80HZ LOWER LIMIT
    if det ~= 0
        if min(cgrpF{1,1}{end,1}(:,2)) <= fLow+1
            xpk = time_pk{cgrpF{1,2},1};
            ypk = freq_pk{cgrpF{1,2},1};

            vdat0 = vdat(vdat(:,:) >= fLowR);
            hdat0 = hdat(:, (hdat >= tLow & hdat <= tHigh));
            cdat0 = cdat(ismember(vdat,vdat0),ismember(hdat,hdat0));
            C = contourc(hdat0, vdat0, cdat0, levels)';
            ind = find(ismember(C(:,1),levels(levels > thresh)));                % Index of Contours above threshold 

            clsd_lp = cell(0,1);
            cont = {};
            for ee = 1:size(ind,1)
                cont{ee,1} = [C((ind(ee)):(ind(ee)+C(ind(ee),2)),:)];
                if isequal([C(ind(ee)+1,:)], [C(ind(ee)+C(ind(ee),2),:)]);
                    clsd_lp = [clsd_lp; {[C((ind(ee)):(ind(ee)+C(ind(ee),2)),:)]}];
                end
            end

            cGrp{1,1} = {};
            for jj = 1:length(clsd_lp)
                if inpolygon(xpk, ypk, clsd_lp{jj,1}(2:end, 1), clsd_lp{jj,1}(2:end, 2));
                    cGrp{1,1} = [clsd_lp(jj,1); cGrp{1,1}];
                end
            end

            [H, V] = meshgrid(hdat0,vdat0);
            perim = cGrp{1,1}{end,1}(2:end,:);
            inLg = inpolygon(H,V,perim(:,1),perim(:,2));

            avFreq = sum(V(inLg).*cdat0(inLg))/sum(cdat0(inLg));      % 2  Weighted Mean Frequency (Reflex 80)
            avMag  = mean(cdat0(inLg));                                   % 4  Mean Power  (Reflex 80)
            tDur   = (max(perim(:,1)) - min(perim(:,1)));                % 6  tDuration  (Reflex 80)
        end
    end
    
    results(1,:) = [{det} {avFreq} {pkFreq} {avMag} {pkMag} {tDur} {tStart} {tEnd}];
    
   % REFLEX TESTING AT 200 HZ
   if ~isempty(olc)
       [results(2,:)] = zftRipAlpha_reflex_0(eeg);
   end

% %%%%%%%%%%%%%%%%%% PLOTS %%%%%%%%%%%%%%%%%%
if plots
    clcGrp = clp_grps;
    color2 = lines(10);          % Color 1 for plots
    color = hsv(10);           % Color 2 for plots
    color(4:5,:) = [];

    % Surf
    figure(2)
    cla
    surf(hdat0,vdat0,cdat0,'EdgeColor','none')
    ylim([fLow fHigh])
    view(0,90)
    colorbar

    % EEG
    hfFilt = fir1(round(length(eeg)/3)-1,[fLow/(Fs/2) fHigh/(Fs/2)]); 
    eegF = filtfilt(hfFilt,1,eeg);
    figure(1)
    cla
    plot(hdat0, eegF(ismember(hdat,hdat0))-mean(eegF(ismember(hdat,hdat0))))
    hold on
    plot(hdat0, (eeg(ismember(hdat,hdat0)) - mean(eeg(hdat >= 0.28 & hdat<= 0.32)))/4)
    hold off
    ylim([-50 50])

    figure(3)
    cla

    C = contour(hdat0,vdat0, cdat0, levels)';
    hold on

    % PLOT ALL CONTOURS ABOVE THRESHOLD (MARRON)
    contour(hdat0, vdat0, cdat0, levels(levels>thresh), 'LineWidth', 2, 'LineColor', color2(7,:));

    % PLOT ALL CLOSED-LOOP CONTROUS ABOVE THRESHOLD (BLACK)
    for ii = 1:size(clsd_lp,1)
        plot(clsd_lp{ii,1}(2:end,1), clsd_lp{ii,1}(2:end,2), 'LineWidth', 2, 'Color', 'k')
    end


    % PLOT CLOSED-LOOP GROUPS  (BLUE RED ORANGE PURPLE)     
    for ll = 1:length(clcGrp)
        for jj = 1:length(clcGrp{ll,1})
            plot(clcGrp{ll,1}{jj,1}(2:end,1), clcGrp{ll,1}{jj,1}(2:end,2), 'LineWidth', 2.5, 'Color', color(rem(ll-1,8)+1,:));
        end
    end
    colorbar

    % PLOT FINAL EVENT
    for ll = 1:size(cGrp,1)
        for jj = 1:length(cGrp{ll,1})
            plot(cGrp{ll,1}{jj,1}(2:end,1), cGrp{ll,1}{jj,1}(2:end,2), 'LineWidth', 2.5, 'Color', 'g');
        end
    end
    title(['Trial ' num2str(i)]) %num2str(detect)])
    hold off
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% switch nargout
%     case 1
%         varargout{1} = det;
%     case 2
%         varargout{1} = det;
%         varargout{2} = avFreq;
%     case 3
%         varargout{1} = det;
%         varargout{2} = avFreq;
%         varargout{3} = avMag;
%     case 4
%         varargout{1} = det;
%         varargout{2} = avFreq;
%         varargout{3} = avMag;
%         varargout{4} = tDur;
%     case 5                      % (##08)
%         varargout{1} = det;
%         varargout{2} = avFreq;
%         varargout{3} = avMag;
%         varargout{4} = tDur;
%         varargout{5} = pkFreq;
%     case 6                      % (##08)
%         varargout{1} = det;
%         varargout{2} = avFreq;
%         varargout{3} = avMag;
%         varargout{4} = tDur;
%         varargout{5} = pkFreq;
%         varargout{6} = pkMag;
% end
