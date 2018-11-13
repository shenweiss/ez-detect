function write_trc_event(text_file_name,chan_block,channel,time_on,time_off,event_type)

% open text file
txt_fid=fopen(text_file_name,'at');
if txt_fid==-1
    error('Can''t open *.trc file')
end
% write events
fprintf('\n<events>\n');
% addend to file event guide
[event_guide_string]=TRC_evt_guide;
event_guide_cstring=['\n<Event Guid="' event_guide_string '"> \n'];
fprintf(txt_fid,event_guide_cstring);
% addend to file event definition guide
if event_type == 0
fprintf(txt_fid,'<EventDefinitionGuid>bf513752-2cb7-43bc-93f5-370def800b93</EventDefinitionGuid> \n');
end;
if event_type == 1
fprintf(txt_fid,'<EventDefinitionGuid>167b6fad-f95a-4880-a9c6-968f468a1297</EventDefinitionGuid> \n');
end;
if event_type == 2
fprintf(txt_fid,'<EventDefinitionGuid>e0a58c9c-b3c0-4a7d-a3c3-d3ed6a57dc3a</EventDefinitionGuid> \n');
end;
% addend begin time
min_init=9;
sec_init=39.816;
if time_on+sec_init>60
    event_min=min_init+floor((sec_init+time_on)/60);
    event_sec=mod((sec_init+time_on),60);
else
    event_min=9;
    event_sec=39.816+time_on;
end;
if numel(num2str(event_min)) == 1
    s_event_min=num2str(event_min);
    s_event_min=['0',s_event_min];
else
    s_event_min=num2str(event_min);
end;
s_event_sec=num2str(event_sec,'%.7f');
if s_event_sec(3) ~= '.'
    s_event_sec=['0' s_event_sec(1:6)];
end;
time_on_string=['<Begin>1978-11-05T12:' s_event_min ':' s_event_sec '</Begin> \n'];
fprintf(txt_fid,time_on_string);
% addend off time
min_init=9;
sec_init=39.816;
if time_on+sec_init>60
    event_min=min_init+floor((sec_init+time_off)/60);
    event_sec=mod((sec_init+time_off),60); 
else
    event_min=9;
    event_sec=39.816+time_off;
end;
if numel(num2str(event_min)) == 1
    s_event_min=num2str(event_min);
    s_event_min=['0',s_event_min];
else
    s_event_min=num2str(event_min);
end;
s_event_sec=num2str(event_sec,'%.7f');
if s_event_sec(3) ~= '.'
    s_event_sec=['0' s_event_sec(1:6)];
end;
time_off_string=['<End>1978-11-05T12:' s_event_min ':' s_event_sec '</End> \n'];
fprintf(txt_fid,time_off_string);
% addend value
fprintf(txt_fid,'<Value>0</Value> \n');
% addend extravalue
fprintf(txt_fid,'<ExtraValue>0</ExtraValue> \n');
% addend channel number
event_chan=channel;
s_event_chan=num2str(event_chan);
event_chan_string=['<DerivationInvID>' s_event_chan '</DerivationInvID> \n'];
fprintf(txt_fid,event_chan_string);
% addennd null i.e. inverted channel number
fprintf(txt_fid,'<DerivationNotInvID>0</DerivationNotInvID> \n');
% addend created by
fprintf(txt_fid,'<CreatedBy>Shennan Weiss</CreatedBy> \n');
% addend created date
fprintf(txt_fid,'<CreatedDate>2017-04-07T15:39:52.6918243Z</CreatedDate> \n');
% addend updated by
fprintf(txt_fid,'<UpdatedBy>Shennan Weiss</UpdatedBy> \n');
% addend updated date
fprintf(txt_fid,'<UpdatedDate>2017-04-07T15:39:52.6918243Z</UpdatedDate> \n');
% addend </event>
fprintf(txt_fid,'</Event>\n');
fclose(txt_fid);


