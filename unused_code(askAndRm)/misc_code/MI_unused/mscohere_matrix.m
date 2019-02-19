function [MSC] = mscohere_matrix(eeg_data)
i=1;
j=1;
MSC=[];
for i=1:numel(eeg_data(:,1))
  i
    for j=1:numel(eeg_data(:,1))
       test=corrcoef(eeg_data(i,:),eeg_data(j,:));
       MSC(i,j)=test;
    end;
end;
