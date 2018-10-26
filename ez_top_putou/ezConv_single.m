function [cdat hdat vdat] = ezConv_single(eeg, A, foi, toi, tapM)
% function [cdat hdat vdat] = ezConv(eeg, A, foi, toi)

eeg = eeg - mean(eeg,2);

[n N]  = size(eeg);
Nf = size(A,3);

cdat = single(complex(zeros(n,N,Nf)));

%cdat = pagefun(@mtimes,eeg,A);
[~,~,P] = size(A);
for i=1:P
	cdat(:,:,i) = mtimes(eeg,A(:,:,i));
end

cdat = abs(cdat).^2;
cdat = permute(cdat, [3 2 1]);

%cdat = pagefun(@times,cdat,tapM);

[~,~,P] = size(cdat);

for i=1:P
	cdat(:,:,i) = times(cdat(:,:,i),tapM);
end

cdat = cdat - mean(cdat,2);

clear eeg
cdat = single(cdat);

hdat = toi;
vdat = foi;
