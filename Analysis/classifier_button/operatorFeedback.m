function operatorFeedback(resultsDatabase,mode)
% function operatorFeedback(resultsDatabase,mode)
%
%  Calculates a performance measure and returns the result for the operator
%  using either a text or gui mode.
%
% resultsDatabase : A structure the contrains the current results status as follows
%
%      resultsDatabase.data{1} = [];
%      resultsDatabase.sessionId = 0;
%      resultsDatabase.currentBlock = 0;
%      resultsDatabase.imagesInCurrentBlock = 0;  
%      resultsDatabase.blockcount = [];
%       resultsDatabase.blockStatus = 0;  
%
%  where resultsDatabase.data{1}  contains the info
%       [currentblock currentStimulus Ey (Ey>0.5) eventcode];
%
% mode : Three modes are supported
%   mode = 0 : no feedback (fast)
%   mode = 1 : text feedback (relativly fast)
%   mode = 2 : GUI feedback, can cause delays on slow machines.
%
%
% Author: Chrisoforos Christoforou
% Date : September 1, 2008
%

%save('debugOperator.mat','resultsDatabase');
if mode==0,
    % do nothing, simply return.
    return;
end;

nblocks = length(resultsDatabase.blockcount);

tmp = [];
for i=1:nblocks,
  numStim = resultsDatabase.blockcount(i);
  if (numStim>0),
    tmp = cat(2,tmp,resultsDatabase.data{i}(1:numStim,[3 5])');    
  end;
end;

targidx1 =  find(tmp(2,:) == 160);
targidx2 = find(tmp(2,:) == 210);
targidx = union(targidx1,targidx2);

nontargidx1 = find(tmp(2,:) == 80);
nontargidx2 = find(tmp(2,:) == 220);
nontargidx = union(nontargidx1,nontargidx2);

tmp(2,targidx) = 1;
tmp(2,nontargidx) = 0;
idx = [targidx nontargidx];
idx = sort(idx);
huskeL = tmp(2,idx);
huskefi = tmp(1,idx);
%if (length(idx) > 0)
if length(targidx) > 0 && length(nontargidx)>0
  Az = auc(huskeL,huskefi);   
else
  Az = NaN;  
end;

if (mode==1),
  if (isnan(Az))
      fprintf('No ground truth data available to estimate performance \n');
      return;
  else
      fprintf('Total labeled data : %d \n',length(huskeL));
      fprintf('Current Az performance : %2.2f \n',Az);
  end;
end;

    
if (mode == 2),
  if (isnan(Az))
      fprintf('No ground truth data available to estimate performance \n');
      return;
  else
      
  subplot(4,1,[1 2]);    
  rocpoints(huskeL,huskefi);
  axis square;
  title(['Az ' num2str(Az)]);
  subplot(4,1,3);    
  stem(huskeL);
  title('Pre-Triage');
  subplot(4,1,4);
 
  [v hidx] = sort(huskefi,'descend');
  stem(huskeL(hidx),'r');
  title('Post-Triage');
  end;
end
    

