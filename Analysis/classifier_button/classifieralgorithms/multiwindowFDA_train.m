function res = multiwindowFDA_train(trainingDatabase, Cparams)
% res = multiwindowFDA_train(Xproc, Cparams)
%
% Author : Christoforos Christoforou
% Date : August 01, 2008
%


numoftargets = trainingDatabase.targetCounter;     % obtain the size of the number of targets
numofdistractors = trainingDatabase.nontargetCounter;     % obtain the size of the number of distractors

if (numoftargets < 50)
    res = Cparams;
    return;
end;

totalSamples = numoftargets + numofdistractors;

Xtrain = zeros(Cparams.numofwindows,totalSamples);
y = [ones(1,numoftargets) zeros(1,numofdistractors)];

for t=1:Cparams.numofwindows,  
    Xtrain(t,1:numoftargets) = Cparams.Pdetect(t).v' * squeeze(trainingDatabase.Xtargets(:,t,1:numoftargets)) + Cparams.Pdetect(t).b;
    Xtrain(t,(numoftargets+1):end) = Cparams.Pdetect(t).v' * squeeze(trainingDatabase.Xnontargets(:,t,1:numofdistractors)) + Cparams.Pdetect(t).b;
end;

[Cparams.W,loglik] = logisticregr(Xtrain',y,Cparams.W);
if isinf(loglik) | isnan(loglik)
    % if it fails the first time give it a second chance.
   [Cparams.W,loglik] = logisticregr(Xtrain',y,Cparams.W);
end

res = Cparams;