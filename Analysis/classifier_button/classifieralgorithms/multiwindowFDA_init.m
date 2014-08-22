function [res] = multiwindowFDA_init(params)
%
% Implements the classifier initialization interface for the 
% windows based hierarchical classifier. 
%
%
% Author: Christoforos Christoforou
% Date : July 31, 2008
%

numofwindows = params.numofwindows;
eegChannels = params.eegChannels;
numEEGchannels = length(eegChannels); 

% Initialize detector, seperated in trigger.numWindows windows.
 Pdetect = detectinit(numEEGchannels);

for t=2:(numofwindows)
   Pdetect(t) = detectinit(numEEGchannels);
end;

W = 1e-10 * ones(numofwindows + 1,1); 

res.Pdetect = Pdetect;
res.W = W;
res.numofwindows = numofwindows;
res.numEEGchannels = numEEGchannels;
res.eegChannels = eegChannels;
res.windowStart = params.windowStart;
res.windowEnd = params.windowEnd ;