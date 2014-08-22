%%%
%%%This function uses a set of trial data and a set of classifier weights
%%%to determine the corresponding forward model (you can plot that on a
%%%scalp plot).
%%%
%%%[alpha] = forward_model(Cparams,Trial_Matrix,target_ids,nontarget_ids,plotflag);
%%%
%%%alpha        => forward model values
%%%
%%%Cparams      => contains the classifier weights (both Fisher and Logistic
%%%Regrdession).   Can be created using: multiwindowFDA_init.m
%%%
%%%Trial_Matrix => 3-D matrix of trial data (can be created from the .dat
%%%file using the LoadDat2Trial.m function).
%%%
%%%target_ids,nontarget_ids => logical index matrices telling which trials
%%%in Trial_Matrix correspond to target and distracter trials.
%%%
%%%plotflag (optional)      => 1 or 0 (default) depending if you want to make a
%%%scalp plot of the forward model or not (uses functions from the eeglab
%%%module for the plot so, so the topoplot function must be accessible for
%%%this function to work).
%%%
%%%There is some misc code at the end (not currently turned on) in case you
%%%want to try to work on finding the temporal forward model.
%%%
%%%Last modified Sept 2009, EAP
%%%Dec 2009, changed the plotting function so it works if the #windows ~=10

function [alpha] = forward_model(Cparams,Trial_Matrix,target_ids,nontarget_ids,plotflag)

%%%
%%%Location of the scalp plot function (topoplot)
addpath(genpath('D:\MATLAB\R2007a\work\DownLoaded\eeglab\eeglab2008September17_beta\functions'))

%%%
if (nargin < 5)
    plotflag = 'noplot';
end
if plotflag == 1
    plotflag = 'plot';
end
if (nargin < 4)
    nontarget_ids = ~target_ids;
end

target_ids    =   logical(target_ids);
nontarget_ids =   logical(nontarget_ids);

%%%
%%%Data characteristics
[numelectrodes NumDataPts numtrials] = size(Trial_Matrix);

%%%Remove any trials from the matrix that do not correspond to either a
%%%target or a distrater trial.
if ( (numtrials ~= length(target_ids)) || (numtrials ~= length(nontarget_ids)))
    spots         = or(target_ids,nontarget_ids);
    Trial_Matrix  = Trial_Matrix(:,:,spots);
    target_ids    =   target_ids(spots);
    nontarget_ids =   nontarget_ids(spots);
end

%%%
%%%Classifier characteristics
NumWindows = size(Cparams.W,1)-1;

%%%
%%%The forward models for each of the time windows are found independently
alpha = zeros(numelectrodes,NumWindows);

%%%
%%%It is possible that the data in the data matrix is sampled at a higher
%%%rate than is called for than the model weights, you will then need to
%%%make sure each data point is properly assigned to the right classifier
%%%weight.  
%%%If Cparams has the appropriate scaling in its windwStart and
%%%WindowEnd fields you can use that, otherwise determine how to divide
%%%up the data by using the trial length and the number of windows in the
%%%classifier.
%%%If the number of windows matches the number of data points, you don't
%%%need to worry about anything
if NumWindows == NumDataPts
    windowStart = 1:NumWindows;
    windowEnd   = 1:NumWindows;
    disp('Number of weights = Number of data points');
else
    if ( (length(Cparams.windowStart) == NumWindows) && (Cparams.windowEnd(end) == NumDataPts) )
        windowStart = Cparams.windowStart;
        windowEnd   = Cparams.windowEnd;
        disp('Using Cparams to fix how any oversampled data is placed in windows');
    else
        windowStart = floor(1:NumDataPts/NumWindows:NumDataPts);
        windowEnd   = [windowStart(2:end)-1 diff(windowStart(1:2))+windowStart(end)-1];
        disp('Inferring how the data is placed in windows by dividing the full trial length evenly into the requested number of time windows.');
    end
end

