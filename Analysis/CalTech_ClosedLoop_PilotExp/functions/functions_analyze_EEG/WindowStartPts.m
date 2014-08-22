%%%
%%%In the case where the data is sampled at a higher rate than is called for by
%%%the weights utilized by one of the Fisher/Logistic Regression
%%%classifiers (this could occur, for example, in a 3d trial matrix created
%%%using the ConvertDat2Trial.m function) this function will tell you how the
%%%data points for any given trial should be grouped in order to match the
%%%time windows of the classifier.
%%%
%%%If the data in the 3D trial matrix is sampled at a higher rate than is
%%%called for by the classifier, eg Numdatapts > NumWindows, there are
%%%four options one how you can then consolidate this extra data prior to
%%%either creating a classifier from the data or applying a classifier to
%%%the data:
%%%1).  Use the user specified window start/end pts to divide up the data
%%%2).  Use the window start/stop points specified in Cparams to divide up
%%%the data
%%%3).  Evenly distribute the data pts between windows, but with no data
%%%pts getting used more than once (this mimics how it is done in the
%%%online code).  This can be difficult to accomplish automatically if
%%%there is any data 'skipped' by the classifier in the trial (most likely
%%%the data immediately following the trial start event), or other
%%%irregularities
%%%4).  Evenly distribute all the data pts in the trial between the time
%%%windows, some data points will be assigned to two time windows.  Again,
%%%this assumes that there are no pieces of data that are not to be used
%%%(have to use method 1 or 2 for that).
%%%
%%%First define the window stop and start points using whichever of the
%%%above techniques seems most appropriate, then use
%%%mergeTrialTimeData.m to create a new trial data matrix that only has
%%%'NumWindows' data points per trial.
%%%
%%%In cases where you have oversampled data, but still have exactly the
%%%same number of data pts in every time window, you can keep the data
%%%'oversampled' and still apply the classifier weights to the appropriate
%%%data points, thus returning multiple values of the classifier output for
%%%every trial.      
%%%
%%%[window_start window_end] = WindowStartPts(Cparams,NumDatapts,nodupeflag,window_start,window_end);
%%%
%%%Cparams => structure describing a classifier and its paramters
%%%
%%%NumDatapts => qty of data points during a given trial
%%%
%%%nodupeflag (optional) => flag that indicates when evenly dividing
%%%the trial data between time windows, you do not want any data point to
%%%become associated with more than one window.  Default is for this to be
%%%turned off.
%%%
%%%window_start & window_end => specify the bin indices of the first and
%%%last points in each trial at the current sampling rate that are related
%%%to parsing the data into the specified number of time windows (these
%%%windows being as close to being equal length as possible).
%%%
%%%Last modified Sept 2009, EAP

function [window_start window_end] = WindowStartPts(Cparams,NumDatapts,nodupeflag,window_start,window_end)

%%%
%%%Qty of weights for the different time windows used by the classifier
NumWindows = size(Cparams.W,1)-1;

%%%put some dummy values in Cparams if window start/stop aren't specified
if isempty(Cparams.windowStart);   Cparams.windowStart = 0; end;
if isempty(Cparams.windowEnd);   Cparams.windowEnd = 0; end;

%%%
if nargin < 4
    window_start = []; window_end = [];
end
if ( (nargin < 3) || isempty(nodupeflag) )
    nodupeflag = 0;
end

%%%
%%%Determine which of the methods is most approriate/selected and determine
%%%the appropriate bin indices of the start/stop points.
if ( ~isempty(window_start) && ~isempty(window_end) )
    %%%In this case, how the data is to be broken up is
    %%%already specified, so just check that it was specified
    %%%correctly
    if ( (length(window_start) ~= NumWindows) || (length(window_end) ~= NumWindows) )
        disp('WARNING: The number of windowing start/stop points does not match the number of classifier weights');
    end
elseif NumDatapts == NumWindows
    %%%In this case there is only one data pt per trial per weight,
    %%%so you don't have to worry about which weights are getting
    %%%assigne to which data points.
    window_start = 1:NumWindows;
    window_end   = 1:NumWindows;
elseif ( (Cparams.windowEnd(end) == NumDatapts) && (length(Cparams.windowEnd) == NumWindows) && (length(Cparams.windowStart) == NumWindows) )
    %%%In this case it is pretty clear you can use Cparams to
    %%%know how the data is to be divided up
    window_start = Cparams.windowStart;
    window_end   = Cparams.windowEnd;
elseif nodupeflag == 0
    %%%If there is no specified or definite way of dividing up
    %%%the data, just divide the data for a trial evenly (as best
    %%%you can) between the number of Classifier weights.  In this
    %%%formulation some data pts will be assigned to two time windows in
    %%%order for every time window to be associated with the exact same
    %%%number of data points.
    window_start = floor(1:NumDatapts/NumWindows:NumDatapts);
    window_end   = window_start+ceil(NumDatapts/NumWindows)-1;
elseif nodupeflag == 1
    %%%This is similar to the above, except in this case no data pt is
    %%%assigned to more than one window.  Consequently, the number of data
    %%%pts associated with each time window can vary. This method is more
    %%%reminiscent of the methods employed in the online code.
    window_start = round(0:(NumDatapts/NumWindows):(NumDatapts - NumDatapts/NumWindows))+1;
    window_end   = [window_start(2:end)-1 NumDatapts];
else
    disp('Not sure what method to use when assigning data points to specific time windows');
    window_start = []; window_end = [];
    return;
end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%Some other options for knowing how to divide up the data

%%%windowstart   => Time (in seconds) where each window of data should
%%%start relative to the event that signals the beginning of a trial
%%%
%%%windowlength   => Duration (in seconds) of each window of data
% function [window_start window_end] = WindowStartPts(windowstart,windowlength,samplingfreq)
% 
% %%%
% %%%Determine where each time window (for the classifier) would start for
% %%%the data contained in each trial of the 3D trial matrix
% window_start = round(windowstart*samplingfreq)+1;
% 
% %%%
% %%%This is where each window ends
% window_end = windowstart + windowlength;
% window_end = round(window_end*samplingfreq);



%window_start = round([0:((NumDataPts/samplingfreq)/NumWindows):(NumDataPts/samplingfreq - (NumDataPts/samplingfreq)/NumWindows)]*samplingfreq+1);
%window_end = [window_start(2:end)-1 NumDataPts];