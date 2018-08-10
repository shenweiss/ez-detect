function [cdat] = ezInterp3D_single(resAmp)
% resAmp = resampled_amplitude(:,:,Nint*(jj-1)+1:Nint*jj);
% Nint = 300;

gSize   = size(resAmp,2);
Nint    = size(resAmp,3);
Nf      = size(resAmp,1);
freqRes = Nf*floor(gSize/Nf);
    
[x,y,z] = meshgrid (single(1:gSize),single(1:Nf),single(1:Nint));
[xi,yi,zi] = meshgrid (single(1:gSize), single(linspace(1,Nf,freqRes)),single(1:Nint));
cdat = interp3(x,y,z,resAmp,xi,yi,zi,'linear');
% cdat = gather(cdat);