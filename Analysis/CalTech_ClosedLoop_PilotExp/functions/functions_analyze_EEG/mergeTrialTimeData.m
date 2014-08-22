%%%
%%%Given a 3D (RxCxZ) matrix that contains trial information (Z is each
%%%trial and C is the within trial time), this function creates a new 3d
%%%trial matrix (same format) that has fewer data points per trial by
%%%averging together data points so that the temporal data for each trial
%%%in the new matrix covers the same span, but is contained in fewer data
%%%points.
%%%
%%%eg, if T=time of X3 trial, then the number of pts per trial in X3 is
%%%T*freq, and the number of data pts for each trial in the new matrix is:
%%%T*freq/targetwindowlength
%%%
%%%[newtrialmatrix] = mergeTrialTimeData(X3,freq,targetwindowlength);
%%%
%%%X3 => original matrix of trial data
%%%
%%%window_start & window_end => specify the bin indices of the first and
%%%last points in each trial at the current sampling rate that are related
%%%to parsing the data into the specified number of time windows (these
%%%windows being as close to being equal length as possible).  You can get
%%%these from the WindowStartPts.m function.
%%%
%%%Last modified Sept 2009, EAP

function [newtrialmatrix] = mergeTrialTimeData(X3,window_start, window_end)

%%%Dimensions of the original matrix of trial data
[R,C,Z] = size(X3);

%%%
%%%Create the new trial matrix.
%%%
%%%Do this by averaging together all the data within the specified time
%%%windows in the original data matrix (for eachtrial).
newtrialmatrix = zeros(R,length(window_start),Z);
%%%
for N=1:Z
    for t=1:length(window_start)    
        newtrialmatrix(:,t,N) = mean(X3(:,[window_start(t):window_end(t)],N),2);
    end
end





%%%Old, to delete method
% 
% %%%
% %%%These are the desired window spans (in seconds) in which we want to
% %%%merge data for the new trial matrix
% %windowStartSec = 0:targetwindowlength:((C/freq)-targetwindowlength);
% %windowEndSec   = windowStartSec + targetwindowlength;
% windowEndSec   = targetwindowlength:targetwindowlength:(C/freq);
% windowStartSec = windowEndSec - targetwindowlength;
% 
% %%%
% %%%Determine the bin indexes of data that needs to be merged to create the
% %%%new trial data matrix
% windowStart = round(windowStartSec*freq)+1;
% windowEnd   = round(windowEndSec*freq);


