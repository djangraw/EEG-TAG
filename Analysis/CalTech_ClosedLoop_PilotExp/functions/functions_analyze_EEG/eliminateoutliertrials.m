%%%
%%%This function elimates trials from a set of analog data based on the
%%%amount of variation within that trial across all electrodes.
%%%PCT_OF_DATA_TO_REMOVE specifies what percentage of trials are discarded,
%%%these are the trials that have the largest amount of variation (on
%%%average accross all electrodes)during that trial, and thus are most
%%%likely to reflect a trial during which some kind of artifactual noise
%%%was recorded.
%%%
%%%trialdata and y can be generated with the convertanalog2trial.m function. 
%%%
%%%[trialdata y] = eliminateoutliertrials(trialdata , y, PCT_OF_DATA_TO_REMOVE);
%%%
%%%Last modified Feb 2009

function [trialdata y] = eliminateoutliertrials(trialdata , y, PCT_OF_DATA_TO_REMOVE)

if nargin <= 2
    PCT_OF_DATA_TO_REMOVE = 0.05;
end

if nargin == 1
    y = [];
end


%%%For each trial, find the average standard deviation across all the
%%%electrodes (for a trial where some kind of artifcatual noise happened,
%%%this will be large across all the electrodes), and sort the means from
%%%smallest to largest.
% [tmp,sortindx] = sort(mean(squeeze(std(trialdata,[],2))));
%%%
%%%In order to save memory, we are going to find the standard deviation of
%%%each trial one at a time.
[nelectrodes T ntrials] = size(trialdata);
average_std = zeros(1,ntrials);
for k=1:ntrials
    average_std(1,k) = mean(std(trialdata(:,:,k),[],2));
end
[tmp,sortindx] = sort(average_std);

%%%These are id's for all the trials whose variation/power fell within the
%%%acceptable limits
goodindx      = sortindx(1:end-round(length(sortindx)*PCT_OF_DATA_TO_REMOVE));

%%%Return data for all the trials that fall within the cut-off limit
trialdata = trialdata(:,:,goodindx);

if isempty(y)~=1
    original = sum(y);
    y = y(goodindx);
    fprintf('%4.0f target trials were dropped due to excessive analog variation \n', [original - sum(y)])
end
