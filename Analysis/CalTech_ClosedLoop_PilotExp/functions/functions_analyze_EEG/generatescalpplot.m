%%%This function uses the topoplot function from EEG lab to generate a
%%%generic set of scalp maps for a matrix of data.  Each row of the matrix
%%%is assumed to be a different channel of EEG data, and the columns are
%%%assumed to be data related to a different timepoint corresponding to the
%%%channels.  A subplot is generated for each of the scalp plots for each of
%%%these timepoints.
%%%
%%%electrodemapfilename contains the filename that maps each of the rows of
%%%electrode data to their position in the scalpmap.
%%%
%%%badchannels specifies any channels whose data is not to be plotted, if
%%%not specified (or input as []), all the data is plotted.
%%%
%%%timespan tells (in milliseconds) how much data is covered (in total) by
%%%the different columns in data contained in electrode data.  This is an
%%%optional input, if left empty it is assumed to be 1 second (1000
%%%millisec)
%%%
%%%fighandle is the handle for the generated figure
%%%
%%%fighandle = generatescalpplot(electrodedata,electrodemapfilename,timespan,badchannels);
%%%
%%%Last modified Feb 2009 EAP
%%%Dec 2009 modified so can give it specific timespans for plot labels, and
%%%to leave two plotting slots available for plotting distributions.  If
%%%timespan is a matrix, the contents of each row are used to label the
%%%each plot.

function fighandle = generatescalpplot(electrodedata,electrodemapfilename,timespan,badchannels)

if nargin <= 2
    timespan = 1000;%default assumption is a plot of 1 second of data
end

%%%You want timespand to either be a scalar, or a matrix of two columns,
%%%each row specifying the timing of each data window.
if size(timespan,2)~=2
    timespan = timespan';
end 

if nargin <= 3
    badchannels = [];
end

%%The number of channels (D) and time windows (K) that are to be ploted
[D K] = size(electrodedata);

%%%Make sure you have suffficient timespan specifications for each time
%%%window (if not using a single span)
if length(timespan)>1
    if size(timespan,1)~=K
        disp('Insufficient timespan specification');
    end
end

%%%If you don't want information for an electrode(s) affecting the
%%%plot, replace all that data with NaN
if isempty(badchannels) ~= 1
    electrodedata(badchannels,:)=NaN;
end

%%%Create the figure
%fighandle = figure(1); hold on;
fighandle = figure; hold on;
allcax    = [0 0];%default plotting limits

%%%This determines how many rows and columns you need in the subplot format
%%%in order to accomodate all the scalplots that are getting generated.
%%%
%%%This method grows columns slightly faster than rows
% numrows = 1;numcols = 1;
% while numrows*numcols < K
%     if numcols <= numrows; numcols = numcols + 1;
%     else numrows = numrows + 1; end;
% end
%%%this method assumes that you never want to have more columns than 5, and
%%%that you want two spots available for a distribution plot, so it grows
%%%the number of rows until you can do that
numrows = 1;
while ceil((K+2)/numrows) > 5
    numrows = numrows + 1;
end
numcols = ceil((K+2)/numrows);

%%%Now make all the plots
for k=1:K,
    subplot(numrows,numcols,k);

    %%%the default for 'plotrad' is 0.5 (which plots data only from
    %%%electrodes of radius 0.5 or less, which are the ones that
    %%%are above head center).  If you set 'plotrad' to 1 data from all
    %%%electrodes are plotted, with electrdoes below head center (radius
    %%%>0.5) being plotted in a 'skirt' around the head cartoon.
    %%%
    %%%The default for 'headrad' is 0.5 (plots the head cartoon so it only
    %%%contains electrodes of radius 0.5 or less, which are the ones that
    %%%are above head center).  If you set 'headrad' to 1.0 then the
    %%%cartoon is plotted around the data for ALL the electrodes, even the
    %%%ones that are below head center (this makes this cartoon
    %%%anatomically incorrect).  You can't have a plotrad of 0.5 and a head
    %%%radius of 1.0 (cartoon heads not plotted).
    %%%
    %%%The default of 'intrad' is 0.5 (only interpolates data from
    %%%electrodes of radius 0.5 or less, which are the ones that
    %%%are above head center/ie above eyes/ears).
    %%%
    %%%can use pop_chanedit([]); to examine the location file, if want
    %%%smoother looking plot, can increase gridscale value (default=67).
    %%%
    %%%Use the scalp plot function from EEGLab
    %topoplot(electrodedata(:,k),electrodemapfilename,'electrodes','off', 'gridscale',40,'maplimits','maxmin','headrad',0.5,'intrad',0.5,'plotrad',1.0);%plots all data, including outside head cartoon
    %topoplot(electrodedata(:,k),electrodemapfilename,'electrodes','off', 'gridscale',40,'maplimits','maxmin','headrad',0.5,'intrad',0.5,'plotrad',0.5);%only plots within head cartoon
    topoplot(electrodedata(:,k),electrodemapfilename,'electrodes','off', 'gridscale',40,'maplimits','maxmin');%only plots (and interpolates) up to max electrode diameter
    %%%
    %topoplot(electrodedata(:,k),electrodemapfilename,'electrodes','off', 'gridscale',40,'maplimits',range);%specify plotting range
    %%%
    %%%Keep a running tally of the min/max axis limits for the subplots
    cax = caxis;
    allcax(1) = min(allcax(1),cax(1));
    allcax(2) = max(allcax(2),cax(2));

    %%%Title each subplot with the corresponding time intervals
    if length(timespan)==K
        title([num2str(timespan(k,1)) '-'  num2str(timespan(k,2)) 'ms']);
    else
        title([num2str(1+((k-1)*timespan)/K) '-'  num2str(k*timespan/K) 'ms']);
    end
end; 
%%%You want to have the same plotting range for each of the subplots
for k=1:K, subplot(numrows,numcols,k); caxis(allcax); end;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%Some classic code this function was derived
%%%%%%%%%%%%%%%%%%%%%%%%%%%%from
% 
% % Make a scalp plot of the forward model
% figure(1); hold on;
% %range = [min(alpha(:)) max(alpha(:))];
% allcax = [0 0];
% for k=1:K,
%     %%%If you don't want information for an electrode affecting the
%     %%%plot, replace all that data with NaN
%     %alpha(badelectrodes,k)=NaN;        
%     subplot(3,4,k);
%     %%%Use the scalp plot function from EEGLab
%     topoplot(alpha(:,k),'BioSemi64.loc','electrodes','off', 'gridscale',40,'maplimits','maxmin','plotrad',0.5);
%     %topoplot(alpha(:,k),eloc,'electrodes','off','gridscale',40,'maplimits',range);
%     %%%
%     cax = caxis;
%     allcax(1) = min(allcax(1),cax(1));
%     allcax(2) = max(allcax(2),cax(2));
%     title([num2str(1+((k-1)*L)/K) '-'  num2str(k*L/K) 'ms']);
% end; 
% %%%You want to same plotting range for each of the subplots
% for k=1:K, subplot(3,4,k); caxis(allcax); end;