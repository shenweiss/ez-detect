function [spike] = zSpikeAlpha_0(varargin)
% zSpikeAlpha_0 by Zachary J. Waldman
% 
% Spike detector. Used for both ripple and fast ripple detections. 
% Generates TF maps and their gradients, then determines "object volumes" 
% of useing these plots. If these volumes meet certain criteria, a spike 
% detection is triggered.
% Input:
%   eeg:    EEG clip with a sampling frequency of 2000 Hz, and at least 651
%           samples
%   tC:     Onset time of candidate event relative to the start of the
%           clip, where the clip starts at t=0. tC must be greater than
%           0.06. 
% Output
%   spike:  0 if no spike is detected, 1 if spike is detected.

if nargin == 1;
    eeg = varargin{1};
    tC = 0.3;
elseif nargin == 2;
    eeg = varargin{1};
    tC = varargin{2};
end
% function [spike] = zSpikeAlpha_0(eeg)
% clearvars -except eegList*
% for i = 29:length(eegListR)
% for i = 1:10
% eeg = eegListR{i,1};
% eeg = resample(eeg,500,2000);

%     eeg = squeeze(eegDr{1,1}(pp, cc, :))';
%     % Only use 0 - 2.4 s of eeg
%     t = [1:size(eegDr{1,1},3)]/Fs;
%     eeg = eeg(t >= 0 & t <= 2.5);
%     eeg = resample(eeg,2000,500);


% Fs = 500;
Fs = 2000;
t = [1:length(eeg)]/Fs;

% det = 2;
% check = 2;
% color = get(groot,'DefaultAxesColorOrder');
% color2 = hsv(10);

% t_low = .2;
% t_high = .4;
fmin = 30;
fmax = 80;
% tC = 0.3;
tBuf1 = 0.1;
% tBuf1 = 0.15;
tEdge = 0.03;

gSize = 500;
foi = [80 240];
nCont = 50;

