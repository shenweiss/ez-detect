% eeg_checkset() - check consistency of dataset fields.
%
% Structure of an EEG dataset under EEGLAB:
%	EEG.data     	- data array (chans x frames x epochs)
%	EEG.setname  	- name of the dataset
%	EEG.filename 	- filename of the dataset
%	EEG.filepath    - filepath of the dataset
%	EEG.namechan 	- channel labels (will be deprecated)
%	EEG.chanlocs  	- name of file containing names and positions 
%                         of the channels on the scalp
%	EEG.pnts     	- number of frames (time points) per epoch (trial)
%	EEG.nbchan     	- number of channels in each epoch
%	EEG.trials     	- number of epochs (trials) in the dataset
%	EEG.srate      	- sampling rate (in Hz)
%	EEG.xmin      	- epoch start time (in seconds)
%	EEG.xmax      	- epoch end time (in seconds)
%
% ICA variables:
%	EEG.icaact      - ICA activations (components x frames x epochs)  
%	EEG.icasphere   - sphere array returned by ICA
%	EEG.icaweights  - weight array returned by ICA
%	EEG.icawinv     - inverse ICA weight matrix giving the projected
%                         activity of the components at the electrodes.
% Event and epoch structures:	
%       EEG.event       - event structure (any number of events per epoch)
%       EEG.epoch       - epoch structure (one structure per epoch)
%       --> See the web page dealing with this issue     
%
% Variables used for manual and semi-automatic data rejection:
%	EEG.stats.kurtc         - component kurtosis values
%	EEG.stats.kurtg         - global kurtosis of components      
%	EEG.stats.kurta         - kurtosis of accepted epochs      
%	EEG.stats.kurtr         - kurtosis of rejected epochs      
%	EEG.stats.kurtd         - kurtosis of spatial distribution      
%	EEG.reject.entropy  	- entropy of epochs  
%	EEG.reject.entropyc   	- entropy of components
%	EEG.reject.threshold    - rejection thresholds 
%	EEG.reject.icareject    - epochs rejected by ICA criteria
%	EEG.reject.gcompreject  - rejected ICA components
%	EEG.reject.sigreject    - epochs rejected by single-channel criteria
%	EEG.reject.elecreject   - epochs rejected by raw data criteria
%	EEG.reject.compreject   - deprecated
%	EEG.reject.comptrial    - deprecated
%	EEG.reject.eegentropy   - deprecated
%	EEG.reject.eegkurt      - deprecated
%	EEG.reject.eegkurtg     - deprecated
%
% Usage:
%   >> [EEGOUT, res] = eeg_checkset( EEG );
%
% Inputs:
%   EEG        - dataset structure
%
% Outputs:
%   EEGOUT     - output dataset
%
% Author: Arnaud Delorme, CNL / Salk Institute, 2001
%
% See also: eeglab()

%123456789012345678901234567890123456789012345678901234567890123456789012

% Copyright (C) 2001 Arnaud Delorme, Salk Institute, arno@salk.edu
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

% $Log: eeg_checkset.m,v $
% Revision 1.1  2002/04/05 17:32:13  jorn
% Initial revision
%

% 01-25-02 reformated help & license -ad 
% 01-26-02 chandeg events and trial condition format -ad
% 01-27-02 debug when trial condition is empty -ad
% 02-15-02 remove icawinv recompute for pop_epoch -ad & ja
% 02-16-02 remove last modification and test icawinv separatelly -ad
% 02-16-02 empty event and epoch check -ad
% 03-07-02 add the eeglab options -ad
% 03-07-02 corrected typos and rate/point calculation -ad & ja
% 03-15-02 add channel location reading & checking -ad
% 03-15-02 add checking of ICA and epochs with pop_up windows -ad
% 03-27-02 recorrected rate/point calculation -ad & sm

function [EEG, res] = eeg_checkset( EEG, varargin );
msg = '';
res = 0; % 0 = OK, 1 = error, -1=warning

if nargin < 1
    help eeg_checkset;
    return;
end;    
if ~isempty( varargin)
    if isempty(EEG.data)
        helpdlg('Empty dataset', 'Error');
        error('eeg_checkset: empty dataset');
    end;    
end;

