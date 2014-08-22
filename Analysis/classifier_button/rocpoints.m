function R = rocpoints(L,fi,prop)
%  R = rocpoints(L,fi)
%
%    or 
%
%  rocpoints(L,fi); to visualize
%
% rocpoints(L,fi,prop)
%   prop : specify the style/color of the line of the ROC,
%          it is a character string as used in the matlab plot function.
%
% author: Mads Dyrholm
%
% Revision : Added option to specify style of the roc curve.
%            Author: Christoforos Christoforou  
%

if (nargin<3),
    prop = 'b';
end;

P = sum(L==1);
N = sum(L==0);
if ((N==0) | (P==0))
  error('N and P must be positive');
end

[dum,idx] = sort(fi);
idx = idx(end:-1:1);
Lsorted = L(idx);

FP=0;
TP=0;
R=[];
fprev = -inf;
i = 1;

for i = 1:length(L)
  if (fi(i)~=fprev) 
    R = [R;FP/N, TP/P];
    fprev = fi(i);
  end
  if (Lsorted(i) == 1)
    TP = TP + 1;
  else
    FP = FP + 1;
  end
end
R = [R;FP/N, TP/P];

if (nargout==0),
  plot(R(:,1),R(:,2),prop);
  xlabel('False positive rate');
  ylabel('True positive rate');
  h=line([0 1],[0 1]); set(h,'color',[0 0 0]);
  h=line([1 0],[0 1]); set(h,'color',[0 0 0]);
end
