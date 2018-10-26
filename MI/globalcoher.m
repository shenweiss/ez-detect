function [C period ptile] = globalcoher(x,y,varargin)


%Global Coherence
% Computes the global coherence between a time series x and a time series
% y, where global coherence measures the relationship between two time
% series as a function of frequency (or period). 



% Outputs:
%   C - Global coherence at each period
%   period - a vector of periods at which the global coherence was
%   calculated
%   ptile = the critical levels of the pointwise test at each period


[dx,dt]=formatts(x);
[dy,dt]=formatts(y);

nx = length(dx(:,2));
ny = length(dy(:,2));

%----------default arguments for the wavelet transform-----------
Args=struct('Pad',1,...      % pad the time series with zeroes (recommended)
    'Dj',1/12, ...    % this will do 12 sub-octaves per octave
    'S0',2*dt,...    % this says start at a scale of 2 years
    'J1',[],...
    'Mother','Morlet', ...
    'MaxScale',[],...   %a more simple way to specify J1
    'MakeFigure',(nargout==0),... % if zero, no figure is plotted
    'BlackandWhite',0,...
    'AR1x','auto',...
    'AR1y','auto',...
    'Mccount',500,... % number of Monte Carlo interations
    'Alpha',0.05, ... % pointwise significance level 
    'Dir', 'Vert'); % Use Vert to display period on the horizonal axis and global coherence on the vertical axis. 
    
Args=parseArgs(varargin,Args,{'BlackandWhite'});
if isempty(Args.J1)
    if isempty(Args.MaxScale)
        Args.MaxScale=(nx*.17)*2*dt; %automaxscale
    end
    Args.J1=round(log2(Args.MaxScale/Args.S0)/Args.Dj);
end

if strcmpi(Args.AR1x,'auto')
    Args.AR1x=ar1nv(dx(:,2));
    if any(isnan(Args.AR1x))
        error('Automatic AR1 estimation failed. Specify it manually (use arcov or arburg).')
    end
end

if strcmpi(Args.AR1y,'auto')
    Args.AR1y=ar1nv(dy(:,2));
    if any(isnan(Args.AR1y))
        error('Automatic AR1 estimation failed. Specify it manually (use arcov or arburg).')
    end
end

[px,period,scale,coi] = wavelet(dx(:,2),dt,Args.Pad,Args.Dj,Args.S0,Args.J1,Args.Mother);
[py,period,scale,coi] = wavelet(dy(:,2),dt,Args.Pad,Args.Dj,Args.S0,Args.J1,Args.Mother);

pxnew = px(:,:);
pynew = py(:,:);

px = pxnew;
py = pynew; 

pxy = px.*conj(py);
 
  
% compute global coherence 

px = abs(px).^2;
py = abs(py).^2;

G1t = sum(px,2);
G2t = sum(py,2);

XCt = abs(sum(pxy,2)).^2;
Dt = (G1t.*G2t);
C = XCt./Dt;

  %calculate significance using Monte Carlo Methods
 
   h = waitbar(0,'Monte Carlo Significance'); 
    
  for ii=1:Args.Mccount
      x = rednoise(nx,Args.AR1x,1);
      y = rednoise(ny,Args.AR1y,1);
      
      [pxnull,period,scale,coi] = wavelet(x,dt,Args.Pad,Args.Dj,Args.S0,Args.J1,Args.Mother);
      [pynull,period,scale,coi] = wavelet(y,dt,Args.Pad,Args.Dj,Args.S0,Args.J1,Args.Mother);
      
      pxynull = pxnull.*conj(pynull); 
      
      pxnull = abs(pxnull).^2;
      pynull = abs(pynull).^2;
      
      G1t = sum(pxnull,2);
      G2t = sum(pynull,2);
      
      XCt = abs(sum(pxynull,2)).^2;
      Dt = (G1t.*G2t);
      
      %global coherence
      Cnull(ii,:) = XCt./Dt;
      
         
      waitbar(ii/Args.Mccount,h); 
      
  end
  
  close(h);
  
    
    %compute critical level of the test
    ptile = prctile(Cnull, 100 * (1 - Args.Alpha),1); 
    
   %plot results
 if Args.MakeFigure   
    if(strcmp(Args.Dir,'Horiz'))
        plot(C,log2(period)); 
        hold on
        plot(ptile,log2(period),'--k','Linewidth',2);
        Yticks = 2.^(fix(log2(min(period))):fix(log2(max(period))));
        
        set(gca,'YLim',log2([min(period),max(period)]), ...
            'YDir','reverse', ...
            'YTick',log2(Yticks(:)), ...
            'YTickLabel',num2str(Yticks'), ...
            'layer','top');
        
        ylabel('Period');
        xlabel('Global Coherence');
    else
        plot(log2(period),C); 
        hold on
        plot(log2(period),ptile,'--k','Linewidth',2);
        Xticks = 2.^(fix(log2(min(period))):fix(log2(max(period))));
        set(gca,'XLim',log2([min(period),max(period)]), ...
            'XTick',log2(Xticks(:)), ...
            'XTickLabel',num2str(Xticks'), ...
            'layer','top');
        
        ylabel('Global Coherence');
        xlabel('Period');
        
    end
 end    


end
