%%%
%%%This file takes a 3D matrix of trial data (X3) and applies a previously
%%%determined classifier (both Fisher Linear Disrciminant and Logistic
%%%Regression Components) to it and returns the result (Classifier_output)
%%%as well as the explicit Expectation values that are associated with each
%%%data point outputted by the classifier.
%%%
%%%Each row of X3 should correspond to the different electrodes.  Columns
%%%of the data reflect time.  If a 3 dimensional matrix is given as the
%%%input (ie this matrix is more than a single  trial), the 3rd dimension
%%%is considered.
%%%
%%%X3 => trial data, of size: DxT*WxN, where D:#electrodes, N:#trials,
%%%W:#windows, T:#data points per time window.
%%%
%%%Cparams => standard structure of classifier weights
%%%
%%%nodupeflag (optional, default is 0) => in the case where the trial data
%%%is sampled at a higher rate than is called for by the classifier, and
%%%window_start/end is not explicit, you can set this value to 1 so that
%%%data points are associated with windows in a way wherein no data point will
%%%be assigned to more than one window (this is similar to the online code
%%%and means that you may have different numbers of data points being
%%%assigned to each time window.
%%%
%%%condenseflag (optional, default is 1) => set this flag to one if you want
%%%all data within a trial that is associated with a single classifier time
%%%window to be averaged together (this means you will only get a single
%%%classifer output value for each trial).  This is again only necessary if
%%%the trial data is sampled at a higher rate than is called for by the
%%%classifier weights.
%%%
%%%window_start, window_end (optional) => if the trial data is sampled at a
%%%higher rate than is called for be the classifier, these inputs can be
%%%used to specify exactly which trial data pts are to be associated with
%%%which of the classifier weights.  If not specified, these values will be
%%%determined using the number of data points, the number of weights, and
%%%the nodupe and condense flags.
%%%
%%%In the case of an 'oversampled' input and output, you can averaged
%%%together all of the output values for a single trial (and thus
%%%obtaining the output you'd generate if all the oversampled input values
%%%had been combined) using: 
%%%     mean(reshape(Classifier_output',NumPtsPerWindow,NumTrials))
%%%
%%%[Classifier_output Expectations] = applyClassifier(X3, Cparams, condenseflag, nodupeflag, window_start, window_end);
%%%
%%%Last modified Sept 2009, EAP

function [Classifier_output Expectations] = applyClassifier(X3, Cparams, condenseflag, nodupeflag, window_start, window_end)

%%%Need to have either 2, 3, 4, or 6 arguments
if nargin == 5
    disp('Must specify BOTH beginning AND end of window start points')
    Classifier_output = []; Expectations = [];
    return;
end;
%%%
if nargin < 5; window_start = []; window_end = []; end;
if ( (nargin < 3) || isempty(condenseflag) ); condenseflag = 1; end;
if ( (nargin < 4) || isempty(nodupeflag) ); nodupeflag = 0; end;

%%%
%%%Characteristics of trial data
[numelectrodes NumDatapts trials] = size(X3);

%%%
%%%Qty of weights for the different time windows used by the classifier
NumWindows = size(Cparams.W,1)-1;

%%%
%%%If the number of weights matches the number of data points in each
%%%trial, you are ready to convolve the weights with the data.  If they are
%%%not the same, you need to determine exactly how the different weights
%%%should be matched to the different data points.
if NumWindows == NumDatapts
    disp('The number of data points matches the number of classifier weights');
    window_start = 1:NumWindows;
    window_end   = 1:NumWindows;
else
    %%%In this scenario, there are a couple options of how the weights and
    %%%the data points should be matched    
    %%%
    %%%first, if the user has specified window_start&window_end, you should
    %%%just use those, only get fancy if you have to.
    if ( isempty(window_start) || isempty(window_end) )
        disp(['Determining how oversampled data should be assigned to different time windows (nodupeflag = ',int2str(nodupeflag),')']);
        %%%Use the nodupleflag to know whether or not data points must
        %%%be uniquely assigned to a single time window/weight.
        [window_start window_end] = WindowStartPts(Cparams,NumDatapts,nodupeflag,window_start,window_end);
    else
        disp('Using specified windows to associate data with time windows/weights');
    end
    
    %%%Now check and see if the user wants there to be only a single output
    %%%for each trial, or if they want there to be multiple outputs for a
    %%%single trial (this happens as a consquence of the oversampling).
    %%%Even if the user didn't request this, you must do it if there are
    %%%different numbers of data points associated with the different time
    %%%windows.  
    %%%
    %%%If this isn't necessary, you are good to go with the existing
    %%%window_start/end definitions.
    %%%
    if ( (condenseflag == 1) || (length(unique(window_end-window_start)) > 1) )
        %%%This means merge oversampled data together.  Do it using the
        %%%window_start/end variables already determined.        
        disp('Averging together all data that falls within each time window to provide single output value per trial');
        %%%Average together all the data points in each trial that are
        %%%associated with the same time window.
        [X3] = mergeTrialTimeData(X3, window_start, window_end);     
        %%%
        %%%Once this has been done, you will need to redefine the
        %%%window_start/end points as the number of data points now matches
        %%%the number of weights.
        window_start = 1:NumWindows;
        window_end   = 1:NumWindows;        
    end
end


%%%
%%%You can apply the classifier for each trial independently using the
%%%online code, or you can simply apply all the classifier calculations in
%%%a couple large matrix operations (ie batch mode).
%%%
%method_mode = 'online';
method_mode = 'batch';
switch lower(method_mode)
    case 'online',
        %%%
        %%%Pre-allocate space
        Classifier_output = zeros(trials,1);%%%overall classifier
        for k=1:trials
            %%%Grab the data from each electrode (at each time point) for a single
            %%%trial.  This is the online method, and it only works if there is
            %%%only one data point for each time window (as there is in the
            %%%online version).
            Xproc = X3(:,:,k);
            %%%Determine the classifier output for that trial
            Classifier_output(k,1) = multiwindowFDA_run(Xproc,Cparams);    
        end
    case 'batch',
        %%%
        %%%This version does all the calculations at once (for a given time
        %%%window of the classifier), rather than just doing a single trial
        %%%at a time.  
        %%%Make a local copy of Cparams, so that you can be sure that for the
        %%%calculations here Cparams specifies the proper association between data
        %%%pts and time windows.
        Cparams_new = Cparams;
        Cparams_new.windowStart = window_start;
        Cparams_new.windowEnd   = window_end;
        %[window_start' window_end']
        %%%
        %%%Apply the Fisher Linear Discriminant component
        [FLD_output] = applyFisher(X3,Cparams_new);

        %%%
        %%%Apply the Fisher Linear Discriminant component
        [Classifier_output] = applyLgstcRgrsn(FLD_output,Cparams_new);
               
    otherwise,
        disp('something didn''t work');
        Classifier_output = [];
        Expectations = [];
        return;
end
    
%%%
%%%Determine what the actual probability expectation is that is associated
%%%with the classifier output.
Expectations = 1./ (1+exp(-(Classifier_output)));