% cvthresh = 19;
% gvthresh = 2;
% boxthresh = 0.7;
cvthresh = 15;
gvthresh = .8;
% boxthresh = 0.6;

            wavelet=wavelet_amplitude_sig_Z(eeg, Fs, fmin, fmax);  %plot wavelets
            freqs = wavelet.frequencies;
            [wavelet,cdat] = plot_wavelet_tf_Z(wavelet,[freqs(1) freqs(end)], gSize,freqs,1);

            vdat = linspace(fmin,fmax,size(cdat,1));
            hdat = linspace(0,size(eeg,2)/Fs,size(cdat,2));
            
            % Determine Start and End times of the Region Of Interest
            tS = tC - tBuf1;
            tE = tC + tBuf1;
            if tS <= tEdge
                tS = tEdge;
                tE = tEdge + 2*tBuf1;
            elseif tE >= t(end) - tEdge
                tS = t(end) - tEdge - 2*tBuf1;
                tE = t(end) - tEdge;
            end

            vdat0 = vdat;
            hdat0 = hdat(hdat >= tS & hdat <= tE);
            cdat1 = cdat(ismember(vdat,vdat0), ismember(hdat,hdat0));
            
            % CALCULATE GRADIENT
            [gX gY] = gradient(cdat1);
            gR = (gX.^2 + gY.^2).^(1/2);

            % OBJECTS AND VOLUMES
            %     Identify Seperate objects in the final density array.
            %     Using Surface Generated by zDet3_2c.m using Patient 456, Trial 9.3

            % TF MAP (cdat1)
            % Remove Densities below 20% max cdat1 value
            thrC= 0.2*max(cdat1(:));
            cT0 = cdat1;
            cT0(cdat1 < thrC) = 0; 
            cT = cT0;
            % Binarize Remaining Density Map
            cBW = cT;
            cBW(cdat1 >= thrC) = 1;

            % Find Boundaries to Determine Number of Seperate Blobs 
            [cB cL] = bwboundaries(cBW);
            
            % FIX ERROR: Occasionally cB contains an empty cell due to
            % close boundaries.
            for ii = 1:size(cB,1)
                if isempty(cB{ii,1})
                    cbw = zeros(size(cL));
                    cbw(cL == ii) = 1;
                    cBmissing = bwboundaries(cbw);
                    cB(ii,1) = cBmissing;
                end
            end

            % Size of B yields number of objects
            nObjC = size(cB,1);

            % CALCULATE OBJECT VOLUME

            % For each object Grab Objects Indices
            cObj = {};
            % objVol={};
            cObjVol = [];
            for bb = 1:nObjC
                if ~isempty(cB{bb,1})
                    % Logical Array: Determine which indices of HV fall within (or on) obj1's borders
                    % objL = inpolygon(H, V, hdat0(cB{bb,1}(:,2)), vdat0(cB{bb,1}(:,1)));
                    cObjL{bb} = zeros(size(cL));
                    cObjL{bb}(cL == bb) = 1;

                    % Restore dens values for that object only
                    % obj{bb} = cR2; 
                    cObj{bb} = cT; 
                    cObj{bb}(find(~cObjL{bb})) = 0;

                    % Calculate Volume of Object
                    cObjVol(bb,1)= trapz(vdat0, trapz(hdat0, cObj{bb}, 2), 1);
                else
                    nObjC = nObjC - 1;
                end
            end

            % GRADIENT

            % Remove Densities below 20% max grad value
            thrG= 0.2*max(gR(:));
            gT0 = gR;
            gT0(gR < thrG) = 0; 
            gT = gT0;
            % Binarize Remaining Density Map
            gBW = gT;
            gBW(gR >= thrG) = 1;

            % Find Boundaries to Determine Number of Seperate Blobs 
            [gB gL] = bwboundaries(gBW);

            % FIX ERROR: Occasionally cB contains an empty cell due to
            % close boundaries.
            for ii = 1:size(gB,1)
                if isempty(gB{ii,1})
                    gbw = zeros(size(gL));
                    gbw(gL == ii) = 1;
                    gBmissing = bwboundaries(gbw);
                    gB(ii,1) = gBmissing;
                end
            end

            % Size of B yields number of objects
            nObjG = size(gB,1);

            % CALCULATE OBJECT VOLUME
            gObj = {};
            gObjL = {};
            gObjVol = [];
            % For each object Grab Objects Indices
            for bb = nObjG:-1:1
                if ~isempty(gB{bb,1})
                    % Logical Array: Determine which indices of HV fall within (or on) obj1's borders
%                     objL = inpolygon(H, V, hdat0(gB{bb,1}(:,2)), vdat0(gB{bb,1}(:,1)));
                    gObjL{bb} = zeros(size(gL));
                    gObjL{bb}(gL == bb) = 1;

                    % Restore dens values for that object only
                    gObj{bb} = gT; 
                    gObj{bb}(find(~gObjL{bb})) = 0;

                    % Calculate Volume of Object
                    gObjVol(bb,1)= trapz(vdat0, trapz(hdat0, gObj{bb}, 2), 1);
                else
                    gB(bb,:) = [];
                    nObjG = nObjG - 1;
                end
            end

            % 1a. Remove Gradient objects w/ Volume <= 0.1
            gNlist = [];
            gPkVal = [];
            for bb = nObjG:-1:1
%                 if gObjVol(bb,1) <= 0.4
                if gObjVol(bb,1) <= 0.1
                    gT(gL == bb) = 0;
                    gB(bb,:) = [];
                    gObjVol(bb,:) = [];
                else
                    [pkvalG indG] = max(gObj{1,bb}(:));
                    [rG cG] = ind2sub(size(gObj{1,bb}), indG);
                    % Remove objects at the edge