com = sprintf('%s = eeg_checkset( %s );', inputname(1), inputname(1));
res = [];
% verify the type of the variables
% --------------------------------
	% signal dimensions -------------------------
	if size(EEG.data,1) ~= EEG.nbchan
 	  disp( [ 'eeg_checkset warning: number of column in signal array (' int2str(size(EEG.data,1)) ...
 	  ') does not match the number of channels (' int2str(EEG.nbchan) '), corrected' ]); 
 	  res = com;
 	  EEG.nbchan = size(EEG.data,1);
	end;	

	if (ndims(EEG.data)) < 3 & (EEG.pnts > 1)
      if mod(size(EEG.data,2), EEG.pnts) ~= 0
           if popask( [ 'eeg_checkset error: the number of frames does not divide the number of column in signal.'  10 ...
                          'Do you want to EEGLAB to fix that ?' 10 '(press Cancel to fix the problem from the command line)']) 
                res = com;
                EEG.pnts = size(EEG.data,2);
                EEG = eeg_checkset(EEG);
                return;
            else
              	 error( 'eeg_checkset error: number of points do not divide the number of column in signal');
            end;  	  
      else
        if EEG.trials > 1
       		disp( 'eeg_checkset warning: number of dimensions in signal increased to 3'); 
       	    res = com;
       	end;    
       	EEG.data = reshape(EEG.data, EEG.nbchan, EEG.pnts, size(EEG.data,2)/EEG.pnts);		 
      end;    
	end;

	% size of signal -----------
	if size(EEG.data,3) ~= EEG.trials 
 	  disp( ['eeg_checkset warning: 3rd dimension in signal array (' int2str(size(EEG.data,3)) ...
 	  			') does not match the number of epochs (' int2str(EEG.trials) '), corrected' ]); 
 	  res = com;
 	  EEG.trials = size(EEG.data,3);
	end;	
	if size(EEG.data,2) ~= EEG.pnts 
 	  disp( [ 'eeg_checkset warning: number of column in signal array (' int2str(size(EEG.data,2)) ...
 	  	') does not match the number of points (' int2str(EEG.pnts) '), corrected' ]); 
 	  res = com;
 	  EEG.pnts = size(EEG.data,2);
	end;	

	% parameters coherence -------------------------
    if 	round(EEG.srate*(EEG.xmax-EEG.xmin)+1) ~= EEG.pnts	  	
       fprintf( 'eeg_checkset warning: inconsistency (xmax-xmin)*rate+1 (=%f) must be equal to the number of frames (=%d); xmax corrected\n', ...
          EEG.srate*(EEG.xmax-EEG.xmin)+1, EEG.pnts); 
       if EEG.srate == 0
          EEG.srate = 1;
       end;
       EEG.xmax = (EEG.pnts-1)/EEG.srate+EEG.xmin;
   	   res = com;
	end;
	
	% deal with event arrays
    % ----------------------
    if ~isfield(EEG, 'event'), EEG.event = []; res = com; end;
    if ~isempty(EEG.event)
        if EEG.trials > 1 & ~isfield(EEG.event, 'epoch')
             if popask( [ 'eeg_checkset error: the event info structure does not contain any ''epoch'' field.'  ...
                          'Do you want to remove all events ?' 10 '(press Cancel to fix the problem from the command line)']) 
                res = com;
                EEG.event = [];
                EEG = eeg_checkset(EEG);
                return;
            else
                error('eeg_checkset error: no epoch field in event structure');
            end;
        end;
    else
        EEG.event = [];
    end;
    if ~isfield(EEG, 'eventdescription'), EEG.eventdescription = {}; res = com; end;
    
 	% deal with epoch arrays
    % ----------------------
    if ~isfield(EEG, 'epoch'), EEG.epoch = []; res = com; end;
    if ~isfield(EEG, 'epochdescription'), EEG.epochdescription = {}; res = com; end;
    if ~isempty(EEG.epoch)
        if isstruct(EEG.epoch),  l = length( EEG.epoch);
        else                     l = size( EEG.epoch, 2); 
        end;   
        if l ~= EEG.trials
             if popask( [ 'eeg_checkset error: the number of epoch indices in the epoch array/struct (' ...
                   int2str(l) ') is different from the actual number of epochs (' int2str(EEG.trials) ').' 10 ...
                   'Do you want to remove them ?' 10 '(press Cancel to fix the problem from the command line)']) 
                res = com;
                EEG.epoch = [];
                EEG = eeg_checkset(EEG);
                return;
            else
                error('eeg_checkset error: epoch structure size invalid');
            end;
        end;
    else
        EEG.epoch = [];
    end;

	% check ica
	% ---------
	if ~isempty(EEG.icasphere)
		if ~isempty(EEG.icaweights)
			if size(EEG.icaweights,2) ~= size(EEG.icasphere,1)
 	  			if popask( [ 'eeg_checkset error: number of column in weights array (' int2str(size(EEG.icaweights,2)) 10
 	  			') does not match the number of rows in sphere (' int2str(size(EEG.icasphere,1)) ')' 10 ...
 	  			'Do you want to remove them ?' 10 '(press Cancel to fix the problem from the command line)']) 
                    res = com;
                    EEG.icasphere = [];
                    EEG.icaweights = [];
                    EEG = eeg_checkset(EEG);
                    return;
                else
                    error('eeg_checkset error: invalid weight and sphere array size');
                end;    
			end;
			if size(EEG.icasphere,2) ~= size(EEG.data,1)
 	  			disp( [ 'eeg_checkset warning: number of column in ica matrix (' int2str(size(EEG.icasphere,2)) ...
 	  			') does not match the number of rows in signal (' int2str(size(EEG.data,1)) ')' ]); 
                res = com;
			end;
			if isempty(EEG.icaact) | (size(EEG.icaact,1) ~= size(EEG.icaweights,1)) | (size(EEG.icaact,2) ~= size(EEG.data,2))
                eeg_options; % changed from eeglaboptions 3/30/02 -sm
                if size(EEG.data,1) ~= size(EEG.icasphere,2)
	 	  			if popask( [ 'eeg_checkset error: number of column in sphere array (' int2str(size(EEG.icasphere,2)) 10
	 	  			') does not match the number of rows in data(' int2str(size(EEG.data,1)) ')' 10 ...
	 	  			'Do you want to remove them ?' 10 '(press Cancel to fix the problem from the command line)']) 
	                    res = com;
	                    EEG.icasphere = [];
	                    EEG.icaweights = [];
	                    EEG = eeg_checkset(EEG);
	                    return;
	                else
	                    error('eeg_checkset error: invalid weight and sphere array size');
	                end;    
                end;
                if option_computeica
 	    			fprintf('eeg_checkset warning: recalculate ica matrix\n'); 
                    res = com;
                    EEG.icaact     = (EEG.icaweights*EEG.icasphere)*EEG.data(:,:);
                    EEG.icaact    = reshape( EEG.icaact, EEG.nbchan, EEG.pnts, EEG.trials);
                end;
 			end;
            if isempty(EEG.icawinv)
			    EEG.icawinv    = pinv(EEG.icaweights*EEG.icasphere); % a priori same result as inv
                res = com;
			end;     
		else
 	  		disp( [ 'eeg_checkset warning: weights matrix cannot be empty if sphere matrix is not, correcting' ]); 
            res = com;
 	  		EEG.icasphere = [];
		end;
		if (ndims(EEG.icaact)) < 3 & (EEG.trials > 1)
 	  		disp( [ 'eeg_checkset warning: number of dimensions in independent component array increased to 3' ]); 
            res = com;
			EEG.icaact = reshape(EEG.icaact, size(EEG.icaact,1), EEG.pnts, EEG.trials);		
		end;
	else
        if ~isempty( EEG.icaweights ), EEG.icaweights = []; res = com; end;
        if ~isempty( EEG.icawinv ),    EEG.icawinv = []; res = com; end;
        if ~isempty( EEG.icaact ),     EEG.icaact = []; res = com; end;
	end;

