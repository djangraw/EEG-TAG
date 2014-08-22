function [theta] = bspl_logisticregr_map(x,y,theta,C)
%  bspl_logisticregr_map(x,y,theta) Maximu a postiriory estimate for
%  logistic regression.
%
% 
% intput:
%
%      x : input matrix DxN, D dimensions of the space N number of trials.
%      y : taget vector \in {-1,1}
%      theta : initil value of the parameter vector.
%      C :  regularization constant.
%
% Author:
%   Christoforos Christoforou
%  Date: July 15, 2007
%

maxit = 1000;
opts = [1e-8 1e-4 1e-8 maxit];
[N,D] = size(x); if D>N, x = x'; [N,D] = size(x); end
if nargin<4, C=0.001; end
if nargin<3, theta=zeros(D+1,1); end
X = [ones(N,1), x];
y = y(:);
y = (2*y) - 1;
x0 = theta;

[X, info] = ucminf('cost_logreg_map',x0,opts,[],X,y,C);
theta = X;
info
