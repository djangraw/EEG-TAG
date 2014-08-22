%%%
%%%This function just applies the classifier weights for the Fischer
%%%Linear Discriminat Classifier to the data in a 3D trial matrix.  The
%%%classifier weights are stored in the standard strucuter for this:
%%%Cparams.  If the sampling rate in the 3D trial matrix exceeds that for
%%%which the classifier is designed, the data points are associated with
%%%the appropriate Classifier weights by using the windowStart and
%%%windowEnd information contained in Cparams.
%%%
%%%The input matrix is of DxT*WxN, where D=number of electrodes, and the
%%%FLD_output is of size: [T*N x W] where N is the number of trials, W
%%%is the number of time windows in the classifier, and T is the number of
%%%data points associated with each time window within a trial (T==1 if
%%%there is no oversampling).
%%%
%%%Last modified September 2009, EAP

function [FLD_output] = applyFisher(data,Cparams)

%%%
%%%Data is a 3D matrix of trials
[numelectrodes NumDataPts trials] = size(data);

%%%
%%%Qty of weights for the different time windows used by the classifier
NumWindows = size(Cparams.W,1)-1;

%%%
%%%Which data points are relevant to which classifier weight/window.
if NumWindows == NumDataPts
    windowEnd   = 1:NumWindows;
    windowStart = 1:NumWindows;
else
    windowEnd   = Cparams.windowEnd;
    windowStart = Cparams.windowStart;
end

%%%
%%%For each time window use the Fisher weights to collapse the data space
%%%between electrodes to a single value (do this for each time window
%%%independently)
%%%
%%%Pre-allocate space
FLD_output = zeros( trials*(windowEnd(1)-windowStart(1)+1), NumWindows );%rows are trials/timepts, columns are time windows
%%%
for t=1:NumWindows
    Xproc = data(:,windowStart(t):windowEnd(t),:);%chunk of data for this time window across all trials
    %%%
    %%%Multiply by the Classifier weights
    FLD_output(:,t) = [Cparams.Pdetect(t).v' * Xproc(:,:) + Cparams.Pdetect(t).b]';
end

