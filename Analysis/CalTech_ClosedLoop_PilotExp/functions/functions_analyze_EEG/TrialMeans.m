%%%
%%%Given the analog data for a set of electrodes for a single trial, this
%%%function will find the average value of each electrode during that trial
%%%(Xmean).  It the trial corresponds to either a target or non-target
%%%presentation the data is also incorporated into a running average of
%%%the means and variance for each electrode (in Cparams) for eiter targets
%%%or nontargets (as appropriate).
%%%
%%%If there are multiple timewindows that the trial is to be divied up
%%%into, this is done for each time window independantly.
%%%
%%%Basically the goal of this function is to give you the same estimates of
%%%the average electrode activity during every trial (in Xmean) as well as
%%%running averages of the estimates of the means and variances (in
%%%Cparams) that are found in the same was as is done in the real-time
%%%ProducerConsumer code.
%%%
%%%Last modified Sept 2009 EAP

function [Xmean, Cparams] = TrialMeans(Xtrial,Cparams,trialID)

Xmean = zeros(length(Cparams.eegChannels),Cparams.numofwindows);

if ((trialID == 80) || (trialID == 220))%nontarget trial
    level = 2;
elseif ((trialID == 160) || (trialID == 210))%target trial
    level = 1;
    %disp('target trial');
else
    %%%This is not a target or non-target trial, so do not update the
    %%%gaussian estimates of the target/non-target means or variances
    level = [];
end

%%%
%%%For each time window, you need to find the mean value of each electrode
%%%is, as well as dete
for k=1:Cparams.numofwindows
    %%%
    %%%First, just find the average value for each electrode during each
    %%%time window, this is done for regardless of what the exact type of
    %%%trial is.
    Xmean(:,k) = mean(Xtrial(Cparams.eegChannels,[Cparams.windowStart(k):Cparams.windowEnd(k)]),2);
    
    %%%
    %%%If it is a target or non-target trial, update the appropriate estimates of the
    %%%means and variances in Cparams as well.
    if ~isempty(level)
        %%%
        %%%Number of data points in this window
        Qtydatapts = length([Cparams.windowStart(k):Cparams.windowEnd(k)]);

        %%%
        %%%Now update the running averages of the electrode values and
        %%%variances across all the trials to date.
        Cparams.Pdetect(k).mu(:,level)    = [Cparams.Pdetect(k).N(level,1)*Cparams.Pdetect(k).mu(:,level) + Qtydatapts*Xmean(:,k)]/(Cparams.Pdetect(k).N(level,1) + Qtydatapts);
        %%%
        %%%Update the running average variance with the (de-mean'd) variance of
        %%%the current chunk of data
        X = Xtrial(Cparams.eegChannels,[Cparams.windowStart(k):Cparams.windowEnd(k)]);
        X = X - repmat(Cparams.Pdetect(k).mu(:,level),[1 Qtydatapts]);%remove the mean    
        Cparams.Pdetect(k).sig(:,:,level) = [Cparams.Pdetect(k).N(level,1)*Cparams.Pdetect(k).sig(:,:,level) + X*X']/(Cparams.Pdetect(k).N(level,1) + Qtydatapts);

        %%%
        Cparams.Pdetect(k).N(level,1)     = Cparams.Pdetect(k).N(level,1) + Qtydatapts;
    end
end

%%%
%%%Don't do anything with v and b in Cparams, these are found when the
%%%running average takes into account the whole data file and you are
%%%trying to create the classifier (see createClassifier1 if you want to do
%%%that).

