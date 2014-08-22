function [trainingDatabase] = add2trainingset(X,label,trainingDatabase)
% [trainingDatabase] = add2trainingset(X,label,trainingDatabase)
%
% Adds the sample provided in the X variable, to the trainDatabase
% trainDatabase holds the data for the two classes separetly. Since this
% method will be called often we avoid any testing for errors, it assumes
% that you have the write datastructure specified.
%   Input:
%       X : vector or matrix of a training sample, can be raw EEG, filtered
%       EEG of featrure vector/matrix.
%
%       label: The class of X, label =0 non-target label=1 target
%
%       trainingDatabase: structure to store the training samples
%          trainingDatabase.Xtargets : tensor of targets.
%          trainingDatabase.Xnontargets = tensor of non targets
%          trainingDatabase.targetCounter : counter of targets
%          trainingDatabase.nontargetCounter counter of non targets.
%
% Author : Christoforos Christoforou
% Date : August 1, 2008
%

% if not provided initialize

bufferjumps = 2500;
if (isempty(trainingDatabase)),
    trainingDatabase.Xtargets = [];
    trainingDatabase.Xnontargets = [];
    trainingDatabase.targetCounter = 0;
    trainingDatabase.nontargetCounter = 0;
end;



% if array is full, increase the size
if (size(trainingDatabase.Xtargets,3) <= trainingDatabase.targetCounter),
    [D T] = size(X);
    trainingDatabase.Xtargets = cat(3,trainingDatabase.Xtargets,zeros(D,T,bufferjumps));
end;


if (size(trainingDatabase.Xnontargets,3) <= trainingDatabase.nontargetCounter),
    [D T] = size(X);
    trainingDatabase.Xnontargets = cat(3,trainingDatabase.Xnontargets,zeros(D,T,bufferjumps));
end;

switch label
    case 1,
        trainingDatabase.targetCounter = trainingDatabase.targetCounter + 1;
        trainingDatabase.Xtargets(:,:,trainingDatabase.targetCounter) = X;
    case 0,
        trainingDatabase.nontargetCounter = trainingDatabase.nontargetCounter + 1;
        trainingDatabase.Xnontargets(:,:,trainingDatabase.nontargetCounter)=X;
end;

