%%%
%%%This file takes a set of data consisting of known trials and
%%%distracters, and creates a Classifier (combining fisher-logistic
%%%dixriminant and logistics regression components) from the data.
%%%
%%%This is done differently than the online code.  For example, it is done
%%%in a single batch operation.
%%%
%%%To get a suitable form of data from the raw .dat file, the function
%%%ConvertDat2Trial_RT.m can be used, if working from some generic analog
%%%data convertanalog2trial.m can be used.
%%%
%%%In the 3D trial data matrix, each row of data should correspond to the
%%%different electrodes.  Columns of the data reflect data within each
%%%trial, and each successive trial is included as the 3rd dimension of the
%%%matrix.
%%%
%%%The classifier weights are stored in the standard Cparams structure.
%%%
%%%[Cparams] = createClassifier2(Trial_Matrix,All_Events,NumWindows,conditioning_eigenvalue);
%%%
%%%Trial_Matrix => 3d matrix containing analog data for each data trial.
%%%                rows:electrodes, columns:data within trial, Z:each trial
%%%
%%%All_Events   => vector of numbers that shows exactly what kind of trial
%%%                 (target:160, nontarget:80) each trial corresponds to.
%%%                 You can also specify this as a vector of zeros
%%%                 (nontargets) and ones (targets).
%%%
%%%NumWindows   => number of timewindows into which the data for each trial
%%%                 is to be [evenly] divided.  Optional input, this is
%%%                 useful if the sampling rate of the data exceeds the
%%%                 windowing level of the model.  If not specified, it is
%%%                 assumed that each data point for a trial is to be
%%%                 placed in a different time window.
%%%
%%%conditioning_eigenvalue => Optional input (default is none), here you can
%%%                 specify whether or not you want to use an estimate of
%%%                 the noise to help regularize the matrix inversion (this
%%%                 input specifices which eigenvalue, 50 is a good one, of
%%%                 the covariance matrix is used for the noise).
%%%
%%%Last modified Sept 2009, EAP

function [Cparams] = createClassifier2(Trial_Matrix,All_Events,NumWindows,conditioning_eigenvalue)

%%%
[numelectrodes NumDataPts trials] = size(Trial_Matrix);

%%%
%%%Trial ID shouls be as a column vector
[n,d] = size(All_Events);
if d>n
    All_Events = All_Events';
end

%%%
if ((nargin < 4) || isempty(conditioning_eigenvalue) || (conditioning_eigenvalue==0))
    conditioning_eigenvalue = 0;
end
if ((nargin < 3) || isempty(NumWindows))
    NumWindows = NumDataPts;
end

%%%
%%%Initialize an empty Cparams structure
Classifier.UserParams.windowStart  = [];
Classifier.UserParams.windowEnd    = [];
Classifier.UserParams.eegChannels  = [1:numelectrodes];
Classifier.UserParams.numofwindows = NumWindows;
[Cparams] = multiwindowFDA_init(Classifier.UserParams);

%%%
%%%If the sampling exceeds the number of time windows desired for the
%%%classifier, you will then need to make sure each data point is properly
%%%assigned to the right classifier weight.  This can be done by simply
%%%evenly dividing up the data pts between the specified windows.  However,
%%%you must decide whether each data point can only be assigned to a single
%%%window, or if some data points can be associated with two adjacent
%%%windows.
if NumWindows == NumDataPts
    %%%
    window_start = 1:NumWindows;
    window_end   = 1:NumWindows;
    nodupeflag   = [];
    fprintf('Number of data pts per trial: %u; Number of Classifier temporal weights: %u \n',NumDataPts, NumWindows);    
else
    %%%Decide how data points are assigned to time windows
    %nodupeflag = 0;%in this case some data points end up asigned to two windows
    nodupeflag = 1;%Here each data point is uniquely assigned to a single window
    %nodupeflag = input('Enter 1 if you want each ''oversampled'' data pt assigned to one time window, and one time window ONLY ');
    %%%
    [window_start window_end] = WindowStartPts(Cparams,NumDataPts,nodupeflag);
end
%%%
%%%Store this in the Cparams structure
Cparams.windowStart  = window_start;
Cparams.windowEnd    = window_end;

%%%
%%%Target (160) and Distracter (80) trials (this assumes you are using data
%%%recorded during an official training session, in which those are the
%%%flags used).
if sum(unique(All_Events(:,1)) - [0;1]) == 0
    indx_c1 = All_Events(:,1) == 0;
    indx_c2 = All_Events(:,1) == 1;
else
    indx_c1 = All_Events(:,1) == 80;
    indx_c2 = All_Events(:,1) == 160;
end

