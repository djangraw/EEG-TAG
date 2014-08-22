%%%
%%%Here we are going to make a scalp plot of the forward model of a the
%%%real-time training data.  The data used is the data specifically stored
%%%in the _cbci_xxxxxx.xxxx data folder created during the training
%%%session.
%%%
%%%[alpha] = RTscalpplot(training_dir,reref_flag,donotplot);
%%%
%%%training_dir => path of the directory where the classifier, and the
%%%asscoiated results of the training session are stored.
%%%
%%%donotplot => electrode channels that are to be excluded from the scalp
%%%plot
%%%
%%%reref_flag => if a vector of numbers between 1-64, the average of those
%%%channels are used to reference the data.  Default is for no extra
%%%referencing to be done in software (can specify by passing a neg value,
%%%a value of 0, or an empty matrix).  If value is greater than the number of
%%%channels (ie 65 or higher for a 64 channel data), then the average of
%%%all the channels are used (except for any channels that fall into the
%%%'donotplot' class.
%%%
%%%Last modified Jan 2010 EAP

function [alpha] = RTscalpplot(training_dir,reref_flag,donotplot)

if nargin < 1; training_dir = cd; end;
if nargin < 2; reref_flag   = []; end;
if nargin < 3; donotplot    = []; end;
%%%If any part of reref flag is 0 or less, don't do any re-referencing
if sum(reref_flag <= 0)>=1; reref_flag = []; end;

%%%Log the current directory, and then go to the directory that has the
%%%data
current = cd;
cd(training_dir);
%%%
%%%Load Cparams (which has all the model parameters)
load classifier
keep Cparams current donotplot reref_flag
%%%
%%%Load up the EEG data from each trial that was used to create the
%%%classifier in Cparams
load trainDatabase
%%%
%%%Go back to the directory you started from.
cd(current);
%%%
%%%Make a 3D trial matrix of the training data
X3 = cat(3,trainingDatabase.Xtargets(:,:,1:trainingDatabase.targetCounter),...
    trainingDatabase.Xnontargets(:,:,1:trainingDatabase.nontargetCounter));
%%%
%%%Re-reference the data by subtracting the average signal across eletrodes
%%%from each channel (at each time point).
%%%Do not include channels known to be recording noise in this average.
if ~isempty(reref_flag)
    disp(' ');
    %%%Determine which electrodes to use as new reference (it will be the
    %%%average of these channels).
    if max(reref_flag) > size(X3,1);
        %%%Can specify using all channels (except those channels that fall
        %%%into the 'donotplot' category.
        ref_electrodes = setdiff(1:size(X3,1),donotplot);
        disp('Re-referencing data to the average across all channels');
    else
        %%%Use specified channels
        ref_electrodes = reref_flag;
        disp(['Re-referencing data to the average across the following channels: ', int2str(ref_electrodes(:)')]);
    end;    
    disp(' ');
    %%%Subtract out the mean of specified electrodes from each of the other
    %%%electrodes (on a per-trial basis).
    for k=1:size(X3,3)%do on a per-trial basis
        X3(:,:,k) = X3(:,:,k) - repmat( mean( X3(ref_electrodes,:,k), 1 ), size(X3,1) ,1 );
    end
end
%%%
%%%Make vector indicating which trials correspond to target events
target_events = false(trainingDatabase.targetCounter+trainingDatabase.nontargetCounter,1);
target_events(1:trainingDatabase.targetCounter,1) = true;
%%%
%%%Determine the forward model of the online data, make scalp plot
[alpha] = forward_model(Cparams,X3,target_events,~target_events,1);

%%%make a version of the plots without certain (likely bad) channels
if ~isempty(donotplot)
    if size(Cparams.windowStart,2) == size(X3,2)
        %%%Round to the nearest millisecond.
        timespan_msec = 1000*[round(1000*Cparams.windowStart'/2048)/1000 round(1000*Cparams.windowEnd'/2048)/1000];
    else
        timespan_msec =size(X3,2) * 100;
    end
    fighandle = generatescalpplot(alpha,'BioSemi64.loc',timespan_msec,donotplot);
    %figure(fighandle); subplot(3,5,1); ylabel(['No Ch: ',int2str(donotplot)]);
end

%%%
%%%Find the Az value of the data
[Output Expectations] = applyClassifier(X3, Cparams);
Az = rocarea(Output,target_events);
%%%
%%%Now make a scalp plot that shows the ERPs of each electrode.
%%%Plot mean ERP for each electrode, target and non target trials
%%%
%%%Get the sampling freq of the merged/downsampled/averaged data
Fs         = round(mean(2048./(Cparams.windowEnd-Cparams.windowStart)));
%%%If the first timepoint does not correspond to zero lag, ie the
%%%classifier skipped a chunk of data following each event, pad the trial
%%%matrix with a quantity of zeros that reflect this gap in the timing,
%%%that way you are plotting the ERP's relative to zero properly.
if Cparams.windowStart(1) > 1
    disp('Compensating for gap in trial matrix when plotting relative to zero');
    padding = round(Fs*(Cparams.windowStart(1)-1)/2048);
    X3_new = nan(size(X3,1),size(X3,2)+padding,size(X3,3));
    X3_new(:,(padding+1):end,:) = X3;
    clear X3; X3 = X3_new; clear X3_new;
end
%%%when plotting means over all trials, need to know the max of the target
%%%and distracter trials
%X3(donotplot,:,:) = nan;
limit1 = ceil(max([max(max(abs(mean(X3(setdiff(1:size(X3,1),donotplot),:,target_events),3))))
    max(max(abs(mean(X3(setdiff(1:size(X3,1),donotplot),:,~target_events),3))))]));
plotlimits1 = [0 size(X3,2)-1 limit1*[-1 1]];
%%%
titletext  = sprintf('Ave ERP (Target/blue vs Nontarget/red) \nAz: %0.2f', Az);
ERPs_on_scalpplot(X3,titletext,Fs,plotlimits1,target_events,~target_events);



