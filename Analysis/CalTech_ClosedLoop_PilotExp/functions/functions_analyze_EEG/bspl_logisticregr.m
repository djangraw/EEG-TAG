function [theta,loglik,penloglik,Ey,H] = bspl_logisticregr(x,y,theta)
% LOGISTICREGR Maximum Likelihood logistic regression 
%
%    [theta,loglik,penloglik,Ey,H] = logisticregr(x,y,theta)
%    [theta,loglik,penloglik,Ey,H] = logisticregr(x,y)
%
% intput:
%
%      x : input matrix
%      y : taget vector \in {0,1}
%
% output:
%
%      theta     : e.g. 1D x ... [alpha,beta] so that E[y_i] = 1/(1+exp(-(alpha+beta*x_i)))
%      loglik    : log likelihood
%      penloglik : approx. model posterior
%      Ey        : predicted target (real \in [0,1])
%      H         : Hessian of the log likelihood    
%
% Author: Mads Dyrholm
[N,D] = size(x); if D>N, x = x'; [N,D] = size(x); end
if nargin<3, theta=zeros(D+1,1); end
X = [ones(N,1), x];
y = y(:);
stopcrit = 1e-8;
loglik = -1e10; delta = inf; m = 0;
while delta > stopcrit
  Xtheta = X*theta;
  % Newton iteration
  pix = 1./ (1+exp(-Xtheta));
  diagV = repmat(pix.*(1-pix),1,D+1);
  H = (X'*(diagV.*X));
  theta = theta + H\X'*(y-pix);
  %theta = theta + pinv(H)*X'*(y-pix);
  % log likelihood stopping check and display
  m = m+1;
  delta = loglik;
  loglik = sum( y.*(Xtheta) - log(1+exp(Xtheta)));
  fprintf('iteration %i: log likelihood = %f\n',m,loglik);
  delta = abs(delta-loglik);
end
% Laplace approx. model prob
penloglik = loglik + length(theta)*pi - 0.5*log(det(H));
% predict
Ey = 1./ (1+exp(-(Xtheta)));