% check chanlocs
% -------------
if ~isempty( EEG.chanlocs )
    if ~isstruct( EEG.chanlocs)
		if exist( EEG.chanlocs ) ~= 2
			disp( [ 'eeg_checkset warning: channel file does not exist or is not in matlab path, removed' ]); 
	        EEG.chanlocs = [];
	        res = com;
        else
            res = com;
            try, EEG.chanlocs = readlocs( EEG.chanlocs );
 			     disp( [ 'eeg_checkset: channel file read' ]); 
            catch, EEG.chanlocs = []; end;
		end; 	
    end;
    if isstruct( EEG.chanlocs)
        if length( EEG.chanlocs) ~= EEG.nbchan
			disp( [ 'eeg_checkset warning: number of channels different in data and channel file/struct, channel file/struct removed' ]); 
	        EEG.chanlocs = [];
	        res = com;
	    end;
    end;
end;

if ~isfield(EEG, 'specdata') EEG.specdata = []; res = com; end;
if ~isfield(EEG, 'specicaact') EEG.specicaact = []; res = com; end;

% create fields if absent
% -----------------------

if ~isfield(EEG, 'reject')					EEG.reject.rejjp = []; res = com; end;
if ~isfield(EEG.reject, 'rejjp')			EEG.reject.rejjp = []; res = com; end;
if ~isfield(EEG.reject, 'rejjpE')			EEG.reject.rejjpE = []; res = com; end;
if ~isfield(EEG.reject, 'rejkurt')			EEG.reject.rejkurt = []; res = com; end;
if ~isfield(EEG.reject, 'rejkurtE')			EEG.reject.rejkurtE = []; res = com; end;
if ~isfield(EEG.reject, 'rejmanual')		EEG.reject.rejmanual = []; res = com; end;
if ~isfield(EEG.reject, 'rejmanualE')		EEG.reject.rejmanualE = []; res = com; end;
if ~isfield(EEG.reject, 'rejthresh')		EEG.reject.rejthresh = []; res = com; end;
if ~isfield(EEG.reject, 'rejthreshE')		EEG.reject.rejthreshE = []; res = com; end;
if ~isfield(EEG.reject, 'rejfreq')			EEG.reject.rejfreq = []; res = com; end;
if ~isfield(EEG.reject, 'rejfreqE')			EEG.reject.rejfreqE = []; res = com; end;
if ~isfield(EEG.reject, 'rejconst')			EEG.reject.rejconst = []; res = com; end;
if ~isfield(EEG.reject, 'rejconstE')		EEG.reject.rejconstE = []; res = com; end;
if ~isfield(EEG.reject, 'icarejjp')			EEG.reject.icarejjp = []; res = com; end;
if ~isfield(EEG.reject, 'icarejjpE')		EEG.reject.icarejjpE = []; res = com; end;
if ~isfield(EEG.reject, 'icarejkurt')		EEG.reject.icarejkurt = []; res = com; end;
if ~isfield(EEG.reject, 'icarejkurtE')		EEG.reject.icarejkurtE = []; res = com; end;
if ~isfield(EEG.reject, 'icarejmanual')		EEG.reject.icarejmanual = []; res = com; end;
if ~isfield(EEG.reject, 'icarejmanualE')	EEG.reject.icarejmanualE = []; res = com; end;
if ~isfield(EEG.reject, 'icarejthresh')		EEG.reject.icarejthresh = []; res = com; end;
if ~isfield(EEG.reject, 'icarejthreshE')	EEG.reject.icarejthreshE = []; res = com; end;
if ~isfield(EEG.reject, 'icarejfreq')		EEG.reject.icarejfreq = []; res = com; end;
if ~isfield(EEG.reject, 'icarejfreqE')		EEG.reject.icarejfreqE = []; res = com; end;
if ~isfield(EEG.reject, 'icarejconst')		EEG.reject.icarejconst = []; res = com; end;
if ~isfield(EEG.reject, 'icarejconstE')		EEG.reject.icarejconstE = []; res = com; end;

