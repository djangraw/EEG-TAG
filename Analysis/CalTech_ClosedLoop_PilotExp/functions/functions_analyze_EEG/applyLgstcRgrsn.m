%%%
%%%This function just applies Logistic Regression weights of a
%%%classifier to the Fisher Linear version of the data (can be obtained
%%%using applyFisher.m).
%%%
%%%The input matrix is of size T*NxW, where N is the number of trials, W
%%%is the number of time windows in the classifier, and T is the number of
%%%data points associated with each time window within a trial (T==1 if
%%%there is no oversampling).
%%%
%%%The output ILR_output) is of size 1xT*N.
%%%
%%%Last modified Sept 2009, EAP

function [LR_output] = applyLgstcRgrsn(FLDdata,Cparams)

%%%
%%%Multiple the LR weights by the data.
LR_output = FLDdata*Cparams.W(2:end) + Cparams.W(1);

