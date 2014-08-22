function A = auc(L,fi)
% A = auc(L,fi)

% author: Mads Dyrholm
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
FPprev = 0;
TPprev = 0;
A=0;
fprev = -inf;
i = 1;

for i = 1:length(L)
  if (fi(i)~=fprev) 
    A = A + trapezoid_area(FP,FPprev,TP,TPprev);
    fprev = fi(i);
    FPprev = FP;
    TPprev = TP;
  end
  if (Lsorted(i) == 1)
    TP = TP + 1;
  else
    FP = FP + 1;
  end
end
A = A + trapezoid_area(FP,FPprev,TP,TPprev);
A = A / (P*N);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ta = trapezoid_area(X1,X2,Y1,Y2)
base = abs(X1-X2);
heightav = (Y1+Y2)/2;
ta = base * heightav;