%%%
%%%In the case where the data is sampled higher than what is called for by
%%%the classifier, Xmean is the average value of each electrode during each
%%%time window during each trial.
Xmean = zeros(numelectrodes, NumWindows, trials);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%First find the Fisher Linear Discriminant part of the classifier
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%%For each of the 'trials' temporal windows/slices of data that are used in the
%%%model, determine the characteristics of the input data for each
%%%electrode (at each timpoint that falls within the specified window)
for k=1:NumWindows
    %%%
    %%%These are the bins of analog data that correspond to this window of
    %%%time
    currwindex = window_start(k):window_end(k);
    %%%
    %%%Determine the mean and covariance of the analog data accross all the
    %%%the available trials (this average is for each electrode at each
    %%%point of time that spans that window).
    %%%
    %%%X(:,:) still has the same # of rows as X, but the third dimension (accross
    %%%trials aspect) is collapsed down into the 2nd dimension, so you are
    %%%putting all the time data for each trial into a single row for each
    %%%electrode).  This makes X(:,:) of size D x [N * (# of relevent slice pts per window, ie J/K)]
    %%%This is done so that you have several analog data points for each
    %%%window/time slice for a given trial, rather than simply filtering and
    %%%downsampling the analog data such that there is a single data point
    %%%for each window.  Apparently this 'oversampling' can help improve the
    %%%model estimation.  It is called oversampling, as by doing this for a
    %%%single trial you get several different (although not truely
    %%%independant) values of the EEG activity for each electrode that can be
    %%%related to the output (for this model the ouput being the status of the
    %%%presented image as a target or a distracter).    
    %%%
    %%%Do this for the distracter/nontarget trials
    X = Trial_Matrix(:,currwindex,indx_c1);
    m1 = mean(X(:,:),2);
    S1 = cov(X(:,:)');%covariance of the activities accross the electrodes
    %%%Cov matrix is of size D by D and gives the covariance across
    %%%electrodes
    clear X
    %%%
    %%%Do this for the target trials
    X = Trial_Matrix(:,currwindex,indx_c2); 
    m2 = mean(X(:,:),2);
    S2 = cov(X(:,:)');%do transpose so each column related to a diff electrode
    clear X
    %%%
    %%%Record the averages for each electrode during each trial for this
    %%%time window.
    Xmean(:,k,:) = mean(Trial_Matrix(:,currwindex,:),2);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Estimate of the pooled covariance between distracter (S1) and targets (S2)    %
    %%%This option gives the target trials just as much weight as                  %
    %%%distracters.                                                                %
    %SigmaPool = 0.5*S1 + 0.5*S2;                                                  %
    %%%Another option (just weighted mean, this is more similar to online code):   %
    SigmaPool = [sum(indx_c1)*S1 + sum(indx_c2)*S2] ./ (sum(indx_c1)+sum(indx_c1));%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%Here we are incorporating regularization to improve the matrix
    %%%inverse (hopefully)
    if conditioning_eigenvalue == 0
        Noise = 0*eye(numelectrodes);
    else
        % regularizing diagonal (eigenvalues of the pooled covariance matrix)
        Lambda = sort(eig(SigmaPool));        
        %%%
        %%%Get an estimate of the noise by using one of the eigenvalues
        Noise = Lambda(conditioning_eigenvalue)*eye(numelectrodes);
        %Noise = Lambda(end-60)*eye(numelectrodes);
        %Noise = Lambda(50)*eye(numelectrodes);  % eigenvalue index of condition is hard-coded
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%
    %%%Do a regularized LFD (ratio of difference in means to pooled
    %%%covariance between the two conditions)
    %%%
    %%%Use the noise estimates to compensate for the poor conditioning of the
    %%%of the matrix prior to its inversion    
    %Cparams.Pdetect(k).v = inv(SigmaPool+Noise)*(m2-m1);
    %%%
    %Another calc option (uses a pseudo invers)
    Cparams.Pdetect(k).v = pinv(SigmaPool+Noise)*(m2-m1);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%Now do the Logistic Regression part of the classifier
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%%Re-arrange the data matrix into the same format found in the online
%%%trainingDatabase structure
if NumWindows == NumDataPts
    %%%Just use the input matrix
    disp('When finding the LR weights, # data pts per trial = # of weights');
    trainingDatabase.Xtargets         = Trial_Matrix(:,:,indx_c2);
    trainingDatabase.Xnontargets      = Trial_Matrix(:,:,indx_c1);
    trainingDatabase.targetCounter    = sum(indx_c2);
    trainingDatabase.nontargetCounter = sum(indx_c1);
else%you have 'oversampled' data
    %%%
    if ( (length(unique(window_end-window_start)) == 1) && (nodupeflag ~=1 ) )
        disp('Using ''oversampled'' data to find the Logistic Regression weights');
        %%%in the case that you have the same number of data points per every
        %%%window, you can keep the data oversampled when you find the
        %%%logistic regression weights
        window_length = window_end(1)-window_start(1)+1;
        %%%
        %%%Reshuffle the data so that you extract 'window_length' number of
        %%%trials from each actual trial.
        trainingDatabase.Xtargets         = zeros(numelectrodes, NumWindows, sum(indx_c2) * window_length);%Pre-allocate
        trainingDatabase.Xnontargets      = zeros(numelectrodes, NumWindows, sum(indx_c1) * window_length);        
        for k=0:(window_length-1)
            trainingDatabase.Xtargets(:,:,[(sum(indx_c2)*k + 1) : ( sum(indx_c2) * (k+1) )]) = Trial_Matrix(:,window_start+k,indx_c2);            
            trainingDatabase.Xnontargets(:,:,[(sum(indx_c1)*k + 1) : ( sum(indx_c1) * (k+1) )]) = Trial_Matrix(:,window_start+k,indx_c1);
        end
        %%%%
        trainingDatabase.targetCounter    = sum(indx_c2) * window_length;
        trainingDatabase.nontargetCounter = sum(indx_c1) * window_length;        
    else
        %%%Otherwise you will have to use the averages so that you have the
        %%%same number of data points for every window        
        disp('Using the average value of each electrode during each trial in Logistic Regression');
        trainingDatabase.Xtargets         = Xmean(:,:,indx_c2);
        trainingDatabase.Xnontargets      = Xmean(:,:,indx_c1);
        trainingDatabase.targetCounter    = sum(indx_c2);
        trainingDatabase.nontargetCounter = sum(indx_c1);
    end
end

%%%
if trainingDatabase.targetCounter < 50
    disp('Fewer than 50 target examples, not bothering with Logistic Regression weights');
else
    %%%Determine the weights of the logistic regression classifier, storing it in the Cparams structure
    Cparams = multiwindowFDA_train(trainingDatabase, Cparams);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

