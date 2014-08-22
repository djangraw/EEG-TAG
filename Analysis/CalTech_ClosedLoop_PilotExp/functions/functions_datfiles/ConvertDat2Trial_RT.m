%%%
%%%This function takes a raw ProducerConsumer .dat file, and converts it
%%%into a 3D data matrix (X3) that summarizes the data for each electrode
%%%during every trial in the file.  This summary takes the form of
%%%filtering the data, and then breaking it into 'T' time windows that
%%%follow each event that marks a trial.  This particular formulation is
%%%done as it mimics how the data is processed in the real-time
%%%ProducerConsumer code during a training session, where the local
%%%equivalent of X3 is used to estimate the weights for the logistic
%%%regresssion part of the classifier.  Specifcially, the data for each
%%%electrode is simply averaged together to obtain the mean value for each
%%%time window, making X3 of size DxTxN, where D is the qty of electrodes,
%%%T is the number of time windows, and N is the number of trials.
%%%
%%%Furthermore, by assuming gaussians, estimates of the mean and variance
%%%of the analog data for each electrode (during each time window) are also
%%%determined, just as is done in the real-time ProducerConsumer code.
%%%These estimates (stored in the Cparams structure) are used in the
%%%real-time code to find the weights of the Fisher Linear Discriminant
%%%aspect of the classifier.
%%%
%%%In order to ensure that X3 and the gaussian estimates are the same as
%%%those found during a real-time experiment, this function uses the same
%%%functions as the realtime code with the exception of being based around
%%%a stripped-down version of daqdetect and a more streamlined version of
%%%multiwindowFDA_preprocess/detect.m (these changes enable it to run more
%%%quickly).  However, it is important that if you are trying to match a
%%%specific experiment's results that you ensure the directoy where this
%%%function looks for those files (specified in the RT_function_dir input)
%%%does point to the exact files used to compile ProducerConsumer for that
%%%experiment.
%%%
%%%[X3 trialtype Cparams] = ConvertDat2Trial_RT(file_name, RT_function_dir, windowStartSec, windowlength);
%%%
%%%file_name       => .dat file to process (must be from a training session)
%%%RT_function_dir => directory containing the exact set of matlab files
%%%compiled into the code run during the session in question
%%%
%%%windowStartSec  => beginning (in seconds) of each time window for the
%%%classifier
%%%
%%%windowlength    => length (in seconds) of each classifier time window
%%%
%%%X3        => 3D matrix, each row is electrode, each column is
%%%timewindow, Z dim is for each trial.  This contains the average value
%%%of each electrode during each time window during each trial.  These are
%%%found using the same filtering and downsampling methods as is specified
%%%in the real-time code.
%%%
%%%trialtype => vector specifying the ID number of each trial in X3
%%%
%%%Cparams   => classifier weights, also has estimates of mean and variance
%%%for each channel during each time window
%%%
%%%freq => sampling frequency of the analog data (2048Hz for the BioSemi
%%%system is the default value)
%%%
%%%Last modified Sept 2009, EAP

function [X3 trialtype Cparams] = ConvertDat2Trial_RT(file_name, RT_function_dir, windowStartSec, windowlength, freq)

if nargin < 6
    freq   = 2048;  %Typical value for BioSemi system
end

if nargin < 5
    windowlength   = 0.1;  %in seconds
end

if nargin < 4
    windowStartSec = [0:0.1:0.9];  %in seconds
end
    
%%%
%%%These are the parameters that specify how many and large the time
%%%windows are in which the data is binned.
windowEndSec   = windowStartSec+windowlength;% 