if ~isfield(EEG.reject, 'rejglobal')		EEG.reject.rejglobal = []; res = com; end;
if ~isfield(EEG.reject, 'rejglobalE')		EEG.reject.rejglobalE = []; res = com; end;

if ~isfield(EEG, 'stats')			EEG.stats.jp = []; res = com; end;
if ~isfield(EEG.stats, 'jp')		EEG.stats.jp = []; res = com; end;
if ~isfield(EEG.stats, 'jpE')		EEG.stats.jpE = []; res = com; end;
if ~isfield(EEG.stats, 'icajp')		EEG.stats.icajp = []; res = com; end;
if ~isfield(EEG.stats, 'icajpE')	EEG.stats.icajpE = []; res = com; end;
if ~isfield(EEG.stats, 'kurt')		EEG.stats.kurt = []; res = com; end;
if ~isfield(EEG.stats, 'kurtE')		EEG.stats.kurtE = []; res = com; end;
if ~isfield(EEG.stats, 'icakurt')	EEG.stats.icakurt = []; res = com; end;
if ~isfield(EEG.stats, 'icakurtE')	EEG.stats.icakurtE = []; res = com; end;

% component rejection
% -------------------
if ~isfield(EEG.stats, 'compenta')		EEG.stats.compenta = []; res = com; end;
if ~isfield(EEG.stats, 'compentr')		EEG.stats.compentr = []; res = com; end;
if ~isfield(EEG.stats, 'compkurta')		EEG.stats.compkurta = []; res = com; end;
if ~isfield(EEG.stats, 'compkurtr')		EEG.stats.compkurtr = []; res = com; end;
if ~isfield(EEG.stats, 'compkurtdist')	EEG.stats.compkurtdist = []; res = com; end;
if ~isfield(EEG.reject, 'gcompreject')		EEG.reject.gcompreject = []; res = com; end;
if ~isfield(EEG.reject, 'threshold')		EEG.reject.threshold = [0.8 0.8 0.8]; res = com; end;
if ~isfield(EEG.reject, 'threshentropy')	EEG.reject.threshentropy = 600; res = com; end;
if ~isfield(EEG.reject, 'threshkurtact')	EEG.reject.threshkurtact = 600; res = com; end;
if ~isfield(EEG.reject, 'threshkurtdist')	EEG.reject.threshkurtdist = 600; res = com; end;

