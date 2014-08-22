%%%
%%%In this function we determine the Fisher Linear Discriminant classifier
%%%using estimates of gaussian means and variance of the target and
%%%nontarget trials.
%%%
%%%If you want to have regularization, then specify which eigenvalue you
%%%want to used to regularize the matrix inverse.
%%%
%%%[Cparams] = estimateFLD_weights(Cparams,regularizationvalue);
%%%
%%%Cparams => all parameters of FLD classifier (weights:v, offset:b) stored
%%%in this strucuture, also store here is the estimates of the variance
%%%(sig) and mean (mu) for each electrode during eachtime window.  Can
%%%initialize Cparams using the multiwindowFDA_init.m function.
%%%
%%%regularizationvalue (optional) => if using regularization during matrix
%%%inverse, this is which eigenvalue to use
%%%
%%%Last modified Sept 2009 EAP

function [Cparams] = estimateFLD_weights(Cparams,regularizationvalue)

if (nargin<2) || isempty(regularizationvalue)
    regularizationvalue = [];
end

%%%
%%%You need to find the weights for each time window independently
for k=1:Cparams.numofwindows
    %%%
    %compute discriminant vector and bias from Gaussians for this time
    %window
    %%%sigma is an estimate of the pooled variance
    sigma = ( Cparams.Pdetect(k).sig(:,:,1)*Cparams.Pdetect(k).N(1) + Cparams.Pdetect(k).sig(:,:,2)*Cparams.Pdetect(k).N(2) ) / sum(Cparams.Pdetect(k).N);

    %%%Estimate of noise in this time window for use in regularization
    if ~isempty(regularizationvalue)
        % add regularization
        lambda = sort(eig(sigma));  
        %%%
        % check for bad input
        if eigindex<1 || eigindex>64
            noise = 0*eye(size(sigma,1));
            sprintf('regularization disabled');  
        else
            noise = lambda(eigindex)*eye(size(sigma,1));
        end
    end
    
    %%%If using regularization, now is the time
    if ~isempty(regularizationvalue)
        smu = inv(sigma+noise)*P.mu;   % regularization code 
    else
        smu = pinv(sigma)*Cparams.Pdetect(k).mu;   % original code (uses pseudo inverse)
        %  smu = inv(sigma)*Cparams.Pdetect(k).mu;   % faster but not know if works yet
    end
    
    %%%Final calculation of the weights
    Cparams.Pdetect(k).v = smu(:,1)-smu(:,2);

    %%%Find the offset term
    if prod(Cparams.Pdetect(k).N)>0
        Cparams.Pdetect(k).b = (Cparams.Pdetect(k).mu(:,2)'*smu(:,2) - Cparams.Pdetect(k).mu(:,1)'*smu(:,1))/2;
    end
end

