% Mutual Information:
% N4 is the time series matrix where rows are time points and columns are
% sensors (i.e. nodes, voxels, electrodes, etc).
function [IN2] = mutualinformation_norm_strehl_ghosh1(N4)
% this definition of normalized mutual information is taken from 
% Yao, Y. Y. (2003) Information-theoretic measures for knowledge discovery and data mining, in Entropy Measures, Maximum Entropy Principle and Emerging Applications , Karmeshu (ed.), Springer, pp. 115-136. 
% Also see for another option: Strehl, Alexander and Ghosh, Joydeep (2002). Cluster ensembles -- A knowledge reuse framework for combining multiple partitions. Journal of Machine Learning Research 3, 583-617. 


M = numel(N4(1,:))
N = numel(N4(:,1))
MMean = mean(N4);
% Calculate mutual information
I = zeros(M,M);
for i=1:M;
    for j=i:M;
        if MMean(i)~=0 & MMean(j)~=0;
            [ii,n,s,d] = information(N4(:,i)',N4(:,j)');
        else
            ii= 0;
        end
        I(i,j) = ii;
        I(j,i) = ii;
    end
end
% determine the trace which is a measure of the entropy of each sensor
%T3 = trace(I);
% normalize mutual information matrix before using in between-subject analysis;
for i=1:M;
    for j=1:M;
        IN2(i,j) = abs(I(i,j)./(I(i,i) + I(j,j) - I(i,j)));
    end
end