function [resultsDatabase] = add2resultset(Ey,resultsDatabase,eventcode)
% [resultsDatabase] = add2trainingset(Ey,resultsDatabase)
%
% Author : Christoforos Christoforou
% Date : August 2, 2008
%


if (nargin<1)
    resultsDatabase.data{1} = [];
    resultsDatabase.sessionId = 0;
    resultsDatabase.currentBlock = 0;
    resultsDatabase.imagesInCurrentBlock = 0;  
    resultsDatabase.blockcount = [];
    resultsDatabase.blockStatus = 0;  
    return
end

if (nargin<3),
  eventcode = -1;
end;
    


bufferjumps = 400;
resultsStructSize = 5;   % number of field in the result structure currently 4 fields

if (isempty(resultsDatabase)),
    resultsDatabase.data{1} = [];
    resultsDatabase.sessionId = 0;
    resultsDatabase.currentBlock = 0;
    resultsDatabase.imagesInCurrentBlock = 0;  
    resultsDatabase.blockcount = [];
    resultsDatabase.blockStatus = 0;  
end;

if (resultsDatabase.blockStatus == 0)
    % no current block available, do nothing
    fprintf('No current block selected');
    return 
end;


% expand the results dataset if buffer full, 
if (size(resultsDatabase.data{resultsDatabase.currentBlock},1)<= resultsDatabase.imagesInCurrentBlock),
    resultsDatabase.data{resultsDatabase.currentBlock} =  cat(1,resultsDatabase.data{resultsDatabase.currentBlock},zeros(bufferjumps,resultsStructSize));
end;

% prepair to accept a new stimulus results
resultsDatabase.imagesInCurrentBlock =  resultsDatabase.imagesInCurrentBlock + 1;    

cb = resultsDatabase.currentBlock;
cs = resultsDatabase.imagesInCurrentBlock;
resultsDatabase.data{cb}(cs,:) = [cb cs Ey (Ey>0.5) eventcode];
