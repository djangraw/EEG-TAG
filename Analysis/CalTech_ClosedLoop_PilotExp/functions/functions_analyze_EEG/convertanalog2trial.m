%%%
%%%This function parses out a set of analog data into a 3-dimensional
%%%matrix that contains the data for each channel of data for a specified
%%%duration following markers that indicate both target and non-target
%%%(distracter) trials.  It also outputs a vector (y) that indicates
%%%whether each of the trials reflects a target trial (y=1) or a nontarget
%%%trial (y=0).  The amount of data that is desired for each trial is
%%%specified in triallength (the format of triallength should be the specific
%%%number of analog data points that are desired for each trial).
%%%
%%%[X3 y] = convertanalog2trial(analogdata,target_trial_ts,nontarget_trial_ts,triallength);
%%%
%%%X3 contains all the data of the form:
%%%Rows: electrodes
%%%Columns: temporal data within a single trial
%%%z dimension: individual trials
%%%y is vector of the same size of z that specifies whether each trial was
%%%a target (value 1) or a distracter (value 0).
%%%
%%%Last modified Feb 2009

function [X3 y] = convertanalog2trial(analogdata,target_trial_ts,nontarget_trial_ts,triallength)

%%%List of all trial times, in order
target_trial_ts    = target_trial_ts(:);
nontarget_trial_ts = nontarget_trial_ts(:);
alltrials = [target_trial_ts; nontarget_trial_ts];
alltrials = sort(alltrials,'ascend');

%%%Parse the analog data, extractign the requested amount of data following
%%%each event (for each channel) and arranging the data into a
%%%3-dimensional matrix (DxTxN) where
%%%D => number analog channels 
%%%T => number of analog data points during each trial
%%%N => number trials
X3 = analog2trial_matrix(analogdata,alltrials,triallength);

%%%Now make y, a vector that tells whether each the the 'N' trials
%%%corresponds to a target trial (y=1) or a distracter trial (y=0)
y = zeros(size(alltrials,1),1);
for k=1:size(target_trial_ts,1)
    y(alltrials == target_trial_ts(k,1),1) = 1;
end

