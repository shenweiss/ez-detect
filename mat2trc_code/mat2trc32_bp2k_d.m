function mat2trc32_bp2k_d(patient_id,file_block)
load(['/home/mgatti/ez_detect/putou/bp_temp_trc/eeg_2k_d_' file_block '.mat'])

TRC.data=[];
fprintf('checking eeg input size \r');
test_size=numel(eeg.eeg_data(:,1))
if test_size > 32
    fprintf('input file larger than 32 channels \r');
    fprintf('truncating data to 32 channels, WARNING: some data will be lost! \r');
    eeg.eeg_data=eeg.eeg_data(1:32,:);
    test_size=32;
end;

fprintf('adding dummy channels \r');
ts_pts=numel(eeg.eeg_data(1,:));
TRC.data(1,:)=zeros(ts_pts,1);
TRC.data(2:(test_size+1),:)=eeg.eeg_data;
for i=(test_size+2):34
     TRC.data(i,:)=(rand(ts_pts,1)*10);
end;

fprintf('building .TRC header \r');

trcfile='/home/mgatti/ez_detect/putou/bp_temp_trc/EEG_1_d.TRC'
fid=fopen(trcfile,'r+');
if fid==-1
    error('Can''t open *.trc file')
end

%------------------writing patient & recording info----------

status=fseek(fid,64,-1)
surname='xxxxx                 '
fwrite(fid,surname,'char');
name=   'xxxxx               '
eeg_id=[patient_id '_bp4_' file_block];
p_id_size=numel(eeg_id)
name(1:p_id_size)=eeg_id;
fwrite(fid,name,'char');

fseek(fid,128,-1);
day=05;
fwrite(fid,day,'uchar');
month=11;
fwrite(fid,month,'uchar');
year=78;
fwrite(fid,year,'uchar');

%------------------ Writing Header Info ---------
fseek(fid,175,-1);
Header_Type=4;
fwrite(fid,Header_Type,'char');

fseek(fid,138,-1);
Data_Start_Offset=648170;
fwrite(fid,Data_Start_Offset,'uint32');
Num_Chan=34;   % Modify when writing data 
fwrite(fid,Num_Chan,'uint16');
Multiplexer=68;
fwrite(fid,Multiplexer,'uint16');
Rate_Min=2048;   % Sampling Rate, it must be a power of 2, i.e. 2048.  Modify when writing data. 
fwrite(fid,Rate_Min,'uint16');
Bytes=2;
fwrite(fid,Bytes,'uint16');

fseek(fid,184,-1);
Code_Area=640;
fwrite(fid,Code_Area,'uint32');
Code_Area_Length=512;
fwrite(fid,Code_Area_Length,'uint32');

fseek(fid,200,-1);
Electrode_Area=1152;
fwrite(fid,Electrode_Area,'uint32');
Electrode_Area_Length=81920;
fwrite(fid,Electrode_Area_Length,'uint32');

fseek(fid,408,-1);
Trigger_Area=394218;
fwrite(fid,Trigger_Area,'uint32');
Trigger_Area_Length=49152;
fwrite(fid,Trigger_Area_Length,'uint32');


%------------------ Writing Code Info -------------
 fseek(fid,640,-1);
 code=[];

 code=[63:96];
 code(1)=192;
 code(34)=174;
 fwrite(fid,code,'uint16');

positive_input={
'EKG+  '
'RAH1  '
'GLA2  '
'GLA3  '
'GLA4  '
'GLA5  '
'GLA6  '
'GLA7  '
'GLA8  '
'GLB1  '
'GLB2  '
'GLB3  '
'GLB4  '
'GLB5  '
'GLB6  '
'GLB7  '
'GLB8  '
'GLC1  '
'GLC2  '
'GLC3  '
'GLC4  '
'GLC5  '
'GLC6  '
'GLC7  '
'GLC8  '
'GLD1  '
'GLD2  '
'GLD3  '
'GLD4  '
'GLD5  '
'GLD6  '
'GLD7  '
'GLD8  '
'MKR+  '};

fprintf('customizing channel names \r');
for i=2:(test_size+1)
if eeg.chanlist{i-1}(1:3)=='POL'
    chanstr=eeg.chanlist{i-1}(5:end);
    TF = isstrprop(chanstr,'alpha');
    [a,b]=find(TF==0);
    c=max(b);
    chanstr=chanstr(1:c);
    if c<4
        c=4;
        chanstr=[chanstr '--'];
    end;
