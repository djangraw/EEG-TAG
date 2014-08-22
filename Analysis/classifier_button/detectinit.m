function P = detectinit(D)
 
% P = detectinit(D) initializes the data structures for detect(). Note that
% until detect() has been called with at least one positive and one
% negative example no reasonable results can be expected. D is the
% dimensions of the classification vector (number of channels).
%
% (c) Lucas Parra, October 13, 2003, all rights reserved. Exclusive usage
% license to Anil Raj, UWF.

% just to allocated space
P.mu = zeros(D,2);
P.sig = zeros(D,D,2);
P.N = zeros(2,1);

% simply the average of all channels
P.v = ones(D,1);
P.b = 0;
P.thresh = 0;

% initialize mean X history for positive and negative exmaples
P.mhistory = {[],[]};

% here we will store the recomputed y for the entire history
P.y = {[],[]};

