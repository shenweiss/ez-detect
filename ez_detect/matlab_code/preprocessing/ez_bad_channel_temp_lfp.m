function [data, metadata] = ez_bad_channel_temp(input_args_fname)

  fprintf("entering ez_bad_channel_temp() \n");

  load(input_args_fname); % loads variables: data, support_bipolar, metadata, chanlist

  % v.0.0.1 mod
  metadata.file_id=file_id;
  metadata.n_blocks=n_blocks;
  metadata.block_size=block_size;
  metadata.srate=srate;
  metadata.file_block=file_block;
  metadata.ch_names_bp=ch_names_bp;
  metadata.ch_names_mp=ch_names_mp;
  % end of mod

  eeg_bp.eeg_data = support_bipolar;
  eeg_bps.eeg_data = data.bp_channels;
  if strcmp(class(metadata.ch_names_bp), 'char') 
    metadata.ch_names_bp = cellstr(metadata.ch_names_bp);
  end
  eeg_bps.chanlist = metadata.ch_names_bp;
  eeg_mp.eeg_data = data.mp_channels;
  if strcmp(class(metadata.ch_names_mp), 'char')
    metadata.ch_names_mp = cellstr(metadata.ch_names_mp);
  end
  eeg_mp.chanlist = metadata.ch_names_mp;
  metadata.old_montage= [];
  metadata.montage_shape = [numel(ez_montage(:,1)),numel(ez_montage(1,:))];
  metadata.montage= reshape(ez_montage,1,[]); %matlab engine can only return 1*n cell arrays. I changed the data structure to get mlarray.

data.mp_channels = eeg_mp.eeg_data;
data.bp_channels = eeg_bps.eeg_data;
if ~isempty(eeg_mp.eeg_data)
metadata.m_chanlist=eeg_mp.chanlist;
end;
if ~isempty(eeg_bp.eeg_data)
metadata.bp_chanlist=eeg_bps.chanlist;
end;
metadata.lf_bad=[];



%save('/home/tpastore/Documents/ez-detect/disk_dumps/lfbad_metadata.mat','-v7.3')
