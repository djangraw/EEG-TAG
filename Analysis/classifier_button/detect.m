function [Y,Xm,P] = detect(X,P,label)
  
% [Y,P] = detect(X,P,label) is a on-line version of our binary event
% detection algorithm. The discrimination is performed here using Gaussian
% classifiers. X contains the EEG activity that is to be classified. It is
% given as a matrix with dimensions [#channels,#samples]. Y represents the
% classifier output. The algorithm tries to find a classifier such that Y is
% positive examples with label==1, and negative for examples with
% label==0. The variable label provides "truth" data for the detector to
% improve its performance. For instance, to detect P300 for an auditory
% probe one would give the detector as positive examples a segment of data
% of 100ms length starting 300ms after the auditory probe. Negative examples
% may include segments of data following an irrelevant auditory stimulus. If
% no label is provided the classifier will not improve and only the output Y
% for the current X will be returned.  Y could be used as "gauge" that
% measures the intensity of the activity associated with the event.  All
% updated parameters are saved in P and have to be provided in the next
% call. They can be initialized using detectinit(). For a binary
% classification one can compare Y to the current best threshold
% P.thresh. If Y > P.thresh the event can be considered as detected.
%
% See example call at the end.
%
% (c) Lucas Parra, October 13, 2003, all rights reserved. Exclusive usage
% license to Anil Raj, UWF.
%
% (c) Lucas Parra, Jun 21, 2004, modified to set threshold to include
% cost of making different types of errors.
%
% Christoforos Christoforou July 31, 2008, Returning the current mean of
% the trial in the variable P.currentMean 
% 
% 
%

c1 = 1;  % cost of false negative 

c2 = 1; % cost of false positive

% mean activity in this frame
Xmean = mean(X,2);

% generate detector output
Y = P.v'*Xmean + P.b;

% return current mean for this trial
Xm = Xmean;

% update Gaussians, discriminant vector and threshold

if nargin>=3 & ~isempty(label)
  

  % convert 1,0 into index labels 1,2 (positive, negative)
  if label, l=1; else l=2; end
  
  
  % number of samples in this frame
  L = size(X,2); 

  % update Gaussian's mean, sigma, and number of samples
  P.mu(:,l) = (P.N(l) * P.mu(:,l) + Xmean*L)/(P.N(l)+L);
  X = X - repmat(P.mu(:,l),[1 L]);
  % For some reason this returns nan value set thos to zero
  tmp = (P.N(l)*P.sig(:,:,l) + X*X')/(P.N(l)+L);  
  if (length(find(isnan(tmp))) > 0)
     fprintf('Block has issues detect line 67...\n'); 
  end;
  tmp(find(isnan(tmp)))=0;
  P.sig(:,:,l) = tmp;
  %P.sig(:,:,l) = (P.N(l)*P.sig(:,:,l) + X*X')/(P.N(l)+L);
  P.N(l) = P.N(l)+L;

  
  % compute discriminant vector and bias from Gaussians
  sigma = (P.sig(:,:,1)*P.N(1)+P.sig(:,:,2)*P.N(2))/sum(P.N);
  
  % add regularization
  lambda = sort(eig(sigma));
  
  % grab input parameter
  eigindex = str2num( ml_GetPrivateProfileString('reg', 'eigindex', 'CBCI.ini') );    
  
  % check for bad input
  if eigindex<1 || eigindex>64
    noise = 0*eye(size(X,1));
    sprintf('regularization disabled');  
  else
    noise = lambda(eigindex)*eye(size(X,1));
  end
  
  
  %if eigindex == 0
  %  noise = 0*eye(size(X,1));
  %else
  %  noise = lambda(eigindex)*eye(size(X,1));
  %end
    
  %smu = inv(sigma+noise)*P.mu;   % regularization code 
  smu = pinv(sigma)*P.mu;   % original code
%  smu = inv(sigma)*P.mu;   % fastter but not know if works yet
  P.v = smu(:,1)-smu(:,2);
  if prod(P.N)>0
    P.b = (P.mu(:,2)'*smu(:,2) - P.mu(:,1)'*smu(:,1))/2;
  end
  
  % store the means of each block for future reference
  %P.mhistory{l} = [P.mhistory{l} Xmean];    % can  be disabled to save memory

  if 0
      % deal with empty history at beginning
      E=[];

      % compute the classfier output for all means in history
      if ~isempty(P.mhistory{1}), P.y{1} = P.v' * P.mhistory{1} + P.b; end;
      if ~isempty(P.mhistory{2}), P.y{2} = P.v' * P.mhistory{2} + P.b; end;

      % Picks a threshold empirically based on all past mean X.
      % pick as threshold the y that would give the least errors.
      thresh = [P.y{1} P.y{2}];
      for i=1:length(thresh)
          E(i) = c1*sum(y{1}<thresh(i))+c2*sum(y{2}>thresh(i));
      end
      [tmp,minindx] = min(E);
      P.thresh = thresh(minindx);
  else
      P.thresh = 0;
  end
  
end







return
% -- this here is test code.

% examples with L samples each
D = 3;
N1 = 10;  % number of negative examples
N2 = 30;  % number of positive examples
L=10;     % number of samples per example

% generate fake data
X = randn(D,L,N1);             % N1 examples for negatives
X = cat(3,X,randn(D,L,N2)+2);  % N2 examples for positives

% and coresponding labels
labels = [zeros(N1,1); ones(N2,1)];

% I want to feed them to the algorithm in random order
rindx = randperm(size(X,3));

% here finally our code to be tested
P = detectinit(D);
for i=1:length(labels)
  [Y(rindx(i)), P] = detect(X(:,:,rindx(i)),P,labels(rindx(i)));
end

% show some results
clf
plot([Y' squeeze(mean(sum(repmat(P.v,[1 L, N1+N2]).*X),2))+P.b])
hold on;
plot([0 N1+N2], P.thresh*[1 1],'k:')
legend('online','final result','final treshold',2)
ylabel('detector output')
xlabel([num2str(N1) ' negative, ' num2str(N2) ' positve examples'])
