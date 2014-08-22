%%%
%%%This function plots a set of ERPs on a scalp plot.  It uses the EEGlab
%%%function 'plottopo'.
%%%
%%%The ERPs are drawn from a 3D matrix of trial data (X3).  You can either
%%%plot a subset of trials from the matrix (specifying with with the input
%%%trialsA while leaving trialsB empty) or you can plot the mean ERPs of
%%%two subset of trials (by specifying both trialsA, which will be blue,
%%%and trialsB, which will be red).  is this color specification correct?
%%%
%%%Any electrode channels that are not be plotted in the scalp plot can be
%%%specified with the (optional, default is none) input 'noplot'.
%%%
%%%Also plotted is a blue window that shows the timspan from 250-350msec.
%%%
%%%ERPs_on_scalpplot(X3,titletext,Fs,plotlimits,trialsA,trialsB,noplot); 
%%%
%%%Fs=>sampling rate of the data.
%%%
%%%titletext => what should be included as the title of the plot.
%%%
%%%plotlimits => vector that indicates the maximum and minimum x and y axis
%%%values [minX maxX minY maxY] for each ERP plot.  If specifed as 0 or [],
%%%then the default values will be used.
%%%
%%%Last modified Jan 2010 EAP

function ERPs_on_scalpplot(X3,titletext,Fs,plotlimits,trialsA,trialsB,noplot)

if nargin < 7
    noplot = [];
end

if nargin < 6
    trialsB = [];
end

if isempty(plotlimits)
    plotlimits = 0;
end

electrodemapfilename = 'BioSemi64.loc';

%P300block = mat2cell( repmat([-1 + round(Fs*[.25 .35])]',1,size(X3,1)), 2, ones(size(X3,1),1) )';%block showing time window for P300
P300block = mat2cell( repmat([Fs*[.25 .35]]',1,size(X3,1)), 2, ones(size(X3,1),1) )';%block showing time window for P300

if isempty(trialsB)
    toplot = X3(:,:,trialsA); %plot the specified trials only
else
    %%%Plot the means of each set
    toplot        = zeros(size(X3,1),size(X3,2),2);
    toplot(:,:,1) = mean(X3(:,:,trialsA),3);%mean of trial set 1
    toplot(:,:,2) = mean(X3(:,:,trialsB),3);%mean of trial set 2
end
%%%
%%%Make the plot
figure; plottopo(toplot,'chanlocs',readlocs(electrodemapfilename),'regions',P300block,'ydir',+1,'vert',round(.3*Fs),'title',titletext,'chans',setdiff(1:size(X3,1),noplot),'limits',plotlimits);



