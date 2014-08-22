function [X,P] = preprocess2(X,P)
  
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


% delay control channels
if ~isempty(P.channelsNo)
    [X(P.channelsNo,:),P.Zdel] = filter(P.delaygp,   1, X(P.channelsNo,:), P.Zdel,2);
end
    
% preprocess
[X(P.channels,:),  P.Zdec] = filter(    P.gp, 1, X(P.channels,:),   P.Zdec,2); 

% if this is the first time that we're calling the function
%if nargin<3
%    [xr,  P.Zdecr] = filter(    P.br, P.a, X(P.channels,:),   [],2); 
%    [xi,  P.Zdeci] = filter(    P.bi, P.a, X(P.channels,:),   [],2); 
%else
%    % otherwise, continue filtering
%    [xr,  P.Zdecr] = filter(    P.br, P.a, xr,   P.Zdecr,2); 
%    [xi,  P.Zdeci] = filter(    P.bi, P.a, xi,   P.Zdeci,2); 
%end


% form instantaneous power
%Xpower = log( xr.^2 + xi.^2 );

% combine into single structure
%X = [X; Xpower];  

X(P.channels,:) = db(abs( X(P.channels,:) ));  

% downsample
X = X(:,P.fsr:P.fsr:end);  

% remove eye blink and motion and add eye coordinates if requested
if P.U, 
  X = P.U*X;
end







return
% yes, that was it -- this here is test code.

close all
D = 4;        % number of channels
blklen = 10000; % process this many samples at once
fs = 2000;    % input at 1000Hz
fsref = 500;    % output at 500Hz
channels = 2:D; % process all channels except the first

P = preprocessinit2(D,fs,fsref,channels)

  
% simulate reading blklen samples
X = randn(D,blklen); 
  
% add tone at center frequency
fc = 40;
X(4,:) = X(4,:) + 10*cos(2*pi*fc/fs*[1:size(X,2)]);
%X(3,:) = X(3,:) + cos(2*pi*fc/fs*[1:size(X,2)]);

% filter that block
[Xfilter,P] = preprocess2(X,P);


subplot(4,1,1)
plot(X(1,:))
subplot(4,1,2)
plot(X(2,:))
subplot(4,1,3)
plot(X(3,:))
subplot(4,1,4)
plot(X(4,:))

figure
subplot(4,1,1)
plot(Xfilter(1,:))
subplot(4,1,2)
plot(Xfilter(2,:))
subplot(4,1,3)
plot(Xfilter(3,:))
subplot(4,1,4)
plot(Xfilter(4,:))






%subplot(1,2,1); specgram(Xall(1,:),fs,fs)
%subplot(1,2,2); specgram(Xallfilter(1,:),fsref,fsref)









