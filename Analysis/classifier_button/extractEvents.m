function [eventsQueue eventBuffer] = extractEvents(Xfilter,eventBuffer,epochParams);
% [eventsQueue eventBuffer] = extractEvents(Xfilter,eventBuffer);
%
% Extracts from the current block of data the events generatetd and splits
% it in epochs along with problem event type for further action. Events
% that the entire epoch has been completed (i.e enough data to fill the ERP window) are passed
% in the eventQueue. Events that are still waiting for data to be processes
% are stored in the eventBuffer for processing when enough data are
% available.
%
% Input :
%       
%       Xfilter : [D T] matrix of filtered EEG data. D number of channels
%       and T the number of samples in current segment. The first channel 
%       (i.e Xfilter(1,:)) includes the event trigger channel. The second
%       channel Xfilter(2,:) incudes button event triggers.
%
%       eventBuffer - internal structure that temporary stores events,
%       until the full epoched has been collected, initialy use an empty
%       list as input eventBuffer = [], in consecutive runs use the output
%       argument as an input.
%
%       epochParams - Specify details of how the epoching will take place. 
%
%                     epochParams.duration : Specify the epoch length in samples.
%
%                     epochParams.channels_subset : A list of channels to keep. If empty indicates all channels
%                     otherwise the index of channels to be used in epoching.
%
%
% Author : Christoforos Christoforou
% Date : July 30, 2008
%
% Update:
%     Author: Christoforos Christoforou
%     Date: March 03, 2009
%     Fixed a boundary issue for prolongated trigger onsets.
%

%%%
% for compatibility with CBCI v1.0 recorded data, remove uppon delivery
%%%

Xfilter(1,find(Xfilter(1,:) == 40)) = 0;

if (~isempty(eventBuffer)),
  % concatete unprocessed samples samples with new ones,
  Xfilter = cat(2,eventBuffer,Xfilter);
end;

if isempty(epochParams.channels_subset),
   epochParams.channels_subset = [1:size(Xfilter,1)];   % use all the channels
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Detect trigger onsets,
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

events=find(diff(Xfilter(1,:),1) > 0)+1;
events=events(find(Xfilter(1,events)>0)); % Remove 0 events, this can occure due to trigger channel the event drop 

samplesAvailable = size(Xfilter,2);

fullEvents_idx = find(events < (samplesAvailable - epochParams.duration));
PartialEvents_idx = find(events >= (samplesAvailable - epochParams.duration));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% extract full events             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%fprintf('minchan = %d, maxchan = %d\n',min(epochParams.channels_subset),max(epochParams.channels_subset));
%fprintf('acceptable range: [1 %d]\n',size(Xfilter,1));

if (length(fullEvents_idx)>0),
    X = zeros(length(epochParams.channels_subset),epochParams.duration,length(fullEvents_idx));
      for lcv=1:length(fullEvents_idx),
      X(epochParams.channels_subset,:,lcv) = Xfilter(epochParams.channels_subset,events(fullEvents_idx(lcv)):events(fullEvents_idx(lcv))+epochParams.duration-1);
    end;
    eventsQueue.data = X;
    eventsQueue.type = Xfilter(1,events(fullEvents_idx));
else
    eventsQueue = [];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% store unprocessed data for processing during the next iteration.  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


if (length(PartialEvents_idx) == 0),
   eventBuffer = Xfilter(:,end); % only keep one sample  
else
   if (events(PartialEvents_idx(1)) == 1),
       eventBuffer = Xfilter(:,(events(PartialEvents_idx(1))):end); 
   else    
       eventBuffer = Xfilter(:,(events(PartialEvents_idx(1))-1):end); 
   end;
end;