%                     if hdat0(cG) <= 0.03 || hdat0(cG) >= 1.34 || vdat0(rG) == 80
%                     if hdat0(cG) <= 0.03 || hdat0(cG) >= 1.34 
%                     if hdat0(cG) <= (tEdge + .01) || hdat0(cG) >= (t(end) - tEdge - .01)
% %                         gT(gL == bb) = 0;
% %                         gB(bb,:) = [];
% %                         gObjVol(bb,:) = [];
%                         gNlist = [bb; gNlist];
%                         gPkVal = [ pkvalG; gPkVal];
% 
%                     else
%                         gNlist = [bb; gNlist];
%                         gPkVal = [ pkvalG; gPkVal];
%                     end
                    gNlist = [bb; gNlist];
                    gPkVal = [ pkvalG; gPkVal];
                end
            end
            nObjG = size(gB,1);

            % 1b. Remove cdat objects w/ Volume <= 15
            cNlist = []; 
            cPkVal = [];
            for bb = nObjC:-1:1
%                 if cObjVol(bb,1) <= 15
                if cObjVol(bb,1) <= 5
                    cT(cL == bb) = 0;
                    cB(bb,:) = [];
                    cObjVol(bb,:) = [];
                else
                    [pkval ind] = max(cObj{1,bb}(:));
                    [rC cC] = ind2sub(size(cObj{1,bb}), ind);
                    cvdat0 = vdat0'.*cObjL{1,bb};
                    % Remove objects at the edge
                    if hdat0(cC) <= (tEdge + .01) || hdat0(cC) >= (t(end) - tEdge - .01) || (vdat0(rC) == 80 && min(cvdat0(cvdat0 ~= 0)) >= 55)
                        cT(cL == bb) = 0;
                        cB(bb,:) = [];
                        cObjVol(bb,:) = [];
                    else
                        cNlist = [bb; cNlist];
                        cPkVal = [ [pkval ind]; cPkVal];
                    end
                end
            end
            nObjC = size(cB,1);
            
            if nObjC ~= 0 & nObjG ~= 0
                
                % 2. Calculate some properties to investigate

                % 2a. Bounding Box for cdat Object (width/height)
                cXscale = size(cdat1,1)/size(cdat1,2);                      % Calculate x-axis scaling factor
                cnobj = find(cPkVal(:,1) == max(cPkVal(:,1)));                        % Determine cdat Object with peak cdat value
                % cnobj = find(cObjVol == max(cObjVol));
                
                % Calculate time coordinate of peak cdat value
                [cv ch] = ind2sub(size(cObj{cNlist(cnobj)}),cPkVal(cnobj,2));
                ctmax = hdat0(ch);
                chdat0 = hdat0(hdat0 >= ctmax - 0.1 & hdat0 <= ctmax + 0.1);
                                
                % Calculate Properties
                cBB =  regionprops(cObjL{cNlist(cnobj)}, 'BoundingBox','Extent');     
                cBoxRatio = cBB.BoundingBox(1,4) / (cBB.BoundingBox(1,3)*cXscale);
                
                % 3. CONDITIONS FOR SPIKE DETECTION: TRIAL 1
                
                if nObjG == 1; 
                    gTotVol = gObjVol;
                    gVolRange = gObjVol;
                else
                    % Identify Grad Objects within 0.1 s of the chosen cdat Object
                    gVolRange = [];
                    for bb = 1:nObjG
                        if ~isempty(intersect(hdat0.*gObjL{gNlist(bb)},chdat0))
                            gVolRange = [gVolRange; gObjVol(bb)];
                        end
                    end
                    gSortVol = sort(gVolRange,'descend');                 % Sort Gradient Object Volumes
                    if length(gSortVol) == 0;
                        gTotVol = 0;
                    elseif length(gSortVol) == 1;
                        gTotVol = gSortVol;
                    else
                        gTotVol = sum(gSortVol(1:2));
                    end
                end
                    
                if cObjVol(cnobj) <= cvthresh
                    spike = 0;
                else
%                     if gTotVol <= 2
                    if gTotVol <= gvthresh % Make sure to reValidate this setting!!!
                        spike = 0;
                    else
                        spike = 1;
%                         if cBoxRatio <= boxthresh 
%                             spike = 0;
%                         else
%                             spike = 1;
%                         end
                    end
                end
                
            else
                spike = 0;
            end
% end