function [Xproc Cparams] = multiwindowFDA_preprocess(X,class,Cparams)
%
% Implements the preprocess interface for the windows based hierarchical classifier. 
%
% Author: Christoforos Christoforou
% Date : July  31, 2008
%


Xproc = zeros(Cparams.numEEGchannels,Cparams.numofwindows);
for t=1:Cparams.numofwindows,
    [Ytmp,Xmean,Cparams.Pdetect(t)] = detect( X ( Cparams.eegChannels , Cparams.windowStart(t):Cparams.windowEnd(t)) , Cparams.Pdetect(t) , class);
    Xproc(:,t) = Xmean;
end;