%%%
%%%Add a link to the RT functions that you want to emulate (ie the ones
%%%that were used during the Real-Time experiment)
addpath(genpath(RT_function_dir));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set up the recording parameters (these are for the BioSemi)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
D       = 73; % total number of channels: data + control
fs      = freq; % original (biosemi) sampling rate
fsref   = freq; % the downsampled rate (can ease memory, if same no downsampling)
eegchan = [3:66]; % indices of data channels

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% default functiosn used by the real-time code 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Classifier.initfnc       = 'multiwindowFDA_init';
Classifier.preprocfnc    = 'multiwindowFDA_preprocess';
Classifier.classtrainfnc = 'multiwindowFDA_train';
Classifier.classifyfnc   = 'multiwindowFDA_run';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize a classifier structure (Cparams)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Classifier.UserParams.numofwindows = length(windowStartSec);
Classifier.UserParams.windowStart  = round(windowStartSec*fsref)+1;
Classifier.UserParams.windowEnd    = round(windowEndSec*fsref);
Classifier.UserParams.eegChannels  = eegchan;
[Cparams]                          = feval(Classifier.initfnc,Classifier.UserParams);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% initialize Pfilt (filtering parameters)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Pfilt = preprocessinit(D,fs,fsref,eegchan);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% initialize necessary parameters for data loading
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
blklen                      = 1024;%how many data points to load at once
duration_sec                = windowEndSec(end); % epoch by taking duration_sec seconds of data for each trial
epochParams.duration        = round(duration_sec*fsref);   % number of samples in each epoch
epochParams.channels_subset = [eegchan];   % Channels to be used in the analysis.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize the event buffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
eventBuffer = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load data, find the mean values for each eletrode (during each timepoint)
% for each trial, and keep a running average for the electrodes' means and
% variances (also during the timewindows intrinsic to each trial).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%%Here is where you will store the averaged data from each trial, as well
%%%as what kind of event (target vs nontarget) that trial emcompasses
bufferlength = 3500;%how many trials can be loaded before allocating more memory
X3           = zeros(length(Cparams.eegChannels),Cparams.numofwindows,bufferlength);
trialtype    = zeros(bufferlength,1);
%%%
%%%Load 1st chunk of data from the file
[X filetell] = dat2core(file_name, blklen, 2);
%%%
trialcounter = 0;
while size(X,2) == blklen
%    X=X(:,find(~isnan(X(1,:))));       % Remove NaN's which normally separate triggers
    %%%
    %%%Convert event channels into sensible numbers
    X(2,:) = bitand(X(1,:),4096) > 0;               % Extract bit 12 bits of the trigger channels for the button keypad
    X(1,:) = bitand(X(1,:),255);                    % Extract event time markers
    
    %%%
    %%%Pre-processing (ie filtering) each channel (ie row) of data
    [Xfilter,Pfilt] = preprocess(X,Pfilt); 
    
    %%%
    %%%obtain a list of events to be processed
    [eventsQueue eventBuffer]= extractEvents(Xfilter,eventBuffer,epochParams);       
    
    %%%
    %%%For each full trial, update the running average of the mean and variance
    %%%for each electrode during each time window.  Also, save the mean value
    %%%of each electrode during each time window in a matrix for future
    %%%use, you will only be doing this for events for which you have a
    %%%full trials worth of data
    if (~isempty(eventsQueue))
        for lcv=1:length(eventsQueue.type)
            %eventsQueue.type(lcv)%what type of event we are dealing with here
            %80: nontarget, 160: target: for training files
            %220: nontarget, 210: target: for testing files
            trialcounter                    = trialcounter + 1;
            trialtype(trialcounter,1)       = eventsQueue.type(lcv);
            %%%TrialMeans will put the data following the trial event
            %%%marker into X3 for any type of trial.  However, the
            %%%estimates of the target/nontareget trial means and variances
            %%%in Cparams are only updated if the trialtype is 80, 160, 210
            %%%or 220
            [X3(:,:,trialcounter), Cparams] = TrialMeans( eventsQueue.data(:,:,lcv), Cparams, eventsQueue.type(lcv) );
            %%%
            if rem((sum(trialtype==160)+sum(trialtype==80)),100) < 1; fprintf('Processed: %u target trials, %u nontarget trials (%u trials total) \n',sum(trialtype==160),sum(trialtype==80),trialcounter); end;
            %%%check to see if you need to allocate more memory for storing
            %%%the results.
            if trialcounter ==  size(trialtype,1);
                X3         = cat(3,X3,zeros(length(Cparams.eegChannels),Cparams.numofwindows,bufferlength));
                trialtype  = cat(1,trialtype,zeros(bufferlength,1));
            end
        end
    end
    %%%
    %%%Load the next chunk of data
    [X filetell] = dat2core(file_name, blklen, 2, filetell);
end;

%%%
%%%Remove any 'dead', ie unused, space from the buffer matrices
if trialcounter < size(trialtype,1)
    X3         = X3(:,:,1:trialcounter);
    trialtype  = trialtype(1:trialcounter,:);
end

%%%
%%%Remove the path to the real-time code
rmpath(genpath(RT_function_dir));


%%%
%%%Below was some code to use if you only wanted to deal with trial that
%%%were specifically training Target and/or NonTarget trials.  It has been
%%%replaced, so this is here just in case decide to go back to that way
%%%
%     %%%Only care about target and non-target events
%     if ((eventsQueue.type(lcv) == 80) || (eventsQueue.type(lcv) == 160))
%         %80: nontarget, 160: target
%         trialcounter                    = trialcounter + 1;
%         trialtype(trialcounter,1)       = eventsQueue.type(lcv);
%         [X3(:,:,trialcounter), Cparams] = TrialMeans( eventsQueue.data(:,:,lcv), Cparams, eventsQueue.type(lcv) );
%         %%%
%         if rem(trialcounter,100) < 1; fprintf('Processed: %u target trials, %u nontarget trials (%u trials total) \n',sum(trialtype==160),sum(trialtype==80),trialcounter); end;
%         %%%check to see if you need to allocate more memory for storing
%         %%%the results.
%         if trialcounter ==  size(trialtype,1);
%             X3         = cat(3,X3,zeros(length(Cparams.eegChannels),Cparams.numofwindows,bufferlength));
%             trialtype  = cat(1,trialtype,zeros(1,bufferlength));
%         end
%     end
%         %%%There may be other events other than 80 and 160,
%         %%%don't do anything in those cases, the next time
%         %%%extractEvents is called the eventsQueue and eventBuffer
%         %%%will be cleared and recreated, so the all the trials
%         %%%listed in this for loop will disappear whether or not
%         %%%they were utilized (and we want the queue to get cleared
%         %%%out).
