function [Az,tp,fp,fc]=rocarea(p,label);

% [Az,tp,fp]=rocarea(p,label) computes the area under the ROC curve
% corresponding to the classification output p. Labels contain the truth
% data {0,1}. tp and lp are the true and falce positive rate. If no output
% arguments are specified it will display an ROC curve with the Az and
% approximate fraction correct.

[tmp,indx]=sort(-p);

label = label>0;

Np=sum(label==1);
Nn=sum(label==0);

tp=0; pinc=1/Np;
fp=0; finc=1/Nn;
Az=0;

N=Np+Nn;

tp=zeros(N+1,1);
fp=zeros(N+1,1);

for i=1:N
  
  tp(i+1)=tp(i)+label(indx(i))/Np;
  fp(i+1)=fp(i)+(~label(indx(i)))/Nn;
  Az = Az + (~label(indx(i)))*tp(i+1)/Nn;

end;

[m,i]=min(fp-tp);
fc = 1-mean([fp(i), 1-tp(i)]);

if nargout==0
  plot(fp,tp); axis([0 1 0 1]); hold on
  plot([0 1],[1 0],':'); hold off
  xlabel('false positive rate') 
  ylabel('true positive rate') 
  title('ROC Curve'); axis([0 1 0 1]); 
  text(0.4,0.2,sprintf('Az = %.2f',Az))
  text(0.4,0.1,sprintf('fc = %.2f',fc))
  axis square
end
  












