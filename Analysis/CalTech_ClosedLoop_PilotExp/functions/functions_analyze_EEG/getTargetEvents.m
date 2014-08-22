%%%
%%%This function takes a matrix that describes all the events in a file,
%%%and just returns a single column of zeros and ones that correspond to
%%%the order in which just the distracter (zeros) and target (ones) events
%%%occured in the original data.  All other types of events are
%%%disregarded.
%%%
%%%[y] = getTargetEvents(eventdata,targetEvent,nontargetEvent);
%%%
%%%Last modified Sept 2009, EAP

function [y] = getTargetEvents(eventdata,targetEvent,nontargetEvent)


if nargin == 1
    targetEvent = 160;
    nontargetEvent = 80;
end

%%%
%%%These are the locations of the target/distracter trials in the cell
%%%matrix
targets = find(cell2mat(eventdata(:,1)) == targetEvent);
nontargets = find(cell2mat(eventdata(:,1)) == nontargetEvent);

%%%
events = [eventdata{targets,2}; eventdata{nontargets,2}];
y      = [ones(size(eventdata{targets,2},1),1); zeros(size(eventdata{nontargets,2},1),1)];

[Y,I] = sort(events,'ascend');

y = y(I);

