function res = multiwindowFDA_run(Xproc,Cparams)
% res = multiwindowFDA_run(Xproc,Cparams)
% 
% Implements the classifier interface. 
%
% Author : Christoforos Christoforou
% Date : August 01, 2008
%



yvec = zeros(Cparams.numofwindows,1);
for t=1:Cparams.numofwindows,
    yvec(t) = Cparams.Pdetect(t).v' * Xproc(:,t) + Cparams.Pdetect(t).b;
end;
y = Cparams.W(1) + Cparams.W(2:end)' * yvec;
res = y;