% component rejection
% -------------------
% additional checks
% -----------------
if ~isempty( varargin)
    for index = 1:length( varargin )
        switch varargin{ index }
            case 'data',; % already done at the top 
            case 'ica', 
                if isempty(EEG.icaweights)
	               ButtonName=questdlg([ 'No ICA weights. Compute now?' 10 '(then go back to the function you just called)'], ...
	                       'Confirmation', 'Cancel', 'Yes','Yes');
	                           
	               switch lower(ButtonName),
	                   case 'cancel', error('eeg_checkset: ICA components must be computed before running that function'); 
                   end;
                   [EEG res] = pop_runica(EEG);
                   res = [ inputnames(1) ' = eeg_checkset('  inputnames(1) '); ' res ];
                else, return; end;
            case 'epoch', 
                if EEG.trials == 1
                    errordlg([ 'Epochs must be extracted before running that function' 10 'Use /Tools/Extract epochs'], 'Error');
                    error('eeg_checkset: epochs must be extracted before running that function');
                end;
            case 'event', 
                if isempty(EEG.event)
                    errordlg([ 'Can not process if no event. First add event.' 10 'Use /File/Import event info or /Import epoch info'], 'Error');
                    error('eeg_checkset: epochs must be extracted before running that function');
                end;
            case 'chanloc', 
                if isempty(EEG.chanlocs)
                    errordlg( ['Can not process without channel location file.' 10 ...
                               'Enter the name of the file in /Edit/Edit dataset info.' 10 ...
                               'For the file format, enter ''>> help totoplot'' from the command line.' ], 'Error');
                    error('eeg_checkset: can not process without channel location file.');
                end;
            case 'eventconsistency',
                % uniformize fields (str or int) if necessary
                % -------------------------------------------
                allfields = fieldnames(EEG.event);
                for indexfield=1:length(allfields)
                    fieldformat{indexfield} = 'int';
                    for index = 1:length(EEG.event)
                        if isstr(getfield(EEG.event, { index }, allfields{indexfield}))
                            fieldformat{indexfield} = 'str';
                            index = length(EEG.event);
                        end;
                    end;
                end;
                for indexfield=1:length(allfields)
                    if strcmp( fieldformat{indexfield}, 'str') 
	                    for index = 1:length(EEG.event)
	                        fieldcontent = getfield(EEG.event, { index }, allfields{indexfield});
	                        if ~isstr(fieldcontent)
	                            EEG.event = setfield(EEG.event, { index }, allfields{indexfield}, num2str(fieldcontent) );
	                        end;
	                    end;
                    end;
                end;
                                             
				% save information for non latency fields updates
				% -----------------------------------------------
				difffield = [];
				if ~isempty(EEG.event) & isfield(EEG.event, 'epoch')
                    % remove fields with empty epochs
                    % -------------------------------
                    removeevent = [];
				    for indexevent = 1:length(EEG.event)
                        if isempty( EEG.event(indexevent).epoch ) | ~isnumeric(EEG.event(indexevent).epoch) ...
                            | EEG.event(indexevent).epoch < 1 | EEG.event(indexevent).epoch > EEG.trials
                            removeevent = [removeevent indexevent];
                            disp([ 'eeg_checkset warning: event ' int2str(indexevent) ' has invalid epoch number, removed']);
				        end;
				    end;
				    EEG.event(removeevent) = [];
				        
				    difffield = setdiff( fieldnames(EEG.event), { 'latency' 'type' 'epoch' });
  			        for index = 1:length(difffield)
                        % get the field content
                        % ---------------------
				        for indexevent = 1:length(EEG.event)
				            if ~isempty( getfield( EEG.event, {indexevent}, difffield{index}) )
				                arraytmpinfo{EEG.event(indexevent).epoch, index} = getfield( EEG.event, {indexevent}, difffield{index});
				            end;    
				        end;
                        % uniformize content for all epochs
                        % ---------------------------------
				        for indexevent = 1:length(EEG.event)
			                setfield( EEG.event, { EEG.event(indexevent).epoch }, difffield{index}, arraytmpinfo{EEG.event(indexevent).epoch, index});
				        end;
				    end;
				end;
            otherwise, error('eeg_checkset: unknown option');
        end;        
    end;
end;            
       
return;	

function num = popask( text )
	 ButtonName=questdlg( text, ...
	        'Confirmation', 'Cancel', 'Yes','Yes');
	 switch lower(ButtonName),
	      case 'cancel', num = 0;
	      case 'yes',    num = 1;
	 end;
