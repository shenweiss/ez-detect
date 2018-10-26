function [results] = ezRipInt_0(eeg, cdat, hdat, vdat, plots)

if nargin == 4
    plots = 0;
end

Fs = 2000;                  % Sampling Frequency
P = 2;                      % Group Population Limit

t = hdat;
tC = 0.3;                   % Event location
tLow = tC - 0.1;
tHigh = tC + 0.1;
tB = 0.05;                  % Buffer timex
fmin = vdat(1);                 % Min Frequency for Analysis
fmax = vdat(end);                 % Max Frequency for Analysis
fLow = 80;                 % Lower Limit Frequency for Event
fHigh = 200;
fLowR = 70;

det = [];
avFreq = [];
pkFreq = [];
avMag = [];
pkMag = [];
tDur = [];
tStart = [];
tEnd = [];

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
    results(1,:) = [{0} {0} {0} {0} {0} {0} {0} {0}];
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
                % BUG FIX 10/24/17
                % [rPk cPk] = find(cdatGrp{jj,1} == max(cdatGrp{jj,1}(:)));
                % pow_pk{jj,1} = max(cdatGrp{jj,1}(:));
                [pow_pk{jj,1} iPk] = max(cdatGrp{jj,1}(:));
                [rPk cPk] = ind2sub(size(cdatGrp{jj,1}),iPk);
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
   [results(2,:)] = {[] [] [] [] [] [] [] []};
end

% %%%%%%%%%%%%%%%%%% PLOTS %%%%%%%%%%%%%%%%%%
if plots
    clcGrp = clp_grps;
    color2 = lines(10);          % Color 1 for plots
    color = hsv(10);           % Color 2 for plots
    color(4:5,:) = [];

    % Surf
    figure(5)
    cla
    surf(hdat0,vdat0,cdat0,'EdgeColor','none')
    ylim([fLow fHigh])
    view(0,90)
    colorbar

    % EEG
    hfFilt = fir1(round(length(eeg)/3)-1,[fLow/(Fs/2) fHigh/(Fs/2)]); 
    eegF = filtfilt(hfFilt,1,eeg);
    figure(4)
    cla
    plot(hdat0, eegF(ismember(hdat,hdat0))-mean(eegF(ismember(hdat,hdat0))))
    hold on
    plot(hdat0, (eeg(ismember(hdat,hdat0)) - mean(eeg(hdat >= 0.28 & hdat<= 0.32)))/4)
    hold off
    ylim([-50 50])

    figure(6)
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