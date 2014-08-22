%%%This function does a set of three basic plots given the results of a
%%%classification algorithm.  These include plots of the distributions of
%%%the scores, an ROC curve, and a Precision recall curve
%%%
%%%displayclassificationresults(ConfidenceValues,TargetStatus);
%%%
%%%Last modified Feb 2009, EAP

function displayclassificationresults(ConfidenceValues,TargetStatus)

%%%
%%%Plot a distribution of the confidences of the known non-target chips
%plotEEGscoredistributions(ConfidenceValues(TargetStatus),ConfidenceValues(~TargetStatus));
plotEEGscoredistributions2(ConfidenceValues(TargetStatus),ConfidenceValues(~TargetStatus));
%%%
%%%Overlay that distribution with the distribution of the confidences of
%%%the known target chips

%%%
%%%Plot the ROC curve
%[Az,tp,fp,fc]=rocarea(ConfidenceValues,TargetStatus);
figure;
rocarea(ConfidenceValues,TargetStatus);

%%%
%%%Plot the Precision recall curve
%[prec,tpr, fpr, pred_thresh] = prec_rec(pred,pos,count,num_thresh,varargin);
%prec_rec(ConfidenceValues,TargetStatus);
[Precision Recall h_precrcall] = precisionrecallcurve(ConfidenceValues,TargetStatus);
title('Precision-Recall Curve');