%%%
%%%Estimate the forward model for each time window
for k=1:NumWindows
    %%%
    %These are the indices of the data that falls within the current window
    %(do it this way in case you have more than one data point per window).
    currwindex = windowStart(k):windowEnd(k);
    %currwindex = window_start(k)+(0:window_size-1);
    %%%
    %%%forward model (alpha) calculation
    %%%
    %%%Define X so that each of rows (D) are for a different electrode, and
    %%%each row thus contains all the data pts from each trial that would fall within this
    %%%window (this use of reshape is equivalent to doing
    %%%Trial_Matrix(:,:).  By doing it this way you can take advantage of
    %%%an 'oversampled' trial data matrix, ie data that has a higher
    %%%sampling rate than is called for by the number of time windows in
    %%%the classifier.
    X = reshape(Trial_Matrix(:,currwindex,:),[numelectrodes length(currwindex)*numtrials]);
    R = X*X';%covariance of the data
    %%%
    alpha(:,k) = [R*Cparams.Pdetect(k).v]/[(Cparams.Pdetect(k).v'*R*Cparams.Pdetect(k).v)];  
    %%%
    clear X R currwindex
end

%%%
%%%Make a scalp plot of the forward model
if strcmp(plotflag,'plot');
    %%%
    %%%This is the timespan of each trial (ie all the windows) in milliseconds
    %%%(used for plotting)
    if size(Cparams.windowStart,2) == NumDataPts
        %%%Round to the nearest 10 milliseconds.
        timespan_msec = 1000*[round(100*Cparams.windowStart'/2048)/100 round(100*Cparams.windowEnd'/2048)/100];
    else
    %    timespan_msec = 1000;
        timespan_msec =NumWindows * 100;
    end
    %%%
    fighandle = generatescalpplot(alpha,'BioSemi64.loc',timespan_msec);%plotting the forward model
    %fighandle = generatescalpplot(alpha,'BioSemi64.loc',timespan_msec,[57]);%plotting the forward model with no electrode 57
%    fighandle = generatescalpplot(u,'BioSemi64.loc',timespan_msec);    %this is for plotting the pure weights
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%
%%%The following determines how effective the classifier can be in properly
%%%dividing the data into the two classes.  You can then add this
%%%information to the scalp plot.  Just get a single classifier value for
%%%each trial.
[Classifier_output Expectations] = applyClassifier(Trial_Matrix, Cparams, 1, 0, windowStart, windowEnd);
p = Classifier_output;

%%%This is for merging together the results in the case where you have
%%%oversampled data yielding more than one output per every trial.
% window_size = windowEnd(1) - windowStart(1) + 1;
% p = mean(reshape(Classifier_output,window_size,length(Classifier_output)/window_size),1);

%%%
%%This figure plots 'p', which shows the distribution of the probabilities
%%for both the target and non-target data, adding it to the previous figure
if strcmp(plotflag,'plot');
    %%%Determine the number of rows and columns that weould be in the plot
    numrows = 1;[D K] = size(alpha);
    while ceil((K+2)/numrows) > 5
        numrows = numrows + 1;
    end
    numcols = ceil((K+2)/numrows);
    %%%
    figure(fighandle); hold on;
    subplot(numrows,numcols,(numrows*numcols - 1):(numrows*numcols))
    n  = min(p):(max(p)-min(p))/20:max(p);
    h1 = hist(p(nontarget_ids),n); %nontargets
    h2 = hist(p(target_ids),n);%target trials
    bar(n,[h1'/sum(h1) h2'/sum(h2)],1); 
    xlim([min(n) max(n)]);
    %%%Labels
    legend('non-target','target')
    colormap('jet');
    title('class conditional likelihood')
    xlabel('classifier output y (a.u.)')
    ylabel('probability')
    hold off; 
end

%%%
%%%In case you'd want to print the figure
%print -depsc miniClassifierFigures.eps

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%Here is some first pass code for finding the temporal forward model
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for k=1:NumWindows
    % select current samples within this window
    currwindex = windowStart(k):windowEnd(k);
%    currwindex = window_start(k)+(0:window_size-1);
    %%%
    %%%Find the ...
    v(:,k) = zeros(NumDataPts,1);
    v(currwindex,k) = 1/Cparams.W(k+1);
    %%%The raw data is projected onto xxx
    %%%And then the projection is reshaped so that each row corresponds to
    %%%the amoutn of analog data during a trial, and each column represents
    %%%a different trail
    X = reshape(Cparams.Pdetect(k).v'*Trial_Matrix(:,:),[NumDataPts numtrials]);
    %%%Cov matrix of the data accross 
    R = X*X';
    %%%
    beta(:,k) = R*v(:,k)/(v(:,k)'*R*v(:,k));
end;

sampling_rate = NumDataPts;
if strcmp(plotflag,'plot');
    figure; hold on;
    range2 = [0 max(beta(:))];
    for k=1:NumWindows,
        subplot(3,4,k);
        plot((1:NumDataPts)*1000/sampling_rate,beta(:,k));  
        if k==5 || k==10, xlabel('time (ms)'); else set(gca, 'xtick',[]); end;
        xlim([0 1000]); ylim(range2); set(gca,'ytick',[]);
    end
end