else
    chanstr=eeg.chanlist{i-1}(3:end);
    TF = isstrprop(chanstr,'alpha');
    [a,b]=find(TF==0);
    c=max(b);
    if c<4
        c=4;
        chanstr=[chanstr '--'];
    end;
    chanstr=chanstr(1:c);
end;
    positive_input{i}(1:c)=chanstr(1:c);
end;

if test_size<32    
  for i=(test_size+2):33
    dmy_str=['DMY' num2str(i)];
    if i < 10    
    positive_input{i}(1:4)=dmy_str;
    else
    positive_input{i}(1:5)=dmy_str;
  end
end
end

negative_input={
'EKG-  '
'G2    '
'G2    '
'G2    '
'G2    '
'G2    '
'G2    '
'G2    '
'G2    '
'G2    '
'G2    '
'G2    '
'G2    '
'G2    '
'G2    '
'G2    '
'G2    '
'G2    '
'G2    '
'G2    '
'G2    '
'G2    '
'G2    '
'G2    '
'G2    '
'G2    '
'G2    '
'G2    '
'G2    '
'G2    '
'G2    '
'G2    '
'G2    '
'MKR-  '};

chan_record=[
192
64
65
66
67
68
69
70
71
72
73
74
75
76
77
78
79
80
81
82
83
84
85
86
87
88
89
90
91
92
93
94
95
174];

for i=1:Num_Chan
  fseek(fid,Electrode_Area+code(i)*128,-1);
  fseek(fid,2,0);
  electrode(i).positive_input=char(positive_input(i));
  fwrite(fid,electrode(i).positive_input,'char');
  electrode(i).negative_input=char(negative_input(i));
  fwrite(fid,electrode(i).negative_input,'char');
  electrode(i).logical_min=int32(0);
  fwrite(fid,electrode(i).logical_min,'uint32');
  electrode(i).logical_max=int32(65535);
  fwrite(fid,electrode(i).logical_max,'uint32');
  electrode(i).logical_ground=int32(32768);
  fwrite(fid,electrode(i).logical_ground,'uint32');
  electrode(i).physical_min=int32(-3200);
  [count]=fwrite(fid,electrode(i).physical_min,'int32')
  electrode(i).physical_max=int32(3200);
  [count]=fwrite(fid,electrode(i).physical_max,'uint32')
  electrode(i).measurement_unit=int16(1e-6);
  fwrite(fid,electrode(i).measurement_unit,'uint16');
  fseek(fid,8,0);
  electrode(i).rate_coef=1;
  fwrite(fid,electrode(i).rate_coef,'uint16');
end;

%% Hex dump for header information
status=fseek(fid,0,-1)
A=fread(fid,(Data_Start_Offset*1),'uchar');
fclose(fid);
trcfilename=[patient_id '_bp4_' file_block '.TRC'];
trcfilename=strcat('/home/mgatti/ez_detect/putou/TRC_out/',trcfilename);
fid2=fopen(trcfilename,'w+');
if fid2==-1
    error('Can''t open *.trc file')
end
status=fseek(fid,1,-1)
fwrite(fid2,A,'uchar');
fclose(fid2);

fprintf('writing 2048 Hz data to trc file \r'); 
% add padding to data to allow multiplexing in Matlab
fid=fopen(trcfilename,'a');
if fid==-1
    error('Can''t open *.trc file')
end

Data_Start_Offset=648170;
Num_Chan=34;
Bytes=2;

%----padding
padding=zeros(1,1);
padding=uint16(padding);
fwrite(fid,padding,'uint16');
fclose(fid)

% Write multiplexed data
fid=fopen(trcfilename,'r+');
if fid==-1
    error('Can''t open *.trc file')
end

Data_Start_Offset=648170;
Num_Chan=34;
Bytes=2;

position=[];
 for i=1:Num_Chan
     [status]=fseek(fid,Data_Start_Offset-(i-1)*Bytes,-1);
     tracedata=((TRC.data((Num_Chan-(i-1)),:)/6400)*65534)+32768;
     [a,b] = find(tracedata(:)>65534);
     if numel(b)>0
     tracedata(b)=65533;
     end;
     [a,b] = find(tracedata(:)<-32767)
     if numel(b)>0
     tracedata(b)=-32766;
     end;
     tracedata=tracedata';
     position.pre(i) = ftell(fid);
     position.advance(i) = (Num_Chan-1)*Bytes;
     position.size(i) = numel(tracedata)
     fwrite(fid,tracedata,'uint16',((Num_Chan-1)*Bytes)); 
     position.post(i) = ftell(fid)
     padding=zeros(i,1);
     fwrite(fid,padding,'uint16'); 
     position.post(i) = ftell(fid)
 end;
fclose(fid);
