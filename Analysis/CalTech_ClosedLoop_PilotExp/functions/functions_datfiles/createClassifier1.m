%%%
%%%This function produces the same classifier (Fisher Linear Discriminant (FLD)
%%%and Logistric Regression) as is created by the Real-Time code at the end
%%%of an experiment (it does NOT produce the interatively refined
%%%classifier estimates that are created 'on the fly' in the real-time
%%%code).  Both this classifier (which contains the final estimates of the
%%%gauassian means and variances for each electrode in each time window)
%%%and the estimates of the average analog value during each time window
%%%for each electrode are returned.
%%%
%%%This function uses the same functions as the realtime code with the exception of
%%%being based around a stripped-down version of daqdetect and a more
%%%streamlined version of multiwindowFDA_preprocess/detect.m (these changes
%%%enable it to run more quickly).
%%%
%%%[Xm trialtype Cparams] = createClassifier1(file_name, RT_function_dir,windowStartSec,windowlength,regularizationvalue);
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
%%%Xm        => 3D matrix, each row is electrode, each column is
%%%timewindow, Z dim is for each trial.  This contains the average value
%%%of each electrode during each time window during each trial.  These are
%%%found using the same filtering and downsampling methods as is specified
%%%in the real-time code.
%%%
%%%trialtype => vector specifying the ID number of each trial in Xm
%%%
%%%Cparams   => classifier weights, also has estimates of mean and variance
%%%for each channel during each time window
%%%
%%%Last modified Sept 2009, EAP

function [Xm trialtype Cparams] = createClassifier1(file_name, RT_function_dir, windowStartSec, windowlength,regularizationvalue)

if nargin < 6
    regularizationvalue   = [];  %if you want to use regularization in the FLD calculation
end

if nargin < 5
    windowlength   = 0.1;  %in seconds
end

if nargin < 4
    windowStartSec = [0:0.1:0.9];  %in seconds
end

%%%
%%%First get overall estimates of the mean and variance for each electrode during
%%%each time window, as well as find the mean values for each and every
%%%trial.  You want to do this in the same way as is done by the online
%%%code.
[Xm trialtype Cparams] = ConvertDat2Trial_RT(file_name, RT_function_dir, windowStartSec, windowlength, 2048);

%%%
%%%Add a link to the RT functions that you want to emulate (ie the ones
%%%that were used during the Real-Time experiment) for the calculations for
%%%the classifier weights
addpath(genpath(RT_function_dir));

%%%
%%%Use the final running average values to calculate the Fisher Linear
%%%Discriminant weights
[Cparams] = estimateFLD_weights(Cparams,regularizationvalue);

%%%
%%%Using the mean values of each electrode (during each trial in each
%%%timewindow) and the FLD results, determine the logistic regression
%%%weights.
if sum(trialtype==160) >= 50
    %%%
    %%%Re-arrange the data matrix into the same format found in the online
    %%%trainingDatabase structure
    nontarget_trials = trialtype(:,1) == 80;
    target_trials    = trialtype(:,1) == 160;
    %%%
    trainingDatabase.Xtargets         = Xm(:,:,target_trials);
    trainingDatabase.Xnontargets      = Xm(:,:,nontarget_trials);
    trainingDatabase.targetCounter    = sum(target_trials);
    trainingDatabase.nontargetCounter = sum(nontarget_trials);
    %%%
    %%%Determine the weights of the logistic regression classifier, storing it in the Cparams structure
    Cparams = multiwindowFDA_train(trainingDatabase, Cparams);
end

%%%
%%%Remove the path to the real-time code
rmpath(genpath(RT_function_dir));

