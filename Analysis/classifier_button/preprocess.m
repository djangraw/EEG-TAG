function [X,P] = preprocess(X,P)
  
% Preprocess is a on-line version of our signal conditioning algorithm
% required prior to single trial event detection. It serves a number of
% functions: 1) subtracts eye activity 2) removes low frequency drifts, 60Hz
% noise, and 120Hz harmonic noise. 3) down-samples the data if required. 4)
% one can specify the channels that are to be filtered. The rest is left
% alone except for potentially down-sampling. 5) Optionally the filters can
% be applied as a FIR with linear phase (constant delay). Note that in that
% case the entire activity will be delayed by length(p.delay)/2
% samples. This guarantees zero phase delay. Most of the logic happens in
% preprocessinit.m.  Modify that code to set the options outlines above.
%
% [X,P] = preprocess(X,P) X has D rows, one for each channel, and one column
% for each sample. All parameters are stored in the structure P that is set
% by preprocessinit(). preprocess() itself updates some buffers in P and has
% to use the previous P as new input when called on consecutive frames of X.
%
% See example call at the end.
%
% (c) Lucas Parra, October 13, 2003, all rights reserved. Exclusive usage
% license to Anil Raj, UWF.


% filter some, delay others
[X(P.channels,:),  P.Zdec] = filter(    P.b, P.a, X(P.channels,:),   P.Zdec,2); 
[X(P.channelsNo,:),P.Zdel] = filter(P.delay,   1, X(P.channelsNo,:), P.Zdel,2);

% downsample
X = X(:,P.fsr:P.fsr:end);  

% remove eye blink and motion and add eye coordinates if requested
if P.U, 
  X = P.U*X;
end







return
% yes, that was it -- this here is test code.

D = 2;        % number of channels
blklen = 100; % process this many samples at once
fs = 2000;    % input at 1000Hz
fsref = 500;    % output at 500Hz
channels = 1:D-1; % process all channels except the last

P = preprocessinit(D,fs,fsref,channels)
Xall=[];Xallfilter=[];

% apply prerocess to a number of blocks data
for i=1:1000
  
  % simulate reading blklen samples
  X = randn(D,blklen); 

  % filter that block
  [Xfilter,P] = preprocess(X,P);

  % keep them so we can look at it
  Xall = [Xall X];
  Xallfilter = [Xallfilter Xfilter];
  
end

subplot(1,2,1); specgram(Xall(1,:),fs,fs)
subplot(1,2,2); specgram(Xallfilter(1,:),fsref,fsref)









